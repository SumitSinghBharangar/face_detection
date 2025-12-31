import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorProvider extends ChangeNotifier {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast, // Important for live stream
    ),
  );

  bool _isBusy = false;
  List<Face> _faces = [];
  CameraLensDirection _cameraLensDirection = CameraLensDirection.front;

  CameraController? get cameraController => _cameraController;
  List<Face> get faces => _faces;
  CameraLensDirection get cameraLensDirection => _cameraLensDirection;

  // 1. Initialize Camera
  Future<void> initializeCamera() async {
    final cameras = await availableCameras();

    final cameraDescription = cameras.firstWhere(
      (camera) => camera.lensDirection == _cameraLensDirection,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup
                .nv21 // Android standard for MLKit
          : ImageFormatGroup.bgra8888, // iOS standard
    );

    await _cameraController!.initialize();
    _startImageStream();
    notifyListeners();
  }

  // 2. Start Stream & Detect Faces
  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isBusy) return;
      _isBusy = true;

      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage != null) {
          final faces = await _faceDetector.processImage(inputImage);
          _faces = faces;
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Error detecting faces: $e");
      } finally {
        _isBusy = false;
      }
    });
  }

  // 3. Switch Camera
  void switchCamera() {
    _cameraLensDirection = _cameraLensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    stopCamera();
    initializeCamera();
  }

  // 4. Cleanup
  void stopCamera() async {
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;
  }

  @override
  void dispose() {
    stopCamera();
    _faceDetector.close();
    super.dispose();
  }

  // 5. Convert CameraImage to InputImage (FIXED LOGIC)
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation rotation = InputImageRotation.rotation0deg;

    if (Platform.isIOS) {
      rotation =
          InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation0deg;
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation =
          InputImageRotationValue.fromRawValue(rotationCompensation) ??
          InputImageRotation.rotation0deg;
    }

    // Get correct format
    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    // Validate planes
    if (image.planes.isEmpty) return null;

    // Create InputImage
    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow, // FIXED: Correct parameter
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (var plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
}
