import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../models/child_profile.dart';
import '../models/game_progress.dart';
import '../models/achievement.dart';
import '../utils/constants.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;
  static Map<String, dynamic>? _memoryStorage;
  
  LocalStorageService._();
  
  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService._();
    if (_prefs == null) {
      try {
        _prefs = await SharedPreferences.getInstance();
        print('SharedPreferences initialized successfully');
      } catch (e) {
        print('Error initializing SharedPreferences: $e');
        print('LocalStorageService will work in memory-only mode');
        // Initialize in-memory storage as fallback
        _memoryStorage ??= <String, dynamic>{};
      }
    }
    // Persist auth session between launches: Firebase Auth handles session, but keep a local flag if needed
    return _instance!;
  }

  bool get _isLoggedIn => FirebaseAuthService.instance.isLoggedIn;
  String? get _currentParentId => FirebaseAuthService.instance.currentUser?.uid;
  
  // Returns a random avatar asset path from assets/images/avatars/, or null if none exist
  Future<String?> pickRandomAvatarFromAssets() async {
    try {
      final manifestString = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = jsonDecode(manifestString) as Map<String, dynamic>;
      final candidates = manifestMap.keys
          .where((k) => k.startsWith('assets/images/avatars/') &&
              (k.endsWith('.png') || k.endsWith('.jpg') || k.endsWith('.jpeg')))
          .toList();
      if (candidates.isEmpty) return null;
      candidates.sort();
      final randomIndex = math.Random().nextInt(candidates.length);
      return candidates[randomIndex];
    } catch (e) {
      print('Error picking random avatar from assets: $e');
      return null;
    }
  }
  
  // Child Profile Methods
  Future<void> saveChildProfile(ChildProfile profile) async {
    // If logged in, persist to Firestore and keep local cache in sync
    if (_isLoggedIn && _currentParentId != null) {
      try {
        final firestore = FirestoreService.instance;
        final String parentId = _currentParentId!;
        // Ensure parentId is correct
        ChildProfile toSave = profile.parentId == parentId
            ? profile
            : profile.copyWith(parentId: parentId);
        // Ensure we have a valid id (avoid default placeholder)
        if (toSave.id.isEmpty || toSave.id == 'default_child') {
          toSave = toSave.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
        }
        // Upsert child
        try {
          await firestore.updateChildProfile(toSave);
        } catch (_) {
          await firestore.createChildProfile(toSave);
        }
        // Also cache locally
        final jsonString = jsonEncode(toSave.toJson());
        if (_prefs != null) {
          try {
            await _prefs!.setString(AppConstants.childProfileKey, jsonString);
          } catch (_) {}
        }
        _memoryStorage ??= <String, dynamic>{};
        _memoryStorage![AppConstants.childProfileKey] = jsonString;
        return;
      } catch (e) {
        print('Error saving profile to Firestore, falling back to local: $e');
      }
    }

    final jsonString = jsonEncode(profile.toJson());
    
    if (_prefs != null) {
      try {
        await _prefs!.setString(AppConstants.childProfileKey, jsonString);
        print('Child profile saved to SharedPreferences');
        return;
      } catch (e) {
        print('Error saving child profile to SharedPreferences: $e');
      }
    }
    
    // Fallback to memory storage
    if (_memoryStorage != null) {
      _memoryStorage![AppConstants.childProfileKey] = jsonString;
      print('Child profile saved to memory storage (temporary)');
    } else {
      print('No storage available, cannot save profile');
    }
  }
  
  Future<ChildProfile?> getChildProfile() async {
    // If logged in, prefer Firestore and cache locally (strict account binding)
    if (_isLoggedIn && _currentParentId != null) {
      try {
        final firestore = FirestoreService.instance;
        final children = await firestore.getChildrenForParent(_currentParentId!);
        if (children.isNotEmpty) {
          final active = children.first;
          // Cache locally for faster reads
          await saveChildProfile(active);
          return active;
        }
      } catch (e) {
        print('Error loading child profile from Firestore: $e');
      }
    }
    String? jsonString;
    
    // Try SharedPreferences first
    if (_prefs != null) {
      try {
        jsonString = _prefs!.getString(AppConstants.childProfileKey);
        if (jsonString != null) {
          print('Child profile loaded from SharedPreferences');
        }
      } catch (e) {
        print('Error loading child profile from SharedPreferences: $e');
      }
    }
    
    // Fallback to memory storage
    if (jsonString == null && _memoryStorage != null) {
      jsonString = _memoryStorage![AppConstants.childProfileKey];
      if (jsonString != null) {
        print('Child profile loaded from memory storage');
      }
    }
    
    if (jsonString == null) {
      print('No child profile found in any storage');
      return null;
    }
    
    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return ChildProfile.fromJson(jsonMap);
    } catch (e) {
      print('Error parsing child profile: $e');
      return null;
    }
  }
  
  Future<void> deleteChildProfile() async {
    // If logged in, try to delete from Firestore as well
    if (_isLoggedIn && _currentParentId != null) {
      try {
        final local = await getChildProfile();
        if (local != null) {
          await FirestoreService.instance.deleteChildProfile(local.id, _currentParentId!);
        }
      } catch (e) {
        print('Error deleting cloud child profile: $e');
      }
    }

    if (_prefs == null) {
      print('SharedPreferences not available, cannot delete profile');
      return;
    }
    
    try {
      await _prefs!.remove(AppConstants.childProfileKey);
    } catch (e) {
      print('Error deleting child profile: $e');
    }
  }
  
    // Fix avatar paths that might be SVG
  Future<void> fixAvatarPaths() async {
    final profile = await getChildProfile();
    if (profile != null) {
      // If empty, pick a random local asset avatar to ensure avatar always shows
      if (profile.avatarPath.isEmpty) {
        final picked = await pickRandomAvatarFromAssets();
        if (picked != null) {
          await saveChildProfile(profile.copyWith(avatarPath: picked));
        } else {
          // fallback to a known bundled asset
          await saveChildProfile(profile.copyWith(avatarPath: 'assets/images/avatars/child.png'));
        }
        return;
      }

      // If old SVG path, fallback to a random local asset
      if (profile.avatarPath.endsWith('.svg')) {
        print('Found SVG avatar path, fixing to procedural seed: ${profile.avatarPath}');
        final picked = await pickRandomAvatarFromAssets();
        if (picked != null) {
          await saveChildProfile(profile.copyWith(avatarPath: picked));
          print('Avatar path fixed to random asset');
        } else {
          await saveChildProfile(profile.copyWith(avatarPath: 'assets/images/avatars/child.png'));
          print('Avatar path fixed to default asset');
        }
        return;
      }

      // If non-asset (e.g. http dicebear or any non-local), switch to random asset
      if (!profile.avatarPath.startsWith('assets/images/avatars/')) {
        final picked = await pickRandomAvatarFromAssets();
        if (picked != null) {
          await saveChildProfile(profile.copyWith(avatarPath: picked));
          return;
        }
      }

      // If avatar points to removed PNG/JPG asset, switch to first valid asset or procedural seed
      if (profile.avatarPath.startsWith('assets/images/avatars/')) {
        try {
          final manifestString = await rootBundle.loadString('AssetManifest.json');
          final Map<String, dynamic> manifestMap = jsonDecode(manifestString) as Map<String, dynamic>;
          final validAvatars = manifestMap.keys
              .where((k) => k.startsWith('assets/images/avatars/') &&
                  (k.endsWith('.png') || k.endsWith('.jpg') || k.endsWith('.jpeg')))
              .toList()
            ..sort();

          final bool stillExists = validAvatars.contains(profile.avatarPath);
          if (!stillExists) {
            print('Avatar asset missing: ${profile.avatarPath}. Selecting a new one.');
            final picked = await pickRandomAvatarFromAssets();
            if (picked != null) {
              await saveChildProfile(profile.copyWith(avatarPath: picked));
            } else {
              await saveChildProfile(profile.copyWith(avatarPath: 'assets/images/avatars/child.png'));
            }
          }
        } catch (e) {
          print('Error checking AssetManifest for avatars: $e');
        }
      }
    }
  }
  
  // Game Progress Methods
  Future<void> saveGameProgress(List<GameProgress> progressList) async {
    final jsonList = progressList.map((progress) => progress.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    // Local cache only; cloud writes are handled in addGameProgress when logged in
    if (_prefs != null) {
      try {
        await _prefs!.setString(AppConstants.gameProgressKey, jsonString);
        return;
      } catch (e) {
        print('Error saving game progress to SharedPreferences: $e');
      }
    }
    // Fallback to memory storage
    _memoryStorage ??= <String, dynamic>{};
    _memoryStorage![AppConstants.gameProgressKey] = jsonString;
    print('Game progress saved to memory storage (temporary)');
  }
  
  Future<List<GameProgress>> getGameProgress() async {
    // If logged in, read from Firestore for the active child
    if (_isLoggedIn) {
      try {
        final profile = await getChildProfile();
        if (profile != null) {
          final list = await FirestoreService.instance.getGameProgressForChild(profile.id);
          // Optionally cache locally
          return list;
        }
      } catch (e) {
        print('Error loading game progress from Firestore: $e');
      }
    }

    String? jsonString;
    if (_prefs != null) {
      try {
        jsonString = _prefs!.getString(AppConstants.gameProgressKey);
      } catch (e) {
        print('Error loading game progress from SharedPreferences: $e');
      }
    }
    if (jsonString == null) {
      _memoryStorage ??= <String, dynamic>{};
      jsonString = _memoryStorage![AppConstants.gameProgressKey];
    }
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
    // If logged in, write to Firestore (also updates child aggregate stats)
    if (_isLoggedIn) {
      try {
        await FirestoreService.instance.saveGameProgress(progress);
      } catch (e) {
        print('Error saving game progress to Firestore: $e');
      }
    }
    // Always update local cache as well
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
    if (_prefs != null) {
      try {
        await _prefs!.setString(AppConstants.achievementsKey, jsonString);
        return;
      } catch (e) {
        print('Error saving achievements to SharedPreferences: $e');
      }
    }
    _memoryStorage ??= <String, dynamic>{};
    _memoryStorage![AppConstants.achievementsKey] = jsonString;
    print('Achievements saved to memory storage (temporary)');
  }
  
  Future<List<Achievement>> getAchievements() async {
    // If logged in, prefer local template merged with cloud unlocked items
    // For simplicity, return local default and rely on updateAchievement to persist unlocked states to cloud
    String? jsonString;
    if (_prefs != null) {
      try {
        jsonString = _prefs!.getString(AppConstants.achievementsKey);
      } catch (e) {
        print('Error loading achievements from SharedPreferences: $e');
      }
    }
    if (jsonString == null && _memoryStorage != null) {
      jsonString = _memoryStorage![AppConstants.achievementsKey];
    }
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
      // If unlocked and logged in, persist to Firestore
      if (_isLoggedIn && achievement.isUnlocked) {
        try {
          await FirestoreService.instance.saveAchievement(achievement);
        } catch (e) {
          print('Error syncing achievement to Firestore: $e');
        }
      }
    }
  }
  
  Future<List<Achievement>> getUnlockedAchievements() async {
    final achievements = await getAchievements();
    return achievements.where((achievement) => achievement.isUnlocked).toList();
  }
  
  // Game Settings Methods
  Future<void> saveGameSettings(Map<String, dynamic> settings) async {
    final jsonString = jsonEncode(settings);
    if (_prefs != null) {
      try {
        await _prefs!.setString(AppConstants.settingsKey, jsonString);
        return;
      } catch (e) {
        print('Error saving game settings to SharedPreferences: $e');
      }
    }
    _memoryStorage ??= <String, dynamic>{};
    _memoryStorage![AppConstants.settingsKey] = jsonString;
    print('Game settings saved to memory storage (temporary)');
  }
  
  Future<Map<String, dynamic>> getGameSettings() async {
    String? jsonString;
    if (_prefs != null) {
      try {
        jsonString = _prefs!.getString(AppConstants.settingsKey);
      } catch (e) {
        print('Error loading game settings from SharedPreferences: $e');
      }
    }
    if (jsonString == null && _memoryStorage != null) {
      jsonString = _memoryStorage![AppConstants.settingsKey];
    }
    if (jsonString == null) {
      // Default settings (audio enabled by default)
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
        'soundEnabled': false,
        'musicEnabled': false,
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
    if (_prefs != null) {
      try {
        await _prefs!.clear();
      } catch (e) {
        print('Error clearing SharedPreferences: $e');
      }
    }
    _memoryStorage?.clear();
  }

  // --------- CLOUD SYNC HELPERS ---------
  Future<void> syncFromCloud(String parentId) async {
    try {
      final firestore = FirestoreService.instance;
      final children = await firestore.getChildrenForParent(parentId);
      if (children.isEmpty) return;
      final child = children.first;
      await saveChildProfile(child);
      // Progress is loaded on demand from Firestore; no need to pre-cache
      // Achievements are persisted on unlock via updateAchievement
    } catch (e) {
      print('Error syncing from cloud: $e');
    }
  }

  Future<void> syncLocalToCloudOnLogin(String parentId) async {
    try {
      final firestore = FirestoreService.instance;
      final localProfile = await getChildProfile();
      if (localProfile != null) {
        // Upsert profile with correct parentId
        var profileForCloud = localProfile.parentId == parentId
            ? localProfile
            : localProfile.copyWith(parentId: parentId);
        if (profileForCloud.id.isEmpty || profileForCloud.id == 'default_child') {
          profileForCloud = profileForCloud.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
        }
        try {
          await firestore.updateChildProfile(profileForCloud);
        } catch (_) {
          await firestore.createChildProfile(profileForCloud);
        }
        // Push recent progress entries
        final progress = await getGameProgress();
        for (final p in progress) {
          if (p.childId == localProfile.id) {
            final cloudProgress = p.copyWith(childId: profileForCloud.id);
            try {
              await firestore.saveGameProgress(cloudProgress);
            } catch (_) {}
          }
        }
        // Push unlocked achievements if any
        final achievements = await getAchievements();
        for (final a in achievements) {
          if (a.isUnlocked) {
            try {
              await firestore.saveAchievement(a);
            } catch (_) {}
          }
        }
        // Cache the cloud-aligned profile locally
        await saveChildProfile(profileForCloud);
      }
    } catch (e) {
      print('Error syncing local data to cloud: $e');
    }
  }
  
  Future<bool> hasChildProfile() async {
    if (_prefs != null) {
      try {
        return _prefs!.containsKey(AppConstants.childProfileKey);
      } catch (_) {}
    }
    return _memoryStorage != null && _memoryStorage!.containsKey(AppConstants.childProfileKey);
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

  // Remember Me functionality
  Future<void> saveLoginCredentials(String email, String password) async {
    final credentials = {
      'email': email,
      'password': password,
      'savedAt': DateTime.now().toIso8601String(),
    };
    final jsonString = jsonEncode(credentials);
    
    if (_prefs != null) {
      try {
        await _prefs!.setString('saved_login_credentials', jsonString);
        print('Login credentials saved');
        return;
      } catch (e) {
        print('Error saving login credentials: $e');
      }
    }
    
    // Fallback to memory storage
    _memoryStorage ??= <String, dynamic>{};
    _memoryStorage!['saved_login_credentials'] = jsonString;
    print('Login credentials saved to memory storage (temporary)');
  }

  Future<Map<String, String>?> getSavedLoginCredentials() async {
    String? jsonString;
    
    if (_prefs != null) {
      try {
        jsonString = _prefs!.getString('saved_login_credentials');
      } catch (e) {
        print('Error loading saved credentials from SharedPreferences: $e');
      }
    }
    
    if (jsonString == null && _memoryStorage != null) {
      jsonString = _memoryStorage!['saved_login_credentials'];
    }
    
    if (jsonString == null) {
      return null;
    }
    
    try {
      final Map<String, dynamic> credentials = jsonDecode(jsonString);
      return {
        'email': credentials['email'] as String? ?? '',
        'password': credentials['password'] as String? ?? '',
      };
    } catch (e) {
      print('Error parsing saved credentials: $e');
      return null;
    }
  }

  Future<void> clearSavedLoginCredentials() async {
    if (_prefs != null) {
      try {
        await _prefs!.remove('saved_login_credentials');
        print('Saved login credentials cleared');
        return;
      } catch (e) {
        print('Error clearing saved credentials: $e');
      }
    }
    
    _memoryStorage?.remove('saved_login_credentials');
  }

  Future<bool> hasRememberMeEnabled() async {
    if (_prefs != null) {
      try {
        return _prefs!.getBool('remember_me_enabled') ?? false;
      } catch (e) {
        print('Error checking remember me status: $e');
      }
    }
    
    return _memoryStorage?['remember_me_enabled'] ?? false;
  }

  Future<void> setRememberMeEnabled(bool enabled) async {
    if (_prefs != null) {
      try {
        await _prefs!.setBool('remember_me_enabled', enabled);
        print('Remember me status set to: $enabled');
        return;
      } catch (e) {
        print('Error setting remember me status: $e');
      }
    }
    
    _memoryStorage ??= <String, dynamic>{};
    _memoryStorage!['remember_me_enabled'] = enabled;
  }
}

