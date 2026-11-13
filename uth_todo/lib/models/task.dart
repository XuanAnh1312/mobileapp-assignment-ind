enum TaskGroup {
  study('Học tập'),
  life('Cuộc sống');

  const TaskGroup(this.label);
  final String label;
}

enum TaskPriority {
  low('Thấp'),
  medium('Vừa'),
  high('Cao');

  const TaskPriority(this.label);
  final String label;
}

class Subtask {
  const Subtask({required this.id, required this.title, this.done = false});
  final String id;
  final String title;
  final bool done;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};
  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
    id: json['id'] as String,
    title: json['title'] as String,
    done: json['done'] as bool,
  );
}

/// Immutable values prevent an unsaved form from changing the shared list.
class Task {
  Task({
    required this.id,
    required this.title,
    required this.due,
    this.note = '',
    this.group = TaskGroup.study,
    this.priority = TaskPriority.medium,
    this.reminder = true,
    this.done = false,
    this.completedAt,
    List<Subtask> subtasks = const [],
  }) : subtasks = List.unmodifiable(subtasks);

  final String id;
  final String title;
  final String note;
  final DateTime due;
  final TaskGroup group;
  final TaskPriority priority;
  final bool reminder;
  final bool done;
  final DateTime? completedAt;
  final List<Subtask> subtasks;

  Task copyWith({
    String? title,
    String? note,
    DateTime? due,
    TaskGroup? group,
    TaskPriority? priority,
    bool? reminder,
    bool? done,
    DateTime? completedAt,
    List<Subtask>? subtasks,
  }) => Task(
    id: id,
    title: title ?? this.title,
    note: note ?? this.note,
    due: due ?? this.due,
    group: group ?? this.group,
    priority: priority ?? this.priority,
    reminder: reminder ?? this.reminder,
    done: done ?? this.done,
    completedAt: (done ?? this.done) ? completedAt ?? this.completedAt : null,
    subtasks: subtasks ?? this.subtasks,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'due': due.toIso8601String(),
    'group': group.name,
    'priority': priority.name,
    'reminder': reminder,
    'done': done,
    'completedAt': completedAt?.toIso8601String(),
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    note: json['note'] as String,
    due: DateTime.parse(json['due'] as String),
    group: TaskGroup.values.byName(json['group'] as String),
    priority: TaskPriority.values.byName(json['priority'] as String),
    reminder: json['reminder'] as bool,
    done: json['done'] as bool,
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt'] as String),
    subtasks: (json['subtasks'] as List)
        .map((s) => Subtask.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList(),
  );
}
