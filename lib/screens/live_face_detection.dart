import 'package:face_detection/provider/face_detector_provider.dart';
import 'package:face_detection/widgets/face_painter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';


class LiveDetectorScreen extends StatelessWidget {
  const LiveDetectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Wrap the screen in the Provider
    return ChangeNotifierProvider(
      create: (_) => FaceDetectorProvider()..initializeCamera(),
      child: Consumer<FaceDetectorProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(title: const Text("Face Detector Live")),
            body: _buildBody(context, provider),
            floatingActionButton: FloatingActionButton(
              onPressed: provider.switchCamera,
              child: const Icon(Icons.cameraswitch),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, FaceDetectorProvider provider) {
    if (provider.cameraController == null ||
        !provider.cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * provider.cameraController!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. The Camera Preview
        Transform.scale(
          scale: scale,
          child: Center(
            child: CameraPreview(provider.cameraController!),
          ),
        ),
        
        // 2. The Face Painter Overlay
        Transform.scale(
          scale: scale,
          child: Center(
            child: AspectRatio(
              aspectRatio: provider.cameraController!.value.aspectRatio,
              child: CustomPaint(
                painter: FacePainter(
                  faces: provider.faces,
                  absoluteImageSize: Size(
                    provider.cameraController!.value.previewSize!.height,
                    provider.cameraController!.value.previewSize!.width,
                  ),
                  cameraLensDirection: provider.cameraLensDirection,
                ),
              ),
            ),
          ),
        ),

        // 3. Info Text
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black54,
            child: Text(
              "Faces: ${provider.faces.length}",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}