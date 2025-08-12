import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/audio_service.dart';
import '../../services/progress_tracker.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/game_button.dart';
import '../../widgets/star_collect_overlay.dart';
import '../../utils/game_utils.dart';
import '../../widgets/game_result_views.dart';
import '../../l10n/app_localizations.dart';

// ثيمات جولات العد (يجب أن تكون على مستوى الملف وليس داخل الكلاس)
enum _CountingRoundTheme {
  fallingStars,
  passingPlanets,
  jumpingAnimals,
  explodingBubbles,
  flyingKites,
  racingCars,
  swimmingFish,
  dancingButterflies,
  spaceRockets,
  fireworks,
}

class CountingGameScreen extends StatefulWidget {
  const CountingGameScreen({Key? key}) : super(key: key);

  @override
  State<CountingGameScreen> createState() => _CountingGameScreenState();
}

class _CountingGameScreenState extends State<CountingGameScreen>
    with TickerProviderStateMixin {
  static const int _totalRounds = 10;
  int _maxItems = 12;

  // ترتيب جولات موضوعية متنوعة
  static const List<_CountingRoundTheme> _themeOrder = [
    _CountingRoundTheme.fallingStars,
    _CountingRoundTheme.passingPlanets,
    _CountingRoundTheme.jumpingAnimals,
    _CountingRoundTheme.explodingBubbles,
    _CountingRoundTheme.flyingKites,
    _CountingRoundTheme.racingCars,
    _CountingRoundTheme.swimmingFish,
    _CountingRoundTheme.dancingButterflies,
    _CountingRoundTheme.spaceRockets,
    _CountingRoundTheme.fireworks,
  ];

  // تعريف الثيمات موجود أعلى الملف

  final Random _random = Random();

  int _roundIndex = 0;
  int _correctCount = 0;
  int _score = 0;
  int _startTimeMs = 0;

  List<int> _options = [];
  int _answer = -1;
  bool _isAnswered = false;
  bool _isCompleted = false;
  // Timer per round (50s)
  Timer? _roundTimer;
  int _remainingSeconds = 50;
  // Animals round data
  List<String> _animalsInRound = <String>[]; // 'elephant' | 'lion' | 'giraffe'

  AudioService? _audioService;
  ProgressTracker? _progressTracker;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _audioService = await AudioService.getInstance();
    } catch (e) {
      print('Error initializing audio service in counting game: $e');
      // Continue without audio
    }
    
    try {
      _progressTracker = await ProgressTracker.getInstance();
    } catch (e) {
      print('Error initializing progress tracker in counting game: $e');
      // Continue without progress tracking
    }
    
    await _loadAdaptiveDifficulty();
    _startNewGame();
  }

  Future<void> _loadAdaptiveDifficulty() async {
    try {
      if (_progressTracker == null) return;
      final stats = await _progressTracker!.getDetailedStatistics();
      // استخدم الأداء الأخير في لعبة العد لضبط _maxItems
      final gameTypeStats = (stats['gameTypeStats'] as Map<String, dynamic>? ?? {});
      final countingStats = gameTypeStats[AppConstants.countingGame] as Map<String, dynamic>?;
      final avg = (countingStats != null ? (countingStats['averageScore'] ?? 0.0) : 0.0) as double;
      // قواعد بسيطة: أداء ضعيف => أرقام أقل، أداء جيد => أرقام أكثر
      if (avg < 0.5) {
        _maxItems = 8;   // أسهل
      } else if (avg < 0.8) {
        _maxItems = 12;  // متوسط
      } else {
        _maxItems = 15;  // أصعب
      }
    } catch (_) {
      _maxItems = 12;
    }
  }

  void _startNewGame() {
    _roundIndex = 0;
    _correctCount = 0;
    _score = 0;
    _isCompleted = false;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _generateRound();
    setState(() {});
  }

  void _generateRound() {
    // reset round timer
    _roundTimer?.cancel();
    _remainingSeconds = 50;
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted || _isCompleted) {
        t.cancel();
        return;
      }
      if (_isAnswered) return;
      setState(() => _remainingSeconds = max(0, _remainingSeconds - 1));
      if (_remainingSeconds <= 0) {
        t.cancel();
        await _onTimeout();
      }
    });

    final theme = _themeOrder[_roundIndex % _themeOrder.length];
    _animalsInRound = <String>[];

    int correct;
    if (theme == _CountingRoundTheme.jumpingAnimals) {
      // animals scene: count elephants among others
      final totalAnimals = _random.nextInt(min(9, _maxItems - 2)) + 5; // 5..<=11
      final elephants = _random.nextInt(max(1, totalAnimals - 3)) + 1; // >=1
      correct = elephants;
      for (int i = 0; i < elephants; i++) {
        _animalsInRound.add('elephant');
      }
      final pool = ['lion', 'giraffe'];
      while (_animalsInRound.length < totalAnimals) {
        _animalsInRound.add(pool[_random.nextInt(pool.length)]);
      }
      _animalsInRound.shuffle(_random);
    } else {
      correct = _random.nextInt(_maxItems - 2) + 3; // 3.._maxItems
    }

    final allPossibleAnswers = <int>[];
    for (int i = 1; i <= _maxItems; i++) {
      if (i != correct) allPossibleAnswers.add(i);
    }
    allPossibleAnswers.shuffle(_random);
    final wrong1 = allPossibleAnswers[0];
    final wrong2 = allPossibleAnswers[1];
    final options = [correct, wrong1, wrong2]..shuffle(_random);

    _correctCount = correct;
    _options = options;
    _answer = -1;
    _isAnswered = false;
  }

  Future<void> _onTimeout() async {
    if (_roundIndex + 1 >= _totalRounds) {
      await _finishGame();
    } else {
      setState(() {
        _roundIndex++;
        _generateRound();
      });
    }
  }

  Future<void> _selectAnswer(int value) async {
    if (_isAnswered || _isCompleted) return;
    setState(() {
      _answer = value;
      _isAnswered = true;
    });
    _roundTimer?.cancel();

    final isCorrect = value == _correctCount;
    if (isCorrect) {
      _score += AppConstants.pointsPerCorrectAnswer;
      await _audioService?.playCorrectSound();
    } else {
      await _audioService?.playIncorrectSound();
    }

    // Skip delay on the final question to transition immediately
    if (_roundIndex + 1 >= _totalRounds) {
      await _finishGame();
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _roundIndex++;
        _generateRound();
      });
    }
  }

  Future<void> _finishGame() async {
    _roundTimer?.cancel();
    final elapsedSeconds = ((DateTime.now().millisecondsSinceEpoch - _startTimeMs) / 1000).round();

    // Record progress if tracker is available
    try {
      if (_progressTracker != null) {
        // تشغيل في الخلفية حتى لا يحجب الانتقال إلى النجوم
        _progressTracker!.recordGameProgress(
          gameType: AppConstants.countingGame,
          level: 1,
          score: _score,
          maxScore: _totalRounds * AppConstants.pointsPerCorrectAnswer,
          timeSpentSeconds: elapsedSeconds,
          gameData: {
            'rounds': _totalRounds,
            'maxItems': _maxItems,
          },
        );
      }
    } catch (e) {
      print('Error recording game progress: $e');
      // Continue anyway - don't block completion
    }

    // Show stars overlay first, then play end sequence and show result
    try {
      final mx = _totalRounds * AppConstants.pointsPerCorrectAnswer;
      final success = mx > 0 ? (_score / mx) >= AppConstants.passScoreRatio : false;
      await _showStarsThenResult(mx, success);
    } catch (e) {
      print('Error showing stars/result: $e');
    }
  }

  Future<void> _showStarsThenResult(int maxScore, bool success) async {
    if (!mounted) return;
    final int stars = GameUtils.computeStars(score: _score, maxScore: maxScore);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => StarCollectOverlay(
        stars: stars,
        onCompleted: () async {
          entry.remove();
          try { _audioService?.playGameEndSequence(success); } catch (_) {}
          if (!mounted) return;
          setState(() { _isCompleted = true; });
        },
      ),
    );
    Overlay.of(context)?.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: _isCompleted ? _buildResult() : _buildPlayArea(),
                ),
                const SizedBox(height: 16),
                if (_isCompleted)
                  GameButton(
                    text: 'العودة للقائمة',
                    onPressed: () => Navigator.of(context).pop(),
                    backgroundColor: AppColors.buttonSecondary,
                    textColor: AppColors.textSecondary,
                  )
                else
                  GameButton(
                    text: 'تخطي الجولة',
                    onPressed: _isAnswered
                        ? () {
                            if (_roundIndex + 1 >= _totalRounds) {
                              _finishGame();
                            } else {
                              setState(() {
                                _roundIndex++;
                                _generateRound();
                              });
                            }
                          }
                        : () {}, // Empty function instead of null
                    backgroundColor: AppColors.warning,
                    icon: Icons.skip_next,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final maxScore = _totalRounds * AppConstants.pointsPerCorrectAnswer;
    return Row(
      children: [
        GameIconButton(
          icon: Icons.close,
          onPressed: () => Navigator.of(context).pop(),
          size: 45,
          backgroundColor: AppColors.surface,
          iconColor: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'لعبة العد',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'الجولة ${_roundIndex + 1} / $_totalRounds · النقاط $_score / $maxScore',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: _remainingSeconds / 50,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 2),
              const Text('الوقت المتاح: 50 ثانية لكل جولة', style: TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayArea() {
    final theme = _themeOrder[_roundIndex % _themeOrder.length];
    return Column(
      children: [
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final area = Size(
                  min(constraints.maxWidth, constraints.maxHeight) * 0.9,
                  min(constraints.maxWidth, constraints.maxHeight) * 0.9,
                );
                return SizedBox(
                  width: area.width,
                  height: area.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: theme == _CountingRoundTheme.jumpingAnimals
                        ? _buildAnimalsArea(area)
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildThemedBackground(theme),
                              ..._buildAnimatedItemsForTheme(theme, area, _correctCount),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _options
              .map((opt) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ElevatedButton(
                        onPressed: () => _selectAnswer(opt),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: _isAnswered
                              ? (opt == _correctCount
                                  ? AppColors.correct
                                  : (opt == _answer ? AppColors.incorrect : AppColors.buttonSecondary))
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('$opt', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildThemedBackground(_CountingRoundTheme theme) {
    switch (theme) {
      case _CountingRoundTheme.fallingStars:
      case _CountingRoundTheme.spaceRockets:
      case _CountingRoundTheme.fireworks:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0a0f2c), Color(0xFF1b2a6a)],
            ),
          ),
        );
      case _CountingRoundTheme.passingPlanets:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF00111a), Color(0xFF002d40)]),
          ),
        );
      case _CountingRoundTheme.swimmingFish:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0a3d62), Color(0xFF3c6382)]),
          ),
        );
      default:
        return Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        );
    }
  }

  List<Widget> _buildAnimatedItemsForTheme(_CountingRoundTheme theme, Size area, int count) {
    final rnd = Random(_roundIndex + _correctCount);
    final items = <Widget>[];
    for (int i = 0; i < count; i++) {
      final dx = rnd.nextDouble();
      final dy = rnd.nextDouble();
      final delay = (250 + rnd.nextInt(600)).ms;
      final color = _funPalette[i % _funPalette.length];

      switch (theme) {
        case _CountingRoundTheme.fallingStars:
          // one-shot fall and disappear
          items.add(
            Animate(
              delay: delay,
              effects: [
                MoveEffect(
                  begin: Offset(0, -area.height * 0.6),
                  end: Offset(0, area.height * 0.6),
                  duration: 2200.ms,
                  curve: Curves.easeIn,
                ),
                FadeEffect(duration: 300.ms, curve: Curves.easeIn),
              ],
              child: Align(
                alignment: Alignment(-1 + 2 * dx, -1),
                child: Icon(Icons.star, color: Colors.amber.shade300, size: 24 + rnd.nextInt(16).toDouble()),
              ),
            ),
          );
          break;
        case _CountingRoundTheme.passingPlanets:
          items.add(
            Align(
              alignment: Alignment(-1.2, -1 + 2 * dy),
              child: _planet(color: color, size: 26 + rnd.nextInt(18).toDouble())
                  .animate(onPlay: (c) => c.repeat())
                  .moveX(begin: -area.width * 0.45, end: area.width * 0.45, duration: (2200 + rnd.nextInt(800)).ms, curve: Curves.easeInOut)
                  .rotate(begin: 0, end: pi * 2, duration: 2600.ms),
            ),
          );
          break;
        case _CountingRoundTheme.jumpingAnimals:
          // animals drawn in _buildAnimalsArea
          break;
        case _CountingRoundTheme.explodingBubbles:
          items.add(
            Align(
              alignment: Alignment(-1 + 2 * dx, -1 + 2 * dy),
              child: _bubble(color: color)
                  .animate(onPlay: (c) => c.repeat(period: 2000.ms))
                  .scale(begin: const Offset(0.2, 0.2), end: const Offset(1.0, 1.0), duration: 1200.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 400.ms)
                  .then()
                  .fadeOut(duration: 400.ms),
            ),
          );
          break;
        case _CountingRoundTheme.flyingKites:
          items.add(
            Align(
              alignment: Alignment(-1 + 2 * dx, -0.3 + 0.6 * dy),
              child: const Text('🪁', style: TextStyle(fontSize: 28))
                  .animate(onPlay: (c) => c.repeat())
                  .moveX(begin: -12, end: 12, duration: (1800 + rnd.nextInt(900)).ms, curve: Curves.easeInOut)
                  .moveY(begin: -8, end: 8, duration: 1400.ms, curve: Curves.easeInOut),
            ),
          );
          break;
        case _CountingRoundTheme.racingCars:
          items.add(
            Align(
              alignment: Alignment(-1.1, -0.8 + 1.6 * dy),
              child: Icon(Icons.directions_car, color: color, size: 28)
                  .animate(onPlay: (c) => c.repeat())
                  .moveX(begin: -area.width * 0.45, end: area.width * 0.45, duration: (1500 + rnd.nextInt(900)).ms, curve: Curves.easeIn),
            ),
          );
          break;
        case _CountingRoundTheme.swimmingFish:
          items.add(
            Align(
              alignment: Alignment(-1 + 2 * dx, -1 + 2 * dy),
              child: Icon(Icons.pool, color: Colors.white70, size: 22)
                  .animate(onPlay: (c) => c.repeat())
                  .moveX(begin: -18, end: 18, duration: (1800 + rnd.nextInt(800)).ms, curve: Curves.easeInOut)
                  .moveY(begin: -6, end: 6, duration: 1200.ms, curve: Curves.easeInOut),
            ),
          );
          break;
        case _CountingRoundTheme.dancingButterflies:
          items.add(
            Align(
              alignment: Alignment(-1 + 2 * dx, -1 + 2 * dy),
              child: Icon(Icons.auto_awesome, color: Colors.pinkAccent.shade100, size: 20)
                  .animate(onPlay: (c) => c.repeat())
                  .shake(hz: 2, duration: 1200.ms)
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 900.ms),
            ),
          );
          break;
        case _CountingRoundTheme.spaceRockets:
          items.add(
            Align(
              alignment: Alignment(-1 + 2 * dx, 1.1),
              child: Icon(Icons.rocket_launch, color: Colors.orangeAccent, size: 28)
                  .animate(onPlay: (c) => c.repeat())
                  .moveY(begin: 24, end: -120, duration: (1800 + rnd.nextInt(900)).ms, curve: Curves.easeIn)
                  .fadeIn(duration: 200.ms),
            ),
          );
          break;
        case _CountingRoundTheme.fireworks:
          items.add(
            Align(
              alignment: Alignment(-1 + 2 * dx, -1 + 2 * dy),
              child: _fireworkSpark(color)
                  .animate(onPlay: (c) => c.repeat(period: (1400 + rnd.nextInt(600)).ms))
                  .scale(begin: Offset.zero, end: const Offset(1.0, 1.0), duration: 500.ms)
                  .then()
                  .fadeOut(duration: 500.ms),
            ),
          );
          break;
      }
    }
    return items;
  }

  Widget _planet({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.6)]),
        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: 2,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(1)),
        ),
      ),
    );
  }

  Widget _bubble({required Color color}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [Colors.white.withOpacity(0.9), color.withOpacity(0.5)]),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
      ),
    );
  }

  Widget _fireworkSpark(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
        BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 2),
      ]),
    );
  }

  static const List<Color> _funPalette = <Color>[
    AppColors.funRed,
    AppColors.funBlue,
    AppColors.funYellow,
    AppColors.funGreen,
    AppColors.funOrange,
    AppColors.funPurple,
  ];

  static const List<String> _animalEmoji = <String>['🐶', '🐱', '🐭', '🐹', '🐰', '🐻', '🐼', '🐨'];
  
  // Animals grid without emoji
  Widget _buildAnimalsArea(Size area) {
    final cols = 3;
    return Container(
      color: AppColors.surface.withOpacity(0.1),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _animalsInRound.length,
        itemBuilder: (_, i) => _AnimalTile(kind: _animalsInRound[i]),
      ),
    );
  }
  Widget _buildResult() {
    final maxScore = _totalRounds * AppConstants.pointsPerCorrectAnswer;
    final success = maxScore > 0 ? (_score / maxScore) >= AppConstants.passScoreRatio : false;
    final stars = GameUtils.computeStars(score: _score, maxScore: maxScore);
    final view = success
        ? SuccessResultView(
            score: _score,
            maxScore: maxScore,
            stars: stars,
            onRetry: _startNewGame,
            onBack: () => Navigator.of(context).pop(),
          )
        : FailureResultView(
            score: _score,
            maxScore: maxScore,
            stars: stars,
            onRetry: _startNewGame,
            onBack: () => Navigator.of(context).pop(),
          );
    return view;
  }
}

