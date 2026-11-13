import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uth_todo/models/task.dart';
import 'package:uth_todo/screens/task_shell.dart';
import 'package:uth_todo/services/firestore_task_repository.dart';
import 'package:uth_todo/services/mock_task_api.dart';
import 'package:uth_todo/services/task_store.dart';

import 'mock_task_api_test.dart' as fixtures;

Future<void> finishImport(TaskStore store) async {
  for (var step = 0; step < 30 && store.apiLoading; step++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(store.apiLoading, isFalse);
}

class _Account extends FirestoreTaskRepository {
  _Account(String uid) : super(uid: uid);
  final events = StreamController<List<Task>>.broadcast(sync: true);
  final tasks = <String, Task>{};
  final importedIds = <String>[];
  bool imported = false;

  @override
  Stream<List<Task>> watchTasks() async* {
    yield tasks.values.toList();
    yield* events.stream;
  }

  @override
  Future<void> importMockTasksOnce(List<Task> samples) async {
    if (imported) return;
    for (final task in samples) {
      tasks.putIfAbsent(task.id, () => task);
      importedIds.add(task.id);
    }
    imported = true;
    events.add(tasks.values.toList());
  }

  @override
  Future<void> save(Task task) async {
    tasks[task.id] = task;
    events.add(tasks.values.toList());
  }

  @override
  Future<void> remove(String id) async {
    tasks.remove(id);
    events.add(tasks.values.toList());
  }
}

void main() {
  test('Guest import is durable and refresh/relaunch preserves edits and deletions', () async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient(
      (_) async =>
          fixtures.jsonResponse([fixtures.apiTask(), fixtures.apiTask(id: 3)]),
    );
    final store = await TaskStore.load();
    store.attachMockApi(MockTaskApi(token: 'test', client: client));
    await finishImport(store);
    expect(store.tasks.length, 2);
    await store.save(store.find('mock_2')!.copyWith(title: 'Tên đã sửa'));
    await store.remove('mock_3');
    await store.importMockTasks();
    expect(store.tasks.single.title, 'Tên đã sửa');
    store.dispose();
    final restored = await TaskStore.load();
    addTearDown(restored.dispose);
    restored.attachMockApi(MockTaskApi(token: 'test', client: client));
    await finishImport(restored);
    expect(restored.tasks.single.title, 'Tên đã sửa');
    expect(restored.find('mock_3'), isNull);
  });

  test('HTTP failure keeps existing tasks and retry imports once', () async {
    var fail = true;
    final store = TaskStore(
      initialTasks: [
        Task(id: 'local', title: 'Việc riêng', due: DateTime.now()),
      ],
    );
    addTearDown(store.dispose);
    store.attachMockApi(
      MockTaskApi(
        token: 'test',
        client: MockClient(
          (_) async => fail
              ? fixtures.jsonResponse({}, status: 401)
              : fixtures.jsonResponse([fixtures.apiTask()]),
        ),
      ),
    );
    await finishImport(store);
    expect(store.apiError, contains('MOCK_API_TOKEN'));
    expect(store.tasks.single.id, 'local');
    expect(store.syncError, isNull);
    fail = false;
    await store.retryMockApi();
    expect(store.apiError, isNull);
    expect(store.tasks.map((t) => t.id), containsAll(['local', 'mock_2']));
  });

  test(
    'Account import does not upload guest tasks; deletion is not resurrected',
    () async {
      final store = TaskStore(
        initialTasks: [
          Task(id: 'guest', title: 'Việc khách', due: DateTime.now()),
        ],
      );
      final account = _Account('A');
      addTearDown(() async {
        store.dispose();
        await account.events.close();
      });
      store.bindRepository(account);
      await Future<void>.delayed(Duration.zero);
      store.attachMockApi(
        MockTaskApi(
          token: 'test',
          client: MockClient(
            (_) async => fixtures.jsonResponse([fixtures.apiTask()]),
          ),
        ),
      );
      await finishImport(store);
      expect(account.importedIds, ['mock_2']);
      expect(account.tasks.containsKey('guest'), isFalse);
      expect(store.find('mock_2'), isNotNull);
      await store.remove('mock_2');
      await store.importMockTasks();
      expect(account.tasks, isEmpty);
      expect(store.tasks, isEmpty);
    },
  );

  test(
    'A late guest HTTP response cannot be imported into the signed-in account',
    () async {
      final lateGuest = Completer<http.Response>();
      var calls = 0;
      final store = TaskStore();
      final account = _Account('A');
      addTearDown(() async {
        store.dispose();
        await account.events.close();
      });
      store.attachMockApi(
        MockTaskApi(
          token: 'test',
          client: MockClient((_) {
            calls++;
            return calls == 1
                ? lateGuest.future
                : Future.value(
                    fixtures.jsonResponse([fixtures.apiTask(id: 3)]),
                  );
          }),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      store.bindRepository(account);
      await finishImport(store);
      lateGuest.complete(fixtures.jsonResponse([fixtures.apiTask()]));
      await Future<void>.delayed(Duration.zero);
      expect(account.importedIds, ['mock_3']);
      expect(store.find('mock_2'), isNull);
      expect(store.find('mock_3'), isNotNull);
    },
  );

  testWidgets(
    'API data reaches Home, List and Detail and can be edited locally',
    (tester) async {
      final store = TaskStore();
      addTearDown(store.dispose);
      store.attachMockApi(
        MockTaskApi(
          token: 'test',
          client: MockClient(
            (_) async => fixtures.jsonResponse([fixtures.apiTask()]),
          ),
        ),
      );
      await tester.pumpWidget(
        TaskScope(
          store: store,
          child: MaterialApp(
            theme: ThemeData(useMaterial3: false),
            home: const TaskShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Old API dates remain old dates; they appear as overdue rather than today.
      expect(find.text('Việc quá hạn'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Ôn chương 3 – Cấu trúc dữ liệu'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Ôn chương 3 – Cấu trúc dữ liệu'));
      await tester.pumpAndSettle();
      expect(find.text('Đọc tài liệu tiếng Việt.'), findsOneWidget);
      await tester.tap(find.text('Sửa'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('task-title')),
        'Việc API đã chỉnh sửa',
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(store.find('mock_2')!.title, 'Việc API đã chỉnh sửa');
      await tester.tap(find.widgetWithText(TextButton, 'Danh sách'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Danh sách'));
      await tester.pumpAndSettle();
      expect(find.text('Việc API đã chỉnh sửa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
