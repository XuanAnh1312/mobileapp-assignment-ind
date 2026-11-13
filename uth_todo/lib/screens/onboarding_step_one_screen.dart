import 'package:flutter/material.dart';

import '../models/onboarding_content.dart';
import '../widgets/onboarding_page_layout.dart';
import 'onboarding_step_three_screen.dart';
import 'onboarding_step_two_screen.dart';

class OnboardingStepOneScreen extends StatelessWidget {
  const OnboardingStepOneScreen({super.key});
  static const _content = OnboardingContent(title: 'Mọi việc, gọn trong một chỗ', description: 'Ghi lại bài tập, việc nhà, lịch hẹn. Không còn quên việc nào.', buttonLabel: 'Tiếp tục', illustration: OnboardingIllustrationType.checklist);

  @override
  Widget build(BuildContext context) => OnboardingPageLayout(
        content: _content,
        step: 0,
        onSkip: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const OnboardingStepThreeScreen())),
        onContinue: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const OnboardingStepTwoScreen())),
      );
}
