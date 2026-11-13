import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'task_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: AuthService.instance.authStateChanges,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return const Scaffold(
          body: Center(
            child: Text('Không thể đọc phiên đăng nhập. Hãy mở lại ứng dụng.'),
          ),
        );
      }
      final user = snapshot.data;
      if (user == null) return const LoginScreen();
      // Login is now opened above the Home shell. Return to that shell rather
      // than stacking a second bottom navigation after authentication.
      if (Navigator.of(context).canPop()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return const TaskShell();
    },
  );
}
