import '../models/child_profile.dart';
import '../models/game_progress.dart';
import '../models/achievement.dart';
import '../utils/constants.dart';
import 'local_storage.dart';

class ProgressTracker {
  static ProgressTracker? _instance;
  late LocalStorageService _storage;
  
  ProgressTracker._();
  
  static Future<ProgressTracker> getInstance() async {
    _instance ??= ProgressTracker._();
    _instance!._storage = await LocalStorageService.getInstance();
    return _instance!;
  }
  
  // Game Progress Tracking
  Future<void> recordGameProgress({
    required String gameType,
    required int level,
    required int score,
    required int maxScore,
    required int timeSpentSeconds,
    Map<String, dynamic>? gameData,
  }) async {
    // Calculate stars based on score percentage
    final scorePercentage = maxScore > 0 ? score / maxScore : 0.0;
    int stars = 0;
    if (scorePercentage >= 0.9) {
      stars = 3;
    } else if (scorePercentage >= 0.7) {
      stars = 2;
    } else if (scorePercentage >= 0.5) {
      stars = 1;
    }
    
    // Create game progress record
    // Get active child profile
    final activeProfile = await _storage.getChildProfile();
    final currentChildId = activeProfile?.id ?? 'default_child';

    final progress = GameProgress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      childId: currentChildId,
      gameType: gameType,
      level: level,
      score: score,
      maxScore: maxScore,
      stars: stars,
      timeSpentSeconds: timeSpentSeconds,
      durationMinutes: (timeSpentSeconds / 60).ceil(),
      isCompleted: true,
      gameData: gameData ?? {},
    );
    
    // Save progress
    await _storage.addGameProgress(progress);
    
    // Update child profile
    await _updateChildProfile(gameType, score, timeSpentSeconds);
    
