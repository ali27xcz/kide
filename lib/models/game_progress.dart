class GameProgress {
  final String gameType;
  final int level;
  final int score;
  final int maxScore;
  final int stars;
  final int timeSpentSeconds;
  final DateTime completedAt;
  final bool isCompleted;
  final Map<String, dynamic> gameData;
  
  GameProgress({
    required this.gameType,
    required this.level,
    required this.score,
    required this.maxScore,
    required this.stars,
    required this.timeSpentSeconds,
    DateTime? completedAt,
    this.isCompleted = false,
    Map<String, dynamic>? gameData,
  }) : completedAt = completedAt ?? DateTime.now(),
       gameData = gameData ?? {};
  
  // Copy with method
  GameProgress copyWith({
    String? gameType,
    int? level,
    int? score,
    int? maxScore,
    int? stars,
    int? timeSpentSeconds,
    DateTime? completedAt,
    bool? isCompleted,
    Map<String, dynamic>? gameData,
  }) {
    return GameProgress(
      gameType: gameType ?? this.gameType,
      level: level ?? this.level,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      stars: stars ?? this.stars,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      gameData: gameData ?? this.gameData,
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'gameType': gameType,
      'level': level,
      'score': score,
      'maxScore': maxScore,
      'stars': stars,
      'timeSpentSeconds': timeSpentSeconds,
      'completedAt': completedAt.toIso8601String(),
      'isCompleted': isCompleted,
      'gameData': gameData,
    };
  }
  
  // Create from JSON
  factory GameProgress.fromJson(Map<String, dynamic> json) {
    return GameProgress(
      gameType: json['gameType'] ?? '',
      level: json['level'] ?? 1,
      score: json['score'] ?? 0,
      maxScore: json['maxScore'] ?? 0,
      stars: json['stars'] ?? 0,
      timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
      completedAt: DateTime.parse(json['completedAt'] ?? DateTime.now().toIso8601String()),
      isCompleted: json['isCompleted'] ?? false,
      gameData: Map<String, dynamic>.from(json['gameData'] ?? {}),
    );
  }
  
  // Helper methods
  double get scorePercentage {
    if (maxScore == 0) return 0.0;
    return score / maxScore;
  }
  
  String get performanceLevel {
    double percentage = scorePercentage;
    if (percentage >= 0.9) return 'ممتاز';
    if (percentage >= 0.7) return 'جيد جداً';
    if (percentage >= 0.5) return 'جيد';
    return 'يحتاج تحسين';
  }
  
  String get timeSpentFormatted {
    int minutes = timeSpentSeconds ~/ 60;
    int seconds = timeSpentSeconds % 60;
    if (minutes > 0) {
      return '${minutes}د ${seconds}ث';
    }
    return '${seconds}ث';
  }
  
  bool get isPerfectScore => score == maxScore && maxScore > 0;
  
  bool get isGoodScore => scorePercentage >= 0.7;
  
  bool get needsImprovement => scorePercentage < 0.5;
  
  @override
  String toString() {
    return 'GameProgress(gameType: $gameType, level: $level, score: $score/$maxScore, stars: $stars)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameProgress &&
        other.gameType == gameType &&
        other.level == level &&
        other.completedAt == completedAt;
  }
  
  @override
  int get hashCode => Object.hash(gameType, level, completedAt);
}

class GameSession {
  final String sessionId;
  final String childId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<GameProgress> gamesPlayed;
  final int totalScore;
  final int totalTimeSeconds;
  
  GameSession({
    required this.sessionId,
    required this.childId,
    DateTime? startTime,
    this.endTime,
    List<GameProgress>? gamesPlayed,
    this.totalScore = 0,
    this.totalTimeSeconds = 0,
  }) : startTime = startTime ?? DateTime.now(),
       gamesPlayed = gamesPlayed ?? [];
  
  // Copy with method
  GameSession copyWith({
    String? sessionId,
    String? childId,
    DateTime? startTime,
    DateTime? endTime,
    List<GameProgress>? gamesPlayed,
    int? totalScore,
    int? totalTimeSeconds,
  }) {
    return GameSession(
      sessionId: sessionId ?? this.sessionId,
      childId: childId ?? this.childId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalScore: totalScore ?? this.totalScore,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'childId': childId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'gamesPlayed': gamesPlayed.map((game) => game.toJson()).toList(),
      'totalScore': totalScore,
      'totalTimeSeconds': totalTimeSeconds,
    };
  }
  
  // Create from JSON
  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      sessionId: json['sessionId'] ?? '',
      childId: json['childId'] ?? '',
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      gamesPlayed: (json['gamesPlayed'] as List<dynamic>?)
          ?.map((game) => GameProgress.fromJson(game))
          .toList() ?? [],
      totalScore: json['totalScore'] ?? 0,
      totalTimeSeconds: json['totalTimeSeconds'] ?? 0,
    );
  }
  
  // Helper methods
  bool get isActive => endTime == null;
  
  Duration get sessionDuration {
    DateTime end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
  
  void addGameProgress(GameProgress progress) {
    gamesPlayed.add(progress);
  }
  
  GameSession endSession() {
    return copyWith(endTime: DateTime.now());
  }
}

