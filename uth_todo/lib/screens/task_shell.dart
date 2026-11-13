import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/task.dart';

import '../services/task_store.dart';
import '../widgets/task_widgets.dart';
import 'add_task_screen.dart';
import 'account_screen.dart';
import 'background_screen.dart';
import 'home_screen.dart';
import 'task_list_screen.dart';

/// One shell owns the bottom navigation; task forms/details are pushed above it.
class TaskShell extends StatefulWidget {
  const TaskShell({super.key});
  @override
  State<TaskShell> createState() => _TaskShellState();
}

class _TaskShellState extends State<TaskShell> {
  int _tab = 0;
  int _listVersion = 0;
  int? _visibleSession;
  TaskGroup? _group;
  void _openList(TaskGroup? group) => setState(() {
    _group = group;
    _tab = 1;
  });
  Future<void> _add() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
    if (id != null && mounted) {
      // A previous search must not hide the task just created.
      setState(() {
        _tab = 1;
        _group = null;
        _listVersion++;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu công việc.')));
    }
  }

  Future<bool?> _account({bool fromSettings = false}) async {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) =>
            AccountScreen(backLabel: fromSettings ? 'Cài đặt' : 'Trang chủ'),
      ),
    );
  }

  void _reminders() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: taskBackground,
    builder: (sheetContext) {
      final store = TaskScope.of(sheetContext);
      final tasks = store.tasks.where((t) => t.reminder && !t.done).toList()
        ..sort((a, b) => a.due.compareTo(b.due));
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .75,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Thông báo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    tooltip: 'Đóng',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Nhắc nhở trong ứng dụng • trước hạn 15 phút. Chưa gửi thông báo hệ thống khi đóng app.',
                style: TextStyle(color: taskMuted, height: 1.5),
              ),
              const SizedBox(height: 18),
              if (tasks.isEmpty)
                const Text('Không có công việc đang bật nhắc nhở.'),
              for (final task in tasks)
                TaskTile(
                  task: task,
                  onToggle: store.saving
                      ? null
                      : () => taskAction(
                          sheetContext,
                          () => store.toggle(task.id),
                        ),
                  onOpen: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => BackgroundScreen(taskId: task.id),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    },
  );

  Future<void> _settings() async {
    final openAccount = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: taskBackground,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cài đặt',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: const Text('Tài khoản'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext, true);
                },
              ),
              Text(
                TaskScope.of(sheetContext).usesFirestore
                    ? 'Công việc mẫu được lấy từ API bài tập. Thay đổi của tài khoản này được lưu bằng Firestore.'
                    : 'Công việc được lưu trên thiết bị này khi chưa đăng nhập. Dữ liệu mẫu được lấy từ API bài tập.',
                style: TextStyle(color: taskMuted, height: 1.5),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
    if (openAccount == true && mounted) {
      final revision = TaskScope.of(context).sessionRevision;
      final returnToSettings = await _account(fromSettings: true);
      if (mounted &&
          returnToSettings != false &&
          TaskScope.of(context).sessionRevision == revision) {
        await _settings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = TaskScope.of(context);
    if (_visibleSession != null && _visibleSession != store.sessionRevision) {
      _tab = 0;
      _group = null;
      _listVersion++;
      final revision = store.sessionRevision;
      // Close any form/detail belonging to the previous account.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && store.sessionRevision == revision) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
    _visibleSession = store.sessionRevision;
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: Scaffold(
        backgroundColor: taskBackground,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (store.loading || store.apiLoading)
                const LinearProgressIndicator(minHeight: 3),
              if (store.apiError != null && store.syncError == null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.apiError!,
                          style: const TextStyle(
                            color: Color(0xFFB5372B),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => store.retryMockApi(),
                        child: const Text('Thử lại API'),
                      ),
                    ],
                  ),
                ),
              if (store.syncError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.syncError!,
                          style: const TextStyle(
                            color: Color(0xFFB5372B),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: store.retrySync,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: [
                    HomeScreen(
                      onList: _openList,
                      onAccount: _account,
                      onReminders: _reminders,
                    ),
                    TaskListScreen(
                      key: ValueKey(_listVersion),
                      initialGroup: _group,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE9E9ED))),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 73,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _nav(
                    Icons.home_outlined,
                    'Trang chủ',
                    _tab == 0,
                    () => setState(() => _tab = 0),
                  ),
                  _nav(
                    Icons.format_list_bulleted,
                    'Danh sách',
                    _tab == 1,
                    () => _openList(null),
                  ),
                  Expanded(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -12),
                        child: FloatingActionButton(
                          heroTag: 'add-task',
                          tooltip: 'Thêm công việc',
                          onPressed: _add,
                          backgroundColor: AppColors.mainBlue,
                          foregroundColor: Colors.white,
                          elevation: 5,
                          child: const Icon(Icons.add, size: 29),
                        ),
                      ),
                    ),
                  ),
                  _nav(
                    Icons.notifications_none,
                    'Thông báo',
                    false,
                    _reminders,
                  ),
                  _nav(Icons.tune, 'Cài đặt', false, _settings),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(
    IconData icon,
    String label,
    bool selected,
    VoidCallback action,
  ) => Expanded(
    child: InkWell(
      onTap: action,
      child: Semantics(
        selected: selected,
        button: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: selected ? AppColors.mainBlue : taskMuted,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                color: selected ? AppColors.mainBlue : taskMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
