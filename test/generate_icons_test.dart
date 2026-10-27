// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azm_gym/core/widgets/azm_logo.dart';

void main() {
  test('Generate Android Launcher Icons from AzmLogo', () async {
    final sizes = {
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };

    for (final entry in sizes.entries) {
      final folder = entry.key;
      final size = entry.value;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw rounded background
      final bgPaint = Paint()..color = const Color(0xFFF8F7FF);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), bgPaint);

      // Draw AzmLogo in the center with slight padding
      final logoSize = size.toDouble() * 0.82;
      final offset = (size.toDouble() - logoSize) / 2;

      canvas.save();
      canvas.translate(offset, offset);
      final painter = AzmLogoPainter();
      painter.paint(canvas, Size(logoSize, logoSize));
      canvas.restore();

      final picture = recorder.endRecording();
      final img = await picture.toImage(size, size);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final targetPath = 'android/app/src/main/res/$folder/ic_launcher.png';
      final file = File(targetPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      print('Generated icon: $targetPath ($size x $size)');
    }

    // Generate iOS 1024x1024 App Store / Main icon
    {
      const size = 1024;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final bgPaint = Paint()..color = const Color(0xFFF8F7FF);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 1024, 1024), bgPaint);

      const logoSize = 1024.0 * 0.80;
      const offset = (1024.0 - logoSize) / 2;

      canvas.save();
      canvas.translate(offset, offset);
      final painter = AzmLogoPainter();
      painter.paint(canvas, const Size(logoSize, logoSize));
      canvas.restore();

      final picture = recorder.endRecording();
      final img = await picture.toImage(size, size);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final iosFile = File('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png');
      if (await iosFile.parent.exists()) {
        await iosFile.writeAsBytes(bytes);
        print('Generated iOS icon: ${iosFile.path}');
      }
    }
  });
}
