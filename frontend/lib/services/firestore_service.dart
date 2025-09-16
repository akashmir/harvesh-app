import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // User Profile Management
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUserId == null) return null;

    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUserId!).get();

      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('users').doc(currentUserId!).update(updates);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<void> updateFarmDetails({
    required double farmSize,
    required String farmType,
    required Map<String, dynamic> location,
    List<String>? cropPreferences,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      Map<String, dynamic> updates = {
        'farmSize': farmSize,
        'farmType': farmType,
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (cropPreferences != null) {
        updates['cropPreferences'] = cropPreferences;
      }

      await _firestore.collection('users').doc(currentUserId!).update(updates);
    } catch (e) {
      throw Exception('Failed to update farm details: $e');
    }
  }

  // Crop Recommendation Query Management
  Future<void> saveCropRecommendationQuery({
    required Map<String, dynamic> inputData,
    required List<Map<String, dynamic>> recommendations,
    required String queryType, // 'location' or 'manual'
    String? location,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('crop_queries')
          .add({
        'inputData': inputData,
        'recommendations': recommendations,
        'queryType': queryType,
        'location': location,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save crop recommendation query: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCropRecommendationHistory({
    int limit = 20,
  }) async {
    if (currentUserId == null) return [];

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('crop_queries')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to get crop recommendation history: $e');
    }
  }

  Future<void> deleteCropRecommendationQuery(String queryId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('crop_queries')
          .doc(queryId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete crop recommendation query: $e');
    }
  }

  // Plant Disease Detection History
  Future<void> savePlantDiseaseDetection({
    required String imagePath,
    required Map<String, dynamic> detectionResult,
    required String confidence,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('disease_detections')
          .add({
        'imagePath': imagePath,
        'detectionResult': detectionResult,
        'confidence': confidence,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save plant disease detection: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPlantDiseaseDetectionHistory({
    int limit = 20,
  }) async {
    if (currentUserId == null) return [];

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('disease_detections')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to get plant disease detection history: $e');
    }
  }

  // Weather Query History
  Future<void> saveWeatherQuery({
    required Map<String, dynamic> location,
    required Map<String, dynamic> weatherData,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('weather_queries')
          .add({
        'location': location,
        'weatherData': weatherData,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save weather query: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWeatherQueryHistory({
    int limit = 20,
  }) async {
    if (currentUserId == null) return [];

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('weather_queries')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to get weather query history: $e');
    }
  }

  // User Statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    if (currentUserId == null) return {};

    try {
      // Get counts for different query types
      Future<int> cropQueriesCount = _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('crop_queries')
          .get()
          .then((snapshot) => snapshot.docs.length);

      Future<int> diseaseDetectionsCount = _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('disease_detections')
          .get()
          .then((snapshot) => snapshot.docs.length);

      Future<int> weatherQueriesCount = _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('weather_queries')
          .get()
          .then((snapshot) => snapshot.docs.length);

      // Wait for all counts
      List<int> counts = await Future.wait([
        cropQueriesCount,
        diseaseDetectionsCount,
        weatherQueriesCount,
      ]);

      return {
        'cropQueriesCount': counts[0],
        'diseaseDetectionsCount': counts[1],
        'weatherQueriesCount': counts[2],
        'totalQueries': counts[0] + counts[1] + counts[2],
      };
    } catch (e) {
      throw Exception('Failed to get user statistics: $e');
    }
  }

  // Search queries
  Future<List<Map<String, dynamic>>> searchCropQueries(
      String searchTerm) async {
    if (currentUserId == null) return [];

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('crop_queries')
          .where('queryType', isEqualTo: searchTerm)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to search crop queries: $e');
    }
  }

  // Clear all user data (for account deletion)
  Future<void> clearAllUserData() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      // Delete all subcollections
      await Future.wait([
        _deleteCollection('crop_queries'),
        _deleteCollection('disease_detections'),
        _deleteCollection('weather_queries'),
      ]);

      // Delete user document
      await _firestore.collection('users').doc(currentUserId!).delete();
    } catch (e) {
      throw Exception('Failed to clear user data: $e');
    }
  }

  Future<void> _deleteCollection(String collectionName) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection(collectionName)
        .get();

    WriteBatch batch = _firestore.batch();
    for (DocumentSnapshot doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
