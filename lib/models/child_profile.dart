class ChildProfile {
  final String id;
  final String name;
  final int age;
  final String avatarPath;
  final DateTime createdAt;
  final DateTime lastPlayedAt;
  final int totalPoints;
  final int totalGamesPlayed;
  final int totalTimePlayedMinutes;
  final Map<String, int> gameStats;
  
  ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    this.avatarPath = '',
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    this.totalPoints = 0,
    this.totalGamesPlayed = 0,
    this.totalTimePlayedMinutes = 0,
    Map<String, int>? gameStats,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastPlayedAt = lastPlayedAt ?? DateTime.now(),
       gameStats = gameStats ?? {};
  
  // Copy with method for updating profile
  ChildProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? avatarPath,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    int? totalPoints,
    int? totalGamesPlayed,
    int? totalTimePlayedMinutes,
    Map<String, int>? gameStats,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      totalPoints: totalPoints ?? this.totalPoints,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalTimePlayedMinutes: totalTimePlayedMinutes ?? this.totalTimePlayedMinutes,
      gameStats: gameStats ?? this.gameStats,
    );
  }
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'avatarPath': avatarPath,
      'createdAt': createdAt.toIso8601String(),
      'lastPlayedAt': lastPlayedAt.toIso8601String(),
      'totalPoints': totalPoints,
      'totalGamesPlayed': totalGamesPlayed,
      'totalTimePlayedMinutes': totalTimePlayedMinutes,
      'gameStats': gameStats,
    };
  }
  
  // Create from JSON
  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 5,
      avatarPath: json['avatarPath'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastPlayedAt: DateTime.parse(json['lastPlayedAt'] ?? DateTime.now().toIso8601String()),
      totalPoints: json['totalPoints'] ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalTimePlayedMinutes: json['totalTimePlayedMinutes'] ?? 0,
      gameStats: Map<String, int>.from(json['gameStats'] ?? {}),
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
  
  @override
  String toString() {
    return 'ChildProfile(id: $id, name: $name, age: $age, totalPoints: $totalPoints)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChildProfile && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

