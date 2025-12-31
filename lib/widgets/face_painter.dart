import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size absoluteImageSize; // Size of the image from camera sensor
  final InputImageRotation rotation; // Rotation to check orientation
  final CameraLensDirection cameraLensDirection; // To mirror front camera

  FacePainter({
    required this.faces,
    required this.absoluteImageSize,
    required this.rotation,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.red;

    for (final face in faces) {
      // 1. Get the bounding box
      final rect = face.boundingBox;

      // 2. Calculate scaling factors
      // The camera image might be e.g. 1280x720, but screen is 400x800
      // Note: In portrait, width/height are often swapped in ML Kit metadata depending on rotation
      final double scaleX = size.width / absoluteImageSize.height;
      final double scaleY = size.height / absoluteImageSize.width;

      // 3. Scale and translate the rect
      // ML Kit coordinates need to be flipped for front camera mirror effect
      double left = rect.left * scaleX;
      double top = rect.top * scaleY;
      double right = rect.right * scaleX;
      double bottom = rect.bottom * scaleY;

      if (cameraLensDirection == CameraLensDirection.front) {
        // Mirror logic for front camera
        final w = size.width;
        left = w - right;
        right = w - (rect.left * scaleX);
      }

      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}
