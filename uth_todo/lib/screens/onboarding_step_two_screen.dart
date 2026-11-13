import 'package:flutter/material.dart';

import '../models/onboarding_content.dart';
import '../widgets/onboarding_page_layout.dart';
import 'onboarding_step_three_screen.dart';

class OnboardingStepTwoScreen extends StatelessWidget {
  const OnboardingStepTwoScreen({super.key});
  static const _content = OnboardingContent(title: 'Chia theo Học tập và Cuộc sống', description: 'Mỗi việc có nhóm riêng, nhìn là biết hôm nay cần lo gì.', buttonLabel: 'Tiếp tục', illustration: OnboardingIllustrationType.categories);

  @override
  Widget build(BuildContext context) => OnboardingPageLayout(
        content: _content,
        step: 1,
        onSkip: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const OnboardingStepThreeScreen())),
        onContinue: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const OnboardingStepThreeScreen())),
      );
}
