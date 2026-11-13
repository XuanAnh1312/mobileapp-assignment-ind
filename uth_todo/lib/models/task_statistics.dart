import 'task.dart';

class TaskStatistics {
  TaskStatistics(List<Task> tasks, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));
    completed = tasks.where((task) => task.done).length;
    percent = tasks.isEmpty ? 0 : (completed / tasks.length * 100).round();
    final timedCompletions = tasks
        .where((task) => task.done && task.completedAt != null)
        .toList();
    onTimePercent = timedCompletions.isEmpty
        ? null
        : (timedCompletions
                      .where((task) => !task.completedAt!.isAfter(task.due))
                      .length /
                  timedCompletions.length *
                  100)
              .round();
    for (final task in tasks) {
      final due = task.due.toLocal();
      if (!due.isBefore(monday) && due.isBefore(nextMonday)) {
        days[due.weekday - 1]++;
        if (task.done) completedThisWeek++;
      }
    }
    final dates = tasks
        .where((task) => task.done && task.completedAt != null)
        .map((task) => _day(task.completedAt!.toLocal()))
        .toSet();
    // Legacy/API tasks have no completion time: don't infer a streak from due dates.
    if (completed > 0 && dates.isEmpty) {
      streak = null;
    } else {
      var cursor = dates.contains(today)
          ? today
          : today.subtract(const Duration(days: 1));
      var count = 0;
      while (dates.contains(cursor)) {
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      streak = count;
    }
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  late final int completed;
  late final int percent;
  late final int? onTimePercent;
  late final int? streak;
  int completedThisWeek = 0;
  final List<int> days = List.filled(7, 0);
  int get totalThisWeek => days.fold(0, (sum, count) => sum + count);
}
