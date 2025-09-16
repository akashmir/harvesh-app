# Plant Disease Detection Feature

This feature implements YOLOv8-based plant disease detection using TensorFlow Lite for Flutter. It can identify 38 different plant disease classes based on the PlantVillage dataset.

## Features

- **Real-time Disease Detection**: Analyze plant images to detect diseases
- **38 Disease Classes**: Supports detection of various plant diseases including:
  - Apple diseases (scab, black rot, cedar apple rust)
  - Corn diseases (leaf spot, common rust, northern leaf blight)
  - Grape diseases (black rot, esca, leaf blight)
  - Tomato diseases (bacterial spot, early blight, late blight, leaf mold, etc.)
  - And many more...
- **Confidence Scoring**: Provides confidence percentages for predictions
- **Top Predictions**: Shows the top 5 most likely disease classifications
- **Healthy Plant Detection**: Identifies when plants are healthy
- **Visual Feedback**: Color-coded results with icons

## Setup Instructions

### 1. Dependencies
The following dependencies are already added to `pubspec.yaml`:
```yaml
dependencies:
  tflite_flutter: ^0.10.4
  image: ^4.1.7
  image_picker: ^1.1.2
```

### 2. Model File
You need to add a pre-trained TensorFlow Lite model file:

1. **Download a model**:
   - Visit [TensorFlow Hub](https://tfhub.dev/) and search for plant disease models
   - Look for models trained on PlantVillage dataset
   - Convert to TensorFlow Lite format if needed

2. **Place the model**:
   - Save the model as `plant_disease_model.tflite`
   - Place it in `Flutter/assets/models/` directory

3. **Model Requirements**:
   - Input shape: [1, 224, 224, 3] (batch_size, height, width, channels)
   - Output shape: [1, 38] (38 disease classes)
   - Format: TensorFlow Lite (.tflite)

### 3. Assets Configuration
The `pubspec.yaml` already includes the assets configuration:
```yaml
flutter:
  assets:
    - assets/models/
```

## Usage

### Basic Usage
```dart
import 'package:your_app/services/plant_disease_detector.dart';

// Initialize detector
final detector = PlantDiseaseDetector();
await detector.initialize();

// Detect disease in image
final result = await detector.detectDisease(imageFile);

if (result != null) {
  print('Disease: ${result.diseaseName}');
  print('Confidence: ${result.confidence}%');
  print('Is Healthy: ${result.isHealthy}');
}
```

### In the Pest Detection Screen
The pest detection screen automatically uses the plant disease detector:

1. **Select Image**: Choose from gallery, camera, or URL
2. **Detect Disease**: Tap "Detect Disease" button
3. **View Results**: See disease classification with confidence scores

## API Reference

### PlantDiseaseDetector Class

#### Methods
- `Future<bool> initialize()`: Initialize the detector and load the model
- `Future<PlantDiseaseResult?> detectDisease(File imageFile)`: Analyze an image for diseases
- `void dispose()`: Clean up resources

#### Properties
- `bool _isInitialized`: Whether the detector is ready to use

### PlantDiseaseResult Class

#### Properties
- `String diseaseName`: Name of the detected disease
- `double confidence`: Confidence percentage (0-100)
- `bool isHealthy`: Whether the plant is healthy
- `List<Map<String, dynamic>> allPredictions`: Top 5 predictions

#### Methods
- `String get formattedResult`: Formatted result string
- `String get detailedResult`: Detailed result with top predictions

## Supported Disease Classes

The detector supports 38 disease classes from the PlantVillage dataset:

1. Apple___Apple_scab
2. Apple___Black_rot
3. Apple___Cedar_apple_rust
4. Apple___healthy
5. Blueberry___healthy
6. Cherry_(including_sour)___Powdery_mildew
7. Cherry_(including_sour)___healthy
8. Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot
9. Corn_(maize)___Common_rust
10. Corn_(maize)___Northern_Leaf_Blight
11. Corn_(maize)___healthy
12. Grape___Black_rot
13. Grape___Esca_(Black_Measles)
14. Grape___Leaf_blight_(Isariopsis_Leaf_Spot)
15. Grape___healthy
16. Orange___Haunglongbing_(Citrus_greening)
17. Peach___Bacterial_spot
18. Peach___healthy
19. Pepper,_bell___Bacterial_spot
20. Pepper,_bell___healthy
21. Potato___Early_blight
22. Potato___Late_blight
23. Potato___healthy
24. Raspberry___healthy
25. Soybean___healthy
26. Squash___Powdery_mildew
27. Strawberry___Leaf_scorch
28. Strawberry___healthy
29. Tomato___Bacterial_spot
30. Tomato___Early_blight
31. Tomato___Late_blight
32. Tomato___Leaf_Mold
33. Tomato___Septoria_leaf_spot
34. Tomato___Spider_mites Two-spotted_spider_mite
35. Tomato___Target_Spot
36. Tomato___Tomato_Yellow_Leaf_Curl_Virus
37. Tomato___Tomato_mosaic_virus
38. Tomato___healthy

## Troubleshooting

### Common Issues

1. **"Failed to initialize plant disease detector"**
   - Ensure the model file exists at `assets/models/plant_disease_model.tflite`
   - Check that the model is in TensorFlow Lite format
   - Verify the model has the correct input/output shapes

2. **"Failed to analyze the image"**
   - Check that the image file is valid and accessible
   - Ensure the image is in a supported format (JPEG, PNG)
   - Verify the detector is properly initialized

3. **Low confidence scores**
   - Ensure the image shows a clear view of plant leaves
   - Try different lighting conditions
   - Make sure the plant species is supported by the model

### Performance Tips

- The model works best with clear, well-lit images of plant leaves
- Avoid images with multiple plants or complex backgrounds
- For best results, crop the image to focus on the plant leaves
- The detector processes images at 224x224 resolution

## Future Enhancements

- Support for more plant species and diseases
- Real-time camera detection
- Disease treatment recommendations
- Historical disease tracking
- Integration with weather data for disease prediction
