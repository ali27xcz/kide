import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/audio_service.dart';

enum CharacterState {
  idle,
  happy,
  excited,
  encouraging,
  thinking,
  celebrating,
  sad,
  waving,
}

class AnimatedCharacter extends StatefulWidget {
  final CharacterState state;
  final double size;
  final String? message;
  final bool showMessage;
  final bool playSound;
  final VoidCallback? onTap;
  final Duration animationDuration;
  
  const AnimatedCharacter({
    Key? key,
    this.state = CharacterState.idle,
    this.size = 120.0,
    this.message,
    this.showMessage = true,
    this.playSound = true,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<AnimatedCharacter> createState() => _AnimatedCharacterState();
}

class _AnimatedCharacterState extends State<AnimatedCharacter>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  
  AudioService? _audioService;
  CharacterState _currentState = CharacterState.idle;

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
    
    _bounceController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _initAudioService();
    _startStateAnimation();
  }

  void _initAudioService() async {
    _audioService = await AudioService.getInstance();
  }

  @override
  void didUpdateWidget(AnimatedCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _currentState = widget.state;
      _startStateAnimation();
      _playStateSound();
    }
  }

  void _startStateAnimation() {
    switch (_currentState) {
      case CharacterState.idle:
        _bounceController.repeat(reverse: true);
        break;
      case CharacterState.happy:
        _scaleController.forward().then((_) => _scaleController.reverse());
        break;
      case CharacterState.excited:
        _bounceController.forward();
        _scaleController.repeat(reverse: true);
        break;
      case CharacterState.encouraging:
        _bounceController.forward();
        break;
      case CharacterState.thinking:
        _rotationController.repeat();
        break;
      case CharacterState.celebrating:
        _rotationController.forward();
        _scaleController.repeat(reverse: true);
        break;
      case CharacterState.sad:
        _bounceController.reverse();
        break;
      case CharacterState.waving:
        _bounceController.repeat(reverse: true);
        break;
    }
  }

  void _playStateSound() async {
    if (!widget.playSound || _audioService == null) return;
    
    switch (_currentState) {
      case CharacterState.happy:
      case CharacterState.excited:
        await _audioService!.playMascotCelebration();
        break;
      case CharacterState.encouraging:
        await _audioService!.playMascotEncouragement();
        break;
      case CharacterState.celebrating:
        await _audioService!.playCelebrationSound();
        break;
      case CharacterState.waving:
        await _audioService!.playMascotWelcome();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Character
          AnimatedBuilder(
            animation: Listenable.merge([
              _bounceAnimation,
              _rotationAnimation,
              _scaleAnimation,
            ]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, -_bounceAnimation.value * 10),
                  child: Transform.rotate(
                    angle: _getRotationAngle(),
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _getCharacterGradient(),
                        boxShadow: [
                          BoxShadow(
                            color: _getCharacterColor().withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Face
                          _buildFace(),
                          
                          // Eyes
                          Positioned(
                            top: widget.size * 0.3,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildEye(isLeft: true),
                                SizedBox(width: widget.size * 0.1),
                                _buildEye(isLeft: false),
                              ],
                            ),
                          ),
                          
                          // Mouth
                          Positioned(
                            top: widget.size * 0.6,
                            child: _buildMouth(),
                          ),
                          
                          // Special effects
                          if (_currentState == CharacterState.celebrating)
                            ..._buildCelebrationEffects(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Message bubble
          if (widget.showMessage && widget.message != null) ...[
            const SizedBox(height: 12),
            _buildMessageBubble(),
          ],
        ],
      ),
    );
  }

  double _getRotationAngle() {
    switch (_currentState) {
      case CharacterState.thinking:
        return _rotationAnimation.value * 0.2;
      case CharacterState.celebrating:
        return _rotationAnimation.value * 0.1;
      default:
        return 0.0;
    }
  }

  Color _getCharacterColor() {
    switch (_currentState) {
      case CharacterState.happy:
      case CharacterState.excited:
      case CharacterState.celebrating:
        return AppColors.funYellow;
      case CharacterState.encouraging:
        return AppColors.funGreen;
      case CharacterState.thinking:
        return AppColors.funBlue;
      case CharacterState.sad:
        return AppColors.funRed;
      default:
        return AppColors.primary;
    }
  }

  Gradient _getCharacterGradient() {
    final color = _getCharacterColor();
    return LinearGradient(
      colors: [
        color,
        color.withOpacity(0.7),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildFace() {
    return Container(
      width: widget.size * 0.8,
      height: widget.size * 0.8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.9),
      ),
    );
  }

  Widget _buildEye({required bool isLeft}) {
    return Container(
      width: widget.size * 0.08,
      height: widget.size * 0.08,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getEyeColor(),
      ),
    );
  }

  Color _getEyeColor() {
    switch (_currentState) {
      case CharacterState.happy:
      case CharacterState.excited:
      case CharacterState.celebrating:
        return AppColors.textPrimary;
      case CharacterState.sad:
        return AppColors.textSecondary;
      case CharacterState.thinking:
        return AppColors.primary;
      default:
        return AppColors.textPrimary;
    }
  }

  Widget _buildMouth() {
    switch (_currentState) {
      case CharacterState.happy:
      case CharacterState.excited:
      case CharacterState.celebrating:
      case CharacterState.encouraging:
        return Container(
          width: widget.size * 0.2,
          height: widget.size * 0.1,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(widget.size * 0.05),
          ),
        );
      case CharacterState.sad:
        return Transform.rotate(
          angle: 3.14159, // 180 degrees
          child: Container(
            width: widget.size * 0.15,
            height: widget.size * 0.08,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(widget.size * 0.04),
            ),
          ),
        );
      case CharacterState.thinking:
        return Container(
          width: widget.size * 0.1,
          height: widget.size * 0.1,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textPrimary,
          ),
        );
      default:
        return Container(
          width: widget.size * 0.15,
          height: widget.size * 0.05,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(widget.size * 0.025),
          ),
        );
    }
  }

  List<Widget> _buildCelebrationEffects() {
    return [
      Positioned(
        top: 0,
        left: widget.size * 0.1,
        child: Icon(
          Icons.star,
          size: widget.size * 0.15,
          color: AppColors.goldStar,
        ),
      ),
      Positioned(
        top: widget.size * 0.1,
        right: widget.size * 0.1,
        child: Icon(
          Icons.favorite,
          size: widget.size * 0.12,
          color: AppColors.funRed,
        ),
      ),
      Positioned(
        bottom: widget.size * 0.1,
        left: widget.size * 0.2,
        child: Icon(
          Icons.celebration,
          size: widget.size * 0.1,
          color: AppColors.funOrange,
        ),
      ),
    ];
  }

  Widget _buildMessageBubble() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: widget.size * 2,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        widget.message!,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class CharacterDialog extends StatefulWidget {
  final String message;
  final CharacterState characterState;
  final List<String>? options;
  final Function(int)? onOptionSelected;
  final VoidCallback? onClose;
  final bool autoClose;
  final Duration autoCloseDuration;
  
  const CharacterDialog({
    Key? key,
    required this.message,
    this.characterState = CharacterState.happy,
    this.options,
    this.onOptionSelected,
    this.onClose,
    this.autoClose = false,
    this.autoCloseDuration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<CharacterDialog> createState() => _CharacterDialogState();
}

class _CharacterDialogState extends State<CharacterDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
    
    if (widget.autoClose) {
      Future.delayed(widget.autoCloseDuration, () {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onClose?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
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
                    // Character
                    AnimatedCharacter(
                      state: widget.characterState,
                      size: 100,
                      showMessage: false,
                      playSound: true,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Message
                    Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Options or Close Button
                    if (widget.options != null && widget.options!.isNotEmpty)
                      ...widget.options!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onOptionSelected?.call(index);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList()
                    else
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
                          'حسناً',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
    );
  }
}

// Helper function to show character dialog
Future<void> showCharacterDialog(
  BuildContext context, {
  required String message,
  CharacterState characterState = CharacterState.happy,
  List<String>? options,
  Function(int)? onOptionSelected,
  VoidCallback? onClose,
  bool autoClose = false,
  Duration autoCloseDuration = const Duration(seconds: 3),
}) {
  return showDialog(
    context: context,
    barrierDismissible: !autoClose,
    builder: (context) => CharacterDialog(
      message: message,
      characterState: characterState,
      options: options,
      onOptionSelected: onOptionSelected,
      onClose: onClose,
      autoClose: autoClose,
      autoCloseDuration: autoCloseDuration,
    ),
  );
}

