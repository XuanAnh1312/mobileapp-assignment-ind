import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_store.dart';
import '../widgets/task_widgets.dart';
import 'background_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, this.initialGroup});
  final TaskGroup? initialGroup;
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late TaskGroup? _group = widget.initialGroup;
  String _query = '';
  @override
  void didUpdateWidget(TaskListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGroup != widget.initialGroup) {
      _group = widget.initialGroup;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = TaskScope.of(context);
    final tasks =
        store.tasks
            .where(
              (task) =>
                  (_group == null || task.group == _group) &&
                  task.title.toLowerCase().contains(
                    _query.trim().toLowerCase(),
                  ),
            )
            .toList()
          ..sort((a, b) => a.due.compareTo(b.due));
    final pending = tasks.where((t) => !t.done).toList();
    final done = tasks.where((t) => t.done).toList();
    Widget tile(Task task) => TaskTile(
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
    );
    final content = ListView(
      key: const PageStorageKey('task-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              flex: 3,
              child: Text(
                'Danh sách',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
              ),
            ),
            Flexible(
              flex: 2,
              fit: FlexFit.tight,
              child: Text(
                '${pending.length} việc chưa xong',
                textAlign: TextAlign.right,
                style: const TextStyle(color: taskMuted, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          key: const Key('task-search'),
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Tìm công việc',
            hintStyle: const TextStyle(color: taskMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.search, size: 20, color: taskMuted),
            filled: true,
            fillColor: const Color(0xFFEBEBF0),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final group in <TaskGroup?>[null, ...TaskGroup.values])
              ChoiceChip(
                label: Text(group?.label ?? 'Tất cả'),
                selected: _group == group,
                selectedColor: const Color(0xFF202022),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _group == group
                      ? Colors.white
                      : const Color(0xFF28282B),
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: _group == group
                        ? const Color(0xFF202022)
                        : const Color(0xFFDEDEE2),
                  ),
                ),
                onSelected: (_) => setState(() => _group = group),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'CẦN LÀM',
          style: TextStyle(
            color: taskMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (pending.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Text(
              'Không có công việc cần làm.',
              style: TextStyle(color: taskMuted),
            ),
          ),
        ...pending.map(tile),
        const SizedBox(height: 12),
        const Text(
          'ĐÃ XONG',
          style: TextStyle(
            color: taskMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (done.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Text(
              'Chưa có công việc hoàn thành.',
              style: TextStyle(color: taskMuted),
            ),
          ),
        ...done.map(tile),
      ],
    );
    return store.hasMockApi
        ? RefreshIndicator(onRefresh: store.importMockTasks, child: content)
        : content;
  }
}
