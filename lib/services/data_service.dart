import 'dart:convert';
import 'package:flutter/services.dart';

class DataService {
  static DataService? _instance;
  static DataService get instance => _instance ??= DataService._();

  DataService._();

  // Cache for loaded data
  Map<String, dynamic> _cache = {};

  /// Load JSON data from assets
  Future<List<dynamic>> loadJsonData(String assetPath) async {
    // Check cache first
    if (_cache.containsKey(assetPath)) {
      return _cache[assetPath] as List<dynamic>;
    }

    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> jsonData = json.decode(jsonString) as List<dynamic>;
      
      // Cache the data
      _cache[assetPath] = jsonData;
      
      return jsonData;
    } catch (e) {
      print('Error loading JSON data from $assetPath: $e');
      return [];
    }
  }

  /// Load alphabet data
  Future<List<Map<String, String>>> loadAlphabetData() async {
    final data = await loadJsonData('assets/data/alphabet.json');
    return data.map((item) => Map<String, String>.from(item)).toList();
  }

  /// Load colors data
  Future<List<Map<String, dynamic>>> loadColorsData() async {
    final data = await loadJsonData('assets/data/colors.json');
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Load shapes data
  Future<List<Map<String, dynamic>>> loadShapesData() async {
    final data = await loadJsonData('assets/data/shapes.json');
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Load animals data
  Future<List<Map<String, dynamic>>> loadAnimalsData() async {
    final data = await loadJsonData('assets/data/animals.json');
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Load numbers data
  Future<List<Map<String, dynamic>>> loadNumbersData() async {
    final data = await loadJsonData('assets/data/numbers.json');
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Load puzzles data
  Future<List<Map<String, dynamic>>> loadPuzzlesData() async {
    final data = await loadJsonData('assets/data/puzzles.json');
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Load Match Pairs data
  Future<List<Map<String, dynamic>>> loadMatchPairsData() async {
    final data = await loadJsonData('assets/data/match_pairs.json');
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Load Drag & Drop Categories data
  Future<List<Map<String, dynamic>>> loadCategoriesData() async {
    final data = await loadJsonData('assets/data/categories.json');
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Load Sound Recognition data
  Future<List<Map<String, dynamic>>> loadSoundRecognitionData() async {
    final data = await loadJsonData('assets/data/sound_recognition.json');
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }
}
