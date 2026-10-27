import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/widgets/azm_logo.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../main_navigation_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate fields
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final success = await ref.read(authProvider.notifier).login(username, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const MainNavigationScaffold(),
          transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    } else {
      final authError = ref.read(authProvider).errorMessage;
      setState(() {
        _errorMessage = authError ?? AppStrings.invalidCredentials;
      });
    }
  }

  void _showResetAccountDialog() {
    final newUserController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('إعادة تعيين الحساب', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أدخل اسم المستخدم وكلمة المرور الجديدة لتعيينها كحساب مالك للجيم:',
              style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: newUserController,
              label: AppStrings.username,
              hint: 'مثال: كابتن',
            ),
            const SizedBox(height: 10),
            CustomTextField(
              controller: newPassController,
              label: AppStrings.password,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel, style: GoogleFonts.cairo(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final u = newUserController.text.trim();
              final p = newPassController.text.trim();
              if (u.isEmpty || p.isEmpty) return;

              final ok = await ref.read(authProvider.notifier).resetCredentials(u, p);
              if (ctx.mounted) Navigator.pop(ctx);

              if (ok && mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainNavigationScaffold()),
                );
              }
            },
            child: Text(AppStrings.save, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBiometricLogin() async {
    final result = await ref.read(authProvider.notifier).loginWithBiometrics();
    if (result.isSuccess && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScaffold()),
      );
    } else if (mounted) {
      AppNotification.showError(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider).value;
    final biometricsEnabled = settings?.biometricsEnabled ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Smooth bouncing drag & swipe physics
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Clean Logo and Name
                  const AzmLogo(
                    size: 84,
                    showText: true,
                    isDarkText: true,
                  ),
                  const SizedBox(height: 28),

                  // Login Surface Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0x0C1B1F3B), width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x061B1F3B),
                          blurRadius: 16,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.signIn,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Error Banner if invalid credentials
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.statusRedBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.statusRedFg),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.statusRedFg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Username Field
                        CustomTextField(
                          controller: _usernameController,
                          label: AppStrings.username,
                          hint: 'أدخل اسم المستخدم',
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            _passwordFocusNode.requestFocus();
                          },
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'يرجى كتابة اسم المستخدم';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        CustomTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          label: AppStrings.password,
                          hint: 'أدخل كلمة المرور',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'يرجى كتابة كلمة المرور';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Crimson Full-width Login Button
                        CustomButton(
                          label: AppStrings.signIn,
                          icon: Icons.login_rounded,
                          isLoading: _isLoading,
                          onPressed: _submit,
                        ),

                        // Reset button if error occurred
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _showResetAccountDialog,
                            child: Text(
                              'نسيت البيانات؟ اضغط هنا لإعادة تعيين الحساب',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],

                        // Optional Biometric Button
                        if (biometricsEnabled) ...[
                          const SizedBox(height: 12),
                          CustomButton(
                            label: AppStrings.signInWithBiometrics,
                            icon: Icons.fingerprint_rounded,
                            type: ButtonType.secondary,
                            onPressed: _handleBiometricLogin,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
