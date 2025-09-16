import 'package:firebase_core/firebase_core.dart';
import 'app_config.dart';

class FirebaseConfig {
  static FirebaseOptions get currentPlatform {
    if (AppConfig.isFirebaseConfigValid) {
      return _getFirebaseOptions();
    } else {
      throw Exception(
          'Firebase configuration is not valid. Please check your environment variables.\n'
          'Required: FIREBASE_API_KEY, FIREBASE_PROJECT_ID, FIREBASE_APP_ID, '
          'FIREBASE_MESSAGING_SENDER_ID, FIREBASE_STORAGE_BUCKET');
    }
  }

  static FirebaseOptions _getFirebaseOptions() {
    return FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.firebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      storageBucket: AppConfig.firebaseStorageBucket,
    );
  }

  // Platform-specific configurations
  static FirebaseOptions get android {
    return FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.firebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      storageBucket: AppConfig.firebaseStorageBucket,
    );
  }

  static FirebaseOptions get ios {
    return FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.firebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      storageBucket: AppConfig.firebaseStorageBucket,
      iosBundleId: 'com.example.crop',
    );
  }

  static FirebaseOptions get web {
    return FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.firebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      storageBucket: AppConfig.firebaseStorageBucket,
    );
  }

  static FirebaseOptions get macos {
    return FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.firebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      storageBucket: AppConfig.firebaseStorageBucket,
      iosBundleId: 'com.example.crop',
    );
  }

  static FirebaseOptions get windows {
    return FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.firebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      storageBucket: AppConfig.firebaseStorageBucket,
    );
  }

  static FirebaseOptions get linux {
    return FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.firebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      storageBucket: AppConfig.firebaseStorageBucket,
    );
  }
}
