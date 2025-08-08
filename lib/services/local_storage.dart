import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_profile.dart';
import '../models/game_progress.dart';
import '../models/achievement.dart';
import '../utils/constants.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;
  
  LocalStorageService._();
  
  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }
  
  // Child Profile Methods
  Future<void> saveChildProfile(ChildProfile profile) async {
    final jsonString = jsonEncode(profile.toJson());
    await _prefs!.setString(AppConstants.childProfileKey, jsonString);
  }
  
  Future<ChildProfile?> getChildProfile() async {
    final jsonString = _prefs!.getString(AppConstants.childProfileKey);
    if (jsonString == null) return null;
    
    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return ChildProfile.fromJson(jsonMap);
    } catch (e) {
      print('Error loading child profile: $e');
      return null;
    }
  }
  
  Future<void> deleteChildProfile() async {
    await _prefs!.remove(AppConstants.childProfileKey);
  }
  
  // Game Progress Methods
  Future<void> saveGameProgress(List<GameProgress> progressList) async {
    final jsonList = progressList.map((progress) => progress.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs!.setString(AppConstants.gameProgressKey, jsonString);
  }
  
  Future<List<GameProgress>> getGameProgress() async {
    final jsonString = _prefs!.getString(AppConstants.gameProgressKey);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => GameProgress.fromJson(json)).toList();
    } catch (e) {
      print('Error loading game progress: $e');
      return [];
    }
  }
  
  Future<void> addGameProgress(GameProgress progress) async {
    final currentProgress = await getGameProgress();
    currentProgress.add(progress);
    await saveGameProgress(currentProgress);
  }
  
  Future<List<GameProgress>> getGameProgressByType(String gameType) async {
    final allProgress = await getGameProgress();
    return allProgress.where((progress) => progress.gameType == gameType).toList();
  }
  
  Future<GameProgress?> getBestGameProgress(String gameType, int level) async {
    final gameProgress = await getGameProgressByType(gameType);
    final levelProgress = gameProgress.where((p) => p.level == level).toList();
    
    if (levelProgress.isEmpty) return null;
    
    // Return the progress with the highest score
    levelProgress.sort((a, b) => b.score.compareTo(a.score));
    return levelProgress.first;
  }
  
  // Achievements Methods
  Future<void> saveAchievements(List<Achievement> achievements) async {
    final jsonList = achievements.map((achievement) => achievement.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs!.setString(AppConstants.achievementsKey, jsonString);
  }
  
  Future<List<Achievement>> getAchievements() async {
    final jsonString = _prefs!.getString(AppConstants.achievementsKey);
    if (jsonString == null) {
      // Return default achievements if none exist
      final defaultAchievements = AchievementManager.getDefaultAchievements();
      await saveAchievements(defaultAchievements);
      return defaultAchievements;
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      print('Error loading achievements: $e');
      final defaultAchievements = AchievementManager.getDefaultAchievements();
      await saveAchievements(defaultAchievements);
      return defaultAchievements;
    }
  }
  
  Future<void> updateAchievement(Achievement achievement) async {
    final achievements = await getAchievements();
    final index = achievements.indexWhere((a) => a.id == achievement.id);
    
    if (index != -1) {
      achievements[index] = achievement;
      await saveAchievements(achievements);
    }
  }
  
  Future<List<Achievement>> getUnlockedAchievements() async {
    final achievements = await getAchievements();
    return achievements.where((achievement) => achievement.isUnlocked).toList();
  }
  
  // Game Settings Methods
  Future<void> saveGameSettings(Map<String, dynamic> settings) async {
    final jsonString = jsonEncode(settings);
    await _prefs!.setString(AppConstants.settingsKey, jsonString);
  }
  
  Future<Map<String, dynamic>> getGameSettings() async {
    final jsonString = _prefs!.getString(AppConstants.settingsKey);
    if (jsonString == null) {
      // Return default settings
      final defaultSettings = {
        'soundEnabled': true,
        'musicEnabled': true,
        'difficulty': AppConstants.easyLevel,
        'language': 'ar',
        'parentControlsActive': false,
      };
      await saveGameSettings(defaultSettings);
      return defaultSettings;
    }
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading game settings: $e');
      final defaultSettings = {
        'soundEnabled': true,
        'musicEnabled': true,
        'difficulty': AppConstants.easyLevel,
        'language': 'ar',
        'parentControlsActive': false,
      };
      await saveGameSettings(defaultSettings);
      return defaultSettings;
    }
  }
  
  Future<void> updateGameSetting(String key, dynamic value) async {
    final settings = await getGameSettings();
    settings[key] = value;
    await saveGameSettings(settings);
  }
  
  // Statistics Methods
  Future<Map<String, dynamic>> getGameStatistics() async {
    final profile = await getChildProfile();
    final progress = await getGameProgress();
    final achievements = await getUnlockedAchievements();
    
    if (profile == null) {
      return {
        'totalGames': 0,
        'totalPoints': 0,
        'totalTimeMinutes': 0,
        'averageScore': 0.0,
        'unlockedAchievements': 0,
        'favoriteGame': 'none',
      };
    }
    
    // Calculate statistics
    final totalGames = progress.length;
    final totalPoints = profile.totalPoints;
    final totalTimeMinutes = profile.totalTimePlayedMinutes;
    final averageScore = totalGames > 0 
        ? progress.map((p) => p.scorePercentage).reduce((a, b) => a + b) / totalGames
        : 0.0;
    
    // Find favorite game (most played)
    final gameTypeCounts = <String, int>{};
    for (final p in progress) {
      gameTypeCounts[p.gameType] = (gameTypeCounts[p.gameType] ?? 0) + 1;
    }
    
    String favoriteGame = 'none';
    int maxCount = 0;
    gameTypeCounts.forEach((gameType, count) {
      if (count > maxCount) {
        maxCount = count;
        favoriteGame = gameType;
      }
    });
    
    return {
      'totalGames': totalGames,
      'totalPoints': totalPoints,
      'totalTimeMinutes': totalTimeMinutes,
      'averageScore': averageScore,
      'unlockedAchievements': achievements.length,
      'favoriteGame': favoriteGame,
      'gameTypeCounts': gameTypeCounts,
    };
  }
  
  // Utility Methods
  Future<void> clearAllData() async {
    await _prefs!.clear();
  }
  
  Future<bool> hasChildProfile() async {
    return _prefs!.containsKey(AppConstants.childProfileKey);
  }
  
  Future<DateTime?> getLastPlayDate() async {
    final profile = await getChildProfile();
    return profile?.lastPlayedAt;
  }
  
  Future<void> updateLastPlayDate() async {
    final profile = await getChildProfile();
    if (profile != null) {
      final updatedProfile = profile.copyWith(lastPlayedAt: DateTime.now());
      await saveChildProfile(updatedProfile);
    }
  }
}

