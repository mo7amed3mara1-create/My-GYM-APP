import 'package:url_launcher/url_launcher.dart';

class PhoneHelper {
  /// Normalizes phone numbers, specifically Egyptian formats:
  /// - '01012345678' -> '201012345678'
  /// - '+201012345678' -> '201012345678'
  /// - '00201012345678' -> '201012345678'
  /// - '01xxxxxxxxx' -> '201xxxxxxxxx'
  static String normalizeEgyptianNumber(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
    }

    // Egyptian mobile starts with 01 and is 11 digits: e.g. 010, 011, 012, 015
    if (cleaned.startsWith('01') && cleaned.length == 11) {
      return '2$cleaned';
    }

    return cleaned;
  }

  /// Builds a valid WhatsApp Web / App intent URL.
  static String buildWhatsAppUrl(String phone, String message) {
    final normalized = normalizeEgyptianNumber(phone);
    final encoded = Uri.encodeComponent(message);
    return 'https://wa.me/$normalized?text=$encoded';
  }

  /// Launches WhatsApp with the prepared text.
  static Future<bool> launchWhatsApp(String phone, String message) async {
    final urlString = buildWhatsAppUrl(phone, message);
    final uri = Uri.parse(urlString);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Launches native phone dialer.
  static Future<bool> launchPhoneCall(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  /// Strict Egyptian mobile phone validation:
  /// Must be exactly 11 digits starting with 01 (010, 011, 012, 015),
  /// or international +201 / 201 followed by 9 digits.
  static bool isValidEgyptianMobile(String phone) {
    final trimmed = phone.trim();
    // Local format: 010xxxxxxxx, 011xxxxxxxx, 012xxxxxxxx, 015xxxxxxxx (11 digits)
    final localRegExp = RegExp(r'^01[0125][0-9]{8}$');
    if (localRegExp.hasMatch(trimmed)) return true;

    // International format: +2010xxxxxxxx or 2010xxxxxxxx
    final intlRegExp = RegExp(r'^(\+?20)1[0125][0-9]{8}$');
    return intlRegExp.hasMatch(trimmed);
  }

  /// Validates phone number format for general input (used as fallback).
  static bool isValidPhone(String phone) {
    return isValidEgyptianMobile(phone);
  }
}
