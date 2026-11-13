import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import 'firestore_task_repository.dart';
import 'mock_task_api.dart';

class TaskStore extends ChangeNotifier {
  /// In-memory store for tests. The app uses [load] for disk storage.
  TaskStore({List<Task> initialTasks = const []})
    : _preferences = null,
      _guestTasks = List.of(initialTasks),
      _tasks = List.of(initialTasks);

  TaskStore._(this._preferences, List<Task> tasks)
    : _guestTasks = List.of(tasks),
      _tasks = List.of(tasks);

  static const storageKey = 'uth.tasks.v1';
  static const mockImportKey = 'uth.mockTeach.imported.v1';
  final SharedPreferences? _preferences;
  List<Task> _guestTasks;
  List<Task> _tasks;
  FirestoreTaskRepository? _repository;
  StreamSubscription<List<Task>>? _remoteSubscription;
  int _sessionRevision = 0;
  bool _disposed = false;
  bool _loading = false;
  String? _syncError;
  MockTaskApi? _mockApi;
  bool _apiLoading = false;
  String? _apiError;
  bool _guestMockImported = false;
  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  bool get hasMockApi => _mockApi != null;
  bool get apiLoading => _apiLoading;
  String? get apiError => _apiError;

  bool get loading => _loading;
  bool get usesFirestore => _repository != null;
  String? get syncError => _syncError;
  int get sessionRevision => _sessionRevision;
  List<Task> get tasks => List.unmodifiable(_tasks);
  Task? find(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  static Future<TaskStore> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    // Never replace damaged saved data with demo data silently.
    final tasks = raw == null
        ? <Task>[]
        : (jsonDecode(raw) as List)
              .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
    return TaskStore._(preferences, tasks);
  }

  bool _saving = false;
  bool get saving => _saving;

  /// Switch source without uploading guest tasks to any account automatically.
  void bindRepository(FirestoreTaskRepository? repository) {
    if (_disposed) return;
    final revision = ++_sessionRevision;
    unawaited(_remoteSubscription?.cancel());
    _remoteSubscription = null;
    _repository = repository;
    _saving = false;
    _loading = repository != null;
    _syncError = null;
    _lastSyncedAt = null;
    _apiLoading = false;
    _apiError = null;
    _tasks = repository == null ? List.of(_guestTasks) : [];
    notifyListeners();

    if (_mockApi != null) unawaited(importMockTasks());

    if (repository == null) return;
    try {
      _remoteSubscription = repository.watchTasks().listen(
        (tasks) {
          if (!_isCurrent(revision)) return;
          _tasks = List.of(tasks);
          _loading = false;
          _syncError = null;
          notifyListeners();
        },
        onError: (Object error) {
          if (_isCurrent(revision)) reportSyncError(error);
        },
      );
    } catch (error) {
      if (_isCurrent(revision)) reportSyncError(error);
    }
  }

  bool _isCurrent(int revision) => !_disposed && revision == _sessionRevision;

  void reportSyncError(Object error) {
    if (_disposed) return;
    _loading = false;
    _syncError = errorMessage(error);
    _tasks = [];
    notifyListeners();
  }

  void retrySync() => bindRepository(_repository);

  Future<void> initializeMockApi() async {
    try {
      final api = await MockTaskApi.fromConfiguration();
      if (_disposed) {
        api.close();
        return;
      }
      attachMockApi(api);
    } catch (error) {
      if (!_disposed) {
        _apiError = errorMessage(error);
        notifyListeners();
      }
    }
  }

  void attachMockApi(MockTaskApi api) {
    if (_disposed) {
      api.close();
      return;
    }
    _mockApi?.close();
    _mockApi = api;
    unawaited(importMockTasks());
  }

  Future<void> retryMockApi() =>
      _mockApi == null ? initializeMockApi() : importMockTasks();

