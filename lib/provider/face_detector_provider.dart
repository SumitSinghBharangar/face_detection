import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui; // Needed for decoding image
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
// Ensure this is in pubspec

class FaceDetectorProvider extends ChangeNotifier {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  bool _isBusy = false;
  List<Face> _faces = [];
  CameraLensDirection _cameraLensDirection = CameraLensDirection.front;

  // --- Gallery/Static State ---
  File? _staticImageFile;
  ui.Image? _staticImage; // The decoded image for painting

  // --- Getters ---
  CameraController? get cameraController => _cameraController;
  List<Face> get faces => _faces;
  CameraLensDirection get cameraLensDirection => _cameraLensDirection;
  bool get isStaticMode => _staticImageFile != null;
  ui.Image? get staticImage => _staticImage;

  // =========================================================
  // LOGIC: GALLERY PICKER
  // =========================================================

  Future<void> pickImageFromGallery() async {
    // 1. Stop the live camera to save battery/resources
    if (_cameraController != null) {
      await _cameraController!.stopImageStream();
      // Optional: Dispose controller if you want to free camera completely
      // await _cameraController!.dispose();
      // _cameraController = null;
    }

    // 2. Pick the image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _staticImageFile = File(image.path);

      // 3. Decode image for the Painter (Your original logic)
      final data = await image.readAsBytes();
      _staticImage = await decodeImageFromList(data);

      // 4. Detect Faces in Static Image
      final inputImage = InputImage.fromFilePath(image.path);
      _faces = await _faceDetector.processImage(inputImage);

      notifyListeners();
    } else {
      // User canceled? Resume camera
      if (_cameraController != null &&
          !_cameraController!.value.isStreamingImages) {
        await _cameraController!.startImageStream(_processCameraImage);
      }
    }
  }

  void closeStaticImage() {
    _staticImageFile = null;
    _staticImage = null;
    _faces = [];
    // Restart live feed
    if (_cameraController != null) {
      // If we disposed it, we would need initializeCamera() here
      _cameraController!.startImageStream(_processCameraImage);
    } else {
      initializeCamera();
    }
    notifyListeners();
  }

  // =========================================================
  // LOGIC: LIVE CAMERA
  // =========================================================

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
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    _cameraController!.startImageStream(_processCameraImage);
    notifyListeners();
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        final faces = await _faceDetector.processImage(inputImage);
        // Only update faces if we are still in live mode
        if (!isStaticMode) {
          _faces = faces;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      _isBusy = false;
    }
  }

  void switchCamera() {
    if (isStaticMode) return; // Disable switching if looking at a photo
    _cameraLensDirection = _cameraLensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    stopCamera();
    initializeCamera();
  }

  Future<void> stopCamera() async {
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

  // --- UTILS (Same as before) ---
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
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation =
          InputImageRotationValue.fromRawValue(rotationCompensation) ??
          InputImageRotation.rotation0deg;
    }

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;
    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
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
