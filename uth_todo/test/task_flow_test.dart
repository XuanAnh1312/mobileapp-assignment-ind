import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uth_todo/models/task.dart';
import 'package:uth_todo/screens/add_task_screen.dart';
import 'package:uth_todo/screens/background_screen.dart';
import 'package:uth_todo/screens/task_shell.dart';
import 'package:uth_todo/services/task_store.dart';
import 'package:uth_todo/widgets/task_widgets.dart';

Task sample({
  String id = '1',
  String title = 'Nộp bài tập Lập trình di động',
  bool done = false,
}) => Task(
  id: id,
  title: title,
  due: DateTime.now().copyWith(hour: 9, minute: 0),
  done: done,
  priority: TaskPriority.high,
  note: 'Nộp file .zip lên hệ thống của trường. Nhớ kèm ảnh chụp màn hình app chạy trên máy ảo.',
  subtasks: const [
    Subtask(id: 's1', title: 'Hoàn thiện màn hình đăng nhập', done: true),
    Subtask(id: 's2', title: 'Chụp ảnh màn hình app', done: true),
    Subtask(id: 's3', title: 'Nén file và nộp bài'),
  ],
);

Widget app(TaskStore store, {Widget child = const TaskShell()}) => TaskScope(
  store: store,
  child: MaterialApp(
    theme: ThemeData(
      useMaterial3: false,
      primaryColor: const Color(0xFF2F5BEA),
    ),
    home: child,
  ),
);

