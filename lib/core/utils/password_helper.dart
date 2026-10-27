import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHelper {
  /// Generates a random alphanumeric salt.
  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  /// Hashes a password with salt using SHA-256.
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password:azm_gym_secret_pepper');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies a password against stored salt and hash.
  static bool verifyPassword({
    required String password,
    required String salt,
    required String storedHash,
  }) {
    final computed = hashPassword(password, salt);
    return computed == storedHash;
  }
}
