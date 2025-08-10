import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('ar');
  bool _isLoading = false;
  bool _isInitialized = false;
  
  // Fallback storage for when SharedPreferences is not available
  static Map<String, String>? _memoryStorage;
  
  // Getters
  Locale get currentLocale => _currentLocale;
  bool get isLoading => _isLoading;
  bool get isArabic => _currentLocale.languageCode == 'ar';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isInitialized => _isInitialized;
  
  LanguageProvider() {
    _initializeLanguage();
  }
  
  Future<void> _initializeLanguage() async {
    // اجعل التهيئة غير حاجزة للواجهة
    Future(() async {
      try {
        await _loadSavedLanguage();
      } finally {
        _isInitialized = true;
        notifyListeners();
      }
    });
  }
  
  // Load saved language from SharedPreferences or memory storage
  Future<void> _loadSavedLanguage() async {
    try {
      _setLoading(true);
      
      // Add a small delay to ensure Flutter engine is ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      String? savedLanguage;
      
      // Try SharedPreferences first
      try {
        final prefs = await SharedPreferences.getInstance();
        savedLanguage = prefs.getString(_languageKey);
        print('Language loaded from SharedPreferences: $savedLanguage');
      } catch (e) {
        print('SharedPreferences failed, trying memory storage: $e');
        // Fallback to memory storage
        _memoryStorage ??= <String, String>{};
        savedLanguage = _memoryStorage![_languageKey];
        print('Language loaded from memory storage: $savedLanguage');
      }
      
      if (savedLanguage != null) {
        if (savedLanguage == 'ar') {
          _currentLocale = const Locale('ar');
        } else if (savedLanguage == 'en') {
          _currentLocale = const Locale('en');
        }
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('Error loading saved language: $e');
      // Use default language if loading fails
      _currentLocale = const Locale('ar');
      _setLoading(false);
    }
  }
  
  // Switch language
  Future<void> switchLanguage() async {
    try {
      _setLoading(true);
      
      print('Switching language from: ${_currentLocale.languageCode}');
      
      String newLanguage;
      if (_currentLocale.languageCode == 'ar') {
        _currentLocale = const Locale('en');
        newLanguage = 'en';
        print('Switched to English');
      } else {
        _currentLocale = const Locale('ar');
        newLanguage = 'ar';
        print('Switched to Arabic');
      }
      
      // Try to save to SharedPreferences first
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, newLanguage);
        print('Language saved to SharedPreferences');
      } catch (e) {
        print('SharedPreferences failed, saving to memory storage: $e');
        // Fallback to memory storage
        _memoryStorage ??= <String, String>{};
        _memoryStorage![_languageKey] = newLanguage;
        print('Language saved to memory storage');
      }
      
      _setLoading(false);
      notifyListeners();
      print('Language switched to: ${_currentLocale.languageCode}, notifying listeners');
    } catch (e) {
      print('Error switching language: $e');
      _setLoading(false);
    }
  }
  
  // Set specific language
  Future<void> setLanguage(String languageCode) async {
    try {
      _setLoading(true);
      
      if (languageCode == 'ar') {
        _currentLocale = const Locale('ar');
      } else if (languageCode == 'en') {
        _currentLocale = const Locale('en');
      }
      
      // Try to save to SharedPreferences first
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, languageCode);
        print('Language $languageCode saved to SharedPreferences');
      } catch (e) {
        print('SharedPreferences failed, saving to memory storage: $e');
        // Fallback to memory storage
        _memoryStorage ??= <String, String>{};
        _memoryStorage![_languageKey] = languageCode;
        print('Language $languageCode saved to memory storage');
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('Error setting language: $e');
      _setLoading(false);
    }
  }
  
  // Get language name
  String getLanguageName() {
    return isArabic ? 'العربية' : 'English';
  }
  
  // Get language code
  String getLanguageCode() {
    return _currentLocale.languageCode;
  }
  
  // Get flag emoji
  String getLanguageFlag() {
    return isArabic ? '🇸🇦' : '🇺🇸';
  }
  
  // Helper method
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
