import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../utils/colors.dart';

class AchievementBadge extends StatefulWidget {
  final Achievement achievement;
  final double size;
  final bool showProgress;
  final bool showTitle;
  final bool showDescription;
  final VoidCallback? onTap;
  
  const AchievementBadge({
    Key? key,
    required this.achievement,
    this.size = 80.0,
    this.showProgress = true,
    this.showTitle = true,
    this.showDescription = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.achievement.isUnlocked) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AchievementBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.achievement.isUnlocked && widget.achievement.isUnlocked) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge Icon
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 0.1,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.achievement.isUnlocked
                          ? const LinearGradient(
                              colors: [
                                AppColors.goldStar,
                                Color(0xFFFFE55C),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey[300]!,
                                Colors.grey[400]!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: widget.achievement.isUnlocked
                          ? [
                              BoxShadow(
                                color: AppColors.goldStar.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Achievement Icon
                        Icon(
                          _getAchievementIcon(),
                          size: widget.size * 0.4,
                          color: widget.achievement.isUnlocked
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                        
                        // Progress Ring
                        if (widget.showProgress && !widget.achievement.isUnlocked)
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              value: widget.achievement.progress,
                              strokeWidth: 3,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        
                        // Lock Icon
                        if (!widget.achievement.isUnlocked && widget.achievement.progress == 0)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: widget.size * 0.3,
                              height: widget.size * 0.3,
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock,
                                size: widget.size * 0.15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Title
          if (widget.showTitle) ...[
            const SizedBox(height: 8),
            Text(
              widget.achievement.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.achievement.isUnlocked
                    ? AppColors.textPrimary
                    : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // Description
          if (widget.showDescription) ...[
            const SizedBox(height: 4),
            Text(
              widget.achievement.description,
              style: TextStyle(
                fontSize: 10,
                color: widget.achievement.isUnlocked
                    ? AppColors.textSecondary
                    : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // Progress Text
          if (widget.showProgress && !widget.achievement.isUnlocked) ...[
            const SizedBox(height: 4),
            Text(
              '${widget.achievement.currentValue}/${widget.achievement.targetValue}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getAchievementIcon() {
    switch (widget.achievement.type) {
      case AchievementType.firstGame:
        return Icons.play_circle_filled;
      case AchievementType.perfectScore:
        return Icons.star;
      case AchievementType.streakWins:
        return Icons.trending_up;
      case AchievementType.timeRecord:
        return Icons.timer;
      case AchievementType.totalPoints:
        return Icons.emoji_events;
      case AchievementType.gameCompletion:
        return Icons.check_circle;
      case AchievementType.dedication:
        return Icons.favorite;
      default:
        return Icons.emoji_events;
    }
  }
}

class StarRating extends StatefulWidget {
  final int stars;
  final int maxStars;
  final double size;
  final bool animated;
  final Duration animationDelay;
  final VoidCallback? onTap;
  
  const StarRating({
    Key? key,
    required this.stars,
    this.maxStars = 3,
    this.size = 24.0,
    this.animated = true,
    this.animationDelay = const Duration(milliseconds: 200),
    this.onTap,
  }) : super(key: key);

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating>
    with TickerProviderStateMixin {
  List<AnimationController> _controllers = [];
  List<Animation<double>> _scaleAnimations = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers.clear();
    _scaleAnimations.clear();
    
    for (int i = 0; i < widget.maxStars; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      
      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
      
      _controllers.add(controller);
      _scaleAnimations.add(animation);
      
      if (widget.animated && i < widget.stars) {
        Future.delayed(
          widget.animationDelay * i,
          () => controller.forward(),
        );
      } else if (!widget.animated) {
        controller.value = i < widget.stars ? 1.0 : 0.0;
      }
    }
  }

  @override
  void didUpdateWidget(StarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stars != widget.stars || oldWidget.maxStars != widget.maxStars) {
      _disposeAnimations();
      _initializeAnimations();
    }
  }

  void _disposeAnimations() {
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.maxStars, (index) {
          return AnimatedBuilder(
            animation: _scaleAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimations[index].value,
                child: Icon(
                  index < widget.stars ? Icons.star : Icons.star_border,
                  size: widget.size,
                  color: AppColors.getStarColor(index < widget.stars ? 3 : 0),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class AchievementUnlockedDialog extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onClose;
  
  const AchievementUnlockedDialog({
    Key? key,
    required this.achievement,
    this.onClose,
  }) : super(key: key);

  @override
  State<AchievementUnlockedDialog> createState() => _AchievementUnlockedDialogState();
}

class _AchievementUnlockedDialogState extends State<AchievementUnlockedDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _scaleController.forward();
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Celebration Icon
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159,
                        child: const Icon(
                          Icons.celebration,
                          size: 48,
                          color: AppColors.goldStar,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  const Text(
                    'إنجاز جديد!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Achievement Badge
                  AchievementBadge(
                    achievement: widget.achievement,
                    size: 100,
                    showProgress: false,
                    showTitle: true,
                    showDescription: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Points
                  if (widget.achievement.points > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${widget.achievement.points} نقطة',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Close Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onClose?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'رائع!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AchievementsList extends StatelessWidget {
  final List<Achievement> achievements;
  final bool showOnlyUnlocked;
  final Function(Achievement)? onAchievementTap;
  
  const AchievementsList({
    Key? key,
    required this.achievements,
    this.showOnlyUnlocked = false,
    this.onAchievementTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredAchievements = showOnlyUnlocked
        ? achievements.where((a) => a.isUnlocked).toList()
        : achievements;
    
    if (filteredAchievements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد إنجازات بعد',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'العب المزيد من الألعاب لفتح الإنجازات!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredAchievements.length,
      itemBuilder: (context, index) {
        final achievement = filteredAchievements[index];
        return AchievementBadge(
          achievement: achievement,
          showProgress: true,
          showTitle: true,
          showDescription: false,
          onTap: () => onAchievementTap?.call(achievement),
        );
      },
    );
  }
}

