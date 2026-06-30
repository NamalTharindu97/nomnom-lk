import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = const Size(1024, 1024);

  // Draw curry-orange background
  final bgPaint = Paint()..color = const Color(0xFFFFB23F);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 1024, 1024), bgPaint);

  // Scale the icon drawing
  canvas.save();
  canvas.scale(1024 / 24.0); // Material icons are 24x24 viewport

  // Draw white restaurant_menu_rounded icon path
  final iconPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  // Path for restaurant_menu_rounded icon
  final path = Path();
  path.moveTo(8.1, 13.34);
  path.lineTo(10.93, 10.51);
  path.lineTo(3.91, 3.5);
  path.cubicTo(2.35, 5.06, 2.35, 7.59, 3.91, 9.16);
  path.lineTo(8.1, 13.34);
  path.close();

  path.moveTo(14.88, 11.53);
  path.cubicTo(16.41, 12.24, 18.56, 11.74, 20.15, 10.15);
  path.cubicTo(22.06, 8.24, 22.43, 5.5, 20.96, 4.03);
  path.cubicTo(19.5, 2.57, 16.76, 2.93, 14.84, 4.84);
  path.cubicTo(13.25, 6.43, 12.75, 8.58, 13.46, 10.11);
  path.lineTo(3.7, 19.87);
  path.lineTo(5.11, 21.28);
  path.lineTo(12, 14.41);
  path.lineTo(18.88, 21.29);
  path.lineTo(20.29, 19.88);
  path.lineTo(13.41, 13.0);
  path.lineTo(14.88, 11.53);
  path.close();

  canvas.drawPath(path, iconPaint);
  canvas.restore();

  // Render to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(1024, 1024);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('assets/app_icon.png');
  await file.writeAsBytes(byteData!.buffer.asUint8List());
  print('Generated assets/app_icon.png');
}
