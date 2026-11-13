import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/task.dart';
import '../services/task_store.dart';
import '../widgets/task_widgets.dart';
import 'background_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onList,
    required this.onAccount,
    required this.onReminders,
  });
  final void Function(TaskGroup?) onList;
  final VoidCallback onAccount;
  final VoidCallback onReminders;

  @override
  Widget build(BuildContext context) {
    // Firebase is optional in widget tests.
    if (Firebase.apps.isEmpty) return _content(context, null);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) =>
          _content(context, snapshot.data ?? FirebaseAuth.instance.currentUser),
    );
  }

  Widget _content(BuildContext context, User? user) {
    final store = TaskScope.of(context);
    final today =
        store.tasks.where((t) => sameDay(t.due, DateTime.now())).toList()
          ..sort((a, b) => a.due.compareTo(b.due));
    final done = today.where((t) => t.done).length;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final overdue =
        store.tasks
            .where((task) => !task.done && task.due.isBefore(startOfToday))
            .toList()
          ..sort((a, b) => a.due.compareTo(b.due));
    final progress = today.isEmpty ? 0.0 : done / today.length;
    final name = user?.displayName?.trim();
    final initials = name == null || name.isEmpty
        ? null
        : name
              .split(RegExp(r'\s+'))
              .where((s) => s.isNotEmpty)
              .take(2)
              .map((s) => s.characters.first)
              .join()
              .toUpperCase();
    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      children: [
        Row(
          children: [
            Semantics(
              label: user == null
                  ? 'Đăng nhập tài khoản'
                  : 'Tài khoản của ${name ?? user.email ?? 'bạn'}',
              button: true,
              child: InkWell(
                onTap: onAccount,
                borderRadius: BorderRadius.circular(25),
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFFE7ECFF),
                  child: user?.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoURL!,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Text(
                              initials ?? 'UTH',
                              style: const TextStyle(
                                color: AppColors.mainBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      : initials != null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.mainBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : const Icon(
                          Icons.person_outline,
                          color: AppColors.mainBlue,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weekdayDate(DateTime.now()),
                    style: const TextStyle(fontSize: 12, color: taskMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name?.isNotEmpty == true
                        ? 'Chào ${name!.split(' ').last}!'
                        : 'Chào UTH!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: 'Nhắc nhở công việc',
                onPressed: onReminders,
                icon: const Icon(
                  Icons.notifications_none,
                  color: AppColors.mainBlack,
                  size: 23,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: AppColors.mainBlue,
            borderRadius: BorderRadius.circular(21),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiến độ hôm nay',
                      style: TextStyle(color: Color(0xFFD9E2FF), fontSize: 13),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$done/${today.length} việc',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Bắt đầu từ việc nhỏ nhất nhé.',
                      style: TextStyle(color: Color(0xFFD9E2FF), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 67,
                height: 67,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        color: Colors.white,
                        backgroundColor: const Color(0xFF829BF5),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            for (final group in TaskGroup.values) ...[
              if (group != TaskGroup.values.first) const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(19),
                    onTap: () => onList(group),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: group == TaskGroup.study
                                  ? const Color(0xFFE7EDFF)
                                  : const Color(0xFFFFECD9),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              group == TaskGroup.study
                                  ? Icons.school_outlined
                                  : Icons.home_outlined,
                              size: 19,
                              color: group == TaskGroup.study
                                  ? AppColors.mainBlue
                                  : const Color(0xFFA65C26),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            group.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${store.tasks.where((t) => t.group == group && !t.done).length} việc còn lại',
                            style: const TextStyle(
                              color: taskMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Việc hôm nay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => onList(null),
              child: const Text('Xem tất cả', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        if (today.isEmpty)
          const TaskPanel(
            padding: EdgeInsets.all(22),
            child: Text(
              'Hôm nay chưa có công việc. Nhấn + để thêm việc đầu tiên.',
              style: TextStyle(color: taskMuted, height: 1.5),
            ),
          ),
        for (final task in today)
          TaskTile(
            task: task,
            home: true,
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => BackgroundScreen(taskId: task.id),
              ),
            ),
            onToggle: store.saving
                ? null
                : () => taskAction(context, () => store.toggle(task.id)),
          ),
        if (overdue.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Việc quá hạn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final task in overdue)
            TaskTile(
              task: task,
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => BackgroundScreen(taskId: task.id),
                ),
              ),
              onToggle: store.saving
                  ? null
                  : () => taskAction(context, () => store.toggle(task.id)),
            ),
        ],
      ],
    );
    return store.hasMockApi
        ? RefreshIndicator(onRefresh: store.importMockTasks, child: content)
        : content;
  }
}
