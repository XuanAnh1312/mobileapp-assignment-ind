import 'package:flutter/material.dart';

import '../models/onboarding_content.dart';
import '../widgets/onboarding_page_layout.dart';
import 'task_shell.dart';

class OnboardingStepThreeScreen extends StatelessWidget {
  const OnboardingStepThreeScreen({super.key});
  static const _content = OnboardingContent(
    title: 'Nhắc đúng lúc',
    description: 'Bật thông báo để UTH Todo nhắc bạn trước hạn chót.',
    buttonLabel: 'Bắt đầu ngay',
    illustration: OnboardingIllustrationType.reminder,
  );

  @override
  Widget build(BuildContext context) {
    void openHome() => Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const TaskShell()),
      (_) => false,
    );
    return OnboardingPageLayout(
      content: _content,
      step: 2,
      onSkip: openHome,
      onContinue: openHome,
    );
  }
}
