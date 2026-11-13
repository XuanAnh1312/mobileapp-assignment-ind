import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uth_todo/models/task.dart';
import 'package:uth_todo/services/mock_task_api.dart';

Map<String, dynamic> apiTask({int id = 2}) => {
  'id': id,
  'title': 'Ôn chương 3 – Cấu trúc dữ liệu',
  'note': 'Đọc tài liệu tiếng Việt.',
  'category': 'study',
  'date': '2026-10-20',
  'time': '14:05',
  'priority': 'high',
  'remind': true,
  'done': false,
  'subtasks': [
    {'title': 'Đọc slide', 'done': true},
  ],
};

http.Response jsonResponse(Object body, {int status = 200}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  test(
    'GET uses the supplied Bearer token and decodes UTF-8 and API fields',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://share.tryapps.store/mock/teach/tasks',
        );
        expect(request.headers['Authorization'], 'Bearer test-token');
        return jsonResponse([apiTask()]);
      });
      final api = MockTaskApi(token: 'test-token', client: client);
      final task = (await api.fetchTasks()).single;
      expect(task.id, 'mock_2');
      expect(task.title, 'Ôn chương 3 – Cấu trúc dữ liệu');
      expect(task.group, TaskGroup.study);
      expect(task.priority, TaskPriority.high);
      expect(task.reminder, isTrue);
      expect(task.done, isFalse);
      expect(task.due, DateTime(2026, 10, 20, 14, 5));
      expect(task.subtasks.single.id, 'mock_2_sub_0');
      expect(task.subtasks.single.done, isTrue);
    },
  );

  for (final status in [401, 403, 500]) {
    test(
      'HTTP $status produces a useful error without exposing the token',
      () async {
        final api = MockTaskApi(
          token: 'private-test-token',
          client: MockClient(
            (_) async => jsonResponse({'error': 'denied'}, status: status),
          ),
        );
        await expectLater(
          api.fetchTasks(),
          throwsA(
            isA<MockApiException>()
                .having(
                  (error) => error.message,
                  'message',
                  isNot(contains('private-test-token')),
                )
                .having(
                  (error) => error.message,
                  'message',
                  contains(status == 500 ? '500' : 'MOCK_API_TOKEN'),
                ),
          ),
        );
      },
    );
  }

  final invalidPayloads = <String, Object>{
    'wrong root': {
      'items': [apiTask()],
    },
    'invalid JSON fields': [apiTask()..remove('date')],
    'normalized invalid date': [apiTask()..['date'] = '2026-02-30'],
    'invalid hour': [apiTask()..['time'] = '25:00'],
    'unknown category': [apiTask()..['category'] = 'other'],
    'duplicate id': [apiTask(), apiTask()],
  };
  for (final entry in invalidPayloads.entries) {
    test(
      'Rejects ${entry.key} instead of inventing fallback task data',
      () async {
        final api = MockTaskApi(
          token: 'test',
          client: MockClient((_) async => jsonResponse(entry.value)),
        );
        await expectLater(api.fetchTasks(), throwsA(isA<MockApiException>()));
      },
    );
  }

  test('Network and timeout failures can be retried by the caller', () async {
    final network = MockTaskApi(
      token: 'test',
      client: MockClient((_) async => throw http.ClientException('network')),
    );
    await expectLater(
      network.fetchTasks(),
      throwsA(
        isA<MockApiException>().having(
          (e) => e.message,
          'message',
          contains('Kiểm tra mạng'),
        ),
      ),
    );
    final response = Completer<http.Response>();
    final timeout = MockTaskApi(
      token: 'test',
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) => response.future),
    );
    await expectLater(
      timeout.fetchTasks(),
      throwsA(
        isA<MockApiException>().having(
          (e) => e.message,
          'message',
          contains('quá lâu'),
        ),
      ),
    );
    response.complete(jsonResponse([]));
  });

  test('Missing token does not send a request', () async {
    var requested = false;
    final api = MockTaskApi(
      token: '',
      client: MockClient((_) async {
        requested = true;
        return jsonResponse([]);
      }),
    );
    await expectLater(api.fetchTasks(), throwsA(isA<MockApiException>()));
    expect(requested, isFalse);
  });
}
