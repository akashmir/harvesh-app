# Plant Disease Detection Model

This directory should contain the TensorFlow Lite model file for plant disease detection.

## Model File Required:
- `plant_disease_model.tflite` - Pre-trained model trained on PlantVillage dataset

## How to obtain the model:

1. **Download a pre-trained model:**
   - Visit [TensorFlow Hub](https://tfhub.dev/) and search for plant disease models
   - Look for models trained on PlantVillage dataset
   - Convert to TensorFlow Lite format if needed

2. **Train your own model:**
   - Use the PlantVillage dataset from [Kaggle](https://www.kaggle.com/datasets/abdallahalidev/plantvillage-dataset)
   - Train using TensorFlow/Keras
   - Convert to TensorFlow Lite format

3. **Alternative models:**
   - Use models from [PlantNet](https://plantnet.org/)
   - Or other plant disease detection models

## Model Requirements:
- Input shape: [1, 224, 224, 3] (batch_size, height, width, channels)
- Output shape: [1, 38] (38 disease classes)
- Format: TensorFlow Lite (.tflite)

## Note:
This is a placeholder file. Replace this README with the actual model file once obtained.
