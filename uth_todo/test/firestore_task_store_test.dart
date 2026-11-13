import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uth_todo/models/task.dart';
import 'package:uth_todo/screens/add_task_screen.dart';
import 'package:uth_todo/screens/task_shell.dart';
import 'package:uth_todo/services/firestore_task_repository.dart';
import 'package:uth_todo/services/task_store.dart';

class _Remote extends FirestoreTaskRepository {
  _Remote(String uid) : super(uid: uid);
  final events = StreamController<List<Task>>.broadcast(sync: true);
  final writes = <Task>[];
  final deletions = <String>[];
  Completer<void>? writeGate;
  Object? writeError;
  int subscriptions = 0;
  List<Task> serverTasks = [];
  Object? serverError;

  @override
  Stream<List<Task>> watchTasks() {
    subscriptions++;
    return events.stream;
  }

  @override
  Future<void> save(Task task) async {
    writes.add(task);
    await writeGate?.future;
    if (writeError != null) throw writeError!;
  }

  @override
  Future<void> remove(String taskId) async {
    deletions.add(taskId);
  }

  @override
  Future<List<Task>> fetchFromServer() async {
    if (serverError != null) throw serverError!;
    return serverTasks;
  }
}

Task _task(String id) => Task(id: id, title: 'Việc $id', due: DateTime.now());

Widget _app(TaskStore store) => TaskScope(
  store: store,
  child: MaterialApp(
    theme: ThemeData(useMaterial3: false),
    home: const TaskShell(),
  ),
);

