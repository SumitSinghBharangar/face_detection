import 'package:camera/camera.dart';
import 'package:face_detection/provider/face_detector_provider.dart';
import 'package:face_detection/widgets/face_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';

class LiveFaceDetectorScreen extends StatelessWidget {
  const LiveFaceDetectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FaceDetectorProvider()..initializeCamera(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Live Face Detector")),
        body: Consumer<FaceDetectorProvider>(
          builder: (context, provider, child) {
            if (provider.cameraController == null ||
                !provider.cameraController!.value.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }

            final size = MediaQuery.of(context).size;

            // Calculate correct aspect ratio to prevent camera preview distortion
            var scale =
                size.aspectRatio * provider.cameraController!.value.aspectRatio;
            if (scale < 1) scale = 1 / scale;

            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. Camera Preview
                Transform.scale(
                  scale: scale,
                  child: Center(
                    child: CameraPreview(provider.cameraController!),
                  ),
                ),

                // 2. Face Painting Overlay
                if (provider.cameraController != null)
                  Transform.scale(
                    scale: scale,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio:
                            provider.cameraController!.value.aspectRatio,
                        child: CustomPaint(
                          painter: FacePainter(
                            faces: provider.faces,
                            absoluteImageSize: Size(
                              provider
                                  .cameraController!
                                  .value
                                  .previewSize!
                                  .height,
                              provider
                                  .cameraController!
                                  .value
                                  .previewSize!
                                  .width,
                            ),
                            rotation:
                                InputImageRotation.rotation0deg, // Simplified
                            cameraLensDirection: provider.cameraLensDirection,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 3. UI Controls
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        "Faces detected: ${provider.faces.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        onPressed: provider.switchCamera,
                        child: const Icon(Icons.cameraswitch),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
