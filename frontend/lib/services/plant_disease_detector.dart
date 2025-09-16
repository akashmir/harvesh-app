import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class PlantDiseaseDetector {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  // Plant disease classes based on PlantVillage dataset
  static const List<String> _diseaseLabels = [
    'Apple___Apple_scab',
    'Apple___Black_rot',
    'Apple___Cedar_apple_rust',
    'Apple___healthy',
    'Blueberry___healthy',
    'Cherry_(including_sour)___Powdery_mildew',
    'Cherry_(including_sour)___healthy',
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot',
    'Corn_(maize)___Common_rust',
    'Corn_(maize)___Northern_Leaf_Blight',
    'Corn_(maize)___healthy',
    'Grape___Black_rot',
    'Grape___Esca_(Black_Measles)',
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)',
    'Grape___healthy',
    'Orange___Haunglongbing_(Citrus_greening)',
    'Peach___Bacterial_spot',
    'Peach___healthy',
    'Pepper,_bell___Bacterial_spot',
    'Pepper,_bell___healthy',
    'Potato___Early_blight',
    'Potato___Late_blight',
    'Potato___healthy',
    'Raspberry___healthy',
    'Soybean___healthy',
    'Squash___Powdery_mildew',
    'Strawberry___Leaf_scorch',
    'Strawberry___healthy',
    'Tomato___Bacterial_spot',
    'Tomato___Early_blight',
    'Tomato___Late_blight',
    'Tomato___Leaf_Mold',
    'Tomato___Septoria_leaf_spot',
    'Tomato___Spider_mites Two-spotted_spider_mite',
    'Tomato___Target_Spot',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus',
    'Tomato___Tomato_mosaic_virus',
    'Tomato___healthy'
  ];

  Future<bool> initialize() async {
    try {
      print('Initializing plant disease detector...');
      print('Loading model from: assets/models/plant_disease_model.tflite');

      // Load the model from assets
      _interpreter = await Interpreter.fromAsset(
          'assets/models/plant_disease_model.tflite');

      print('Model loaded successfully');

      // Initialize labels
      _labels = List.from(_diseaseLabels);
      print('Labels initialized: ${_labels.length} classes');

      _isInitialized = true;
      print('Plant disease detector initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing plant disease detector: $e');
      print('Error type: ${e.runtimeType}');
      if (e is Exception) {
        print('Exception details: ${e.toString()}');
      }
      return false;
    }
  }

  Future<PlantDiseaseResult?> detectDisease(File imageFile) async {
    if (!_isInitialized || _interpreter == null) {
      await initialize();
      if (!_isInitialized) {
        return null;
      }
    }

    try {
      // Load and preprocess image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        return null;
      }

      // Resize image to 224x224 (standard input size for most plant disease models)
      final resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convert to float32 array and normalize
      final input = _preprocessImage(resizedImage);

      // Run inference
      final output =
          List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(input, output);

      // Get the highest confidence prediction
      final predictions = output[0] as List<double>;
      final maxIndex =
          predictions.indexOf(predictions.reduce((a, b) => a > b ? a : b));
      final confidence = predictions[maxIndex];

      // Convert confidence to percentage
      final confidencePercentage = (confidence * 100).clamp(0.0, 100.0);

      // Get disease name and clean it up
      String diseaseName = _labels[maxIndex];
      diseaseName = diseaseName
          .replaceAll('_', ' ')
          .replaceAll('(including sour)', '')
          .trim();

      // Determine if it's healthy or diseased
      final isHealthy = diseaseName.toLowerCase().contains('healthy');

      return PlantDiseaseResult(
        diseaseName: diseaseName,
        confidence: confidencePercentage,
        isHealthy: isHealthy,
        allPredictions: _getTopPredictions(predictions, 5),
      );
    } catch (e) {
      print('Error detecting plant disease: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> _getTopPredictions(
      List<double> predictions, int topK) {
    final indexedPredictions = predictions.asMap().entries.toList();
    indexedPredictions.sort((a, b) => b.value.compareTo(a.value));

    return indexedPredictions.take(topK).map((entry) {
      final index = entry.key;
      final confidence = (entry.value * 100).clamp(0.0, 100.0);
      String diseaseName = _labels[index];
      diseaseName = diseaseName
          .replaceAll('_', ' ')
          .replaceAll('(including sour)', '')
          .trim();

      return {
        'disease': diseaseName,
        'confidence': confidence,
        'isHealthy': diseaseName.toLowerCase().contains('healthy'),
      };
    }).toList();
  }

  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final input = List.generate(
        1,
        (_) => List.generate(224,
            (_) => List.generate(224, (_) => List.generate(3, (_) => 0.0))));

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = image.getPixel(x, y);
        input[0][y][x][0] = (pixel.r / 255.0); // Red channel
        input[0][y][x][1] = (pixel.g / 255.0); // Green channel
        input[0][y][x][2] = (pixel.b / 255.0); // Blue channel
      }
    }

    return input;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

class PlantDiseaseResult {
  final String diseaseName;
  final double confidence;
  final bool isHealthy;
  final List<Map<String, dynamic>> allPredictions;

  PlantDiseaseResult({
    required this.diseaseName,
    required this.confidence,
    required this.isHealthy,
    required this.allPredictions,
  });

  String get formattedResult {
    if (isHealthy) {
      return '✅ Plant appears to be HEALTHY\nConfidence: ${confidence.toStringAsFixed(1)}%';
    } else {
      return '⚠️ Disease detected: $diseaseName\nConfidence: ${confidence.toStringAsFixed(1)}%';
    }
  }

  String get detailedResult {
    final buffer = StringBuffer();
    buffer.writeln(formattedResult);
    buffer.writeln('\nTop predictions:');

    for (int i = 0; i < allPredictions.length; i++) {
      final pred = allPredictions[i];
      final emoji = pred['isHealthy'] ? '✅' : '⚠️';
      buffer.writeln(
          '${i + 1}. $emoji ${pred['disease']} (${pred['confidence'].toStringAsFixed(1)}%)');
    }

    return buffer.toString();
  }
}
