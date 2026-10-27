import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azm_gym/main.dart';
import 'package:azm_gym/core/constants/app_strings.dart';

void main() {
  testWidgets('App smoke test - mounts successfully and passes splash', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AzmGymApp(),
      ),
    );

    // Initial frame
    expect(find.text(AppStrings.appName), findsWidgets);

    // Let splash timer (1.2s) complete cleanly
    await tester.pump(const Duration(milliseconds: 1500));
  });
}
