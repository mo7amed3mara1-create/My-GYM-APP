import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:azm_gym/presentation/screens/checkin/checkin_screen.dart';
import 'package:azm_gym/core/constants/app_theme.dart';

void main() {
  testWidgets('CheckInScreen layout test', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(1080, 2400);
    tester.binding.window.devicePixelRatioTestValue = 3.0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CheckInScreen(),
        ),
      ),
    );
    await tester.pump();
  });
}
