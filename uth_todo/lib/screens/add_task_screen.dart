import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/task.dart';
import '../services/task_store.dart';
import '../widgets/task_widgets.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key, this.task});
  final Task? task;
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _note;
  late DateTime _due;
  late TaskGroup _group;
  late TaskPriority _priority;
  late bool _reminder;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title);
    _note = TextEditingController(text: task?.note);
    _due = task?.due ?? DateTime.now().add(const Duration(hours: 1));
    _group = task?.group ?? TaskGroup.study;
    _priority = task?.priority ?? TaskPriority.medium;
    _reminder = task?.reminder ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final store = TaskScope.of(context);
    // Avoid resurrecting a deleted task from a stale editor.
    if (widget.task != null && store.find(widget.task!.id) == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Công việc đã bị xóa.')));
      return;
    }
    setState(() => _saving = true);
    final task =
        (widget.task ??
                Task(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  title: '',
                  due: _due,
                ))
            .copyWith(
              title: _title.text.trim(),
              note: _note.text.trim(),
              due: _due,
              group: _group,
              priority: _priority,
              reminder: _reminder,
            );
    try {
      await store.save(task);
      if (mounted) Navigator.pop(context, task.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(TaskStore.errorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date != null && mounted) {
      setState(
        () => _due = DateTime(
          date.year,
          date.month,
          date.day,
          _due.hour,
          _due.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      setState(
        () => _due = DateTime(
          _due.year,
          _due.month,
          _due.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      backgroundColor: taskBackground,
      appBar: AppBar(
        backgroundColor: taskBackground,
        elevation: 0,
        leadingWidth: 70,
        leading: TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        title: Text(
          widget.task == null ? 'Việc mới' : 'Sửa công việc',
          style: const TextStyle(
            color: AppColors.mainBlack,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Lưu'),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 38).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Form(
                key: _form,
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TaskPanel(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 10, 15, 8),
                              child: TextFormField(
                                key: const Key('task-title'),
                                controller: _title,
                                enabled: !_saving,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                maxLength: 160,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Tên công việc',
                                  hintText: 'Nhập tên công việc',
                                  border: InputBorder.none,
                                  counterText: '',
                                  isDense: true,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Vui lòng nhập tên công việc.'
                                    : null,
                              ),
                            ),
                            const Divider(height: 1, color: taskBackground),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                15,
                                10,
                                15,
                                13,
                              ),
                              child: TextFormField(
                                controller: _note,
                                enabled: !_saving,
                                minLines: 2,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'Ghi chú',
                                  hintText: 'Thêm ghi chú (không bắt buộc)',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Nhóm',
                        style: TextStyle(color: taskMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final group in TaskGroup.values) ...[
                            if (group != TaskGroup.values.first)
                              const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () => setState(() => _group = group),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 45),
                                  backgroundColor: _group == group
                                      ? const Color(0xFFE8EDFF)
                                      : Colors.white,
                                  foregroundColor: _group == group
                                      ? AppColors.mainBlue
                                      : AppColors.mainBlack,
                                  side: BorderSide(
                                    color: _group == group
                                        ? AppColors.mainBlue
                                        : const Color(0xFFDDDDDF),
                                    width: _group == group ? 1.7 : 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  group.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      TaskPanel(
                        child: Column(
                          children: [
                            _FormRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Ngày',
                              value:
                                  '${['CN', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'][_due.weekday % 7]}, ${_due.day}/${_due.month}',
                              onTap: _saving ? null : _pickDate,
                            ),
                            const Divider(height: 1, color: taskBackground),
                            _FormRow(
                              icon: Icons.schedule,
                              label: 'Giờ',
                              value: taskTime(_due),
                              onTap: _saving ? null : _pickTime,
                            ),
                            const Divider(height: 1, color: taskBackground),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 14,
                                right: 5,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_none,
                                    color: taskMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Nhắc tôi'),
                                        Text(
                                          'Trước 15 phút • trong ứng dụng',
                                          style: TextStyle(
                                            color: taskMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: _reminder,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: const Color(0xFF34C759),
                                    onChanged: _saving
                                        ? null
                                        : (value) =>
                                              setState(() => _reminder = value),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Mức ưu tiên',
                        style: TextStyle(color: taskMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9E9EE),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          children: [
                            for (final priority in TaskPriority.values)
                              Expanded(
                                child: Semantics(
                                  selected: _priority == priority,
                                  child: InkWell(
                                    onTap: _saving
                                        ? null
                                        : () => setState(
                                            () => _priority = priority,
                                          ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _priority == priority
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        priority.label,
                                        style: TextStyle(
                                          fontWeight: _priority == priority
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Spacer(),
                      PrimaryTaskButton(
                        label: _saving ? 'Đang lưu…' : 'Lưu công việc',
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 19, color: taskMuted),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Flexible(
            fit: FlexFit.tight,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: taskBackground,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(value),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
