import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/onboarding_content.dart';

class OnboardingPageLayout extends StatelessWidget {
  const OnboardingPageLayout({
    super.key,
    required this.content,
    required this.step,
    required this.onSkip,
    required this.onContinue,
  });

  final OnboardingContent content;
  final int step;
  final VoidCallback onSkip;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.mainWhite,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 720;
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 38),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(onSkip: onSkip),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: _Illustration(type: content.illustration, compact: compact)),
                          SizedBox(height: compact ? 48 : 68),
                          Text(content.title, style: const TextStyle(fontSize: 26, height: 1.15, fontWeight: FontWeight.w700, color: AppColors.mainBlack)),
                          const SizedBox(height: 14),
                          Text(content.description, style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.mutedText)),
                        ],
                      ),
                    ),
                    _ProgressDots(step: step),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.mainBlue, foregroundColor: AppColors.mainWhite, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: Text(content.buttonLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.onSkip});
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.mainBlue, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.checklist, color: AppColors.mainWhite, size: 21)),
          const SizedBox(width: 10),
          const Text.rich(TextSpan(children: [
            TextSpan(text: 'UTH ', style: TextStyle(color: AppColors.mainBlack, fontWeight: FontWeight.w700)),
            TextSpan(text: 'Todo', style: TextStyle(color: AppColors.mainBlue, fontWeight: FontWeight.w500)),
          ]), style: TextStyle(fontSize: 18)),
          const Spacer(),
          TextButton(onPressed: onSkip, style: TextButton.styleFrom(foregroundColor: AppColors.mutedText), child: const Text('Bỏ qua', style: TextStyle(fontSize: 14))),
        ],
      );
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final active = index == step;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 23 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: active ? AppColors.mainBlue : AppColors.inactiveDot, borderRadius: BorderRadius.circular(8)),
          );
        }),
      );
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.type, required this.compact});
  final OnboardingIllustrationType type;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        width: compact ? 190 : 220,
        height: compact ? 190 : 220,
        decoration: BoxDecoration(color: AppColors.illustrationBlue, borderRadius: BorderRadius.circular(28)),
        child: switch (type) {
          OnboardingIllustrationType.checklist => const _ChecklistArt(),
          OnboardingIllustrationType.categories => const _CategoryArt(),
          OnboardingIllustrationType.reminder => const _ReminderArt(),
        },
      );
}

class _ChecklistArt extends StatelessWidget {
  const _ChecklistArt();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: List.generate(3, (index) => Container(
          width: 192, height: 47, margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: AppColors.mainWhite, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 5))]),
          child: Row(children: [
            Icon(index == 0 ? Icons.check_circle : Icons.circle_outlined, size: 21, color: index == 0 ? AppColors.mainBlue : const Color(0xFFC7C7CC)),
            const SizedBox(width: 12),
            Container(width: index == 0 ? 105 : 84, height: 8, decoration: BoxDecoration(color: const Color(0xFFE2E2E8), borderRadius: BorderRadius.circular(5))),
          ]),
        ))),
      );
}

class _CategoryArt extends StatelessWidget {
  const _CategoryArt();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _CategoryCard(label: 'Học tập', labelColor: AppColors.mainBlue, chipColor: Color(0xFFE5ECFF), lineWidth: 132),
          SizedBox(height: 14),
          _CategoryCard(label: 'Cuộc sống', labelColor: Color(0xFFB65319), chipColor: Color(0xFFFFE8D8), lineWidth: 105),
        ]),
      );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.label, required this.labelColor, required this.chipColor, required this.lineWidth});
  final String label;
  final Color labelColor;
  final Color chipColor;
  final double lineWidth;

  @override
  Widget build(BuildContext context) => Container(
        width: 192, height: 67, padding: const EdgeInsets.fromLTRB(15, 11, 12, 9),
        decoration: BoxDecoration(color: AppColors.mainWhite, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(7)), child: Text(label, style: TextStyle(color: labelColor, fontSize: 11, height: 1.1, fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          Container(width: lineWidth, height: 7, decoration: BoxDecoration(color: const Color(0xFFE2E2E8), borderRadius: BorderRadius.circular(5))),
        ]),
      );
}

class _ReminderArt extends StatelessWidget {
  const _ReminderArt();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 80, height: 80, decoration: const BoxDecoration(color: AppColors.mainWhite, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x17000000), blurRadius: 14, offset: Offset(0, 6))]), child: const Icon(Icons.notifications_none, color: AppColors.mainBlue, size: 38)),
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: AppColors.mainWhite, borderRadius: BorderRadius.circular(13), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 5))]), child: const Text('Ôn bài Toán lúc 19:00', style: TextStyle(fontSize: 12, color: AppColors.mainBlack))),
        ]),
      );
}
