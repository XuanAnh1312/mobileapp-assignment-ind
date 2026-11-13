import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'onboarding_step_one_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});
  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const OnboardingStepOneScreen()));
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.mainBlue,
        body: SafeArea(
          child: Column(children: [
            const Spacer(),
            Center(child: Column(children: [
              Image.asset('reference/logo.png', width: 110, height: 110),
              const SizedBox(height: 22),
              const Text.rich(TextSpan(children: [
                TextSpan(text: 'UTH', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' Todo'),
              ]), style: TextStyle(color: AppColors.mainWhite, fontSize: 38, height: 1.1)),
              const SizedBox(height: 8),
              const Text('Việc học, việc nhà – gọn gàng mỗi ngày', style: TextStyle(color: AppColors.mainWhite, fontSize: 14)),
            ])),
            const Spacer(),
            Padding(padding: const EdgeInsets.only(bottom: 45), child: Column(children: [
              SizedBox(width: 112, child: ClipRRect(borderRadius: BorderRadius.circular(3), child: const LinearProgressIndicator(minHeight: 4, value: 0.42, backgroundColor: Color(0x665B7CEF), valueColor: AlwaysStoppedAnimation(AppColors.mainWhite)))),
              const SizedBox(height: 14),
              const Text('Phiên bản 2.1.0', style: TextStyle(color: AppColors.mainWhite, fontSize: 11)),
            ])),
          ]),
        ),
      );
}
