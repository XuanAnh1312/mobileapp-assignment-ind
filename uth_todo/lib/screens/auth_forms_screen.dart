import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/auth_action_button.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_register ? 'Đăng ký tài khoản' : 'Đăng nhập bằng email'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value != null &&
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(value.trim())
                  ? null
                  : 'Nhập email hợp lệ.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: [
                _register ? AutofillHints.newPassword : AutofillHints.password,
              ],
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Nhập mật khẩu.'
                  : _register && value.length < 6
                  ? 'Dùng ít nhất 6 ký tự.'
                  : null,
            ),
            const SizedBox(height: 24),
            AuthActionButton(
              label: _register ? 'Đăng ký' : 'Đăng nhập',
              action: () {
                if (!_form.currentState!.validate()) {
                  throw FirebaseAuthException(code: 'invalid-form');
                }
                final auth = AuthService.instance;
                return _register
                    ? auth.registerWithEmail(_email.text, _password.text)
                    : auth.signInWithEmail(_email.text, _password.text);
              },
            ),
            TextButton(
              onPressed: () => setState(() => _register = !_register),
              child: Text(
                _register
                    ? 'Đã có tài khoản? Đăng nhập'
                    : 'Chưa có tài khoản? Đăng ký',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  bool _sending = false;
  bool _verifying = false;
  bool _completed = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted || _completed) return;
    setState(() {
      _sending = false;
      _verifying = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(AuthService.errorMessage(error))));
  }

  void _success(UserCredential result) {
    if (!mounted || _completed) return;
    _completed = true;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _send() async {
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(_phone.text.trim())) {
      _showError(FirebaseAuthException(code: 'invalid-phone-number'));
      return;
    }
    setState(() => _sending = true);
    try {
      await AuthService.instance.sendOtp(
        phoneNumber: _phone.text,
        resendToken: _resendToken,
        onCodeSent: (id, token) {
          if (!mounted || _completed) return;
          setState(() {
            _verificationId = id;
            _resendToken = token;
            _sending = false;
            _seconds = 60;
            _code.clear();
          });
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (!mounted || _seconds <= 1) {
              timer.cancel();
              if (mounted) setState(() => _seconds = 0);
            } else {
              setState(() => _seconds--);
            }
          });
        },
        onVerified: _success,
        onError: _showError,
        onTimeout: (id) {
          if (!mounted || _completed) return;
          setState(() {
            _verificationId = id;
            _sending = false;
          });
        },
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      _showError(FirebaseAuthException(code: 'invalid-verification-code'));
      return;
    }
    setState(() => _verifying = true);
    try {
      _success(
        await AuthService.instance.verifyOtp(_verificationId!, _code.text),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đăng nhập bằng số điện thoại')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Nhập số điện thoại để nhận mã xác thực qua SMS.',
          style: TextStyle(color: AppColors.mutedText, height: 1.5),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _phone,
          enabled: !_sending && _verificationId == null,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại',
            hintText: '+84901234567',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _sending || _verifying || _seconds > 0 ? null : _send,
          child: Text(
            _sending
                ? 'Đang gửi mã…'
                : _seconds > 0
                ? 'Gửi lại sau ${_seconds}s'
                : _verificationId == null
                ? 'Gửi mã OTP'
                : 'Gửi lại mã OTP',
          ),
        ),
        if (_verificationId != null) ...[
          const SizedBox(height: 24),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: 'Mã OTP gồm 6 chữ số',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _sending || _verifying ? null : _verify,
            child: Text(
              _verifying ? 'Đang xác thực…' : 'Xác thực và đăng nhập',
            ),
          ),
        ],
      ],
    ),
  );
}
