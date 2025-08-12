import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/audio_service.dart';

class GameButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool isEnabled;
  final bool playSound;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  
  const GameButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
    this.isEnabled = true,
    this.playSound = true,
    this.borderRadius = 16.0,
    this.padding,
    this.textStyle,
  }) : super(key: key);

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  AudioService? _audioService;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _initAudioService();
  }

  void _initAudioService() async {
    _audioService = await AudioService.getInstance();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isEnabled) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.isEnabled) {
      _animationController.reverse();
    }
  }

  void _handleTap() async {
    if (!widget.isEnabled) return;
    
    if (widget.playSound && _audioService != null) {
      await _audioService!.playButtonClickSound();
    }
    
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppColors.primary;
    final textColor = widget.textColor ?? Colors.white;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: _handleTap,
            child: Container(
              width: widget.width,
              height: widget.height ?? 56,
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: widget.isEnabled ? backgroundColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.isEnabled ? [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
                gradient: widget.isEnabled ? LinearGradient(
                  colors: [
                    backgroundColor,
                    backgroundColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.isEnabled ? textColor : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.text,
                        style: widget.textStyle ?? TextStyle(
                          color: widget.isEnabled ? textColor : Colors.grey[600],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class GameIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final bool isEnabled;
  final bool playSound;
  final String? tooltip;
  
  const GameIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 56,
    this.isEnabled = true,
    this.playSound = true,
    this.tooltip,
  }) : super(key: key);

  @override
  State<GameIconButton> createState() => _GameIconButtonState();
}

class _GameIconButtonState extends State<GameIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  AudioService? _audioService;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _initAudioService();
  }

  void _initAudioService() async {
    _audioService = await AudioService.getInstance();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (!widget.isEnabled) return;
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    if (widget.playSound && _audioService != null) {
      await _audioService!.playButtonClickSound();
    }
    
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppColors.primary;
    final iconColor = widget.iconColor ?? Colors.white;
    
    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _handleTap,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.isEnabled ? backgroundColor : Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: widget.isEnabled ? [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Icon(
                widget.icon,
                color: widget.isEnabled ? iconColor : Colors.grey[600],
                size: widget.size * 0.4,
              ),
            ),
          ),
        );
      },
    );
    
    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    
    return button;
  }
}

class GameCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? imagePath;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLocked;
  final int? stars;
  final Widget? badge;
  
  const GameCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.imagePath,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
    this.isLocked = false,
    this.stars,
    this.badge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardColor = backgroundColor ?? AppColors.surface;
    final titleColor = textColor ?? AppColors.textPrimary;
    
    return Card(
      elevation: isLocked ? 2 : 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLocked ? Colors.grey[200] : cardColor,
            borderRadius: BorderRadius.circular(16),
            gradient: !isLocked ? LinearGradient(
              colors: [
                cardColor,
                cardColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon or Image
              if (imagePath != null)
                Image.asset(
                  imagePath!,
                  width: 64,
                  height: 64,
                  color: isLocked ? Colors.grey : null,
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 64,
                  color: isLocked ? Colors.grey : AppColors.primary,
                ),
              
              const SizedBox(height: 12),
              
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey : titleColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Subtitle
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isLocked ? Colors.grey : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              // Stars
              if (stars != null && !isLocked) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Icon(
                      index < stars! ? Icons.star : Icons.star_border,
                      color: AppColors.goldStar,
                      size: 20,
                    );
                  }),
                ),
              ],
              
              // Badge
              if (badge != null) ...[
                const SizedBox(height: 8),
                badge!,
              ],
              
              // Lock indicator
              if (isLocked) ...[
                const SizedBox(height: 8),
                Icon(
                  Icons.lock,
                  color: Colors.grey,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

