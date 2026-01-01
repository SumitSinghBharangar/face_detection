import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class StaticFacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;

  StaticFacePainter(this.image, this.faces);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0 // Thinner for static images usually looks better
      ..color = const Color.fromARGB(255, 253, 228, 5);

    double scaleX = size.width / image.width;
    double scaleY = size.height / image.height;
    double scale = scaleX < scaleY ? scaleX : scaleY;

    double offsetX = (size.width - image.width * scale) / 2;
    double offsetY = (size.height - image.height * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    // Draw the image first
    canvas.drawImage(image, Offset.zero, Paint());

    // Draw the boxes
    for (var face in faces) {
      canvas.drawRect(face.boundingBox, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(StaticFacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}