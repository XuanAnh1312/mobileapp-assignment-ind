import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/task.dart';

class MockApiException implements Exception {
  const MockApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Classroom API is used as a source of sample tasks, not as durable storage.
class MockTaskApi {
  MockTaskApi({
    required String token,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _token = token.trim(),
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  static final endpoint = Uri.parse(
    'https://share.tryapps.store/mock/teach/tasks',
  );
  final String _token;
  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;

  static Future<MockTaskApi> fromConfiguration() async {
    const definedToken = String.fromEnvironment('MOCK_API_TOKEN');
    if (definedToken.trim().isNotEmpty) return MockTaskApi(token: definedToken);
    try {
      final json = jsonDecode(
        await rootBundle.loadString('config/mock_api.local.json'),
      ) as Map<String, dynamic>;
      final token = json['MOCK_API_TOKEN'];
      if (token is! String ||
          token.trim().isEmpty ||
          token == 'YOUR_MOCK_API_TOKEN') {
        throw const FormatException('Missing token');
      }
      return MockTaskApi(token: token);
    } catch (_) {
      throw const MockApiException(
        'Thiếu cấu hình MOCK_API_TOKEN. Kiểm tra config/mock_api.local.json rồi mở lại ứng dụng.',
      );
    }
  }

  Future<List<Task>> fetchTasks() async {
    if (_token.isEmpty || _token.contains('\n') || _token.contains('\r')) {
      throw const MockApiException('MOCK_API_TOKEN không hợp lệ.');
    }
    late http.Response response;
    try {
      response = await _client
          .get(
            endpoint,
            headers: {
              'Authorization': 'Bearer $_token',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const MockApiException(
        'API bài tập phản hồi quá lâu. Hãy thử lại.',
      );
    } on http.ClientException {
      throw const MockApiException(
        'Chưa kết nối được API bài tập. Kiểm tra mạng rồi thử lại.',
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const MockApiException(
        'API từ chối truy cập. Kiểm tra MOCK_API_TOKEN do thầy cấp.',
      );
    }
    if (response.statusCode != 200) {
      throw MockApiException(
        'Không tải được công việc từ API (HTTP ${response.statusCode}).',
      );
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) throw const FormatException('Expected array');
      final tasks = decoded
          .map((item) => _decodeTask(Map<String, dynamic>.from(item as Map)))
          .toList();
      if (tasks.map((t) => t.id).toSet().length != tasks.length) {
        throw const FormatException('Duplicate ids');
      }
      return tasks;
    } catch (_) {
      throw const MockApiException(
        'Dữ liệu API không đúng định dạng công việc. Không nhập dữ liệu để tránh làm sai danh sách.',
      );
    }
  }

  Task _decodeTask(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! int && rawId is! String) {
      throw const FormatException('Invalid id');
    }
    final id = rawId.toString();
    if (id.isEmpty || id.contains('/')) {
      throw const FormatException('Invalid id');
    }
    final title = json['title'] as String;
    if (title.trim().isEmpty) throw const FormatException('Missing title');
    final date = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$')
        .firstMatch(json['date'] as String);
    final time = RegExp(r'^(\d{2}):(\d{2})$')
        .firstMatch(json['time'] as String);
    if (date == null || time == null) {
      throw const FormatException('Invalid date/time');
    }
    final year = int.parse(date[1]!);
    final month = int.parse(date[2]!);
    final day = int.parse(date[3]!);
    final hour = int.parse(time[1]!);
    final minute = int.parse(time[2]!);
    final due = DateTime(year, month, day, hour, minute);
    if (due.year != year ||
        due.month != month ||
        due.day != day ||
        hour > 23 ||
        minute > 59) {
      throw const FormatException('Invalid date/time');
    }
    final subtasks = json['subtasks'] as List;
    return Task(
      id: 'mock_$id',
      title: title,
      note: json['note'] as String? ?? '',
      due: due,
      group: TaskGroup.values.byName(json['category'] as String),
      priority: TaskPriority.values.byName(json['priority'] as String),
      reminder: json['remind'] as bool,
      done: json['done'] as bool,
      subtasks: [
        for (var index = 0; index < subtasks.length; index++)
          Subtask(
            id: 'mock_${id}_sub_$index',
            title: (subtasks[index] as Map)['title'] as String,
            done: (subtasks[index] as Map)['done'] as bool,
          ),
      ],
    );
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
