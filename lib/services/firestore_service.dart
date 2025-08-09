import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_profile.dart';
import '../models/game_progress.dart';
import '../models/achievement.dart';
import '../models/parent_profile.dart';

class FirestoreService {
  static FirestoreService? _instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  FirestoreService._();
  
  static FirestoreService get instance {
    _instance ??= FirestoreService._();
    return _instance!;
  }
  
  // ========== CHILDREN MANAGEMENT ==========
  
  // Create new child profile
  Future<void> createChildProfile(ChildProfile child) async {
    try {
      await _firestore
          .collection('children')
          .doc(child.id)
          .set(child.toJson());
      
      // Add child to parent's children list
      await _firestore
          .collection('parents')
          .doc(child.parentId)
          .update({
        'childrenIds': FieldValue.arrayUnion([child.id]),
      });
    } catch (e) {
      print('Error creating child profile: $e');
      throw Exception('فشل في إنشاء ملف الطفل');
    }
  }
  
  // Get child profile by ID
  Future<ChildProfile?> getChildProfile(String childId) async {
    try {
      final doc = await _firestore.collection('children').doc(childId).get();
      if (doc.exists) {
        return ChildProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting child profile: $e');
      return null;
    }
  }
  
  // Get all children for a parent
  Future<List<ChildProfile>> getChildrenForParent(String parentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('children')
          .where('parentId', isEqualTo: parentId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ChildProfile.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting children for parent: $e');
      return [];
    }
  }
  
  // Update child profile
  Future<void> updateChildProfile(ChildProfile child) async {
    try {
      await _firestore
          .collection('children')
          .doc(child.id)
          .update(child.toJson());
    } catch (e) {
      print('Error updating child profile: $e');
      throw Exception('فشل في تحديث ملف الطفل');
    }
  }
  
  // Delete child profile
  Future<void> deleteChildProfile(String childId, String parentId) async {
    try {
      // Delete child profile
      await _firestore.collection('children').doc(childId).delete();
      
      // Remove child from parent's children list
      await _firestore
          .collection('parents')
          .doc(parentId)
          .update({
        'childrenIds': FieldValue.arrayRemove([childId]),
      });
      
      // Delete all game progress for this child
      final progressQuery = await _firestore
          .collection('gameProgress')
          .where('childId', isEqualTo: childId)
          .get();
      
      for (var doc in progressQuery.docs) {
        await doc.reference.delete();
      }
      
      // Delete all achievements for this child
      final achievementsQuery = await _firestore
          .collection('achievements')
          .where('childId', isEqualTo: childId)
          .get();
      
      for (var doc in achievementsQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting child profile: $e');
      throw Exception('فشل في حذف ملف الطفل');
    }
  }
  
  // ========== GAME PROGRESS MANAGEMENT ==========
  
  // Save game progress
  Future<void> saveGameProgress(GameProgress progress) async {
    try {
      await _firestore
          .collection('gameProgress')
          .add(progress.toJson());
      
      // Update child's total stats
      final child = await getChildProfile(progress.childId);
      if (child != null) {
        final updatedChild = child.copyWith(
          totalPoints: child.totalPoints + progress.score,
          totalGamesPlayed: child.totalGamesPlayed + 1,
          totalTimePlayedMinutes: child.totalTimePlayedMinutes + progress.durationMinutes,
          lastPlayedAt: DateTime.now(),
        );
        
        // Update game stats
        final updatedGameStats = Map<String, int>.from(child.gameStats);
        updatedGameStats[progress.gameType] = 
            (updatedGameStats[progress.gameType] ?? 0) + progress.score;
        
        final finalChild = updatedChild.copyWith(gameStats: updatedGameStats);
        await updateChildProfile(finalChild);
      }
    } catch (e) {
      print('Error saving game progress: $e');
      throw Exception('فشل في حفظ تقدم اللعبة');
    }
  }
  
  // Get game progress for a child
  Future<List<GameProgress>> getGameProgressForChild(String childId) async {
    try {
      final querySnapshot = await _firestore
          .collection('gameProgress')
          .where('childId', isEqualTo: childId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => GameProgress.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting game progress: $e');
      return [];
    }
  }
  
  // Get game progress by type for a child
  Future<List<GameProgress>> getGameProgressByType(String childId, String gameType) async {
    try {
      final querySnapshot = await _firestore
          .collection('gameProgress')
          .where('childId', isEqualTo: childId)
          .where('gameType', isEqualTo: gameType)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => GameProgress.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting game progress by type: $e');
      return [];
    }
  }
  
  // ========== ACHIEVEMENTS MANAGEMENT ==========
  
  // Save achievement
  Future<void> saveAchievement(Achievement achievement) async {
    try {
      await _firestore
          .collection('achievements')
          .add(achievement.toJson());
      
      // Add achievement to child's achievements list
      final child = await getChildProfile(achievement.childId);
      if (child != null) {
        final updatedAchievements = List<String>.from(child.achievements);
        if (!updatedAchievements.contains(achievement.id)) {
          updatedAchievements.add(achievement.id);
        }
        
        final updatedChild = child.copyWith(achievements: updatedAchievements);
        await updateChildProfile(updatedChild);
      }
    } catch (e) {
      print('Error saving achievement: $e');
      throw Exception('فشل في حفظ الإنجاز');
    }
  }
  
  // Get achievements for a child
  Future<List<Achievement>> getAchievementsForChild(String childId) async {
    try {
      final querySnapshot = await _firestore
          .collection('achievements')
          .where('childId', isEqualTo: childId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Achievement.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting achievements: $e');
      return [];
    }
  }
  
  // ========== STATISTICS AND ANALYTICS ==========
  
  // Get detailed statistics for a child
  Future<Map<String, dynamic>> getChildStatistics(String childId) async {
    try {
      final child = await getChildProfile(childId);
      if (child == null) return {};
      
      final gameProgress = await getGameProgressForChild(childId);
      final achievements = await getAchievementsForChild(childId);
      
      // Calculate statistics
      final totalGames = gameProgress.length;
      final totalScore = gameProgress.fold<int>(0, (sum, progress) => sum + progress.score);
      final averageScore = totalGames > 0 ? totalScore / totalGames : 0;
      
      // Game type statistics
      final gameTypeStats = <String, Map<String, dynamic>>{};
      for (final progress in gameProgress) {
        if (!gameTypeStats.containsKey(progress.gameType)) {
          gameTypeStats[progress.gameType] = {
            'totalGames': 0,
            'totalScore': 0,
            'bestScore': 0,
            'averageScore': 0,
          };
        }
        
        final stats = gameTypeStats[progress.gameType]!;
        stats['totalGames'] = (stats['totalGames'] as int) + 1;
        stats['totalScore'] = (stats['totalScore'] as int) + progress.score;
        if (progress.score > (stats['bestScore'] as int)) {
          stats['bestScore'] = progress.score;
        }
      }
      
      // Calculate averages
      for (final stats in gameTypeStats.values) {
        stats['averageScore'] = stats['totalGames'] > 0 
            ? (stats['totalScore'] as int) / (stats['totalGames'] as int) 
            : 0;
      }
      
      return {
        'child': child,
        'totalGames': totalGames,
        'totalScore': totalScore,
        'averageScore': averageScore,
        'totalAchievements': achievements.length,
        'gameTypeStats': gameTypeStats,
        'recentProgress': gameProgress.take(10).toList(),
        'recentAchievements': achievements.take(5).toList(),
      };
    } catch (e) {
      print('Error getting child statistics: $e');
      return {};
    }
  }
  
  // Get parent dashboard data
  Future<Map<String, dynamic>> getParentDashboard(String parentId) async {
    try {
      final children = await getChildrenForParent(parentId);
      final dashboardData = <String, dynamic>{
        'totalChildren': children.length,
        'totalGamesPlayed': 0,
        'totalScore': 0,
        'totalAchievements': 0,
        'children': [],
      };
      
      for (final child in children) {
        final childStats = await getChildStatistics(child.id);
        dashboardData['totalGamesPlayed'] += childStats['totalGames'] ?? 0;
        dashboardData['totalScore'] += childStats['totalScore'] ?? 0;
        dashboardData['totalAchievements'] += childStats['totalAchievements'] ?? 0;
        
        dashboardData['children'].add({
          'child': child,
          'stats': childStats,
        });
      }
      
      return dashboardData;
    } catch (e) {
      print('Error getting parent dashboard: $e');
      return {};
    }
  }
}
