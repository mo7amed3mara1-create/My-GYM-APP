import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthResult {
  final bool isSuccess;
  final String message;

  const BiometricAuthResult({required this.isSuccess, required this.message});
}

class BiometricService {
  static final BiometricService instance = BiometricService._init();
  final LocalAuthentication _auth = LocalAuthentication();

  BiometricService._init();

  /// Checks if hardware and device support biometric authentication
  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Attempts biometric authentication. Returns true ONLY upon valid physical match.
  Future<BiometricAuthResult> authenticate({
    String reason = 'يرجى تأكيد بصمة الإصبع أو الوجه لتسجيل الدخول إلى MY GYM',
  }) async {
    try {
      final isAvailable = await canAuthenticate();
      if (!isAvailable) {
        return const BiometricAuthResult(
          isSuccess: false,
          message: 'خاصية البصمة غير مدعومة أو غير مفعلة على هذا الهاتف',
        );
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        return const BiometricAuthResult(
          isSuccess: true,
          message: 'تم تأكيد البصمة بنجاح',
        );
      } else {
        return const BiometricAuthResult(
          isSuccess: false,
          message: 'تم إلغاء تأكيد البصمة أو لم تتطابق',
        );
      }
    } on PlatformException catch (e) {
      return BiometricAuthResult(
        isSuccess: false,
        message: 'تعذر التحقق من البصمة: ${e.message ?? e.code}',
      );
    } catch (e) {
      return BiometricAuthResult(
        isSuccess: false,
        message: 'حدث خطأ أثناء فحص البصمة: $e',
      );
    }
  }
}