  /// Fetch real API data, then import it once into the current durable store.
  /// Repeated fetches never overwrite edits or resurrect deleted sample tasks.
  Future<void> importMockTasks() async {
    final api = _mockApi;
    if (_disposed || api == null || _apiLoading) return;
    final revision = _sessionRevision;
    final repository = _repository;
    _apiLoading = true;
    _apiError = null;
    notifyListeners();
    try {
      final samples = await api.fetchTasks();
      if (!_isCurrent(revision) || samples.isEmpty) return;
      if (repository != null) {
        await repository.importMockTasksOnce(samples);
      } else if (!_guestMockImported &&
          _preferences?.getBool(mockImportKey) != true) {
        final ids = _guestTasks.map((task) => task.id).toSet();
        final missing = samples
            .where((task) => !ids.contains(task.id))
            .toList();
        if (missing.isNotEmpty) {
          await _commit([..._guestTasks, ...missing], (_) async {});
        }
        if (!_isCurrent(revision)) return;
        final saved = await _preferences?.setBool(mockImportKey, true);
        if (saved == false) {
          throw StateError('Không thể lưu trạng thái nhập dữ liệu API.');
        }
        _guestMockImported = true;
      }
    } catch (error) {
      if (_isCurrent(revision)) _apiError = errorMessage(error);
    } finally {
      if (_isCurrent(revision)) {
        _apiLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _commit(
    List<Task> next,
    Future<void> Function(FirestoreTaskRepository repository) remoteWrite,
  ) async {
    if (_disposed) throw StateError('Danh sách công việc đã đóng.');
    if (_saving) throw StateError('Đang lưu thay đổi. Vui lòng thử lại.');
    if (_loading) throw StateError('Đang tải công việc. Vui lòng đợi.');
    if (_syncError != null) throw StateError(_syncError!);
    final revision = _sessionRevision;
    final repository = _repository;
    _saving = true;
    notifyListeners();
    try {
      if (repository != null) {
        // The Firestore stream owns the list, including server rollbacks.
        await remoteWrite(repository);
        if (_isCurrent(revision)) _lastSyncedAt = DateTime.now();
      } else {
        final saved = await _preferences?.setString(
          storageKey,
          jsonEncode(next.map((t) => t.toJson()).toList()),
        );
        if (saved == false) {
          throw StateError('Không thể lưu dữ liệu trên thiết bị.');
        }
        _guestTasks = List.of(next);
        if (_isCurrent(revision)) _tasks = List.of(next);
      }
      if (!_isCurrent(revision)) {
        throw StateError('Tài khoản đã thay đổi. Hãy mở lại công việc.');
      }
    } finally {
      if (_isCurrent(revision)) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  Future<void> save(Task task) => _commit([
    for (final current in _tasks)
      if (current.id == task.id) task else current,
    if (find(task.id) == null) task,
  ], (repository) => repository.save(task));
  Future<void> remove(String id) => _commit(
    _tasks.where((t) => t.id != id).toList(),
    (repository) => repository.remove(id),
  );
  Future<void> toggle(String id) async {
    final task = find(id);
    if (task != null) {
      await save(
        task.copyWith(
          done: !task.done,
          completedAt: task.done ? null : DateTime.now(),
        ),
      );
    }
  }

  Future<void> syncNow() async {
    final repository = _repository;
    if (repository == null) {
      throw StateError('Đăng nhập Google để đồng bộ dữ liệu tài khoản.');
    }
    if (_loading || _saving || _apiLoading) {
      throw StateError('Đang tải hoặc lưu công việc. Vui lòng đợi.');
    }
    final revision = _sessionRevision;
    final tasks = await repository.fetchFromServer();
    if (!_isCurrent(revision)) throw StateError('Tài khoản đã thay đổi.');
    _tasks = List.of(tasks);
    _syncError = null;
    _lastSyncedAt = DateTime.now();
    notifyListeners();
  }

  static String errorMessage(Object error) {
    if (error is MockApiException) return error.message;
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => 'Không có quyền truy cập công việc. Kiểm tra Firestore Rules và UID đã đăng nhập.',
        'unauthenticated' =>
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        'unavailable' || 'deadline-exceeded' =>
          'Chưa kết nối được Firestore. Kiểm tra mạng rồi thử lại.',
        _ => 'Không thể đồng bộ công việc (${error.code}). Vui lòng thử lại.',
      };
    }
    if (error is StateError) return error.message.toString();
    if (error is TypeError ||
        error is FormatException ||
        error is ArgumentError) {
      return 'Dữ liệu công việc chưa đúng định dạng. Kiểm tra các trường trên Firestore, đặc biệt due phải là timestamp.';
    }
    return 'Không thể lưu thay đổi. Vui lòng thử lại.';
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionRevision++;
    unawaited(_remoteSubscription?.cancel());
    _mockApi?.close();
    super.dispose();
  }
}

class TaskScope extends InheritedNotifier<TaskStore> {
  const TaskScope({super.key, required TaskStore store, required super.child})
    : super(notifier: store);
  static TaskStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TaskScope>()!.notifier!;
}
