# Face App

A new Flutter project.

## Getting Started

Face App is a Flutter-based mobile application designed to detect faces in real-time using on-device Machine Learning. Users can seamlessly switch between live camera streaming and selecting static images from their gallery, with visual overlays highlighting detected faces.

## Features

### Dual Detection Modes:

- Live Stream: Real-time face detection overlay on the camera feed with high performance.

- Gallery Mode: Pick existing photos to detect and highlight faces.

### Smart Visuals:

- Dynamic bounding boxes that track faces smoothly.

- Automatic scaling and mirroring handling for front/back cameras.

- Face Counting: Real-time counter displaying the number of faces detected in the frame.

## Efficient Performance:

- Powered by Google ML Kit for fast, offline inference.

- Optimized state management using Provider to handle camera streams without lag.

- Clean UI: Intuitive interface to switch cameras, pick images, and view results instantly.

- Cross-Platform: Runs on both Android and iOS.

## Technical Stack

### Framework: Flutter

- ML Engine: Google ML Kit (Face Detection)

- State Management: Provider

- Camera: Camera Plugin (with stream processing)

- Image Handling: Image Picker & Custom Painters

## Prerequisites

- **Flutter SDK**: Version 3.6.0 or higher
- **Dart SDK**: '>=3.6.0 <4.0.0'
- **IDE**: Android Studio or VS Code with Flutter plugins installed
- **Physical Device**: An Android or iOS device for testing

### Installation

1. **Clone the Repository**:

```bash
   git clone https://github.com/SumitSinghBharangar/type_tracker
   cd type_tracker
```

2. **Install Dependencies**:

```bash
    flutter pub get
```

3. **Run App**:

```bash
    flutter run
```

### Built With 🛠️

- Flutter – The UI framework for cross-platform development.

### Contributing 🤝

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch (git checkout -b feature/YourFeature).
3. Commit your changes (git commit -m 'Add YourFeature').
4. Push to the branch (git push origin feature/YourFeature).
5. Open a Pull Request.

#### ⭐ If you like this project, star it on GitHub!

Repository: [https://github.com/SumitSinghBharangar/face_detection](https://github.com/SumitSinghBharangar/face_detection)
