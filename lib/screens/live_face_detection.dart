import 'package:face_detection/provider/face_detector_provider.dart';
import 'package:face_detection/widgets/face_painter.dart';
import 'package:face_detection/widgets/static_face_painter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

class LiveDetectorScreen extends StatelessWidget {
  const LiveDetectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FaceDetectorProvider()..initializeCamera(),
      child: Consumer<FaceDetectorProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(provider.isStaticMode ? "Image Mode" : "Live Mode"),
              // If in static mode, show a 'Back' button in AppBar
              leading: provider.isStaticMode
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: provider.closeStaticImage,
                    )
                  : null,
            ),
            body: Stack(
              children: [
                // MAIN CONTENT (Switch between Live and Static)
                if (provider.isStaticMode && provider.staticImage != null)
                  // --- STATIC IMAGE VIEW ---
                  Center(
                    child: CustomPaint(
                      painter: StaticFacePainter(
                        provider.staticImage!,
                        provider.faces,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  )
                else if (provider.cameraController != null &&
                    provider.cameraController!.value.isInitialized)
                  // --- LIVE CAMERA VIEW ---
                  _buildLiveView(context, provider)
                else
                  const Center(child: CircularProgressIndicator()),

                // CONTROLS (Only show in Live Mode)
                if (!provider.isStaticMode)
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 1. Gallery Button
                        FloatingActionButton(
                          heroTag: "gallery",
                          onPressed: () => provider.pickImageFromGallery(),
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.photo_library),
                        ),

                        // 2. Info Text
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${provider.faces.length} Faces",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),

                        // 3. Switch Camera Button
                        FloatingActionButton(
                          heroTag: "switch",
                          onPressed: () => provider.switchCamera(),
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.cameraswitch),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveView(BuildContext context, FaceDetectorProvider provider) {
    final size = MediaQuery.of(context).size;

    // Calculate scale to make camera fill the screen (BoxFit.cover logic)
    var scale = size.aspectRatio * provider.cameraController!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: The Camera Preview (Zoomed/Scaled to cover)
        Transform.scale(
          scale: scale,
          child: Center(child: CameraPreview(provider.cameraController!)),
        ),

        // Layer 2: The Painter (Full Screen, No Transform)
        // We pass the screen size to it, and it calculates the sync manually
        Positioned.fill(
          child: CustomPaint(
            painter: FacePainter(
              faces: provider.faces,
              absoluteImageSize: Size(
                provider.cameraController!.value.previewSize!.width,
                provider.cameraController!.value.previewSize!.height,
              ),
              rotation: provider.rotation,
              cameraLensDirection: provider.cameraLensDirection,
            ),
          ),
        ),
      ],
    );
  }
}