void main() {
  test('Tasks and subtasks persist through a new store instance; deleting stays deleted', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await TaskStore.load();
    await first.save(sample());
    await first.toggle('1');
    final second = await TaskStore.load();
    expect(second.find('1')!.done, isTrue);
    expect(second.find('1')!.subtasks.where((s) => s.done).length, 2);
    await second.remove('1');
    final third = await TaskStore.load();
    expect(third.tasks, isEmpty);
    first.dispose();
    second.dispose();
    third.dispose();
  });

  testWidgets(
    'Add validates, cancel leaves data alone, save updates Home and List',
    (tester) async {
      final store = TaskStore();
      addTearDown(store.dispose);
      await tester.pumpWidget(app(store));
      await tester.tap(find.byTooltip('Thêm công việc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập tên công việc.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('task-title')),
        'Ôn chương 4 – Giải thuật',
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(store.tasks, isEmpty);
      await tester.tap(find.byTooltip('Thêm công việc'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('task-title')),
        'Ôn chương 4 – Giải thuật',
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(store.tasks.single.title, 'Ôn chương 4 – Giải thuật');
      expect(find.text('Ôn chương 4 – Giải thuật'), findsOneWidget);
      await tester.tap(find.text('Trang chủ'));
      await tester.pumpAndSettle();
      expect(find.text('0/1 việc'), findsOneWidget);
      await tester.tap(find.byType(TaskCheck).first);
      await tester.pumpAndSettle();
      expect(find.text('1/1 việc'), findsOneWidget);
      expect(store.tasks.single.done, isTrue);
    },
  );

  testWidgets(
    'Search, category, detail editing, subtasks and delete share one source',
    (tester) async {
      final store = TaskStore(
        initialTasks: [
          sample(),
          sample(id: '2', title: 'Đi chợ').copyWith(group: TaskGroup.life),
        ],
      );
      addTearDown(store.dispose);
      await tester.pumpWidget(app(store));
      await tester.tap(find.text('Danh sách'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('task-search')), 'Đi chợ');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TaskTile, 'Đi chợ'), findsOneWidget);
      expect(find.text('Nộp bài tập Lập trình di động'), findsNothing);
      await tester.enterText(find.byKey(const Key('task-search')), '');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Học tập'));
      await tester.pumpAndSettle();
      expect(find.text('Đi chợ'), findsNothing);
      await tester.tap(find.text('Nộp bài tập Lập trình di động'));
      await tester.pumpAndSettle();
      expect(find.byType(BackgroundScreen), findsOneWidget);
      await tester.tap(find.text('Sửa'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('task-title')),
        'Bài tập đã sửa',
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Bài tập đã sửa'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('subtask-title')));
      await tester.enterText(
        find.byKey(const Key('subtask-title')),
        'Kiểm tra file zip',
      );
      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();
      expect(store.find('1')!.subtasks.length, 4);
      await tester.ensureVisible(find.text('Xóa công việc'));
      await tester.tap(find.text('Xóa công việc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(store.find('1'), isNull);
      expect(find.byType(BackgroundScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Adding a task clears a previous search so the new task is visible',
    (tester) async {
      final store = TaskStore(initialTasks: [sample()]);
      addTearDown(store.dispose);
      await tester.pumpWidget(app(store));
      await tester.tap(find.text('Danh sách'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('task-search')),
        'Không có kết quả',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Thêm công việc'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('task-title')),
        'Công việc mới cần nhìn thấy',
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Công việc mới cần nhìn thấy'), findsOneWidget);
      expect(
        tester
                .widget<TextField>(find.byKey(const Key('task-search')))
                .controller
                ?.text ??
            '',
        isEmpty,
      );
    },
  );

  testWidgets('Date, time, group, priority and reminder choices are saved', (
    tester,
  ) async {
    final store = TaskStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(app(store));
    await tester.tap(find.byTooltip('Thêm công việc'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title')),
      'Việc có lịch hẹn',
    );
    await tester.tap(find.text('Ngày'));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(DatePickerDialog),
            matching: find.text('15'),
          )
          .last,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giờ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '19');
    await tester.enterText(fields.at(1), '30');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuộc sống'));
    await tester.tap(find.text('Cao'));
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    final task = store.tasks.single;
    expect(task.due.day, 15);
    expect(task.due.hour, 19);
    expect(task.due.minute, 30);
    expect(task.group, TaskGroup.life);
    expect(task.priority, TaskPriority.high);
    expect(task.reminder, isFalse);
  });

  testWidgets(
    'Subtask editing and completion update progress; settings and reminders open',
    (tester) async {
      final store = TaskStore(initialTasks: [sample()]);
      addTearDown(store.dispose);
      await tester.pumpWidget(app(store));
      await tester.tap(find.text('Thông báo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nhắc nhở trong ứng dụng'), findsOneWidget);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cài đặt'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Công việc được lưu'), findsOneWidget);
      Navigator.pop(tester.element(find.text('Tài khoản')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(sample().title));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Checkbox).last);
      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
      await tester.tap(find.byTooltip('Sửa việc nhỏ').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Nộp bài lên hệ thống',
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(store.find('1')!.subtasks.last.title, 'Nộp bài lên hệ thống');
      await tester.tap(find.byTooltip('Xóa việc nhỏ').last);
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Large text keeps task screens scrollable without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = TaskStore(initialTasks: [sample()]);
    addTearDown(store.dispose);
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
          home: const TaskShell(),
        ),
      ),
    );

    await tester.tap(find.text('Danh sách'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(sample().title));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Xóa công việc'));

    await tester.tap(find.widgetWithText(TextButton, 'Danh sách'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thêm công việc'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lưu công việc'));
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
  ]) {
    testWidgets('All screens fit $size; long Background scrolls to delete', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final longTask = sample().copyWith(
        note: List.filled(10, 'Ghi chú dài cần giữ đủ nội dung.').join('\n'),
        subtasks: List.generate(
          10,
          (i) => Subtask(
            id: '$i',
            title: 'Việc nhỏ thứ $i có nội dung dài để kiểm tra xuống dòng',
          ),
        ),
      );
      final store = TaskStore(initialTasks: [longTask]);
      addTearDown(store.dispose);
      await tester.pumpWidget(app(store));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Danh sách'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(longTask.title));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Xóa công việc'));
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const Key('background-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(TextButton, 'Danh sách'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Thêm công việc'));
      await tester.pumpAndSettle();
      expect(find.byType(AddTaskScreen), findsOneWidget);
      await tester.ensureVisible(find.text('Lưu công việc'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Opening the keyboard must keep the form scrollable.
      await tester.ensureVisible(find.byKey(const Key('task-title')));
      await tester.tap(find.byKey(const Key('task-title')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lưu công việc'));
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
    });
  }
}