void main() {
  test(
    'Manual sync confirms server data and never reports success after failure',
    () async {
      final store = TaskStore();
      final remote = _Remote('A');
      addTearDown(() async {
        store.dispose();
        await remote.events.close();
      });
      store.bindRepository(remote);
      remote.events.add([_task('cached')]);
      expect(store.lastSyncedAt, isNull);
      remote.serverError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      await expectLater(store.syncNow(), throwsA(isA<FirebaseException>()));
      expect(store.lastSyncedAt, isNull);
      expect(store.tasks.single.id, 'cached');
      remote.serverError = null;
      remote.serverTasks = [_task('server')];
      await store.syncNow();
      expect(store.lastSyncedAt, isNotNull);
      expect(store.tasks.single.id, 'server');
      store.bindRepository(null);
      expect(store.lastSyncedAt, isNull);
    },
  );

  test('Cloud changes drive the list; guest data stays separate on disk', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await TaskStore.load();
    final remote = _Remote('A');
    addTearDown(() async {
      store.dispose();
      await remote.events.close();
    });

    await store.save(_task('guest'));
    store.bindRepository(remote);
    expect(store.tasks, isEmpty);
    expect(store.loading, isTrue);
    expect(remote.writes, isEmpty);
    remote.events.add([_task('cloud')]);
    expect(store.loading, isFalse);
    expect(store.tasks.single.id, 'cloud');

    await store.toggle('cloud');
    expect(remote.writes.single.done, isTrue);
    // Don't synthesize a successful cloud state before receiving its snapshot.
    expect(store.tasks.single.done, isFalse);
    remote.events.add([_task('cloud').copyWith(done: true)]);
    expect(store.tasks.single.done, isTrue);
    await store.remove('cloud');
    expect(remote.deletions, ['cloud']);
    remote.events.add([]);
    expect(store.tasks, isEmpty);

    store.bindRepository(null);
    expect(remote.events.hasListener, isFalse);
    expect(store.tasks.single.id, 'guest');
    final reloaded = await TaskStore.load();
    expect(reloaded.tasks.single.id, 'guest');
    reloaded.dispose();
  });

  test(
    'Changing accounts cancels the previous stream and clears its data',
    () async {
      final store = TaskStore();
      final a = _Remote('A');
      final b = _Remote('B');
      addTearDown(() async {
        store.dispose();
        await a.events.close();
        await b.events.close();
      });
      store.bindRepository(a);
      a.events.add([_task('A')]);
      store.bindRepository(b);
      expect(a.events.hasListener, isFalse);
      expect(store.tasks, isEmpty);
      a.events.add([_task('stale-A')]);
      expect(store.tasks, isEmpty);
      b.events.add([_task('B')]);
      expect(store.tasks.single.id, 'B');
    },
  );

  test(
    'A pending write from A cannot change B or unlock B pending write',
    () async {
      final store = TaskStore();
      final a = _Remote('A')..writeGate = Completer<void>();
      final b = _Remote('B')..writeGate = Completer<void>();
      addTearDown(() async {
        store.dispose();
        await a.events.close();
        await b.events.close();
      });
      store.bindRepository(a);
      a.events.add([_task('A')]);
      final oldWrite = expectLater(
        store.save(_task('A-new')),
        throwsStateError,
      );
      store.bindRepository(b);
      b.events.add([_task('B')]);
      final newWrite = store.save(_task('B-new'));
      a.writeGate!.complete();
      await oldWrite;
      expect(store.tasks.single.id, 'B');
      expect(store.saving, isTrue);
      b.writeGate!.complete();
      await newWrite;
      expect(store.saving, isFalse);
      expect(a.writes.single.id, 'A-new');
      expect(b.writes.single.id, 'B-new');
    },
  );

  test(
    'Permission errors are visible, block writes and can be retried',
    () async {
      final store = TaskStore();
      final remote = _Remote('A');
      addTearDown(() async {
        store.dispose();
        await remote.events.close();
      });
      store.bindRepository(remote);
      remote.events.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      expect(store.loading, isFalse);
      expect(store.syncError, contains('Firestore Rules'));
      await expectLater(store.save(_task('blocked')), throwsStateError);
      expect(remote.writes, isEmpty);
      store.retrySync();
      expect(store.loading, isTrue);
      expect(remote.subscriptions, 2);
      remote.events.add([_task('retry')]);
      expect(store.syncError, isNull);
      expect(store.tasks.single.id, 'retry');
    },
  );

  test('Malformed data explains the required Firestore timestamp', () async {
    final store = TaskStore();
    final remote = _Remote('A');
    addTearDown(() async {
      store.dispose();
      await remote.events.close();
    });
    store.bindRepository(remote);
    remote.events.addError(const FormatException('Invalid task data'));
    expect(store.syncError, contains('due phải là timestamp'));
    expect(store.tasks, isEmpty);
  });

  test(
    'Rejected writes preserve the current list and restore the save button',
    () async {
      final store = TaskStore();
      final remote = _Remote('A')
        ..writeError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      addTearDown(() async {
        store.dispose();
        await remote.events.close();
      });
      store.bindRepository(remote);
      remote.events.add([_task('existing')]);
      await expectLater(
        store.save(_task('rejected')),
        throwsA(isA<FirebaseException>()),
      );
      expect(store.tasks.single.id, 'existing');
      expect(store.saving, isFalse);
    },
  );

  test(
    'Disposal cancels the listener and handles a late write completion',
    () async {
      final store = TaskStore();
      final remote = _Remote('A')..writeGate = Completer<void>();
      store.bindRepository(remote);
      remote.events.add([]);
      final write = expectLater(store.save(_task('late')), throwsStateError);
      store.dispose();
      expect(remote.events.hasListener, isFalse);
      remote.writeGate!.complete();
      await write;
      await remote.events.close();
    },
  );

  testWidgets(
    'Loading/error/retry is displayed rather than a silent empty list',
    (tester) async {
      final store = TaskStore();
      final remote = _Remote('A');
      addTearDown(() async {
        store.dispose();
        await remote.events.close();
      });
      store.bindRepository(remote);
      await tester.pumpWidget(_app(store));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      remote.events.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Firestore Rules'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      remote.events.add([_task('cloud')]);
      await tester.pumpAndSettle();
      expect(find.text('Việc cloud'), findsOneWidget);
      expect(find.textContaining('Firestore Rules'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Account changes close a form from the previous session', (
    tester,
  ) async {
    final store = TaskStore(initialTasks: [_task('guest')]);
    final remote = _Remote('A');
    addTearDown(() async {
      store.dispose();
      await remote.events.close();
    });
    await tester.pumpWidget(_app(store));
    await tester.tap(find.byTooltip('Thêm công việc'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task-title')), 'Nhập dở');
    store.bindRepository(remote);
    await tester.pump();
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(AddTaskScreen), findsNothing);
    remote.events.add([_task('account')]);
    await tester.pumpAndSettle();
    expect(find.text('Việc account'), findsOneWidget);
    store.bindRepository(null);
    await tester.pumpAndSettle();
    expect(find.text('Việc guest'), findsOneWidget);
    expect(find.text('Việc account'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
