class ChildProfile {
  final String id;
  final String name;
  final int age;
  final String avatarPath;
  final String parentId; // ربط بالوالد
  final DateTime createdAt;
  final DateTime lastPlayedAt;
  final int totalPoints;
  final int totalGamesPlayed;
  final int totalTimePlayedMinutes;
  final Map<String, int> gameStats;
  final Map<String, dynamic> preferences; // تفضيلات الطفل
  final List<String> achievements; // قائمة الإنجازات
  
  ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    this.avatarPath = '',
    required this.parentId,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    this.totalPoints = 0,
    this.totalGamesPlayed = 0,
    this.totalTimePlayedMinutes = 0,
    Map<String, int>? gameStats,
    Map<String, dynamic>? preferences,
    List<String>? achievements,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastPlayedAt = lastPlayedAt ?? DateTime.now(),
       gameStats = gameStats ?? {},
       preferences = preferences ?? {},
       achievements = achievements ?? [];
  
  // Copy with method for updating profile
  ChildProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? avatarPath,
    String? parentId,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    int? totalPoints,
    int? totalGamesPlayed,
    int? totalTimePlayedMinutes,
    Map<String, int>? gameStats,
    Map<String, dynamic>? preferences,
    List<String>? achievements,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarPath: avatarPath ?? this.avatarPath,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      totalPoints: totalPoints ?? this.totalPoints,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalTimePlayedMinutes: totalTimePlayedMinutes ?? this.totalTimePlayedMinutes,
      gameStats: gameStats ?? this.gameStats,
      preferences: preferences ?? this.preferences,
      achievements: achievements ?? this.achievements,
    );
  }
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'avatarPath': avatarPath,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
      'lastPlayedAt': lastPlayedAt.toIso8601String(),
      'totalPoints': totalPoints,
      'totalGamesPlayed': totalGamesPlayed,
      'totalTimePlayedMinutes': totalTimePlayedMinutes,
      'gameStats': gameStats,
      'preferences': preferences,
      'achievements': achievements,
    };
  }
  
  // Create from JSON
  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 5,
      avatarPath: json['avatarPath'] ?? '',
      parentId: json['parentId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastPlayedAt: DateTime.parse(json['lastPlayedAt'] ?? DateTime.now().toIso8601String()),
      totalPoints: json['totalPoints'] ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalTimePlayedMinutes: json['totalTimePlayedMinutes'] ?? 0,
      gameStats: Map<String, int>.from(json['gameStats'] ?? {}),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }
  
  // Helper methods
  int getGameStats(String gameType) {
    return gameStats[gameType] ?? 0;
  }
  
  void updateGameStats(String gameType, int points) {
    gameStats[gameType] = (gameStats[gameType] ?? 0) + points;
  }
  
  int getCurrentLevel() {
    if (totalPoints < 100) return 1;
    if (totalPoints < 300) return 2;
    if (totalPoints < 600) return 3;
    if (totalPoints < 1000) return 4;
    return 5;
  }
  
  String getLevelTitle() {
    switch (getCurrentLevel()) {
      case 1:
        return 'مبتدئ';
      case 2:
        return 'متعلم';
      case 3:
        return 'ماهر';
      case 4:
        return 'خبير';
      case 5:
        return 'عالم صغير';
      default:
        return 'مبتدئ';
    }
  }
  
  double getProgressToNextLevel() {
    int currentLevel = getCurrentLevel();
    if (currentLevel >= 5) return 1.0;
    
    List<int> levelThresholds = [0, 100, 300, 600, 1000];
    int currentThreshold = levelThresholds[currentLevel - 1];
    int nextThreshold = levelThresholds[currentLevel];
    
    return (totalPoints - currentThreshold) / (nextThreshold - currentThreshold);
  }
  
  // إضافة إنجاز جديد
  void addAchievement(String achievementId) {
    if (!achievements.contains(achievementId)) {
      achievements.add(achievementId);
    }
  }
  
  // التحقق من وجود إنجاز
  bool hasAchievement(String achievementId) {
    return achievements.contains(achievementId);
  }
  
  // تحديث التفضيلات
  void updatePreference(String key, dynamic value) {
    preferences[key] = value;
  }
  
  // الحصول على تفضيل
  dynamic getPreference(String key, {dynamic defaultValue}) {
    return preferences[key] ?? defaultValue;
  }
  
  @override
  String toString() {
    return 'ChildProfile(id: $id, name: $name, age: $age, parentId: $parentId, totalPoints: $totalPoints)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChildProfile && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

