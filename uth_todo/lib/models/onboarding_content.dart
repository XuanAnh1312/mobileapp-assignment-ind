enum OnboardingIllustrationType { checklist, categories, reminder }

class OnboardingContent {
  const OnboardingContent({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.illustration,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final OnboardingIllustrationType illustration;
}
