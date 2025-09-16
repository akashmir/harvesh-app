import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  // Initialize authentication state
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Wait for Firebase to be ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if user is already authenticated
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _user = currentUser;
        await _loadUserModel();
      }
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _init() {
    // Set initial user state immediately
    _user = _authService.currentUser;
    print('🔍 AuthProvider initialized - User: ${_user?.uid ?? 'null'}');

    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) async {
      print('🔄 Auth state changed - User: ${user?.uid ?? 'null'}');
      _user = user;
      if (user != null) {
        await _loadUserModel();
      } else {
        _userModel = null;
      }
      notifyListeners();
    });

    // Load user model if user is already authenticated
    if (_user != null) {
      _loadUserModel();
    }
  }

  Future<void> _loadUserModel() async {
    if (_user == null) return;

    try {
      final userData = await _firestoreService.getUserProfile();
      if (userData != null) {
        _userModel = UserModel.fromMap(userData);
      }
    } catch (e) {
      _errorMessage = 'Failed to load user profile: $e';
    }
  }

  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result != null) {
        _user = result.user;
        await _loadUserModel();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
    return false;
  }

  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      if (result != null) {
        _user = result.user;
        await _loadUserModel();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
    return false;
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithGoogle();

      if (result != null) {
        _user = result.user;
        await _loadUserModel();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
    return false;
  }

  Future<bool> signInWithPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyPhoneNumberWithCode({
    required String verificationId,
    required String smsCode,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.verifyPhoneNumberWithCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      if (result != null) {
        _user = result.user;
        await _loadUserModel();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
    return false;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _user = null;
      _userModel = null;
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.deleteAccount();
      _user = null;
      _userModel = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (_user == null) return;

    _setLoading(true);
    _clearError();

    try {
      await _firestoreService.updateUserProfile(updates);
      await _loadUserModel();
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
  }

  Future<void> updateFarmDetails({
    required double farmSize,
    required String farmType,
    required Map<String, dynamic> location,
    List<String>? cropPreferences,
  }) async {
    if (_user == null) return;

    _setLoading(true);
    _clearError();

    try {
      await _firestoreService.updateFarmDetails(
        farmSize: farmSize,
        farmType: farmType,
        location: location,
        cropPreferences: cropPreferences,
      );
      await _loadUserModel();
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
