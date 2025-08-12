import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ProgressBar extends StatefulWidget {
  final double progress;
  final Color? backgroundColor;
  final Color? progressColor;
  final double height;
  final double borderRadius;
  final String? label;
  final bool showPercentage;
  final bool animated;
  final Duration animationDuration;
  
  const ProgressBar({
    Key? key,
    required this.progress,
    this.backgroundColor,
    this.progressColor,
    this.height = 8.0,
    this.borderRadius = 4.0,
    this.label,
    this.showPercentage = false,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.animated) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress.clamp(0.0, 1.0),
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      if (widget.animated) {
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppColors.cardBackground;
    final progressColor = widget.progressColor ?? AppColors.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              if (widget.showPercentage)
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    final percentage = widget.animated
                        ? (_progressAnimation.value * 100).round()
                        : (widget.progress * 100).round();
                    return Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: AnimatedBuilder(
              animation: widget.animated ? _progressAnimation : 
                  AlwaysStoppedAnimation(widget.progress.clamp(0.0, 1.0)),
              builder: (context, child) {
                final currentProgress = widget.animated
                    ? _progressAnimation.value
                    : widget.progress.clamp(0.0, 1.0);
                
                return LinearProgressIndicator(
                  value: currentProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class CircularProgressBar extends StatefulWidget {
  final double progress;
  final Color? backgroundColor;
  final Color? progressColor;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final bool showPercentage;
  final bool animated;
  final Duration animationDuration;
  
  const CircularProgressBar({
    Key? key,
    required this.progress,
    this.backgroundColor,
    this.progressColor,
    this.size = 100.0,
    this.strokeWidth = 8.0,
    this.child,
    this.showPercentage = false,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<CircularProgressBar> createState() => _CircularProgressBarState();
}

class _CircularProgressBarState extends State<CircularProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.animated) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(CircularProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress.clamp(0.0, 1.0),
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      if (widget.animated) {
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppColors.cardBackground;
    final progressColor = widget.progressColor ?? AppColors.primary;
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: widget.animated ? _progressAnimation : 
                AlwaysStoppedAnimation(widget.progress.clamp(0.0, 1.0)),
            builder: (context, child) {
              final currentProgress = widget.animated
                  ? _progressAnimation.value
                  : widget.progress.clamp(0.0, 1.0);
              
              return CircularProgressIndicator(
                value: currentProgress,
                strokeWidth: widget.strokeWidth,
                backgroundColor: backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              );
            },
          ),
          if (widget.child != null)
            widget.child!
          else if (widget.showPercentage)
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                final percentage = widget.animated
                    ? (_progressAnimation.value * 100).round()
                    : (widget.progress * 100).round();
                return Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class LevelProgressBar extends StatelessWidget {
  final int currentLevel;
  final double progressToNextLevel;
  final int totalPoints;
  final String levelTitle;
  final Color? backgroundColor;
  final Color? progressColor;
  
  const LevelProgressBar({
    Key? key,
    required this.currentLevel,
    required this.progressToNextLevel,
    required this.totalPoints,
    required this.levelTitle,
    this.backgroundColor,
    this.progressColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المستوى $currentLevel',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    levelTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalPoints نقطة',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(
            progress: progressToNextLevel,
            progressColor: progressColor,
            height: 12,
            borderRadius: 6,
            showPercentage: true,
            label: currentLevel >= 5 ? 'مكتمل!' : 'التقدم للمستوى التالي',
          ),
        ],
      ),
    );
  }
}

class GameProgressIndicator extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final int score;
  final int maxScore;
  
  const GameProgressIndicator({
    Key? key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.score,
    required this.maxScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = totalQuestions > 0 ? currentQuestion / totalQuestions : 0.0;
    final scorePercentage = maxScore > 0 ? score / maxScore : 0.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'السؤال $currentQuestion من $totalQuestions',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$score / $maxScore',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ProgressBar(
                  progress: progress,
                  height: 6,
                  borderRadius: 3,
                  animated: false,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircularProgressBar(
            progress: scorePercentage,
            size: 40,
            strokeWidth: 4,
            animated: false,
            child: Text(
              '${(scorePercentage * 100).round()}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

