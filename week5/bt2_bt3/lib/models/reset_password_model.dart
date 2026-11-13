// ignore_for_file: unnecessary_getters_setters, prefer_initializing_formals
//btap 3
// Tính Đóng Gói (Encapsulation) lưu trữ dữ liệu luồng Data Flow
class ResetPasswordData {
  String _email;
  String _otpCode;
  String _newPassword;

  ResetPasswordData({
    String email = '',
    String otpCode = '',
    String newPassword = '',
  })  : _email = email,
        _otpCode = otpCode,
        _newPassword = newPassword;

  String get email => _email;
  String get otpCode => _otpCode;
  String get newPassword => _newPassword;

  set email(String value) => _email = value;
  set otpCode(String value) => _otpCode = value;
  set newPassword(String value) => _newPassword = value;
}