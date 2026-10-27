import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

enum MemberStatusType { active, expiring, expired, paid, unpaid }

class StatusBadge extends StatelessWidget {
  final MemberStatusType status;
  final String? customText;
  final VoidCallback? onTap;
  final bool isInteractive;

  const StatusBadge({
    super.key,
    required this.status,
    this.customText,
    this.onTap,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;
    IconData icon;

    switch (status) {
      case MemberStatusType.active:
        bg = AppColors.statusTealBg;
        fg = AppColors.statusTealFg;
        text = customText ?? AppStrings.filterActive;
        icon = Icons.check_circle_outline_rounded;
        break;
      case MemberStatusType.expiring:
        bg = AppColors.statusAmberBg;
        fg = AppColors.statusAmberFg;
        text = customText ?? AppStrings.filterExpiring;
        icon = Icons.access_time_rounded;
        break;
      case MemberStatusType.expired:
        bg = AppColors.statusRedBg;
        fg = AppColors.statusRedFg;
        text = customText ?? AppStrings.filterExpired;
        icon = Icons.error_outline_rounded;
        break;
      case MemberStatusType.paid:
        bg = AppColors.statusGreenBg;
        fg = AppColors.statusGreenFg;
        text = customText ?? AppStrings.paid;
        icon = Icons.check_rounded;
        break;
      case MemberStatusType.unpaid:
        bg = AppColors.statusRedBg;
        fg = AppColors.statusRedFg;
        text = customText ?? AppStrings.unpaid;
        icon = Icons.close_rounded;
        break;
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );

    if (isInteractive && onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: badge,
      );
    }

    return badge;
  }
}
