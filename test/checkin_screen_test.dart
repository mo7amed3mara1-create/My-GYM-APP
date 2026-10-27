import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azm_gym/core/constants/app_strings.dart';
import 'package:azm_gym/presentation/screens/checkin/checkin_screen.dart';
import 'package:azm_gym/presentation/screens/main_navigation_scaffold.dart';

void main() {
  testWidgets('CheckInScreen mounts with custom slivers, input field, and buttons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CheckInScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(CheckInScreen), findsOneWidget);
    expect(find.byKey(const Key('checkin_id_field')), findsOneWidget);
    expect(find.text(AppStrings.submitCheckIn), findsWidgets);
    expect(find.text('تسجيل حضور برقم العضو (ID)'), findsOneWidget);
  });

  testWidgets('MainNavigationScaffold switches to CheckIn tab without crash', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationScaffold(initialIndex: 2),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(CheckInScreen), findsOneWidget);
    expect(find.text(AppStrings.checkInTitle), findsOneWidget);
  });

  testWidgets('Entering numeric ID updates text field in CheckInScreen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CheckInScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    final textFieldFinder = find.byKey(const Key('checkin_id_field'));
    await tester.enterText(textFieldFinder, '12');
    await tester.pump();
    expect(find.text('12'), findsOneWidget);
  });
}
