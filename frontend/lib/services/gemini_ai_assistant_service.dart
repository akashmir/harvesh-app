import 'dart:async';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/satellite_soil_service.dart';
import '../services/ultra_crop_service.dart';

/// Professional AI Assistant Service using Gemini Pro API
/// Provides ChatGPT/Gemini-like experience with voice interaction
class GeminiAiAssistantService {
  static final GeminiAiAssistantService _instance =
      GeminiAiAssistantService._internal();
  factory GeminiAiAssistantService() => _instance;
  GeminiAiAssistantService._internal();

  // Core voice components
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  // State management
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  bool _isTyping = false;

  // Gemini API configuration
  String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  String get _geminiApiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey';

  // Callbacks
  Function(String)? onTranscription;
  Function(String)? onResponse;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;
  Function(bool)? onSpeakingStateChanged;
  Function(bool)? onTypingStateChanged;

  // Context data
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _currentSoil;
  Map<String, dynamic>? _currentLocation;
  Map<String, dynamic>? _ultraCropData;
  String? _currentSeason;
  String? _currentTopography;
  String _detectedLanguage = 'en';

  // Agricultural data cache
  Map<String, dynamic> _agriculturalContext = {};
  DateTime? _lastDataUpdate;

  // Conversation history
  List<Map<String, dynamic>> _conversationHistory = [];
  int _maxHistoryLength = 20;

  // Professional system prompt with agricultural context
  String get _systemPrompt => '''
You are KisanAI, a professional AI agricultural assistant designed specifically for Indian farmers. You are knowledgeable, empathetic, and practical.

Your expertise includes:
- Crop cultivation and management
- Soil health and fertilization
- Pest and disease control
- Weather impact on farming
- Irrigation and water management
- Market prices and selling strategies
- Government schemes and subsidies
- Modern farming techniques
- Organic farming practices
- Farm equipment and machinery
- Livestock management
- Financial planning for farming

CURRENT AGRICULTURAL CONTEXT:
${_buildContextString()}

RESPONSE FORMATTING GUIDELINES:
1. Use beautiful formatting with emojis, bullet points, and clear sections
2. Structure responses with clear headings and visual separators
3. Use emojis to make responses more engaging and easy to scan
4. Format numbers, percentages, and data clearly
5. Use bullet points for lists and step-by-step instructions
6. Highlight important information with visual emphasis
7. Use line breaks and spacing for better readability
8. Include relevant agricultural symbols and icons

RESPONSE STRUCTURE:
- Start with a warm greeting and brief context
- Use clear section headers with emojis
- Present data in organized, scannable format
- Include actionable steps with numbered lists
- End with encouragement and follow-up suggestions

EXAMPLE FORMAT:
🌾 **CROP RECOMMENDATION**

Based on your current conditions, I recommend:

**🥇 Primary Choice: [Crop Name]**
• Confidence: XX%
• Expected Yield: X.X tons/acre
• Profit Potential: ₹XXX per acre

**📊 Why This Crop Works:**
• Soil pH: X.X (Perfect for this crop)
• Weather: Current conditions ideal
• Season: Optimal planting time

**📋 Action Plan:**
1. Prepare seedbeds
2. Apply fertilizers
3. Plant seeds
4. Monitor growth

**💰 Cost Breakdown:**
• Seeds: ₹XXX
• Fertilizers: ₹XXX
• Total Investment: ₹XXX

IMPORTANT: If any agricultural data (weather, soil, location) is not available, you MUST inform the user that you cannot provide accurate recommendations without real data. Do NOT make up or simulate data. Be honest about data limitations.

Remember: You're not just answering questions, you're helping farmers succeed and improve their livelihoods using real-time agricultural data.
''';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isProcessing => _isProcessing;
  bool get isTyping => _isTyping;
  List<Map<String, dynamic>> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// Initialize the AI assistant service
  Future<bool> initialize() async {
    try {
      print('🤖 KisanAI: Starting initialization...');
      print(
          '🔑 API Key check: ${_geminiApiKey.isNotEmpty ? "Found" : "Missing"}');

      if (_geminiApiKey.isEmpty) {
        print('❌ KisanAI: Gemini API key not found');
        _handleError(
            'Gemini API key not found. Please add GEMINI_API_KEY to your .env file');
        return false;
      }

      print('✅ KisanAI: API key found, initializing services...');

      // Initialize Speech-To-Text
      print('🎤 KisanAI: Initializing speech recognition...');
      final speechAvailable = await _speechToText.initialize(
        onError: (error) =>
            _handleError('Speech recognition error: ${error.errorMsg}'),
        onStatus: (status) => _handleSpeechStatus(status),
      );

      if (!speechAvailable) {
        print('❌ KisanAI: Speech recognition not available');
        _handleError('Speech recognition not available on this device');
        return false;
      }
      print('✅ KisanAI: Speech recognition initialized');

      // Initialize text-to-speech
      print('🔊 KisanAI: Initializing text-to-speech...');
      await _flutterTts.setLanguage(_detectedLanguage);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      print('✅ KisanAI: Text-to-speech initialized');

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        onSpeakingStateChanged?.call(true);
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        onSpeakingStateChanged?.call(false);
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        onSpeakingStateChanged?.call(false);
        _handleError('Text-to-speech error: $msg');
      });

