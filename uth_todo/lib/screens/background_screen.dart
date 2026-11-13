import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/task.dart';
import '../services/task_store.dart';
import '../widgets/task_widgets.dart';
import 'add_task_screen.dart';

/// Background.jpg is a task detail screen, not a shared decorative image.
class BackgroundScreen extends StatefulWidget {
  const BackgroundScreen({super.key, required this.taskId});
  final String taskId;
  @override
  State<BackgroundScreen> createState() => _BackgroundScreenState();
}

class _BackgroundScreenState extends State<BackgroundScreen> {
  final _newSubtask = TextEditingController();
  @override
  void dispose() {
    _newSubtask.dispose();
    super.dispose();
  }

  Future<void> _editSubtask(Task task, Subtask subtask) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _SubtaskEditor(title: subtask.title),
    );
    if (title != null && mounted) {
      await taskAction(
        context,
        () => TaskScope.of(context).save(
          task.copyWith(
            subtasks: [
              for (final item in task.subtasks)
                if (item.id == subtask.id)
                  Subtask(id: item.id, title: title, done: item.done)
                else
                  item,
            ],
          ),
        ),
      );
    }
  }

  Future<void> _delete(Task task) async {
    final store = TaskScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: Text('“${task.title}” và các việc nhỏ sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await store.remove(task.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa. Hãy thử lại.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = TaskScope.of(context);
    final task = store.find(widget.taskId);
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết')),
        body: Center(
          child: store.loading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(store.syncError ?? 'Công việc không còn tồn tại.'),
                      if (store.syncError != null)
                        TextButton(
                          onPressed: store.retrySync,
                          child: const Text('Thử lại'),
                        ),
                    ],
                  ),
                ),
        ),
      );
    }
    final completed = task.subtasks.where((s) => s.done).length;
    return Scaffold(
      backgroundColor: taskBackground,
      appBar: AppBar(
        backgroundColor: taskBackground,
        elevation: 0,
        leadingWidth: 150,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left),
          label: const Text('Danh sách'),
        ),
        actions: [
          TextButton(
            onPressed: store.saving
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute<String>(
                      builder: (_) => AddTaskScreen(task: task),
                    ),
                  ),
            child: const Text('Sửa'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: const Key('background-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 9,
                runSpacing: 6,
                children: [
                  GroupBadge(task.group),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE7E8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Ưu tiên ${task.priority.label.toLowerCase()}',
                      style: const TextStyle(
                        color: Color(0xFFB93632),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainBlack,
                ),
              ),
              const SizedBox(height: 22),
              TaskPanel(
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Hạn chót',
                      value: '${taskDate(task.due)}, ${taskTime(task.due)}',
                    ),
                    const Divider(height: 1, color: taskBackground),
                    _DetailRow(
                      icon: Icons.notifications_none,
                      label: 'Nhắc nhở',
                      value: task.reminder ? 'Trước 15 phút' : 'Tắt',
                    ),
                    const Divider(height: 1, color: taskBackground),
                    const _DetailRow(
                      icon: Icons.repeat,
                      label: 'Lặp lại',
                      value: 'Không',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ghi chú',
                style: TextStyle(
                  color: taskMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TaskPanel(
                  padding: const EdgeInsets.all(17),
                  child: Text(
                    task.note.isEmpty ? 'Chưa có ghi chú.' : task.note,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Việc nhỏ',
                      style: TextStyle(
                        color: taskMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '$completed/${task.subtasks.length}',
                    style: const TextStyle(color: taskMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: task.subtasks.isEmpty
                      ? 0
                      : completed / task.subtasks.length,
                  minHeight: 6,
                  color: AppColors.mainBlue,
                  backgroundColor: const Color(0xFFE4E4EA),
                ),
              ),
              const SizedBox(height: 12),
              TaskPanel(
                child: Column(
                  children: [
                    for (final subtask in task.subtasks) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 5,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: subtask.done,
                              activeColor: AppColors.mainBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              onChanged: store.saving
                                  ? null
                                  : (done) => taskAction(
                                      context,
                                      () => store.save(
                                        task.copyWith(
                                          subtasks: [
                                            for (final item in task.subtasks)
                                              if (item.id == subtask.id)
                                                Subtask(
                                                  id: item.id,
                                                  title: item.title,
                                                  done: done!,
                                                )
                                              else
                                                item,
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                            Expanded(
                              child: Text(
                                subtask.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: subtask.done
                                      ? taskMuted
                                      : AppColors.mainBlack,
                                  decoration: subtask.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Sửa việc nhỏ',
                              onPressed: store.saving
                                  ? null
                                  : () => _editSubtask(task, subtask),
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 19,
                                color: taskMuted,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Xóa việc nhỏ',
                              onPressed: store.saving
                                  ? null
                                  : () => taskAction(
                                      context,
                                      () => store.save(
                                        task.copyWith(
                                          subtasks: task.subtasks
                                              .where((s) => s.id != subtask.id)
                                              .toList(),
                                        ),
                                      ),
                                    ),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 19,
                                color: Color(0xFFB5372B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: taskBackground),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 5, 6, 5),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add,
                            color: AppColors.mainBlue,
                            size: 21,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: TextField(
                              key: const Key('subtask-title'),
                              controller: _newSubtask,
                              maxLength: 160,
                              decoration: const InputDecoration(
                                hintText: 'Thêm việc nhỏ',
                                border: InputBorder.none,
                                counterText: '',
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: store.saving
                                ? null
                                : () async {
                                    final title = _newSubtask.text.trim();
                                    if (title.isEmpty) return;
                                    try {
                                      await store.save(
                                        task.copyWith(
                                          subtasks: [
                                            ...task.subtasks,
                                            Subtask(
                                              id: DateTime.now()
                                                  .microsecondsSinceEpoch
                                                  .toString(),
                                              title: title,
                                            ),
                                          ],
                                        ),
                                      );
                                      _newSubtask.clear();
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Không thể thêm việc nhỏ.',
                                                ),
                                              ),
                                            );
                                      }
                                    }
                                  },
                            child: const Text(
                              'Thêm',
                              style: TextStyle(
                                color: taskMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 44),
              PrimaryTaskButton(
                label: task.done
                    ? 'Đánh dấu chưa hoàn thành'
                    : 'Đánh dấu hoàn thành',
                onPressed: store.saving
                    ? null
                    : () => taskAction(context, () => store.toggle(task.id)),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: store.saving ? null : () => _delete(task),
                  child: const Text(
                    'Xóa công việc',
                    style: TextStyle(color: Color(0xFFB5372B), fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    child: Row(
      children: [
        Icon(icon, color: taskMuted, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: taskMuted, fontSize: 15),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          fit: FlexFit.tight,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class _SubtaskEditor extends StatefulWidget {
  const _SubtaskEditor({required this.title});
  final String title;
  @override
  State<_SubtaskEditor> createState() => _SubtaskEditorState();
}

class _SubtaskEditorState extends State<_SubtaskEditor> {
  late final _controller = TextEditingController(text: widget.title);
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Sửa việc nhỏ'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        maxLength: 160,
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Nhập tên việc nhỏ.' : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      TextButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _controller.text.trim());
          }
        },
        child: const Text('Lưu'),
      ),
    ],
  );
}
