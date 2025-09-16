// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/plant_disease_detector.dart';

class PestDetectionScreen extends StatefulWidget {
  const PestDetectionScreen({super.key});

  @override
  _PestDetectionScreenState createState() => _PestDetectionScreenState();
}

class _PestDetectionScreenState extends State<PestDetectionScreen> {
  File? _pickedImage;
  String _result = "No results yet!";
  bool _isImageLoaded = false;
  bool _isProcessing = false;
  PlantDiseaseResult? _diseaseResult;

  // Initialize Plant Disease Detector
  late PlantDiseaseDetector _diseaseDetector;

  @override
  void initState() {
    super.initState();
    _diseaseDetector = PlantDiseaseDetector();
    _initializeDetector();
  }

  Future<void> _initializeDetector() async {
    setState(() {
      _result = "Initializing plant disease detector...";
    });

    final success = await _diseaseDetector.initialize();
    if (success) {
      setState(() {
        _result = "Plant disease detector ready! Select an image to analyze.";
      });
    } else {
      setState(() {
        _result =
            "Failed to initialize plant disease detector. Please check if the model file is available.";
      });
    }
  }

  Future<void> _getImageFromGallery() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
          _isImageLoaded = true;
          _result = "Image loaded. Click 'Label' to start!";
        });
      } else {
        setState(() {
          _result = "No image selected.";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Error selecting image: $e";
      });
    }
  }

  Future<void> _getImageFromCamera() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
          _isImageLoaded = true;
          _result = "Image loaded. Click 'Label' to start!";
        });
      } else {
        setState(() {
          _result = "No image captured.";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Error capturing image: $e";
      });
    }
  }

  Future<void> _getImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/temp_image.jpg');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _pickedImage = file;
          _isImageLoaded = true;
          _result = "Image loaded from URL. Click 'Label' to start!";
        });
      } else {
        setState(() {
          _result = "Failed to fetch image from URL.";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Error loading image from URL: $e";
      });
    }
  }

  Future<void> _detectDisease() async {
    if (_pickedImage == null) {
      setState(() {
        _result = "Please select or load an image first!";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _result = "Analyzing plant for diseases...";
    });

    try {
      final result = await _diseaseDetector.detectDisease(_pickedImage!);

      if (result != null) {
        setState(() {
          _diseaseResult = result;
          _result = result.detailedResult;
        });
      } else {
        setState(() {
          _result = "Failed to analyze the image. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Error analyzing image: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _diseaseDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urlController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Disease Detection"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _getImageFromGallery,
                  icon: const Icon(Icons.photo),
                  label: const Text("Gallery"),
                ),
                ElevatedButton.icon(
                  onPressed: _getImageFromCamera,
                  icon: const Icon(Icons.camera),
                  label: const Text("Camera"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: "Enter Image URL",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.upload),
                  onPressed: () {
                    if (urlController.text.isNotEmpty) {
                      _getImageFromUrl(urlController.text);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isImageLoaded
                ? Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Image.file(
                      _pickedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Text("No image selected."),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _detectDisease,
              icon: const Icon(Icons.search),
              label: const Text("Detect Disease"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: _buildResultWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultWidget() {
    if (_diseaseResult != null) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _diseaseResult!.isHealthy
                        ? Icons.check_circle
                        : Icons.warning,
                    color: _diseaseResult!.isHealthy
                        ? Colors.green
                        : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _diseaseResult!.isHealthy
                          ? 'Plant is Healthy'
                          : 'Disease Detected',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _diseaseResult!.isHealthy
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Disease: ${_diseaseResult!.diseaseName}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Confidence: ${_diseaseResult!.confidence.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Top Predictions:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(_diseaseResult!.allPredictions.map((prediction) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          prediction['isHealthy']
                              ? Icons.check_circle
                              : Icons.warning,
                          color: prediction['isHealthy']
                              ? Colors.green
                              : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${prediction['disease']} (${prediction['confidence'].toStringAsFixed(1)}%)',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ))),
            ],
          ),
        ),
      );
    } else {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _result,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}