      // Clear conversation history for fresh start
      _conversationHistory.clear();
      print('🔄 KisanAI: Conversation history cleared for fresh start');

      // Update context data
      await _updateContextData();

      _isInitialized = true;
      print('🎉 KisanAI: Initialization completed successfully!');
      return true;
    } catch (e) {
      print('❌ KisanAI: Initialization failed: $e');
      _handleError('Failed to initialize AI assistant: $e');
      return false;
    }
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (!_isInitialized || _isListening || _isSpeaking) return;

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            final transcription = result.recognizedWords.trim();
            if (transcription.isNotEmpty) {
              onTranscription?.call(transcription);
              _processUserInput(transcription);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: _detectedLanguage,
        onSoundLevelChange: (level) {
          // Optional: Handle sound level changes for visual feedback
        },
      );

      _isListening = true;
      onListeningStateChanged?.call(true);
    } catch (e) {
      _handleError('Failed to start listening: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      onListeningStateChanged?.call(false);
    } catch (e) {
      _handleError('Failed to stop listening: $e');
    }
  }

  /// Send text message
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    await _processUserInput(message.trim());
  }

  /// Process user input and generate response
  Future<void> _processUserInput(String userInput) async {
    if (_isProcessing) return;

    _isProcessing = true;
    _isTyping = true;
    onTypingStateChanged?.call(true);

    try {
      // Add user message to conversation history
      _conversationHistory.add({
        'role': 'user',
        'content': userInput,
        'timestamp': DateTime.now().toIso8601String(),
        'language': _detectedLanguage,
      });

      // Update context data
      await _updateContextData();

      // Generate AI response using Gemini Pro
      final response = await _generateGeminiResponse(userInput);

      // Add AI response to conversation history
      _conversationHistory.add({
        'role': 'assistant',
        'content': response,
        'timestamp': DateTime.now().toIso8601String(),
        'language': _detectedLanguage,
      });

      // Keep conversation history manageable
      if (_conversationHistory.length > _maxHistoryLength) {
        _conversationHistory.removeAt(0);
      }

      // Save conversation history
      await _saveConversationHistory();

      // Speak the response
      await _speakResponse(response);

      onResponse?.call(response);
    } catch (e) {
      _handleError('Failed to process user input: $e');
    } finally {
      _isProcessing = false;
      _isTyping = false;
      onTypingStateChanged?.call(false);
    }
  }

  /// Generate response using Gemini Pro API
  Future<String> _generateGeminiResponse(String userInput) async {
    try {
      // Check if we have sufficient data
      if (!_hasSufficientData()) {
        return '''❌ **Unable to Provide Recommendations**

I apologize, but I cannot provide accurate agricultural recommendations at this time because some essential data is not available:

${_currentLocation == null ? '• 📍 Location data not available\n' : ''}${_currentWeather == null ? '• 🌤️ Weather data not available\n' : ''}${_currentSoil == null ? '• 🌱 Soil data not available\n' : ''}${_ultraCropData == null ? '• 🚀 Crop recommendation data not available\n' : ''}

**What you can do:**
• Check your internet connection
• Ensure location services are enabled
• Try again in a few minutes
• Contact support if the issue persists

I need real-time agricultural data to provide accurate, location-specific recommendations. Using simulated data could lead to incorrect advice that might harm your crops.

Please try again when the data services are available. 🙏''';
      }

      // Build conversation history for context
      final conversationContext = _buildConversationContext();

      // Prepare the full prompt with enhanced agricultural context
      final fullPrompt = '''
${_systemPrompt}

$conversationContext

User: $userInput

KisanAI:''';

      // Make API request to Gemini Pro
      final response = await http.post(
        Uri.parse(_geminiApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
            'stopSequences': []
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          return content.toString().trim();
        }
      }

      throw Exception(
          'Failed to get response from Gemini API: ${response.statusCode}');
    } catch (e) {
      // Fallback to a simple response
      return _generateFallbackResponse(userInput);
    }
  }

  /// Generate fallback response when API fails
  String _generateFallbackResponse(String userInput) {
    final lowerInput = userInput.toLowerCase();

    if (lowerInput.contains('weather') ||
        lowerInput.contains('rain') ||
        lowerInput.contains('temperature')) {
      return 'I understand you\'re asking about weather. While I can\'t access real-time weather data right now, I can help you with general weather-related farming advice. What specific weather concern do you have?';
    } else if (lowerInput.contains('crop') ||
        lowerInput.contains('plant') ||
        lowerInput.contains('seed')) {
      return 'I\'d be happy to help with crop-related questions! Could you tell me more about what specific crop you\'re interested in or what problem you\'re facing?';
    } else if (lowerInput.contains('soil') ||
        lowerInput.contains('fertilizer') ||
        lowerInput.contains('nutrient')) {
      return 'Soil health is crucial for good crop yield. What specific soil-related question do you have? Are you dealing with soil testing, fertilization, or soil preparation?';
    } else if (lowerInput.contains('pest') ||
        lowerInput.contains('disease') ||
        lowerInput.contains('insect')) {
      return 'Pest and disease management is important for crop protection. Can you describe the symptoms you\'re seeing or the specific pest problem you\'re facing?';
    } else if (lowerInput.contains('price') ||
        lowerInput.contains('market') ||
        lowerInput.contains('sell')) {
      return 'Market prices and selling strategies are important for farmers. What crop are you looking to sell, and what market information do you need?';
    } else {
      return 'I\'m here to help with your farming questions! Could you please provide more details about what you\'d like to know? I can assist with crop management, soil health, pest control, weather advice, and market information.';
    }
  }

  /// Build conversation context from recent history
  String _buildConversationContext() {
    if (_conversationHistory.length <= 2) return '';

    final recentHistory = _conversationHistory.length > 6
        ? _conversationHistory.sublist(_conversationHistory.length - 6)
        : _conversationHistory;
    final buffer = StringBuffer();

    for (final message in recentHistory) {
      final role = message['role'] == 'user' ? 'User' : 'KisanAI';
      buffer.writeln('$role: ${message['content']}');
    }

    return buffer.toString();
  }

  /// Speak the response
  Future<void> _speakResponse(String response) async {
    if (response.isEmpty) return;

    try {
      await _flutterTts.speak(response);
    } catch (e) {
      _handleError('Failed to speak response: $e');
    }
  }

  /// Update context data with comprehensive agricultural information
  Future<void> _updateContextData() async {
    try {
      // Get current location
      final position = await LocationService.getLocationWithFallback();
      if (position != null) {
        _currentLocation = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'coordinates':
              '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}',
          'address':
              await _getLocationAddress(position.latitude, position.longitude),
        };

        // Fetch all agricultural data in parallel
        await Future.wait([
          _fetchWeatherData(position.latitude, position.longitude),
          _fetchSoilData(position.latitude, position.longitude),
          _fetchTopographyData(position.latitude, position.longitude),
          _fetchUltraCropData(position.latitude, position.longitude),
        ]);

        // Determine current season
        _currentSeason = _getCurrentSeason();

        // Build comprehensive agricultural context
        _buildAgriculturalContext();

        _lastDataUpdate = DateTime.now();
        print(
            '🌾 Agricultural context updated: ${_agriculturalContext.keys.join(', ')}');
      }
    } catch (e) {
      print('Error updating agricultural context: $e');
    }
  }

  /// Fetch weather data from your weather API
  Future<void> _fetchWeatherData(double latitude, double longitude) async {
    try {
      final weatherResponse = await WeatherService.getCurrentWeatherAuto();
      if (weatherResponse['success'] == true) {
        _currentWeather = weatherResponse['data'];
        print('🌤️ Weather data fetched: ${_currentWeather?['temperature']}°C');
      } else {
        print('🌤️ Weather data not available - no fallback');
        _currentWeather = null;
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      _currentWeather = null;
    }
  }

  /// Fetch soil data including pH, NPK, and soil type
  Future<void> _fetchSoilData(double latitude, double longitude) async {
    try {
      // Use your satellite soil service
      final soilService = SatelliteSoilService();
      final soilData = await soilService.getCurrentSoilData(
        latitude: latitude,
        longitude: longitude,
      );

      if (soilData['success'] == true && soilData['data'] != null) {
        final data = soilData['data'];
        _currentSoil = {
          'ph': data['ph'] ?? 7.0,
          'nitrogen': data['nitrogen'] ?? 0.0,
          'phosphorus': data['phosphorus'] ?? 0.0,
          'potassium': data['potassium'] ?? 0.0,
          'soil_type': data['soil_type'] ?? 'Loamy',
          'organic_matter': data['organic_matter'] ?? 2.0,
          'moisture': data['moisture'] ?? 50.0,
          'soil_health': data['soil_health'] ?? 'Good',
          'nutrient_balance': data['nutrient_balance'] ?? 'Balanced',
        };
        print(
            '🌱 Soil data fetched: pH ${_currentSoil?['ph']}, NPK ${_currentSoil?['nitrogen']}-${_currentSoil?['phosphorus']}-${_currentSoil?['potassium']}');
      } else {
        print('🌱 Soil data not available - no fallback');
        _currentSoil = null;
      }
    } catch (e) {
      print('Error fetching soil data: $e');
      _currentSoil = null;
    }
  }

  /// Fetch topography data
  Future<void> _fetchTopographyData(double latitude, double longitude) async {
    try {
      // For now, we don't have a real topography API, so we'll set it to null
      // In the future, you can integrate with a real topography service
      _currentTopography = null;
      print('🏔️ Topography data not available - no fallback');
    } catch (e) {
      print('Error fetching topography data: $e');
      _currentTopography = null;
    }
  }

  /// Fetch Ultra Crop Recommender data
  Future<void> _fetchUltraCropData(double latitude, double longitude) async {
    try {
      // Get Ultra Crop Recommender data
      final ultraCropResponse = await UltraCropService.getUltraRecommendation(
        latitude: latitude,
        longitude: longitude,
        location: 'Agricultural Region',
        farmSize: 1.0, // Default 1 acre for general recommendations
        irrigationType: 'Rainfed', // Default irrigation type
        language: _detectedLanguage,
      );

      if (ultraCropResponse['success'] == true &&
          ultraCropResponse['data'] != null) {
        final data = ultraCropResponse['data'];
        _ultraCropData = {
          'primary_crop':
              data['recommendation']?['primary_recommendation'] ?? 'Unknown',
          'confidence': data['recommendation']?['confidence'] ?? 0.0,
          'alternative_crops':
              data['recommendation']?['alternative_crops'] ?? [],
          'environmental_analysis':
              data['comprehensive_analysis']?['environmental_analysis'] ?? {},
          'economic_analysis':
              data['comprehensive_analysis']?['economic_analysis'] ?? {},
          'sustainability_metrics':
              data['comprehensive_analysis']?['sustainability_metrics'] ?? {},
          'risk_assessment':
              data['comprehensive_analysis']?['risk_assessment'] ?? {},
          'actionable_insights': data['actionable_insights'] ?? {},
        };
        print(
            '🚀 Ultra Crop data fetched: ${_ultraCropData?['primary_crop']} (${(_ultraCropData?['confidence'] ?? 0.0 * 100).toStringAsFixed(1)}% confidence)');
      } else {
        print('🚀 Ultra Crop data not available');
      }
    } catch (e) {
      print('Error fetching Ultra Crop data: $e');
    }
  }

  /// Get location address from coordinates
  Future<String> _getLocationAddress(double latitude, double longitude) async {
    try {
      // This would typically use a geocoding service
      // For now, return a simple description
      return 'Agricultural Region (${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)})';
    } catch (e) {
      return 'Unknown Location';
    }
  }

  /// Get current season based on month
  String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) {
      return 'Summer';
    } else if (month >= 6 && month <= 9) {
      return 'Monsoon';
    } else if (month >= 10 && month <= 11) {
      return 'Autumn';
    } else {
      return 'Winter';
    }
  }

  /// Build comprehensive agricultural context
  void _buildAgriculturalContext() {
    _agriculturalContext = {
      'location': _currentLocation,
      'weather': _currentWeather,
      'soil': _currentSoil,
      'ultra_crop': _ultraCropData,
      'season': _currentSeason,
      'topography': _currentTopography,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Build context string for AI prompt
  String _buildContextString() {
    final buffer = StringBuffer();

    // Location information
    if (_currentLocation != null) {
      buffer.writeln(
          '📍 **Location:** ${_currentLocation!['address'] ?? 'Unknown'}');
      buffer.writeln(
          '   📍 Coordinates: ${_currentLocation!['coordinates'] ?? 'N/A'}');
    }

    // Weather information
    if (_currentWeather != null) {
      buffer.writeln('🌤️ **Weather:**');
      buffer.writeln(
          '   🌡️ Temperature: ${_currentWeather!['temperature'] ?? 'N/A'}°C');
      buffer
          .writeln('   💧 Humidity: ${_currentWeather!['humidity'] ?? 'N/A'}%');
      buffer.writeln(
          '   ☁️ Condition: ${_currentWeather!['condition'] ?? 'N/A'}');
    }

    // Soil information
    if (_currentSoil != null) {
      buffer.writeln('🌱 **Soil Analysis:**');
      buffer.writeln(
          '   🧪 pH Level: ${_currentSoil!['ph'] ?? 'N/A'} (${_getPHStatus(_currentSoil!['ph'] ?? 7.0)})');
      buffer.writeln(
          '   ⚗️ NPK Ratio: ${_currentSoil!['nitrogen'] ?? 'N/A'}-${_currentSoil!['phosphorus'] ?? 'N/A'}-${_currentSoil!['potassium'] ?? 'N/A'}');
      buffer
          .writeln('   🏔️ Soil Type: ${_currentSoil!['soil_type'] ?? 'N/A'}');
      buffer.writeln(
          '   🌿 Organic Matter: ${_currentSoil!['organic_matter'] ?? 'N/A'}%');
      buffer.writeln('   💧 Moisture: ${_currentSoil!['moisture'] ?? 'N/A'}%');
      buffer.writeln(
          '   ❤️ Soil Health: ${_currentSoil!['soil_health'] ?? 'N/A'}');
      buffer.writeln(
          '   ⚖️ Nutrient Balance: ${_currentSoil!['nutrient_balance'] ?? 'N/A'}');
    }

    // Ultra Crop Recommender data
    if (_ultraCropData != null) {
      buffer.writeln('🚀 **AI Crop Recommendations:**');
      buffer.writeln(
          '   🥇 Primary Crop: ${_ultraCropData!['primary_crop'] ?? 'N/A'}');
      buffer.writeln(
          '   📊 Confidence: ${((_ultraCropData!['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%');
      if (_ultraCropData!['alternative_crops'] != null &&
          (_ultraCropData!['alternative_crops'] as List).isNotEmpty) {
        buffer.writeln(
            '   🥈 Alternatives: ${(_ultraCropData!['alternative_crops'] as List).join(', ')}');
      }

      // Environmental analysis
      final envAnalysis =
          _ultraCropData!['environmental_analysis'] as Map<String, dynamic>?;
      if (envAnalysis != null) {
        buffer.writeln(
            '   Soil Health Score: ${envAnalysis['soil_health'] ?? 'N/A'}/100');
        buffer.writeln(
            '   Climate Suitability: ${envAnalysis['climate_suitability'] ?? 'N/A'}/100');
      }

      // Economic analysis
      final econAnalysis =
          _ultraCropData!['economic_analysis'] as Map<String, dynamic>?;
      if (econAnalysis != null) {
        buffer.writeln(
            '   Yield Potential: ${econAnalysis['yield_potential'] ?? 'N/A'}');
        buffer.writeln(
            '   ROI Estimate: ${econAnalysis['roi_estimate'] ?? 'N/A'}');
      }

      // Risk assessment
      final riskAssessment =
          _ultraCropData!['risk_assessment'] as Map<String, dynamic>?;
      if (riskAssessment != null) {
        buffer.writeln(
            '   Disease Risk: ${riskAssessment['disease_risk'] ?? 'N/A'}');
        buffer.writeln(
            '   Climate Risk: ${riskAssessment['climate_risk'] ?? 'N/A'}');
        buffer.writeln(
            '   Market Risk: ${riskAssessment['market_risk'] ?? 'N/A'}');
      }
    }

    // Season and topography
    buffer.writeln('📅 **Current Season:** ${_currentSeason ?? 'Unknown'}');
    if (_currentTopography != null) {
      buffer.writeln('🏔️ **Topography:** $_currentTopography');
    } else {
      buffer.writeln('🏔️ **Topography:** Not available');
    }

    // Data freshness
    if (_lastDataUpdate != null) {
      final age = DateTime.now().difference(_lastDataUpdate!);
      buffer.writeln('🕒 Data Updated: ${age.inMinutes} minutes ago');
    }

    return buffer.toString();
  }

  /// Check if we have sufficient data for recommendations
  bool _hasSufficientData() {
    return _currentLocation != null &&
        _currentWeather != null &&
        _currentSoil != null &&
        _ultraCropData != null;
  }

  /// Get pH status description
  String _getPHStatus(double ph) {
    if (ph < 6.0) return 'Acidic';
    if (ph < 6.5) return 'Slightly Acidic';
    if (ph <= 7.5) return 'Neutral';
    if (ph <= 8.0) return 'Slightly Alkaline';
    return 'Alkaline';
  }

  /// Handle speech recognition status changes
  void _handleSpeechStatus(String status) {
    switch (status) {
      case 'listening':
        _isListening = true;
        onListeningStateChanged?.call(true);
        break;
      case 'notListening':
        _isListening = false;
        onListeningStateChanged?.call(false);
        break;
      case 'done':
        _isListening = false;
        onListeningStateChanged?.call(false);
        break;
    }
  }

  /// Handle errors
  void _handleError(String error) {
    onError?.call(error);
  }

  /// Save conversation history
  Future<void> _saveConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(_conversationHistory);
      await prefs.setString('gemini_conversation_history', historyJson);
    } catch (e) {
      // Failed to save, continue
    }
  }

  /// Load conversation history
  Future<void> _loadConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('gemini_conversation_history');
      if (historyJson != null) {
        final history = jsonDecode(historyJson) as List;
        _conversationHistory = history.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Failed to load, start fresh
      _conversationHistory = [];
    }
  }

  /// Load conversation history when history button is clicked
  Future<void> loadHistoryForDisplay() async {
    await _loadConversationHistory();
    print('📚 KisanAI: History loaded for display');
  }

  /// Clear conversation history
  Future<void> clearHistory() async {
    _conversationHistory.clear();
    await _saveConversationHistory();
  }

  /// Set language
  Future<void> setLanguage(String language) async {
    _detectedLanguage = language;
    await _flutterTts.setLanguage(language);
  }

  /// Dispose resources
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
  }
}
