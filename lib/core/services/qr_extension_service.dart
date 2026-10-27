/// Phase 2 Extension Point: QR Code Integration Architecture.
///
/// Per specification:
/// "QR (Phase 2, do NOT build now): structure the code so each member's QR
/// can later encode their ID, and a captain-only scanner screen can open
/// that member's details. Members do not scan to check in themselves.
/// Leave a clean extension point only."
abstract class IQrExtensionService {
  /// Encodes member ID into a standard payload string for badge printing.
  String generateMemberQrPayload(int memberId);

  /// Decodes and validates scanned QR payload to extract 4-digit member ID.
  int? parseMemberQrPayload(String rawPayload);

  /// Validates whether captain scanner detected a valid gym member QR.
  bool isValidMemberPayload(String rawPayload);
}

class QrExtensionService implements IQrExtensionService {
  static const String _qrPrefix = 'MY_GYM_MEMBER:';
  static const String _legacyPrefix = 'AZM_GYM_MEMBER:';

  @override
  String generateMemberQrPayload(int memberId) {
    return '$_qrPrefix$memberId';
  }

  @override
  int? parseMemberQrPayload(String rawPayload) {
    if (!isValidMemberPayload(rawPayload)) {
      // Fallback: raw numeric string
      return int.tryParse(rawPayload.trim());
    }
    final idStr = rawPayload.replaceFirst(_qrPrefix, '').replaceFirst(_legacyPrefix, '').trim();
    return int.tryParse(idStr);
  }

  @override
  bool isValidMemberPayload(String rawPayload) {
    if (rawPayload.startsWith(_qrPrefix) || rawPayload.startsWith(_legacyPrefix)) {
      final idStr = rawPayload.replaceFirst(_qrPrefix, '').replaceFirst(_legacyPrefix, '').trim();
      return int.tryParse(idStr) != null;
    }
    // Also accept clean numeric 4-digit IDs
    final cleanNum = int.tryParse(rawPayload.trim());
    return cleanNum != null && cleanNum >= 1000;
  }
}
