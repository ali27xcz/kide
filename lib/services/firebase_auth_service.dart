import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parent_profile.dart';

class FirebaseAuthService {
  static FirebaseAuthService? _instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  FirebaseAuthService._();
  
  static FirebaseAuthService get instance {
    _instance ??= FirebaseAuthService._();
    return _instance!;
  }
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create parent profile in Firestore
      final parentProfile = ParentProfile(
        id: credential.user!.uid,
        email: email,
        name: name,
        phone: phone,
      );
      
      await _firestore
          .collection('parents')
          .doc(credential.user!.uid)
          .set(parentProfile.toJson());
      
      return credential;
    } catch (e) {
      final errorMessage = _handleAuthError(e);
      throw Exception(errorMessage);
    }
  }
  
  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('FirebaseAuthService: Attempting sign in');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('FirebaseAuthService: Sign in successful');
      
      // Update last login time (non-fatal)
      try {
        await _firestore
            .collection('parents')
            .doc(credential.user!.uid)
            .set({
              'lastLoginAt': DateTime.now().toIso8601String(),
            }, SetOptions(merge: true));
      } catch (e) {
        // Do not fail sign-in if updating Firestore metadata fails
        print('Warning: failed to update lastLoginAt: $e');
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthService: Sign in FirebaseAuthException: $e');
      final errorMessage = _handleAuthError(e);
      print('FirebaseAuthService: Translated error: $errorMessage');
      throw Exception(errorMessage);
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      final errorMessage = _handleAuthError(e);
      throw Exception(errorMessage);
    }
  }
  
  // Get parent profile from Firestore
  Future<ParentProfile?> getParentProfile(String uid) async {
    try {
      final doc = await _firestore.collection('parents').doc(uid).get();
      if (doc.exists) {
        return ParentProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting parent profile: $e');
      return null;
    }
  }
  
  // Update parent profile
  Future<void> updateParentProfile(ParentProfile profile) async {
    try {
      await _firestore
          .collection('parents')
          .doc(profile.id)
          .update(profile.toJson());
    } catch (e) {
      print('Error updating parent profile: $e');
      throw Exception('فشل في تحديث الملف الشخصي');
    }
  }
  
  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Delete parent profile from Firestore
        await _firestore.collection('parents').doc(user.uid).delete();
        
        // Delete user account
        await user.delete();
      }
    } catch (e) {
      print('Error deleting account: $e');
      throw Exception('فشل في حذف الحساب');
    }
  }
  
  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      final errorMessage = _handleAuthError(e);
      throw Exception(errorMessage);
    }
  }
  
  // Handle Firebase Auth errors
  String _handleAuthError(dynamic error) {
    print('Firebase Auth Error: $error'); // إضافة طباعة للخطأ
    
    if (error is FirebaseAuthException) {
      print('Firebase Auth Error Code: ${error.code}');
      switch (error.code) {
        case 'user-not-found':
          return 'لم يتم العثور على المستخدم';
        case 'wrong-password':
          return 'كلمة المرور خاطئة';
        case 'invalid-credential':
          return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم بالفعل';
        case 'weak-password':
          return 'كلمة المرور ضعيفة جداً';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صحيح';
        case 'too-many-requests':
          return 'تم تجاوز عدد المحاولات المسموح، حاول لاحقاً';
        case 'network-request-failed':
          return 'فشل في الاتصال بالشبكة';
        case 'operation-not-allowed':
          return 'طريقة تسجيل الدخول غير مفعلة. يرجى تفعيل Email/Password في Firebase Console';
        default:
          return 'حدث خطأ غير متوقع: ${error.code}';
      }
    }
    return 'حدث خطأ غير متوقع: $error';
  }
}
