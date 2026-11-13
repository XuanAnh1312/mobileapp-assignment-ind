import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_todo/models/account_profile.dart';
import 'package:uth_todo/models/task.dart';
import 'package:uth_todo/models/task_statistics.dart';
import 'package:uth_todo/screens/account_screen.dart';
import 'package:uth_todo/screens/login_screen.dart';
import 'package:uth_todo/screens/task_shell.dart';
import 'package:uth_todo/services/account_service.dart';
import 'package:uth_todo/services/task_store.dart';

class _Account extends AccountService {
  AccountProfile profile = const AccountProfile(
    uid: 'A',
    name: 'Minh Anh',
    email: 'minhanh@example.com',
    googleLinked: true,
  );
  final events = StreamController<AccountProfile>.broadcast(sync: true);
  Object? nameError;
  Object? avatarError;
  int avatarCalls = 0;
  int logoutCalls = 0;
  @override
  AccountProfile get current => profile;
  @override
  Stream<AccountProfile> get changes => events.stream;
  @override
  Future<void> updateName(String name) async {
    if (nameError != null) throw nameError!;
    profile = AccountProfile(
      uid: profile.uid,
      name: name.trim(),
      email: profile.email,
      googleLinked: profile.googleLinked,
    );
    events.add(profile);
  }

  @override
  Future<void> changeAvatar() async {
    avatarCalls++;
    if (avatarError != null) throw avatarError!;
  }

  @override
  Future<void> signOut() async {
    logoutCalls++;
    profile = const AccountProfile();
    events.add(profile);
  }
}

class _Store extends TaskStore {
  int syncCalls = 0;
  DateTime? confirmed;
  @override
  DateTime? get lastSyncedAt => confirmed;
  @override
  Future<void> syncNow() async {
    syncCalls++;
    confirmed = DateTime.now();
    notifyListeners();
  }
}

Widget _app(TaskStore store, Widget home) => TaskScope(
  store: store,
  child: MaterialApp(
    theme: ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F5BEA))
          .copyWith(primary: const Color(0xFF2F5BEA)),
    ),
    home: home,
  ),
);

