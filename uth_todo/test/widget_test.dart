import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_todo/screens/onboarding_step_one_screen.dart';
import 'package:uth_todo/screens/onboarding_step_three_screen.dart';
import 'package:uth_todo/screens/task_shell.dart';
import 'package:uth_todo/services/task_store.dart';

void main() {
  testWidgets('Onboarding step 1 → 2 → 3 → Home clears onboarding routes', (
    tester,
  ) async {
    final store = TaskStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      TaskScope(
        store: store,
        child: const MaterialApp(home: OnboardingStepOneScreen()),
      ),
    );
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingStepThreeScreen), findsOneWidget);
    await tester.tap(find.text('Bắt đầu ngay'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskShell), findsOneWidget);
    expect(find.text('Chào UTH!'), findsOneWidget);
    final context = tester.element(find.byType(TaskShell));
    expect(Navigator.of(context).canPop(), isFalse);
  });
}
