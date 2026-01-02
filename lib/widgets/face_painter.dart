import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

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
      ..strokeWidth = 5.0
      ..color = const Color.fromARGB(255, 253, 228, 5);

    for (final face in faces) {
      canvas.drawRect(
        _scaleRect(
          rect: face.boundingBox,
          imageSize: absoluteImageSize,
          widgetSize: size,
          rotation: rotation,
          cameraLensDirection: cameraLensDirection,
        ),
        paint,
      );
    }
  }

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    required InputImageRotation rotation,
    required CameraLensDirection cameraLensDirection,
  }) {
    // 1. Correct Image Dimensions for Rotation (Android is usually Landscape)
    final bool isRotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    final double imageWidth = isRotated ? imageSize.height : imageSize.width;
    final double imageHeight = isRotated ? imageSize.width : imageSize.height;

    // 2. Calculate Scale to "Cover" the screen (BoxFit.cover)
    final double scaleX = widgetSize.width / imageWidth;
    final double scaleY = widgetSize.height / imageHeight;
    final double scale = scaleX > scaleY ? scaleX : scaleY; // Use max to cover

    // 3. Calculate Offset (Center the image)
    final double offsetX = (widgetSize.width - imageWidth * scale) / 2;
    final double offsetY = (widgetSize.height - imageHeight * scale) / 2;

    // 4. Map Coordinates
    // Standard mapping: x * scale + offset
    double left = rect.left * scale + offsetX;
    double top = rect.top * scale + offsetY;
    double right = rect.right * scale + offsetX;
    double bottom = rect.bottom * scale + offsetY;

    // 5. Mirror X for Front Camera
    if (cameraLensDirection == CameraLensDirection.front) {
      // For selfie, we mirror the X coordinates around the center of the widget
      left = widgetSize.width - right;
      right = widgetSize.width - (rect.left * scale + offsetX);
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.rotation != rotation;
  }
}