void main() {
  test('Profile statistics use actual completion times and preserve legacy unknowns', () {
    final now = DateTime(2026, 11, 10, 12);
    final tasks = [
      Task(
        id: '1',
        title: 'Early',
        due: DateTime(2026, 11, 9, 12),
        done: true,
        completedAt: DateTime(2026, 11, 9, 11),
      ),
      Task(
        id: '2',
        title: 'Late',
        due: DateTime(2026, 11, 10, 9),
        done: true,
        completedAt: DateTime(2026, 11, 10, 10),
      ),
      Task(
        id: '3',
        title: 'Legacy',
        due: DateTime(2026, 11, 10, 20),
        done: true,
      ),
      Task(id: '4', title: 'Pending', due: DateTime(2026, 11, 11, 20)),
    ];
    final stats = TaskStatistics(tasks, now: now);
    expect(stats.completed, 3);
    expect(stats.percent, 75);
    expect(stats.onTimePercent, 50);
    expect(stats.streak, 2);
    expect(stats.days, [1, 2, 1, 0, 0, 0, 0]);
    expect(stats.completedThisWeek, 3);
    expect(TaskStatistics([tasks[2]], now: now).streak, isNull);
    expect(TaskStatistics([tasks[2]], now: now).onTimePercent, isNull);
    expect(Task.fromJson(tasks[0].toJson()).completedAt, tasks[0].completedAt);
    expect(tasks[0].copyWith(done: false).completedAt, isNull);
  });

  test(
    'Toggling completion records the time and clears it when undone',
    () async {
      final store = TaskStore(
        initialTasks: [Task(id: '1', title: 'Task', due: DateTime.now())],
      );
      addTearDown(store.dispose);
      await store.toggle('1');
      expect(store.find('1')!.completedAt, isNotNull);
      await store.toggle('1');
      expect(store.find('1')!.completedAt, isNull);
    },
  );

  testWidgets(
    'Settings → account opens Profile, Privacy and returns to Settings',
    (tester) async {
      final store = TaskStore();
      addTearDown(store.dispose);
      await tester.pumpWidget(_app(store, const TaskShell()));
      await tester.tap(find.text('Cài đặt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tài khoản'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text('Hồ sơ'), findsOneWidget);
      await tester.ensureVisible(find.text('Quyền riêng tư'));
      await tester.tap(find.text('Quyền riêng tư'));
      await tester.pumpAndSettle();
      expect(find.text('Dữ liệu của bạn'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cài đặt'));
      await tester.pumpAndSettle();
      expect(find.text('Tài khoản'), findsOneWidget);
      expect(find.byType(AccountScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Guest can open Login, go back, then continue as guest to Home', (
    tester,
  ) async {
    final store = TaskStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(_app(store, const TaskShell()));
    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Đăng nhập bằng Google'));
    await tester.tap(find.text('Đăng nhập bằng Google'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);
    await tester.tap(find.text('Đăng nhập bằng Google'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dùng thử không cần tài khoản'));
    await tester.tap(find.text('Dùng thử không cần tài khoản'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Tài khoản'), findsNothing);
    expect(find.text('Chào UTH!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile edits validate and update the actual account stream', (
    tester,
  ) async {
    final service = _Account();
    final store = TaskStore();
    addTearDown(() async {
      store.dispose();
      await service.events.close();
    });
    await tester.pumpWidget(_app(store, AccountScreen(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('Minh Anh'), findsOneWidget);
    expect(find.text('MA'), findsOneWidget);
    expect(find.text('✓ Đã liên kết tài khoản Google'), findsOneWidget);
    await tester.tap(find.text('Sửa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile-name')), '');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập tên hiển thị.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('profile-name')),
      'Nguyễn Minh An',
    );
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
    expect(service.current.name, 'Nguyễn Minh An');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Sync status requires confirmation; avatar errors do not fake an update',
    (tester) async {
      final service = _Account()
        ..avatarError = FirebaseException(
          plugin: 'firebase_storage',
          code: 'unauthorized',
        );
      final store = _Store();
      addTearDown(() async {
        store.dispose();
        await service.events.close();
      });
      await tester.pumpWidget(_app(store, AccountScreen(service: service)));
      await tester.pumpAndSettle();
      expect(find.text('Chưa xác nhận'), findsOneWidget);
      expect(find.text('Vừa xong'), findsNothing);
      await tester.ensureVisible(find.text('Đồng bộ dữ liệu'));
      await tester.tap(find.text('Đồng bộ dữ liệu'));
      await tester.pumpAndSettle();
      expect(store.syncCalls, 1);
      expect(find.text('Vừa xong'), findsOneWidget);
      await tester.ensureVisible(find.byIcon(Icons.camera_alt_outlined));
      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      await tester.pumpAndSettle();
      expect(service.avatarCalls, 1);
      expect(find.textContaining('Chưa tải được ảnh đại diện'), findsOneWidget);
      expect(service.current.photoUrl, isNull);
    },
  );

  testWidgets('Logout returns to the previous root screen', (tester) async {
    final service = _Account();
    final store = TaskStore();
    addTearDown(() async {
      store.dispose();
      await service.events.close();
    });
    await tester.pumpWidget(
      _app(
        store,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<bool>(
                context,
                MaterialPageRoute<bool>(
                  builder: (_) => AccountScreen(service: service),
                ),
              ),
              child: const Text('Mở hồ sơ'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở hồ sơ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Đăng xuất'));
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(service.logoutCalls, 1);
    expect(find.byType(AccountScreen), findsNothing);
    expect(find.text('Mở hồ sơ'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
  ]) {
    testWidgets('Profile scrolls without overflow at $size with large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _Account();
      final store = TaskStore(
        initialTasks: [
          Task(
            id: '1',
            title: 'Done',
            due: DateTime.now().add(const Duration(hours: 1)),
            done: true,
            completedAt: DateTime.now(),
          ),
        ],
      );
      addTearDown(() async {
        store.dispose();
        await service.events.close();
      });
      await tester.pumpWidget(
        TaskScope(
          store: store,
          child: MaterialApp(
            theme: ThemeData(useMaterial3: false),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: AccountScreen(service: service),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
