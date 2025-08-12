// animated_character.dart
import 'dart:async';
import 'dart:math' as math;
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

enum MotionStyle {
  gentle,
  lively,
}

class AnimatedCharacter extends StatefulWidget {
  final CharacterState state;
  final double size;
  final String? message;
  final bool showMessage;
  final bool playSound;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final MotionStyle motionStyle;

  const AnimatedCharacter({
    Key? key,
    this.state = CharacterState.idle,
    this.size = 120.0,
    this.message,
    this.showMessage = true,
    this.playSound = true,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 800),
    this.motionStyle = MotionStyle.gentle,
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

  // Micro-animations
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  late AnimationController _pupilController;
  late Animation<double> _pupilAnimation;
  late AnimationController _smileController;
  late Animation<double> _smileAnimation;

  Timer? _blinkTimer;
  bool _isBlinking = false;

  AudioService? _audioService;
  CharacterState _currentState = CharacterState.idle;

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;

    // Core controllers
    _bounceController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Breath
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );
    _breathAnimation = Tween<double>(begin: 0.99, end: 1.02).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _breathController.repeat(reverse: true);

    // Pupil (look around)
    _pupilController = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );
    _pupilAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _pupilController, curve: Curves.easeInOutSine),
    );
    _pupilController.repeat(reverse: true);

    // Smile subtle pulsing
    _smileController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _smileAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _smileController, curve: Curves.easeInOut),
    );
    _smileController.repeat(reverse: true);

    // Blink timer
    _startBlinking();

    if (widget.playSound) {
      _initAudioService();
    }
    _startStateAnimation();
  }

  void _startBlinking() {
    _blinkTimer?.cancel();
    // randomized-ish blink rhythm
    _blinkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      setState(() => _isBlinking = true);
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() => _isBlinking = false);
    });
  }

  void _initAudioService() async {
    _audioService = await AudioService.getInstance();
    // Ensure sfx is enabled for mascot feedback
    try {
      await _audioService!.setSoundEnabled(true);
    } catch (_) {}
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

  void _stopAllStateAnimations() {
    // stop but keep breath/pupil/smile running for liveliness
    _bounceController.stop();
    _rotationController.stop();
    _scaleController.stop();

    // reset to defaults so new animations start from expected values
    _bounceController.reset();
    _rotationController.reset();
    _scaleController.reset();
  }

  void _startStateAnimation() {
    _stopAllStateAnimations();

    // Uniform motion across screens for a consistent, smooth feel
    if (widget.motionStyle == MotionStyle.gentle) {
      switch (_currentState) {
        case CharacterState.celebrating:
          _rotationController.repeat();
          _scaleController.repeat(reverse: true);
          _bounceController.repeat(reverse: true);
          break;
        case CharacterState.waving:
          _bounceController.repeat(reverse: true);
          _rotationController.repeat(reverse: true);
          _scaleController.animateTo(0.0);
          break;
        default:
          _bounceController.repeat(reverse: true);
          _scaleController.animateTo(0.0);
          break;
      }
      return;
    }

    // Lively motion (fallback to previous state-specific behavior)
    switch (_currentState) {
      case CharacterState.idle:
        _bounceController.repeat(reverse: true);
        _scaleController.animateTo(0.0);
        break;
      case CharacterState.happy:
        _bounceController.animateTo(0.7).then((_) => _bounceController.reverse());
        _scaleController.forward().then((_) => _scaleController.reverse());
        break;
      case CharacterState.excited:
        _bounceController.repeat(reverse: true);
        _scaleController.repeat(reverse: true);
        break;
      case CharacterState.encouraging:
        _bounceController.repeat();
        _scaleController.animateTo(1.0);
        break;
      case CharacterState.thinking:
        _rotationController.repeat(reverse: true);
        _scaleController.animateTo(0.98);
        break;
      case CharacterState.celebrating:
        _rotationController.repeat();
        _scaleController.repeat(reverse: true);
        _bounceController.repeat(reverse: true);
        break;
      case CharacterState.sad:
        _bounceController.reverse();
        _scaleController.animateTo(0.96);
        break;
      case CharacterState.waving:
        _bounceController.repeat(reverse: true);
        _rotationController.repeat(reverse: true);
        break;
    }
  }

  void _playStateSound() async {
    if (!widget.playSound || _audioService == null) return;

    try {
      // stop any running mascot sounds to avoid overlap
      await _audioService!.stopAll(); // assume stopAll exists; if not, replace with stop() or handle accordingly
    } catch (_) {
      // ignore if method not present
    }

    try {
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
    } catch (e) {
      // swallow audio errors to avoid crashing UI
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _bounceController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    _breathController.dispose();
    _pupilController.dispose();
    _smileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Merge listenables: keep rebuild scope reasonable
    final merged = Listenable.merge([
      _bounceAnimation,
      _rotationAnimation,
      _scaleAnimation,
      _breathAnimation,
      _pupilAnimation,
      _smileAnimation,
    ]);

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: merged,
            builder: (context, child) {
              final double scaleState = _scaleAnimation.value;
              final double combinedScale = scaleState * _breathAnimation.value;
              final double amplitude = (widget.motionStyle == MotionStyle.gentle) ? 0.05 : 0.08;
              final double bounceOffset = -_bounceAnimation.value * (widget.size * amplitude);
              final double rotation = _getRotationAngle();

              return Transform.scale(
                scale: combinedScale,
                child: Transform.translate(
                  offset: Offset(0, bounceOffset),
                  child: Transform.rotate(
                    angle: rotation,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _getCharacterGradient(),
                        boxShadow: [
                          BoxShadow(
                            color: _getCharacterColor().withOpacity(0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // face plate with soft highlight
                          _buildFacePlate(),

                          // eyes
                          Positioned(
                            top: widget.size * 0.28,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildEye(isLeft: true),
                                SizedBox(width: widget.size * 0.14), // increased separation
                                _buildEye(isLeft: false),
                              ],
                            ),
                          ),

                          // eyebrows removed per design

                          // mouth
                          Positioned(
                            top: widget.size * 0.58,
                            child: _buildMouth(),
                          ),

                          // celebration icons
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

          // message bubble (if provided)
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
        return (math.sin(_rotationAnimation.value * math.pi * 2) * 0.08);
      case CharacterState.celebrating:
        return _rotationAnimation.value * 0.12 * math.sin(_rotationAnimation.value * math.pi * 2);
      case CharacterState.waving:
        return _rotationAnimation.value * 0.14;
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
        color.withOpacity(0.78),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildFacePlate() {
    return Container(
      width: widget.size * 0.78,
      height: widget.size * 0.78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(-6, -6),
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildEye({required bool isLeft}) {
    final double eyeSize = widget.size * 0.09;
    final double pupilSize = eyeSize * 0.46;
    // map pupil animation (-1..1) into offset range
    final double dx = _pupilAnimation.value * eyeSize * 0.16;
    final double dy = math.sin(_pupilAnimation.value * math.pi) * eyeSize * 0.06;

    return Stack(
      alignment: Alignment.center,
      children: [
        // eye white (changes when blinking)
        AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: eyeSize,
          height: _isBlinking ? eyeSize * 0.20 : eyeSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textPrimary.withOpacity(0.14), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),

        // pupil (hidden when blinking)
        if (!_isBlinking)
          Transform.translate(
            offset: Offset(dx, dy),
            child: Container(
              width: pupilSize,
              height: pupilSize,
              decoration: BoxDecoration(
                color: _getEyeColor(),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
      ],
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

  // eyebrows removed

  Widget _buildMouth() {
    switch (_currentState) {
      case CharacterState.happy:
      case CharacterState.excited:
      case CharacterState.celebrating:
      case CharacterState.encouraging:
        final double w = widget.size * 0.36 * _smileAnimation.value;
        final double h = widget.size * 0.18 * (_smileAnimation.value.clamp(0.8, 1.0));
        return CustomPaint(
          size: Size(w, h),
          painter: _FilledSmilePainter(color: AppColors.textPrimary),
        );

      case CharacterState.sad:
        return Transform.rotate(
          angle: math.pi,
          child: Container(
            width: widget.size * 0.18,
            height: widget.size * 0.08,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(widget.size * 0.04),
            ),
          ),
        );

      case CharacterState.thinking:
        return Container(
          width: widget.size * 0.10,
          height: widget.size * 0.10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textPrimary,
          ),
        );

      default:
        return Container(
          width: widget.size * 0.14,
          height: widget.size * 0.06,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(widget.size * 0.03),
          ),
        );
    }
  }

  List<Widget> _buildCelebrationEffects() {
    return [
      Positioned(
        top: 0,
        left: widget.size * 0.08,
        child: Icon(
          Icons.star,
          size: widget.size * 0.14,
          color: AppColors.goldStar,
        ),
      ),
      Positioned(
        top: widget.size * 0.12,
        right: widget.size * 0.08,
        child: Icon(
          Icons.favorite,
          size: widget.size * 0.11,
          color: AppColors.funRed,
        ),
      ),
      Positioned(
        bottom: widget.size * 0.12,
        left: widget.size * 0.2,
        child: Icon(
          Icons.celebration,
          size: widget.size * 0.09,
          color: AppColors.funOrange,
        ),
      ),
    ];
  }

  Widget _buildMessageBubble() {
    return Container(
      constraints: BoxConstraints(maxWidth: widget.size * 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        widget.message!,
        maxLines: 3,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
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

// A filled, soft smile painter with highlight and simple teeth
class _FilledSmilePainter extends CustomPainter {
  final Color color;
  _FilledSmilePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double w = size.width;
    final double h = size.height;

    // mouth path - fuller bottom curve
    final Path mouthPath = Path();
    mouthPath.moveTo(0, h * 0.45);
    mouthPath.quadraticBezierTo(w * 0.5, h * 1.05, w, h * 0.45);
    mouthPath.quadraticBezierTo(w * 0.5, h * 0.75, 0, h * 0.45);
    mouthPath.close();

    // subtle shadow under the mouth
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.save();
    canvas.translate(0, h * 0.06);
    canvas.drawPath(mouthPath, shadowPaint);
    canvas.restore();

    // draw mouth
    canvas.drawPath(mouthPath, fillPaint);

    // light stroke highlight
    final Paint strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.06
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final Rect arcRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawArc(arcRect, 0.18 * math.pi, 0.64 * math.pi, false, strokePaint);

    // simple teeth highlight (top inner shape)
    final Paint teethPaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final Path teeth = Path();
    teeth.moveTo(w * 0.17, h * 0.39);
    teeth.quadraticBezierTo(w * 0.5, h * 0.13, w * 0.83, h * 0.39);
    teeth.lineTo(w * 0.83, h * 0.53);
    teeth.quadraticBezierTo(w * 0.5, h * 0.32, w * 0.17, h * 0.53);
    teeth.close();
    canvas.drawPath(teeth, teethPaint);
  }

  @override
  bool shouldRepaint(covariant _FilledSmilePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
