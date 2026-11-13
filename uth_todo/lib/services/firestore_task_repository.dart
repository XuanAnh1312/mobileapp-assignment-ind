import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';

/// Đọc/ghi công việc tại users/{uid}/tasks của một tài khoản.
class FirestoreTaskRepository {
  FirestoreTaskRepository({required this.uid});

  final String uid;

  CollectionReference<Map<String, dynamic>> get _tasks {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks');
  }

  Map<String, dynamic> _toFirestore(Task task) {
    final data = task.toJson()..remove('id');

    return {
      ...data,
      'due': Timestamp.fromDate(task.due),
      'completedAt': task.completedAt == null
          ? null
          : Timestamp.fromDate(task.completedAt!),
      'remindAt': task.reminder && !task.done
          ? Timestamp.fromDate(task.due.subtract(const Duration(minutes: 15)))
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Task _fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final due = (data['due'] as Timestamp).toDate().toLocal();
    final completedAt = data['completedAt'];

    return Task.fromJson({
      ...data,
      'id': document.id,
      'due': due.toIso8601String(),
      'completedAt': completedAt is Timestamp
          ? completedAt.toDate().toLocal().toIso8601String()
          : completedAt,
    });
  }

  /// Nhận danh sách mới khi dữ liệu Firestore thay đổi.
  Stream<List<Task>> watchTasks() {
    return _tasks.orderBy('due').snapshots().map((snapshot) {
      return snapshot.docs.map(_fromFirestore).toList();
    });
  }

  /// Thêm mới hoặc cập nhật theo ID công việc, giữ các trường mở rộng.
  Future<void> save(Task task) {
    return _tasks.doc(task.id).set(_toFirestore(task), SetOptions(merge: true));
  }

  Future<void> remove(String taskId) {
    return _tasks.doc(taskId).delete();
  }

  Future<List<Task>> fetchFromServer() async {
    final snapshot = await _tasks
        .orderBy('due')
        .get(const GetOptions(source: Source.server));
    return snapshot.docs.map(_fromFirestore).toList();
  }

  /// Seed each account once; later edits/deletions must not be overwritten.
  Future<void> importMockTasksOnce(List<Task> tasks) async {
    final user = FirebaseFirestore.instance.collection('users').doc(uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final profile = await transaction.get(user);
      if (profile.data()?['mockTeachImportedV1'] == true) return;
      // Read before writing, as required by Firestore transactions.
      final existing = [
        for (final task in tasks) await transaction.get(_tasks.doc(task.id)),
      ];
      for (var index = 0; index < tasks.length; index++) {
        if (!existing[index].exists) {
          transaction.set(
            _tasks.doc(tasks[index].id),
            _toFirestore(tasks[index]),
          );
        }
      }
      transaction.set(user, {
        'mockTeachImportedV1': true,
        'mockTeachImportedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
