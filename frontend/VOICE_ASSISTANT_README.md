# 🎤 Voice Assistant Feature for Harvest App

## Overview
The Voice Assistant feature allows farmers to interact with the app using voice commands in their local language. It provides an AI-powered farming assistant that can answer questions about weather, crops, fertilizers, pest control, irrigation, soil health, and market prices.

## 🌟 Features

### ✅ **Core Functionality**
- **Speech-to-Text Recognition**: Convert spoken words to text
- **Text-to-Speech Synthesis**: Convert responses back to speech
- **Voice Activity Detection (VAD)**: Automatically detect when user stops speaking
- **Real-time Audio Monitoring**: Visual feedback during voice interaction
- **Multi-language Support**: 12 Indian languages supported

### 🌍 **Supported Languages**
- English (en)
- Hindi (hi)
- Telugu (te)
- Tamil (ta)
- Bengali (bn)
- Gujarati (gu)
- Marathi (mr)
- Kannada (kn)
- Malayalam (ml)
- Punjabi (pa)
- Odia (or)
- Assamese (as)

### 🤖 **AI Capabilities**
- **Agricultural Knowledge Base**: Comprehensive farming advice
- **OpenAI Whisper Integration**: High-quality speech recognition
- **Contextual Responses**: Smart responses based on farming queries
- **Conversation History**: Track previous interactions

## 📱 **User Interface**

### **Home Screen Integration**
- **Floating Voice Button**: Bottom-right corner of home screen
- **Animated UI**: Pulsing and wave animations during listening
- **Language Indicator**: Shows current selected language
- **Status Feedback**: Visual cues for listening/speaking states

### **Dedicated Voice Assistant Screen**
- **Full-screen Interface**: Comprehensive voice interaction
- **Conversation History**: View previous Q&A sessions
- **Language Selection**: Easy language switching
- **Clear Conversation**: Reset chat history

## 🔧 **Technical Implementation**

### **Dependencies Added**
```yaml
# Voice Assistant dependencies
speech_to_text: ^6.6.0
flutter_tts: ^3.8.5
record: ^5.0.4
audio_waveforms: ^1.0.5
flutter_sound: ^9.2.13
```

### **Key Files**
- `lib/services/voice_assistant_service.dart` - Core voice processing logic
- `lib/widgets/voice_assistant_widget.dart` - Floating voice button UI
- `lib/screens/voice_assistant_screen.dart` - Full-screen voice interface
- `lib/screens/enhanced_home_screen.dart` - Home screen integration

### **Permissions Required**
```xml
<!-- Android Permissions -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

## 🚀 **Usage Instructions**

### **For Farmers**

1. **Access Voice Assistant**:
   - Tap the floating microphone button on home screen
   - Or go to Menu → Voice Assistant

2. **Select Language**:
   - Long press the voice button to change language
   - Or use the language selector in the full screen

3. **Start Speaking**:
   - Tap the microphone button
   - Speak your farming question clearly
   - Wait for the AI response

4. **Example Queries**:
   - "What is the weather like today?"
   - "Tell me about crop advice for rice"
   - "How much fertilizer should I use?"
   - "What about pest control for my crops?"
   - "Irrigation recommendations please"
   - "Soil health advice"
   - "Market prices for wheat"

### **For Developers**

1. **Initialize Service**:
```dart
final voiceService = VoiceAssistantService();
await voiceService.initialize(openAiApiKey: 'your-api-key');
```

2. **Start Listening**:
```dart
await voiceService.startListening(language: 'hi');
```

3. **Handle Responses**:
```dart
voiceService.onTranscription = (text) {
  print('User said: $text');
};

voiceService.onResponse = (response) {
  print('Assistant: $response');
};
```

## 🎯 **Agricultural Knowledge Base**

The voice assistant can answer questions about:

### **Weather & Climate**
- Current weather conditions
- Weather forecasts
- Climate impact on crops

### **Crop Management**
- Crop selection advice
- Planting recommendations
- Growth stage guidance

### **Fertilization**
- NPK ratio recommendations
- Application timing
- Soil pH adjustments

### **Pest Control**
- Pest identification
- Prevention measures
- Treatment options

### **Irrigation**
- Watering schedules
- Irrigation methods
- Water conservation

### **Soil Health**
- Soil testing advice
- Nutrient management
- Soil improvement

### **Market Information**
- Current crop prices
- Market trends
- Selling recommendations

## 🔧 **Configuration**

### **OpenAI Whisper Integration**
To use OpenAI Whisper for enhanced speech recognition:

1. Get an OpenAI API key
2. Add it to the voice assistant initialization:
```dart
VoiceAssistantWidget(
  openAiApiKey: 'your-openai-api-key',
)
```

### **VAD Parameters**
Customize Voice Activity Detection:
```dart
voiceService.setVADParameters(
  noiseThreshold: 0.01,    // Audio level threshold
  silenceDuration: 2000,   // Silence duration in ms
);
```

## 🐛 **Troubleshooting**

### **Common Issues**

1. **Microphone Permission Denied**:
   - Go to app settings
   - Enable microphone permission
   - Restart the app

2. **No Speech Recognition**:
   - Check internet connection
   - Ensure device supports speech recognition
   - Try different language

3. **Poor Audio Quality**:
   - Speak clearly and slowly
   - Reduce background noise
   - Check microphone hardware

4. **Language Not Supported**:
   - Check supported languages list
   - Update app to latest version
   - Use English as fallback

## 📊 **Performance Optimization**

### **Memory Management**
- Automatic cleanup of audio buffers
- Efficient conversation history storage
- Optimized animation controllers

### **Battery Optimization**
- Smart VAD to reduce processing
- Efficient audio recording
- Background task management

## 🔮 **Future Enhancements**

### **Planned Features**
- [ ] Offline voice recognition
- [ ] Voice command shortcuts
- [ ] Multi-user voice profiles
- [ ] Voice-based navigation
- [ ] Integration with IoT sensors
- [ ] Voice-activated camera for plant disease detection

### **Advanced AI Features**
- [ ] Contextual conversation memory
- [ ] Personalized farming advice
- [ ] Voice-based data entry
- [ ] Multi-turn conversations
- [ ] Voice translation between languages

## 📝 **Development Notes**

### **Architecture**
- **Service Layer**: `VoiceAssistantService` handles all voice processing
- **UI Layer**: Widgets provide user interface components
- **Integration Layer**: Home screen and navigation integration

### **Error Handling**
- Graceful fallbacks for API failures
- User-friendly error messages
- Automatic retry mechanisms

### **Testing**
- Unit tests for service methods
- Widget tests for UI components
- Integration tests for voice flow

## 🤝 **Contributing**

To contribute to the voice assistant feature:

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add tests
5. Submit a pull request

## 📄 **License**

This voice assistant feature is part of the Harvest Enterprise App and follows the same license terms.

---

**Made with ❤️ for Indian Farmers** 🌾
