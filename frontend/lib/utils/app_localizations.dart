import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('hi', 'IN'),
  ];

  // English translations
  static const Map<String, String> _localizedValues = {
    'en': 'English',
    'hi': 'हिंदी',
    'ultra_crop_recommender': 'Ultra Crop Recommender',
    'ai_yield_advisory': 'AI Yield & Advisory',
    'location': 'Location',
    'farm_details': 'Farm Details',
    'recommendations': 'Recommendations',
    'farm_size': 'Farm Size (hectares)',
    'irrigation_type': 'Irrigation Type',
    'preferred_crops': 'Preferred Crops',
    'get_location': 'Get Current Location',
    'get_recommendation': 'Get Ultra Recommendation',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'offline_mode': 'Offline Mode',
    'download_offline_data': 'Download Offline Data',
    'soil_data': 'Soil Data',
    'ph_level': 'pH Level',
    'nitrogen': 'Nitrogen (kg/ha)',
    'phosphorus': 'Phosphorus (kg/ha)',
    'potassium': 'Potassium (kg/ha)',
    'organic_carbon': 'Organic Carbon (%)',
    'language': 'Language',
    'select_language': 'Select Language',
    'recommended_crop': 'Recommended Crop',
    'confidence': 'Confidence',
    'yield_potential': 'Yield Potential',
    'market_demand': 'Market Demand',
    'sustainability_score': 'Sustainability Score',
    'economic_analysis': 'Economic Analysis',
    'soil_health': 'Soil Health',
    'environmental_analysis': 'Environmental Analysis',
    'planting_season': 'Planting Season',
    'growth_duration': 'Growth Duration',
    'water_requirement': 'Water Requirement',
    'profit_margin': 'Profit Margin',
    'roi_estimate': 'ROI Estimate',
    'drip': 'Drip Irrigation',
    'sprinkler': 'Sprinkler',
    'canal': 'Canal',
    'tubewell': 'Tubewell',
    'rainfed': 'Rainfed',
    'rice': 'Rice',
    'wheat': 'Wheat',
    'maize': 'Maize',
    'cotton': 'Cotton',
    'sugarcane': 'Sugarcane',
    'soybean': 'Soybean',
    'grains': 'Grains',
    'vegetables': 'Vegetables',
    'cash_crops': 'Cash Crops',
    'pulses': 'Pulses',
    'oilseeds': 'Oilseeds',
  };

  // Hindi translations
  static const Map<String, String> _localizedValuesHi = {
    'en': 'English',
    'hi': 'हिंदी',
    'ultra_crop_recommender': 'अल्ट्रा फसल सिफारिशकर्ता',
    'ai_yield_advisory': 'एआई उपज और सलाह',
    'location': 'स्थान',
    'farm_details': 'खेत की जानकारी',
    'recommendations': 'सिफारिशें',
    'farm_size': 'खेत का आकार (हेक्टेयर)',
    'irrigation_type': 'सिंचाई का प्रकार',
    'preferred_crops': 'पसंदीदा फसलें',
    'get_location': 'वर्तमान स्थान प्राप्त करें',
    'get_recommendation': 'अल्ट्रा सिफारिश प्राप्त करें',
    'loading': 'लोड हो रहा है...',
    'error': 'त्रुटि',
    'success': 'सफलता',
    'offline_mode': 'ऑफलाइन मोड',
    'download_offline_data': 'ऑफलाइन डेटा डाउनलोड करें',
    'soil_data': 'मिट्टी का डेटा',
    'ph_level': 'पीएच स्तर',
    'nitrogen': 'नाइट्रोजन (किग्रा/हेक्टेयर)',
    'phosphorus': 'फास्फोरस (किग्रा/हेक्टेयर)',
    'potassium': 'पोटेशियम (किग्रा/हेक्टेयर)',
    'organic_carbon': 'जैविक कार्बन (%)',
    'language': 'भाषा',
    'select_language': 'भाषा चुनें',
    'recommended_crop': 'सुझाई गई फसल',
    'confidence': 'विश्वसनीयता',
    'yield_potential': 'उत्पादन क्षमता',
    'market_demand': 'बाजार मांग',
    'sustainability_score': 'स्थिरता स्कोर',
    'economic_analysis': 'आर्थिक विश्लेषण',
    'soil_health': 'मिट्टी का स्वास्थ्य',
    'environmental_analysis': 'पर्यावरणीय विश्लेषण',
    'planting_season': 'बुआई का मौसम',
    'growth_duration': 'वृद्धि अवधि',
    'water_requirement': 'पानी की आवश्यकता',
    'profit_margin': 'लाभ मार्जिन',
    'roi_estimate': 'आरओआई अनुमान',
    'drip': 'ड्रिप सिंचाई',
    'sprinkler': 'स्प्रिंकलर',
    'canal': 'नहर',
    'tubewell': 'ट्यूबवेल',
    'rainfed': 'वर्षा आधारित',
    'rice': 'धान',
    'wheat': 'गेहूं',
    'maize': 'मक्का',
    'cotton': 'कपास',
    'sugarcane': 'गन्ना',
    'soybean': 'सोयाबीन',
    'grains': 'अनाज',
    'vegetables': 'सब्जियां',
    'cash_crops': 'नकदी फसलें',
    'pulses': 'दालें',
    'oilseeds': 'तिलहन',
  };

  String translate(String key) {
    final isHindi = locale.languageCode == 'hi';
    final translations = isHindi ? _localizedValuesHi : _localizedValues;
    return translations[key] ?? key;
  }

  // Convenience getters
  String get ultraCropRecommender => translate('ultra_crop_recommender');
  String get location => translate('location');
  String get farmDetails => translate('farm_details');
  String get recommendations => translate('recommendations');
  String get farmSize => translate('farm_size');
  String get irrigationType => translate('irrigation_type');
  String get preferredCrops => translate('preferred_crops');
  String get getLocation => translate('get_location');
  String get getRecommendation => translate('get_recommendation');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get offlineMode => translate('offline_mode');
  String get downloadOfflineData => translate('download_offline_data');
  String get soilData => translate('soil_data');
  String get phLevel => translate('ph_level');
  String get nitrogen => translate('nitrogen');
  String get phosphorus => translate('phosphorus');
  String get potassium => translate('potassium');
  String get organicCarbon => translate('organic_carbon');
  String get language => translate('language');
  String get selectLanguage => translate('select_language');
  String get recommendedCrop => translate('recommended_crop');
  String get confidence => translate('confidence');
  String get yieldPotential => translate('yield_potential');
  String get marketDemand => translate('market_demand');
  String get sustainabilityScore => translate('sustainability_score');
  String get economicAnalysis => translate('economic_analysis');
  String get soilHealth => translate('soil_health');
  String get environmentalAnalysis => translate('environmental_analysis');
  String get plantingSeason => translate('planting_season');
  String get growthDuration => translate('growth_duration');
  String get waterRequirement => translate('water_requirement');
  String get profitMargin => translate('profit_margin');
  String get roiEstimate => translate('roi_estimate');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
