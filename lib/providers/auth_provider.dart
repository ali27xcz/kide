import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/parent_profile.dart';
import '../models/child_profile.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuthService? _authService;
  FirestoreService? _firestoreService;
  
  User? _currentUser;
  ParentProfile? _currentParent;
  List<ChildProfile> _children = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFirebaseInitialized = false;
  
  // Getters
  User? get currentUser => _currentUser;
  ParentProfile? get currentParent => _currentParent;
  List<ChildProfile> get children => _children;
  bool get isLoading => _isLoading;
  String? get errorMessage {
    print('AuthProvider: Getting error message: $_errorMessage');
    print('AuthProvider: Error message is null: ${_errorMessage == null}');
    print('AuthProvider: Error message length: ${_errorMessage?.length ?? 0}');
    return _errorMessage;
  }
  bool get isFirebaseInitialized => _isFirebaseInitialized;
  
  bool get isLoggedIn => _currentUser != null;
  
  AuthProvider() {
    _initializeAuth();
  }
  

  
  String _cleanErrorMessage(Object e) {
    final raw = e.toString();
    const prefix = 'Exception: ';
    return raw.startsWith(prefix) ? raw.substring(prefix.length) : raw;
  }

  void _initializeAuth() {
    // Always try to initialize Firebase services - they will work if Firebase is ready
    _authService = FirebaseAuthService.instance;
    _firestoreService = FirestoreService.instance;
    _isFirebaseInitialized = true;
    
    _currentUser = _authService!.currentUser;
    if (_currentUser != null) {
      _loadParentProfile();
    }
    
    // Fix any SVG avatar paths in stored data
    _fixAvatarPaths();
    
    print('AuthProvider: Firebase services initialized');
  }
  
  Future<void> _fixAvatarPaths() async {
    try {
      final storage = await LocalStorageService.getInstance();
      await storage.fixAvatarPaths();
    } catch (e) {
      print('Error fixing avatar paths: $e');
    }
  }
  
  // Load parent profile and children
  Future<void> _loadParentProfile() async {
    if (_currentUser == null) return;
    
    try {
      _setLoading(true);
      _currentParent = await _authService!.getParentProfile(_currentUser!.uid);
      
      if (_currentParent != null) {
        await _loadChildren();
      }
      
      _setLoading(false);
    } catch (e) {
      // Non-fatal: don't surface to user during sign-in
      print('Warning loading parent profile: $e');
      _setLoading(false);
    }
  }
  
  // Load children for current parent
  Future<void> _loadChildren() async {
    if (_currentParent == null) return;
    
    try {
      _children = await _firestoreService!.getChildrenForParent(_currentParent!.id);
      notifyListeners();
    } catch (e) {
      print('Error loading children: $e');
    }
  }
  
  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    
    _setLoading(true);
    _clearError();
    try {
      await _authService!.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      _setLoading(false);
      return false;
    }
    _currentUser = _authService!.currentUser;
    try {
      await _loadParentProfile();
    } catch (e) {
      print('Warning post-signUp load profile: $e');
    }
    _setLoading(false);
    return true;
  }
  
  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    
    _setLoading(true);
    _clearError();
    print('Attempting to sign in with email: $email');
    try {
      await _authService!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in auth error: $e');
      // If Firebase already authenticated the user despite a non-fatal platform error, treat as success
      if (_authService!.currentUser != null) {
        _currentUser = _authService!.currentUser;
        _setLoading(false);
        print('Sign in considered successful (user present) despite non-fatal error');
        return true;
      }
      // Otherwise show a friendly unknown error message
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
    _currentUser = _authService!.currentUser;
    try {
      await _loadParentProfile();
    } catch (e) {
      print('Warning post-signIn load profile: $e');
    }
    _setLoading(false);
    print('Sign in successful');
    return true;
  }
  
  // Sign out
  Future<void> signOut() async {
    
    try {
      _setLoading(true);
      await _authService!.signOut();
      
      _currentUser = null;
      _currentParent = null;
      _children.clear();
      
      _setLoading(false);
    } catch (e) {
      _setError('فشل في تسجيل الخروج');
      _setLoading(false);
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    
    try {
      _setLoading(true);
      _clearError();
      
      await _authService!.resetPassword(email);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }
  
  // Add child
  Future<bool> addChild({
    required String name,
    required int age,
    String avatarPath = '',
  }) async {
    if (_currentParent == null) return false;
    
    try {
      _setLoading(true);
      _clearError();
      
      final childId = DateTime.now().millisecondsSinceEpoch.toString();
      final child = ChildProfile(
        id: childId,
        name: name,
        age: age,
        avatarPath: avatarPath,
        parentId: _currentParent!.id,
      );
      
      await _firestoreService!.createChildProfile(child);
      await _loadChildren();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Update child
  Future<bool> updateChild(ChildProfile child) async {
    
    try {
      _setLoading(true);
      _clearError();
      
      await _firestoreService!.updateChildProfile(child);
      await _loadChildren();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Delete child
  Future<bool> deleteChild(String childId) async {
    if (_currentParent == null) return false;
    
    try {
      _setLoading(true);
      _clearError();
      
      await _firestoreService!.deleteChildProfile(childId, _currentParent!.id);
      await _loadChildren();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Get child by ID
  ChildProfile? getChildById(String childId) {
    try {
      return _children.firstWhere((child) => child.id == childId);
    } catch (e) {
      return null;
    }
  }
  
  // Update parent profile
  Future<bool> updateParentProfile(ParentProfile profile) async {
    
    try {
      _setLoading(true);
      _clearError();
      
      await _authService!.updateParentProfile(profile);
      _currentParent = profile;
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Change password
  Future<bool> changePassword(String newPassword) async {
    
    try {
      _setLoading(true);
      _clearError();
      
      await _authService!.changePassword(newPassword);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Delete account
  Future<bool> deleteAccount() async {
    
    try {
      _setLoading(true);
      _clearError();
      
      await _authService!.deleteAccount();
      
      _currentUser = null;
      _currentParent = null;
      _children.clear();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    print('AuthProvider: Setting error: $error');
    print('AuthProvider: Error type: ${error.runtimeType}');
    print('AuthProvider: Error is null: ${error == null}');
    _errorMessage = error;
    print('AuthProvider: Error message set to: $_errorMessage');
    notifyListeners();
    print('AuthProvider: Notified listeners');
  }
  
  void _clearError() {
    print('AuthProvider: Clearing error');
    _errorMessage = null;
    notifyListeners();
  }
}
