import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/widgets/azm_logo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../auth/login_screen.dart';
import '../auth/register_owner_screen.dart';
import '../main_navigation_scaffold.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    // Wait for at least 1.2 seconds for branding splash effect AND await DB auth initialization
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1200)),
      ref.read(authProvider.notifier).initializationFuture,
    ]);
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (!authState.hasOwnerAccount) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const RegisterOwnerScreen(),
          transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    } else if (authState.isAuthenticated) {
      final settings = ref.read(settingsNotifierProvider).value;
      if (settings != null && settings.biometricsEnabled) {
        // Biometrics is enabled: require fingerprint validation before entering
        final bioResult = await BiometricService.instance.authenticate(
          reason: 'يرجى تأكيد بصمة الإصبع أو الوجه لتسجيل الدخول إلى MY GYM',
        );
        if (!mounted) return;

        if (bioResult.isSuccess) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, anim, secAnim) => const MainNavigationScaffold(),
              transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          );
        } else {
          // If biometric is cancelled or failed, redirect to LoginScreen for password authentication
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, anim, secAnim) => const LoginScreen(),
              transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => const MainNavigationScaffold(),
            transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const LoginScreen(),
          transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AzmLogo(
                size: 110,
                showText: true,
                isDarkText: true,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.splashLoading,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
