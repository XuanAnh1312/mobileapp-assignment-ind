import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_todo/screens/auth_forms_screen.dart';
import 'package:uth_todo/screens/login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uth_todo/services/auth_service.dart';
import 'package:uth_todo/widgets/auth_action_button.dart';

void main() {
  test('Google configuration errors explain what must be configured', () {
    expect(
      AuthService.errorMessage(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      ),
      contains('google-services.json'),
    );
    expect(
      AuthService.errorMessage(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      ),
      'Bạn đã hủy đăng nhập.',
    );
  });

  testWidgets('Login displays only Google and fits a small Android screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.byType(AuthActionButton), findsOneWidget);
    expect(find.textContaining('Facebook'), findsNothing);
    expect(find.textContaining('Email'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pending Google login blocks duplicate taps and allows retry', (
    tester,
  ) async {
    final pending = Completer<UserCredential>();
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthActionButton(
            label: 'Google',
            action: () {
              attempts++;
              return pending.future;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Google'));
    await tester.pump();
    await tester.tap(find.text('Google'));
    expect(attempts, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã hủy đăng nhập.'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
  });
  test('Unknown Firebase errors preserve the SDK explanation in debug', () {
    final error = FirebaseAuthException(
      code: 'unknown',
      message: 'OAuth response: invalid_client',
    );
    expect(AuthService.errorMessage(error), contains('invalid_client'));
    expect(
      AuthService.errorMessage(FirebaseAuthException(code: 'unknown')),
      contains('(unknown)'),
    );
  });

  testWidgets('Email registration validates input before calling Firebase', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: EmailAuthScreen()));
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập email hợp lệ.'), findsOneWidget);
    expect(find.text('Dùng ít nhất 6 ký tự.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Phone form rejects a local number without country code', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PhoneAuthScreen()));
    await tester.enterText(find.byType(TextField), '0901234567');
    await tester.tap(find.text('Gửi mã OTP'));
    await tester.pumpAndSettle();
    expect(
      find.text('Số điện thoại không hợp lệ. Hãy dùng định dạng +84…'),
      findsOneWidget,
    );
    expect(find.text('Xác thực và đăng nhập'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sign-in errors are displayed and the button can be retried', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthActionButton(
            label: 'Đăng nhập',
            action: () async {
              attempts++;
              throw FirebaseAuthException(code: 'network-request-failed');
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(
      find.text('Không có kết nối mạng. Vui lòng thử lại.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });
}