class _AnimalTile extends StatelessWidget {
  final String kind; // 'elephant' | 'lion' | 'giraffe'
  const _AnimalTile({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: CustomPaint(
        painter: _AnimalPainter(kind),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AnimalPainter extends CustomPainter {
  final String kind;
  _AnimalPainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case 'elephant':
        _paintElephant(canvas, size);
        break;
      case 'lion':
        _paintLion(canvas, size);
        break;
      case 'giraffe':
        _paintGiraffe(canvas, size);
        break;
    }
  }

  void _paintElephant(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFF9ea7ad);
    final head = Paint()..color = const Color(0xFF8d969c);
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.35, w * 0.6, h * 0.4), const Radius.circular(12)),
      body,
    );
    canvas.drawCircle(Offset(w * 0.68, h * 0.45), w * 0.14, head);
    final trunk = Path()
      ..moveTo(w * 0.76, h * 0.48)
      ..quadraticBezierTo(w * 0.9, h * 0.55, w * 0.8, h * 0.7)
      ..quadraticBezierTo(w * 0.72, h * 0.78, w * 0.68, h * 0.72)
      ..close();
    canvas.drawPath(trunk, head);
  }

  void _paintLion(Canvas canvas, Size size) {
    final mane = Paint()..color = const Color(0xFFb26a2a);
    final face = Paint()..color = const Color(0xFFf9c784);
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.28, mane);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.2, face);
  }

  void _paintGiraffe(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFFf4d35e);
    final spots = Paint()..color = const Color(0xFFe09f3e);
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, h * 0.45, w * 0.5, h * 0.3), const Radius.circular(8)),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.6, h * 0.2, w * 0.1, h * 0.35), const Radius.circular(6)),
      body,
    );
    for (int i = 0; i < 5; i++) {
      final dx = (0.3 + 0.4 * (i % 3) / 3) * w;
      final dy = (0.5 + 0.25 * (i ~/ 3)) * h;
      canvas.drawCircle(Offset(dx, dy), w * 0.04, spots);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


