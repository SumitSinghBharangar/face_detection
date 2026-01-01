import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size absoluteImageSize;
  final CameraLensDirection cameraLensDirection;

  FacePainter({
    required this.faces,
    required this.absoluteImageSize,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.yellow;

    for (final face in faces) {
      // Logic to convert camera coordinates to screen coordinates
      final double scaleX = size.width / absoluteImageSize.height;
      final double scaleY = size.height / absoluteImageSize.width;

      double left = face.boundingBox.left * scaleX;
      double top = face.boundingBox.top * scaleY;
      double right = face.boundingBox.right * scaleX;
      double bottom = face.boundingBox.bottom * scaleY;

      // Mirror the rectangle if using front camera
      if (cameraLensDirection == CameraLensDirection.front) {
        final w = size.width;
        // Swap left and right for mirror effect
        double tempLeft = left;
        left = w - right;
        right = w - tempLeft;
      }

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces || 
           oldDelegate.absoluteImageSize != absoluteImageSize;
  }
}

