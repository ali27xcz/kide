enum AchievementType {
  firstGame,
  perfectScore,
  streakWins,
  timeRecord,
  totalPoints,
  gameCompletion,
  dedication,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final AchievementType type;
  final int targetValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String category;
  final int points;
  
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.category = 'general',
    this.points = 0,
  });
  
  // Copy with method
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    AchievementType? type,
    int? targetValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? category,
    int? points,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      category: category ?? this.category,
      points: points ?? this.points,
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'type': type.toString(),
      'targetValue': targetValue,
      'currentValue': currentValue,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'category': category,
      'points': points,
    };
  }
  
  // Create from JSON
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconPath: json['iconPath'] ?? '',
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AchievementType.firstGame,
      ),
      targetValue: json['targetValue'] ?? 0,
      currentValue: json['currentValue'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt']) 
          : null,
      category: json['category'] ?? 'general',
      points: json['points'] ?? 0,
    );
  }
  
  // Helper methods
  double get progress {
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }
  
  bool get isCompleted => currentValue >= targetValue;
  
  Achievement updateProgress(int newValue) {
    bool wasUnlocked = isUnlocked;
    bool shouldUnlock = newValue >= targetValue && !wasUnlocked;
    
    return copyWith(
      currentValue: newValue,
      isUnlocked: shouldUnlock || wasUnlocked,
      unlockedAt: shouldUnlock ? DateTime.now() : unlockedAt,
    );
  }
  
  Achievement unlock() {
    return copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
      currentValue: targetValue,
    );
  }
  
  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, progress: ${currentValue}/${targetValue})';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

class AchievementManager {
  static List<Achievement> getDefaultAchievements() {
    return [
      // First Game Achievements
      Achievement(
        id: 'first_counting',
        title: 'أول عداد',
        description: 'أكمل أول لعبة عد',
        iconPath: 'images/achievements/first_counting.png',
        type: AchievementType.firstGame,
        targetValue: 1,
        category: 'counting',
        points: 50,
      ),
      Achievement(
        id: 'first_addition',
        title: 'أول جامع',
        description: 'أكمل أول لعبة جمع',
        iconPath: 'images/achievements/first_addition.png',
        type: AchievementType.firstGame,
        targetValue: 1,
        category: 'addition',
        points: 50,
      ),
      Achievement(
        id: 'first_shapes',
        title: 'خبير الأشكال',
        description: 'أكمل أول لعبة أشكال',
        iconPath: 'images/achievements/first_shapes.png',
        type: AchievementType.firstGame,
        targetValue: 1,
        category: 'shapes',
        points: 50,
      ),
      Achievement(
        id: 'first_colors',
        title: 'فنان الألوان',
        description: 'أكمل أول لعبة ألوان',
        iconPath: 'images/achievements/first_colors.png',
        type: AchievementType.firstGame,
        targetValue: 1,
        category: 'colors',
        points: 50,
      ),
      Achievement(
        id: 'first_patterns',
        title: 'محلل الأنماط',
        description: 'أكمل أول لعبة أنماط',
        iconPath: 'images/achievements/first_patterns.png',
        type: AchievementType.firstGame,
        targetValue: 1,
        category: 'patterns',
        points: 50,
      ),
      
      // Perfect Score Achievements
      Achievement(
        id: 'perfect_10',
        title: 'مثالي',
        description: 'احصل على درجة مثالية في 10 ألعاب',
        iconPath: 'images/achievements/perfect_10.png',
        type: AchievementType.perfectScore,
        targetValue: 10,
        category: 'performance',
        points: 200,
      ),
      
      // Streak Achievements
      Achievement(
        id: 'streak_5',
        title: 'متتالي',
        description: 'اربح 5 ألعاب متتالية',
        iconPath: 'images/achievements/streak_5.png',
        type: AchievementType.streakWins,
        targetValue: 5,
        category: 'performance',
        points: 150,
      ),
      
      // Total Points Achievements
      Achievement(
        id: 'points_100',
        title: 'جامع النقاط',
        description: 'اجمع 100 نقطة',
        iconPath: 'images/achievements/points_100.png',
        type: AchievementType.totalPoints,
        targetValue: 100,
        category: 'progress',
        points: 100,
      ),
      Achievement(
        id: 'points_500',
        title: 'خبير النقاط',
        description: 'اجمع 500 نقطة',
        iconPath: 'images/achievements/points_500.png',
        type: AchievementType.totalPoints,
        targetValue: 500,
        category: 'progress',
        points: 300,
      ),
      Achievement(
        id: 'points_1000',
        title: 'ملك النقاط',
        description: 'اجمع 1000 نقطة',
        iconPath: 'images/achievements/points_1000.png',
        type: AchievementType.totalPoints,
        targetValue: 1000,
        category: 'progress',
        points: 500,
      ),
      
      // Dedication Achievements
      Achievement(
        id: 'daily_player',
        title: 'لاعب يومي',
        description: 'العب لمدة 7 أيام متتالية',
        iconPath: 'images/achievements/daily_player.png',
        type: AchievementType.dedication,
        targetValue: 7,
        category: 'dedication',
        points: 250,
      ),
      
      // Game Completion Achievements
      Achievement(
        id: 'all_games',
        title: 'مكمل الألعاب',
        description: 'أكمل جميع أنواع الألعاب',
        iconPath: 'images/achievements/all_games.png',
        type: AchievementType.gameCompletion,
        targetValue: 5,
        category: 'completion',
        points: 400,
      ),
    ];
  }
}

