import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:lottie/lottie.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../services/audio_service.dart';
import '../services/local_storage.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
// Removed splash-specific audio calls per requirements
// import '../services/audio_service.dart';
import 'home_screen.dart';
import 'auth/login_screen.dart';
import '../widgets/animated_character.dart';

class SplashScreen extends StatefulWidget {
  final bool renderOnly; // عند true: عرض فقط بدون تنقّل
  const SplashScreen({Key? key, this.renderOnly = false}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _bgController;
  late AnimationController _countdownController; 
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _bgT;
  late Animation<double> _countdownT;
  bool _navigated = false;
  
  String _loadingText = 'جاري التحميل...';
  late Future<void> _servicesFuture;

  // Motivational phrases
  final List<String> _phrases = const [
    'لنبدأ رحلة التعلم الممتعة!',
    'استكشف، تعلم، وابدع!',
    'كل خطوة تعلم تقربك من النجاح!',
  ];
  int _phraseIndex = 0;
  Timer? _phraseTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.renderOnly) {
      // تشغيل مؤثرات بسيطة فقط بدون تنقّل
      _logoController.forward();
      _textController.forward();
      _countdownController.forward();
      _phraseTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        if (!mounted) return;
        setState(() => _phraseIndex = (_phraseIndex + 1) % _phrases.length);
      });
    } else {
      _startLoadingSequence();
    }
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));
    
    // Background waves
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _bgT = CurvedAnimation(parent: _bgController, curve: Curves.linear);

    // 7-second countdown animation
    _countdownController = AnimationController(vsync: this, duration: const Duration(seconds: 7));
    _countdownT = CurvedAnimation(parent: _countdownController, curve: Curves.linear);
  }

  Future<void> _startLoadingSequence() async {
    // Start animations immediately
    _logoController.forward();
    _textController.forward();
    // ابدأ موسيقى الخلفية فورًا عند شاشة الترحيب (بدون انتظار حتى لا نحجب الانتقال)
    unawaited((() async {
      try {
        final audio = await AudioService.getInstance();
        await audio.playBackgroundMusic();
      } catch (_) {}
    })());

    // Rotatgit push origin main
e phrases every 1.5s
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      setState(() => _phraseIndex = (_phraseIndex + 1) % _phrases.length);
    });

    // Kick off services and countdown in parallel, then navigate when both done
    _servicesFuture = _initializeServicesWithProgress();
    // زمن عرض ثابت 7 ثوانٍ كما هو مطلوب
    final countdownFuture = Future.delayed(const Duration(seconds: 5));
    // Start countdown animation
    _countdownController.forward();
    // ضمان عدم التعليق: انتقال احتياطي بعد 8 ثوانٍ كحد أقصى
    unawaited(Future.delayed(const Duration(seconds: 8), () {
      if (!mounted || _navigated) return;
      _performNavigation();
    }));
    await Future.wait([_servicesFuture, countdownFuture]);

    if (!mounted || _navigated) return;
    _performNavigation();
  }

  void _performNavigation() {
    if (_navigated || !mounted) return;
    _navigated = true;
    
    final bool isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isLoggedIn;
    final Widget target = isLoggedIn ? const HomeScreen() : const LoginScreen();
    
    // انتقال فوري بدون مؤثرات أو إعادة تركيب ثقيلة
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => target,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ));
  }

  Future<void> _initializeServicesWithProgress() async {
    try {
      setState(() => _loadingText = 'تحضير البيانات...');
      await LocalStorageService.getInstance();
      // إزالة التأخيرات الاصطناعية
      
      setState(() => _loadingText = 'جاهز للبدء!');
      // إزالة كل التأخيرات غير الضرورية

    } catch (e) {
      print('Error initializing services: $e');
      setState(() => _loadingText = 'حدث خطأ في التحميل');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _bgController.dispose();
    _countdownController.dispose();
    _phraseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dynamic background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgT,
              builder: (_, __) => CustomPaint(
                painter: _WaveBackgroundPainter(t: _bgT.value),
              ),
            ),
          ),
          // Content
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with countdown ring
                        AnimatedBuilder(
                          animation: Listenable.merge([_logoController, _countdownT]),
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: CircularProgressIndicator(
                                    value: _countdownT.value,
                                    strokeWidth: 6,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    backgroundColor: Colors.white.withOpacity(0.25),
                                  ),
                                ),
                                Transform.scale(
                                  scale: _logoScaleAnimation.value,
                                  child: SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Lottie.asset(
                                      'assets/lottie/welcome.json',
                                      repeat: true,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // App Name and motivational phrase
                        FadeTransition(
                          opacity: _textFadeAnimation,
                          child: Column(
                            children: [
                              Text(
                                AppConstants.appName(context),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                                child: Text(
                                  _phrases[_phraseIndex],
                                  key: ValueKey(_phraseIndex),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF1ABC9C), // أخضر مائل للأزرق (Teal)
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        
                        // Bottom animation - NO DELAY
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: Lottie.asset(
                            'assets/lottie/SandyLoading.json',
                            key: const ValueKey('sandy_loading'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Loading section (text only)
                        FadeTransition(
                          opacity: _textFadeAnimation,
                          child: Text(
                            _loadingText,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'الإصدار ${AppConstants.appVersion}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveBackgroundPainter extends CustomPainter {
  final double t; // 0..1
  _WaveBackgroundPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF9ADCF7), Color(0xFFEFD3FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    final wavePaint1 = Paint()..color = Colors.white.withOpacity(0.25);
    final wavePaint2 = Paint()..color = Colors.white.withOpacity(0.18);

    void drawWave(Paint p, double amp, double yBase, double speed, double freq) {
      final path = Path()..moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 4) {
        final y = yBase + amp * math.sin((x / size.width * freq * 2 * math.pi) + (t * speed * 2 * math.pi));
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, p);
    }

    drawWave(wavePaint1, 18, size.height * 0.35, 0.5, 1.5);
    drawWave(wavePaint2, 24, size.height * 0.55, 0.8, 2.2);
    drawWave(wavePaint1, 14, size.height * 0.75, 1.1, 1.0);
  }

  @override
  bool shouldRepaint(covariant _WaveBackgroundPainter oldDelegate) => oldDelegate.t != t;
}

// Ripple effect classes are removed for brevity as they are not part of the core logic change.
// You can keep them in your actual code.
class _RippleData {
  final Key key;
  final Offset position;
  _RippleData({required this.key, required this.position});
}

class _Ripple extends StatelessWidget {
  final Offset position;
  final VoidCallback onEnd;
  const _Ripple({super.key, required this.position, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      onEnd: onEnd,
      builder: (_, value, __) {
        final double radius = 20 + 60 * value;
        final double opacity = (1.0 - value).clamp(0.0, 1.0);
        return Positioned(
          left: position.dx - radius,
          top: position.dy - radius,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.6 * opacity), width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
