import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Android authentication. Enable each provider in Firebase Console first.
class AuthService {
  AuthService._();
  static final instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void>? _googleInitialization;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      return _auth.signInWithPopup(
        GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'}),
      );
    }
    // google_sign_in 7.x: initialize the singleton exactly once.
    try {
      await (_googleInitialization ??= GoogleSignIn.instance.initialize());
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
    // Clear provider selection so an explicit login opens account selection.
    await GoogleSignIn.instance.signOut();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(code: 'missing-google-id-token');
    }
    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<UserCredential> registerWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  /// The Future only starts verification; results arrive through callbacks.
  /// Use E.164 phone numbers, e.g. +84901234567.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(UserCredential result) onVerified,
    required void Function(FirebaseAuthException error) onError,
    required void Function(String verificationId) onTimeout,
    int? resendToken,
  }) => _auth.verifyPhoneNumber(
    phoneNumber: phoneNumber.trim(),
    forceResendingToken: resendToken,
    timeout: const Duration(seconds: 60),
    verificationCompleted: (credential) async {
      try {
        onVerified(await _auth.signInWithCredential(credential));
      } on FirebaseAuthException catch (error) {
        onError(error);
      }
    },
    verificationFailed: onError,
    codeSent: onCodeSent,
    codeAutoRetrievalTimeout: onTimeout,
  );

  Future<UserCredential> verifyOtp(String verificationId, String smsCode) =>
      _auth.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode.trim(),
        ),
      );

  Future<UserCredential> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );
    if (result.status == LoginStatus.cancelled) {
      throw FirebaseAuthException(code: 'sign-in-cancelled');
    }
    final token = result.accessToken;
    if (result.status != LoginStatus.success || token == null) {
      throw FirebaseAuthException(code: 'facebook-login-failed');
    }
    return _auth.signInWithCredential(
      FacebookAuthProvider.credential(token.tokenString),
    );
  }

  // Firebase owns the browser flow and credential exchange on Android.
  // Web uses a popup; signInWithProvider is the native-platform API.
  Future<UserCredential> _signInWithOAuth(AuthProvider provider) async {
    try {
      return kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
    } on FirebaseAuthException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '${provider.providerId} sign-in failed: ${error.code}: ${error.message}',
        );
      }
      rethrow;
    }
  }

  Future<UserCredential> signInWithMicrosoft() =>
      _signInWithOAuth(MicrosoftAuthProvider()..addScope('user.read'));

  Future<UserCredential> signInWithGithub() =>
      _signInWithOAuth(GithubAuthProvider()..addScope('user:email'));

  Future<void> signOut() async {
    // Firebase is the source of truth; signing out always clears its session.
    await _auth.signOut();
    try {
      if (_googleInitialization != null) await GoogleSignIn.instance.signOut();
      await FacebookAuth.instance.logOut();
    } catch (_) {
      // Provider cleanup must not prevent a Firebase logout.
    }
  }

  static String errorMessage(Object error) {
    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        return 'Google Login chưa được cấu hình đúng. Kiểm tra Web OAuth client trong google-services.json, SHA-1/SHA-256 và bật Google trong Firebase Console.';
      }
      return error.code == GoogleSignInExceptionCode.canceled
          ? 'Bạn đã hủy đăng nhập.'
          : 'Không thể đăng nhập Google. Kiểm tra cấu hình Google và kết nối mạng.';
    }
    if (error is FirebaseAuthException) {
      // Preserve the SDK explanation during development; release builds keep
      // the translated message without exposing provider diagnostics.
      if (kDebugMode &&
          error.code == 'unknown' &&
          error.message != null &&
          error.message!.trim().isNotEmpty) {
        return 'Firebase Auth (unknown): ${error.message}';
      }
      return switch (error.code) {
        'missing-google-id-token' => 'Google không trả về mã xác thực. Hãy kiểm tra Web OAuth client rồi thử lại.',
        'invalid-form' => 'Vui lòng kiểm tra các ô thông tin.',
        'invalid-email' => 'Email không hợp lệ.',
        'weak-password' => 'Mật khẩu quá yếu. Hãy dùng ít nhất 6 ký tự.',
        'email-already-in-use' => 'Email này đã được đăng ký.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Thông tin đăng nhập không đúng hoặc đã hết hạn.',
        'invalid-phone-number' =>
          'Số điện thoại không hợp lệ. Hãy dùng định dạng +84…',
        'invalid-verification-code' => 'Mã OTP không đúng.',
        'session-expired' ||
        'invalid-verification-id' => 'Mã OTP đã hết hạn. Hãy gửi lại mã.',
        'too-many-requests' =>
          'Bạn thao tác quá nhiều lần. Vui lòng thử lại sau.',
        'network-request-failed' => 'Không có kết nối mạng. Vui lòng thử lại.',
        'user-disabled' => 'Tài khoản đã bị vô hiệu hóa.',
        'operation-not-allowed' =>
          'Phương thức này chưa được bật trong Firebase.',
        'account-exists-with-different-credential' => 'Email đã dùng phương thức khác. Hãy đăng nhập bằng phương thức ban đầu.',
        'sign-in-cancelled' ||
        'web-context-cancelled' ||
        'canceled' => 'Bạn đã hủy đăng nhập.',
        'facebook-login-failed' =>
          'Không thể đăng nhập Facebook. Kiểm tra cấu hình Meta.',
        _ => 'Đăng nhập thất bại (${error.code}). Vui lòng thử lại.',
      };
    }
    if (error is PlatformException) {
      return 'Không thể mở đăng nhập. Kiểm tra cấu hình ứng dụng (${error.code}).';
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
}
