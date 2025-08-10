import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../services/audio_service.dart';
import '../../services/progress_tracker.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/animated_character.dart';
import '../../widgets/game_button.dart';

class MagicalLettersAdventureScreen extends StatefulWidget {
  const MagicalLettersAdventureScreen({Key? key}) : super(key: key);

  @override
  State<MagicalLettersAdventureScreen> createState() => _MagicalLettersAdventureScreenState();
}

class _MagicalLettersAdventureScreenState extends State<MagicalLettersAdventureScreen>
    with TickerProviderStateMixin {
  final DataService _dataService = DataService.instance;
  AudioService? _audioService;
  ProgressTracker? _progressTracker;

  bool _loading = true;
  List<Map<String, String>> _alphabet = [];
  // جولات وتحدّي الحرف المستهدف
  int _round = 1;
  final int _totalRounds = 3;
  String _targetLetter = '';
  int _targetsToCollect = 3;
  int _targetsCollected = 0;
  int _mistakes = 0;
  int _score = 0;
  // شبكة الجولة الحالية (حروف)
  List<String> _gridLetters = [];
  Set<int> _disabledIndexes = {};
  Set<int> _revealedTempIndexes = {};
  late final Stopwatch _stopwatch = Stopwatch();
  late AnimationController _bgController;
  // عدّاد الوقت
  static const int _initialSeconds = 40;
  int _remainingSeconds = _initialSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    _init();
  }

  Future<void> _init() async {
    try {
      _audioService = await AudioService.getInstance();
    } catch (_) {}
    try {
      _progressTracker = await ProgressTracker.getInstance();
    } catch (_) {}
    final data = await _dataService.loadAlphabetData();
    if (!mounted) return;
    setState(() {
      _alphabet = data.take(16).toList(); // مجموعة أولية
      _loading = false;
    });
    _startGame();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _stopwatch
      ..reset()
      ..start();
    _round = 1;
    _score = 0;
    _mistakes = 0;
    _remainingSeconds = _initialSeconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds = (_remainingSeconds - 1).clamp(0, _initialSeconds);
      });
      if (_remainingSeconds <= 0) {
        _onTimeout();
      }
    });
    _startRound();
  }

  void _startRound() {
    // اختر حرفاً مستهدفاً عشوائياً
    final letters = _alphabet.map((m) => m['letter'] ?? '').where((e) => e.isNotEmpty).toList();
    letters.shuffle();
    _targetLetter = letters.first;
    _targetsToCollect = 3;
    _targetsCollected = 0;
    _disabledIndexes.clear();

    // ابنِ شبكة 12 خانة مع 3 أهداف والباقي مشتتات
    final List<String> grid = [];
    grid.addAll(List.filled(_targetsToCollect, _targetLetter));
    final distractors = letters.where((l) => l != _targetLetter).toList()..shuffle();
    for (int i = 0; i < 12 - _targetsToCollect; i++) {
      grid.add(distractors[i % distractors.length]);
    }
    grid.shuffle();

    setState(() {
      _gridLetters = grid;
    });
  }

  Future<void> _onTapTile(int index) async {
    if (_disabledIndexes.contains(index)) return;
    final letter = _gridLetters[index];
    // اكشف الحرف مؤقتاً
    setState(() {
      _revealedTempIndexes.add(index);
    });

    if (letter == _targetLetter) {
      setState(() {
        _disabledIndexes.add(index);
        _targetsCollected += 1;
        _score = (_score + AppConstants.pointsPerCorrectAnswer);
      });
      try {
        await _audioService?.playCorrectSound();
      } catch (_) {}

      if (_targetsCollected >= _targetsToCollect) {
        // الجولة انتهت
        if (_round < _totalRounds) {
          _round += 1;
          _startRound();
        } else {
          await _finishGame();
        }
      }
    } else {
      setState(() {
        _mistakes += 1;
        _score = (_score - 5).clamp(0, 1 << 30);
      });
      try {
        await _audioService?.playIncorrectSound();
      } catch (_) {}
      // إخفاء الكشف المؤقت بعد فترة قصيرة إذا لم يكن الهدف
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        if (!_disabledIndexes.contains(index)) {
          _revealedTempIndexes.remove(index);
        }
      });
    }
  }

  Future<void> _finishGame() async {
    _stopwatch.stop();
    _countdownTimer?.cancel();
    final timeSeconds = _stopwatch.elapsed.inSeconds;
    final maxScore = _totalRounds * _targetsToCollect * AppConstants.pointsPerCorrectAnswer;
    try {
      await _progressTracker?.recordGameProgress(
        gameType: AppConstants.alphabetGame,
        level: 1,
        score: _score,
        maxScore: maxScore,
        timeSpentSeconds: timeSeconds == 0 ? 1 : timeSeconds,
        gameData: {
          'rounds': _totalRounds,
          'mistakes': _mistakes,
        },
      );
    } catch (_) {}

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('أحسنت!'),
        content: Text('انتهت المغامرة! نتيجتك: $_score / $maxScore'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('متابعة')),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _onTimeout() async {
    _countdownTimer?.cancel();
    _stopwatch.stop();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('فشلت في المهمة يا بطل'),
        content: const Text('ولكن نحن متأكدون أنك ستنجح في المحاولة الأخرى! انطلق 🚀'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGame();
            },
            child: const Text('إعادة المحاولة'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildAnimatedBackground(),
              Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 8),
                  _buildMeadow(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GameIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
            size: 45,
            backgroundColor: AppColors.surface,
            iconColor: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: SizedBox.shrink(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'النقاط $_score',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final t = _bgController.value;
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _MagicalSkyPainter(t: t),
        );
      },
    );
  }

  Widget _buildMeadow() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const AnimatedCharacter(
              state: CharacterState.encouraging,
              size: 90,
              showMessage: false,
              motionStyle: MotionStyle.gentle,
            ),
            const SizedBox(height: 12),
            _buildPrompt(),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _gridLetters.length,
                itemBuilder: (context, index) {
                  final letter = _gridLetters[index];
                  final collected = _disabledIndexes.contains(index);
                  final revealed = collected || _revealedTempIndexes.contains(index);
                  return _LetterTile(
                    letter: letter,
                    name: _nameForLetter(letter),
                    collected: collected,
                    revealed: revealed,
                    onTap: () => _onTapTile(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nameForLetter(String letter) {
    final found = _alphabet.firstWhere(
      (e) => (e['letter'] ?? '') == letter,
      orElse: () => const {'name': ''},
    );
    return found['name'] ?? '';
  }

  Widget _buildPrompt() {
    final double progress = _remainingSeconds / _initialSeconds;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'الجولة $_round/$_totalRounds • ابحث عن الحرف: $_targetLetter',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.funOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('المتبقي: ${(_targetsToCollect - _targetsCollected).clamp(0, 99)}'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('الوقت: $_remainingSeconds ث'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: progress,
                    backgroundColor: Colors.black.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LetterTile extends StatefulWidget {
  final String letter;
  final String name;
  final bool collected;
  final bool revealed;
  final VoidCallback onTap;

  const _LetterTile({
    required this.letter,
    required this.name,
    required this.collected,
    required this.revealed,
    required this.onTap,
  });

  @override
  State<_LetterTile> createState() => _LetterTileState();
}

class _LetterTileState extends State<_LetterTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppConstants.shortAnimation);
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _LetterTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.collected && !oldWidget.collected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.collected ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.collected
                    ? Colors.white.withOpacity(0.35)
                    : (widget.revealed ? AppColors.surface : Colors.white),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (widget.revealed)
                    Center(
                      child: Text(
                        widget.letter,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Icon(Icons.local_florist,
                          size: 28, color: AppColors.textSecondary.withOpacity(0.6)),
                    ),
                  if (widget.collected)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Icon(Icons.auto_awesome, color: AppColors.goldStar.withOpacity(0.9)),
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

class _MagicalSkyPainter extends CustomPainter {
  final double t;
  _MagicalSkyPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // خلفية تدرّج سماء
    final Rect rect = Offset.zero & size;
    final Paint bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF87CEEB), Color(0xFFDDA0DD)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // سحب لطيفة
    final Paint cloud = Paint()..color = Colors.white.withOpacity(0.85);
    for (int i = 0; i < 4; i++) {
      final double y = size.height * (0.12 + i * 0.16);
      final double x = (size.width * (0.2 + 0.6 * ((t + i * 0.23) % 1))) - 60;
      _drawCloud(canvas, Offset(x, y));
    }

    // نجوم وميض
    final Paint star = Paint()..color = const Color(0xFFFFD700).withOpacity(0.7 + 0.3 * math.sin(t * math.pi * 2));
    for (int i = 0; i < 12; i++) {
      final double x = (i * 0.08 * size.width + (t * 40) % size.width) % size.width;
      final double y = size.height * (0.05 + (i % 3) * 0.08);
      canvas.drawCircle(Offset(x, y), 2.2, star);
    }
  }

  void _drawCloud(Canvas canvas, Offset origin) {
    final r = 18.0;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(origin.dx, origin.dy, 120, 34), Radius.circular(r)))
      ..addOval(Rect.fromCircle(center: origin + const Offset(16, -8), radius: 20))
      ..addOval(Rect.fromCircle(center: origin + const Offset(40, -14), radius: 24))
      ..addOval(Rect.fromCircle(center: origin + const Offset(74, -10), radius: 18));
    final paint = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MagicalSkyPainter oldDelegate) => oldDelegate.t != t;
}