    // Check and update achievements
    await _checkAchievements(gameType, progress);
  }
  
  Future<void> _updateChildProfile(String gameType, int score, int timeSpentSeconds) async {
    var profile = await _storage.getChildProfile();
    // إذا لم يوجد ملف طفل، أنشئ ملفاً افتراضياً لربط التقدم تلقائياً
    if (profile == null) {
      profile = ChildProfile(
        id: 'default_child',
        name: 'عالم صغير',
        age: 6,
        parentId: 'default_parent',
      );
    }
    
    final updatedProfile = profile.copyWith(
      totalPoints: profile.totalPoints + score,
      totalGamesPlayed: profile.totalGamesPlayed + 1,
      totalTimePlayedMinutes: profile.totalTimePlayedMinutes + (timeSpentSeconds / 60).ceil(),
      lastPlayedAt: DateTime.now(),
    );
    
    // Update game-specific stats
    updatedProfile.updateGameStats(gameType, score);
    
    await _storage.saveChildProfile(updatedProfile);
  }
  
  // Achievement System
  Future<void> _checkAchievements(String gameType, GameProgress progress) async {
    final achievements = await _storage.getAchievements();
    final profile = await _storage.getChildProfile();
    final allProgress = await _storage.getGameProgress();
    
    if (profile == null) return;
    
    bool hasUpdates = false;
    
    for (final achievement in achievements) {
      if (achievement.isUnlocked) continue;
      
      Achievement? updatedAchievement;
      
      switch (achievement.type) {
        case AchievementType.firstGame:
          if (achievement.category == gameType) {
            updatedAchievement = achievement.unlock();
          }
          break;
          
        case AchievementType.perfectScore:
          final perfectGames = allProgress.where((p) => p.isPerfectScore).length;
          if (perfectGames >= achievement.targetValue) {
            updatedAchievement = achievement.unlock();
          } else {
            updatedAchievement = achievement.updateProgress(perfectGames);
          }
          break;
          
        case AchievementType.streakWins:
          final currentStreak = _calculateWinStreak(allProgress);
          if (currentStreak >= achievement.targetValue) {
            updatedAchievement = achievement.unlock();
          } else {
            updatedAchievement = achievement.updateProgress(currentStreak);
          }
          break;
          
        case AchievementType.totalPoints:
          if (profile.totalPoints >= achievement.targetValue) {
            updatedAchievement = achievement.unlock();
          } else {
            updatedAchievement = achievement.updateProgress(profile.totalPoints);
          }
          break;
          
        case AchievementType.gameCompletion:
          final completedGameTypes = _getCompletedGameTypes(allProgress);
          if (completedGameTypes.length >= achievement.targetValue) {
            updatedAchievement = achievement.unlock();
          } else {
            updatedAchievement = achievement.updateProgress(completedGameTypes.length);
          }
          break;
          
        case AchievementType.dedication:
          final playDays = await _calculatePlayDays();
          if (playDays >= achievement.targetValue) {
            updatedAchievement = achievement.unlock();
          } else {
            updatedAchievement = achievement.updateProgress(playDays);
          }
          break;
          
        case AchievementType.timeRecord:
          // Implementation for time-based achievements
          break;
      }
      
      if (updatedAchievement != null && updatedAchievement != achievement) {
        await _storage.updateAchievement(updatedAchievement);
        hasUpdates = true;
        
        // If achievement was just unlocked, award bonus points
        if (updatedAchievement.isUnlocked && !achievement.isUnlocked) {
          await _awardAchievementBonus(updatedAchievement);
        }
      }
    }
  }
  
  int _calculateWinStreak(List<GameProgress> allProgress) {
    if (allProgress.isEmpty) return 0;
    
    // Sort by completion date (most recent first)
    final sortedProgress = List<GameProgress>.from(allProgress);
    sortedProgress.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    
    int streak = 0;
    for (final progress in sortedProgress) {
      if (progress.isGoodScore) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  Set<String> _getCompletedGameTypes(List<GameProgress> allProgress) {
    return allProgress.map((p) => p.gameType).toSet();
  }
  
  Future<int> _calculatePlayDays() async {
    final allProgress = await _storage.getGameProgress();
    if (allProgress.isEmpty) return 0;
    
    final playDates = allProgress
        .map((p) => DateTime(p.completedAt.year, p.completedAt.month, p.completedAt.day))
        .toSet();
    
    return playDates.length;
  }
  
  Future<void> _awardAchievementBonus(Achievement achievement) async {
    final profile = await _storage.getChildProfile();
    if (profile == null) return;
    
    final updatedProfile = profile.copyWith(
      totalPoints: profile.totalPoints + achievement.points,
    );
    
    await _storage.saveChildProfile(updatedProfile);
  }
  
  // Statistics and Analytics
  Future<Map<String, dynamic>> getDetailedStatistics() async {
    final profile = await _storage.getChildProfile();
    final allProgress = await _storage.getGameProgress();
    final achievements = await _storage.getUnlockedAchievements();
    
    if (profile == null) {
      return _getEmptyStatistics();
    }
    
    // Game type statistics
    final gameTypeStats = <String, Map<String, dynamic>>{};
    for (final gameType in [
      AppConstants.countingGame,
      AppConstants.additionGame,
      AppConstants.shapesGame,
      AppConstants.colorsGame,
      AppConstants.patternsGame,
    ]) {
      final gameProgress = allProgress.where((p) => p.gameType == gameType).toList();
      gameTypeStats[gameType] = _calculateGameTypeStats(gameProgress);
    }
    
    // Overall performance
    final totalGames = allProgress.length;
    final averageScore = totalGames > 0
        ? allProgress.map((p) => p.scorePercentage).reduce((a, b) => a + b) / totalGames
        : 0.0;
    final overallStars = allProgress.fold<int>(0, (sum, p) => sum + p.stars);
    
    final perfectGames = allProgress.where((p) => p.isPerfectScore).length;
    final goodGames = allProgress.where((p) => p.isGoodScore).length;
    
    // Time statistics
    final totalTimeMinutes = allProgress.fold<int>(
      0, (sum, p) => sum + (p.timeSpentSeconds / 60).ceil()
    );
    final averageTimePerGame = totalGames > 0 ? totalTimeMinutes / totalGames : 0.0;
    
    // Progress trends
    final recentProgress = _getRecentProgress(allProgress, 7); // Last 7 days
    final progressTrend = _calculateProgressTrend(recentProgress);
    
    return {
      'profile': profile.toJson(),
      'totalGames': totalGames,
      'totalPoints': profile.totalPoints,
      'totalTimeMinutes': totalTimeMinutes,
      'averageScore': averageScore,
      'totalStars': overallStars,
      'averageTimePerGame': averageTimePerGame,
      'perfectGames': perfectGames,
      'goodGames': goodGames,
      'unlockedAchievements': achievements.length,
      'currentLevel': profile.getCurrentLevel(),
      'levelTitle': profile.getLevelTitle(),
      'progressToNextLevel': profile.getProgressToNextLevel(),
      'gameTypeStats': gameTypeStats,
      'progressTrend': progressTrend,
      'winStreak': _calculateWinStreak(allProgress),
      'playDays': await _calculatePlayDays(),
      'favoriteGame': _getFavoriteGame(allProgress),
      'recentAchievements': achievements
          .where((a) => a.unlockedAt != null && 
                      DateTime.now().difference(a.unlockedAt!).inDays <= 7)
          .toList()
          .map((a) => a.toJson())
          .toList(),
    };
  }
  
  Map<String, dynamic> _calculateGameTypeStats(List<GameProgress> gameProgress) {
    if (gameProgress.isEmpty) {
      return {
        'totalPlayed': 0,
        'averageScore': 0.0,
        'bestScore': 0,
        'totalStars': 0,
        'averageTime': 0.0,
        'lastPlayed': null,
      };
    }
    
    final totalPlayed = gameProgress.length;
    final averageScore = gameProgress.map((p) => p.scorePercentage).reduce((a, b) => a + b) / totalPlayed;
    final bestScore = gameProgress.map((p) => p.score).reduce((a, b) => a > b ? a : b);
    final totalStars = gameProgress.fold<int>(0, (sum, p) => sum + p.stars);
    final averageTime = gameProgress.map((p) => p.timeSpentSeconds).reduce((a, b) => a + b) / totalPlayed;
    final lastPlayed = gameProgress.map((p) => p.completedAt).reduce((a, b) => a.isAfter(b) ? a : b);
    
    return {
      'totalPlayed': totalPlayed,
      'averageScore': averageScore,
      'bestScore': bestScore,
      'totalStars': totalStars,
      'averageTime': averageTime,
      'lastPlayed': lastPlayed.toIso8601String(),
    };
  }
  
  List<GameProgress> _getRecentProgress(List<GameProgress> allProgress, int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return allProgress.where((p) => p.completedAt.isAfter(cutoffDate)).toList();
  }
  
  String _calculateProgressTrend(List<GameProgress> recentProgress) {
    if (recentProgress.length < 2) return 'stable';
    
    final sortedProgress = List<GameProgress>.from(recentProgress);
    sortedProgress.sort((a, b) => a.completedAt.compareTo(b.completedAt));
    
    final firstHalf = sortedProgress.take(sortedProgress.length ~/ 2).toList();
    final secondHalf = sortedProgress.skip(sortedProgress.length ~/ 2).toList();
    
    final firstHalfAverage = firstHalf.isEmpty ? 0.0 : 
        firstHalf.map((p) => p.scorePercentage).reduce((a, b) => a + b) / firstHalf.length;
    final secondHalfAverage = secondHalf.isEmpty ? 0.0 :
        secondHalf.map((p) => p.scorePercentage).reduce((a, b) => a + b) / secondHalf.length;
    
    final difference = secondHalfAverage - firstHalfAverage;
    
    if (difference > 0.1) return 'improving';
    if (difference < -0.1) return 'declining';
    return 'stable';
  }
  
  String _getFavoriteGame(List<GameProgress> allProgress) {
    if (allProgress.isEmpty) return 'none';
    
    final gameTypeCounts = <String, int>{};
    for (final progress in allProgress) {
      gameTypeCounts[progress.gameType] = (gameTypeCounts[progress.gameType] ?? 0) + 1;
    }
    
    String favoriteGame = 'none';
    int maxCount = 0;
    gameTypeCounts.forEach((gameType, count) {
      if (count > maxCount) {
        maxCount = count;
        favoriteGame = gameType;
      }
    });
    
    return favoriteGame;
  }
  
  Map<String, dynamic> _getEmptyStatistics() {
    return {
      'totalGames': 0,
      'totalPoints': 0,
      'totalTimeMinutes': 0,
      'averageScore': 0.0,
      'averageTimePerGame': 0.0,
      'perfectGames': 0,
      'goodGames': 0,
      'unlockedAchievements': 0,
      'currentLevel': 1,
      'levelTitle': 'مبتدئ',
      'progressToNextLevel': 0.0,
      'gameTypeStats': {},
      'progressTrend': 'stable',
      'winStreak': 0,
      'playDays': 0,
      'favoriteGame': 'none',
      'recentAchievements': [],
    };
  }
  
  // Utility Methods
  Future<List<Achievement>> getNewlyUnlockedAchievements() async {
    final achievements = await _storage.getAchievements();
    final now = DateTime.now();
    
    return achievements.where((achievement) =>
        achievement.isUnlocked &&
        achievement.unlockedAt != null &&
        now.difference(achievement.unlockedAt!).inMinutes <= 5
    ).toList();
  }
  
  Future<bool> hasRecentProgress() async {
    final lastPlayDate = await _storage.getLastPlayDate();
    if (lastPlayDate == null) return false;
    
    final daysSinceLastPlay = DateTime.now().difference(lastPlayDate).inDays;
    return daysSinceLastPlay <= 1;
  }
  
  Future<Map<String, int>> getWeeklyProgress() async {
    final allProgress = await _storage.getGameProgress();
    final weeklyStats = <String, int>{};
    
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final dayProgress = allProgress.where((p) =>
          p.completedAt.year == date.year &&
          p.completedAt.month == date.month &&
          p.completedAt.day == date.day
      ).length;
      
      weeklyStats[dateKey] = dayProgress;
    }
    
    return weeklyStats;
  }
}

