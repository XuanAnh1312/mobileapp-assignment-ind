import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/task.dart';
import '../services/task_store.dart';

const taskBackground = Color(0xFFF5F5F7);
const taskMuted = Color(0xFF818186);

String taskTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String taskDate(DateTime value) {
  final now = DateTime.now();
  if (sameDay(value, now)) return 'Hôm nay';
  if (sameDay(value, now.add(const Duration(days: 1)))) return 'Ngày mai';
  return '${value.day}/${value.month}/${value.year}';
}

String weekdayDate(DateTime value) =>
    '${['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'][value.weekday % 7]}, ${value.day} tháng ${value.month}';

Future<void> taskAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(TaskStore.errorMessage(error))));
    }
  }
}

class TaskPanel extends StatelessWidget {
  const TaskPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}

class GroupBadge extends StatelessWidget {
  const GroupBadge(this.group, {super.key});
  final TaskGroup group;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: group == TaskGroup.study
          ? const Color(0xFFE8EEFF)
          : const Color(0xFFFFECD9),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      group.label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: group == TaskGroup.study
            ? const Color(0xFF244DB7)
            : const Color(0xFF9C531E),
      ),
    ),
  );
}

class TaskCheck extends StatelessWidget {
  const TaskCheck({super.key, required this.done, required this.onTap});
  final bool done;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: done ? 'Đánh dấu chưa hoàn thành' : 'Đánh dấu hoàn thành',
    checked: done,
    button: true,
    child: InkResponse(
      onTap: onTap,
      radius: 23,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          width: 23,
          height: 23,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.mainBlue : Colors.white,
            border: Border.all(
              color: done ? AppColors.mainBlue : const Color(0xFFCCCCD0),
              width: 1.5,
            ),
          ),
          child: done
              ? const Icon(Icons.check, size: 15, color: Colors.white)
              : null,
        ),
      ),
    ),
  );
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onOpen,
    required this.onToggle,
    this.home = false,
  });
  final Task task;
  final VoidCallback onOpen;
  final VoidCallback? onToggle;
  final bool home;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 9, 13, 9),
          child: Row(
            children: [
              TaskCheck(done: task.done, onTap: onToggle),
              const SizedBox(width: 3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: task.done
                            ? const Color(0xFF99999D)
                            : AppColors.mainBlack,
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (!task.done || home) ...[
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          GroupBadge(task.group),
                          Text(
                            home
                                ? taskTime(task.due)
                                : '${taskDate(task.due)}, ${taskTime(task.due)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: taskMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (home)
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFB9B9BD),
                  size: 19,
                )
              else if (!task.done && task.priority == TaskPriority.high)
                Container(
                  margin: const EdgeInsets.only(left: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBED),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'Gấp',
                    style: TextStyle(fontSize: 10, color: Color(0xFFB73434)),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PrimaryTaskButton extends StatelessWidget {
  const PrimaryTaskButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mainBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
