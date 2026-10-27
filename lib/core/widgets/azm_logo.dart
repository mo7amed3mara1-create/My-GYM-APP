import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// A custom geometric vector logo for AZM GYM (عزم جيم) drawn in code via CustomPaint.
/// Combines a strong hexagonal shield, an upward-pointing peak (letter A / determination),
/// and barbell weight plates.
class AzmLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  AzmLogoPainter({
    this.primaryColor = AppColors.primary,
    this.accentColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Draw outer rounded hexagonal shield
    final shieldPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Clean stylized modern shield with beveled corners:
    final p1 = Offset(w * 0.50, h * 0.05); // top vertex
    final p2 = Offset(w * 0.92, h * 0.28); // top-right
    final p3 = Offset(w * 0.92, h * 0.72); // bottom-right
    final p4 = Offset(w * 0.50, h * 0.96); // bottom vertex
    final p5 = Offset(w * 0.08, h * 0.72); // bottom-left
    final p6 = Offset(w * 0.08, h * 0.28); // top-left

    final hexPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..lineTo(p5.dx, p5.dy)
      ..lineTo(p6.dx, p6.dy)
      ..close();

    // Subtle drop shadow for shield
    canvas.drawShadow(hexPath, AppColors.textPrimary.withOpacity(0.3), 6, true);
    canvas.drawPath(hexPath, shieldPaint);

    // Inner subtle glow border
    final borderPaint = Paint()
      ..color = accentColor.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..isAntiAlias = true;
    canvas.drawPath(hexPath, borderPaint);

    // 2. Dumbbell bar (horizontal central power bar)
    final barPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final barRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.08), width: w * 0.55, height: h * 0.08),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(barRect, barPaint);

    // 3. Central upward Chevron / Peak ("A" / "عزم" / Resolve)
    final peakPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final peakPath = Path()
      ..moveTo(center.dx, h * 0.20) // apex
      ..lineTo(center.dx + w * 0.22, h * 0.52)
      ..lineTo(center.dx + w * 0.12, h * 0.52)
      ..lineTo(center.dx, h * 0.35)
      ..lineTo(center.dx - w * 0.12, h * 0.52)
      ..lineTo(center.dx - w * 0.22, h * 0.52)
      ..close();
    canvas.drawPath(peakPath, peakPaint);

    // 4. Weight plates on left and right
    final platePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Left plate
    final leftPlate = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx - w * 0.23, center.dy + h * 0.08), width: w * 0.07, height: h * 0.28),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(leftPlate, platePaint);

    // Left outer plate
    final leftOuterPlate = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx - w * 0.28, center.dy + h * 0.08), width: w * 0.045, height: h * 0.20),
      Radius.circular(w * 0.015),
    );
    canvas.drawRRect(leftOuterPlate, platePaint);

    // Right plate
    final rightPlate = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx + w * 0.23, center.dy + h * 0.08), width: w * 0.07, height: h * 0.28),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(rightPlate, platePaint);

    // Right outer plate
    final rightOuterPlate = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx + w * 0.28, center.dy + h * 0.08), width: w * 0.045, height: h * 0.20),
      Radius.circular(w * 0.015),
    );
    canvas.drawRRect(rightOuterPlate, platePaint);

    // Bottom power dot
    canvas.drawCircle(Offset(center.dx, h * 0.78), w * 0.035, barPaint);
  }

  @override
  bool shouldRepaint(covariant AzmLogoPainter oldDelegate) => false;
}

/// A responsive, high-end widget to display the AZM logo.
class AzmLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDarkText;

  const AzmLogo({
    super.key,
    this.size = 56,
    this.showText = false,
    this.isDarkText = true,
  });

  @override
  Widget build(BuildContext context) {
    final emblem = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: AzmLogoPainter(),
      ),
    );

    if (!showText) {
      return emblem;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblem,
        const SizedBox(height: 12),
        Text(
          AppStrings.appName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w900,
            color: isDarkText ? AppColors.textPrimary : Colors.white,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          AppStrings.gymSlogan,
          style: GoogleFonts.cairo(
            fontSize: size * 0.16,
            fontWeight: FontWeight.w700,
            color: isDarkText ? AppColors.textSecondary : Colors.white70,
          ),
        ),
      ],
    );
  }
}
