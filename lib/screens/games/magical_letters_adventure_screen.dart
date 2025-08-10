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
  final Set<int> _collected = {};
  int _score = 0;
  late AnimationController _bgController;

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
      _alphabet = data.take(12).toList(); // خريطة مبسطة للنسخة الأولى
      _loading = false;
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _onCollect(int index) async {
    if (_collected.contains(index)) return;
    setState(() {
      _collected.add(index);
      _score += AppConstants.pointsPerCorrectAnswer;
    });
    try {
      await _audioService?.playCorrectSound();
    } catch (_) {}

    if (_collected.length == _alphabet.length) {
      // سجل تقدّم مبسّط للمستوى الأول
      try {
        await _progressTracker?.recordGameProgress(
          gameType: AppConstants.alphabetGame,
          level: 1,
          score: _score,
          maxScore: _alphabet.length * AppConstants.pointsPerCorrectAnswer,
          timeSpentSeconds: 60,
          gameData: {
            'collected': _collected.length,
          },
        );
      } catch (_) {}

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('أحسنت!'),
          content: const Text('جمعت جميع الحروف!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    }
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
            child: Text(
              'مغامرة الحروف السحرية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
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
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _alphabet.length,
                itemBuilder: (context, index) {
                  final item = _alphabet[index];
                  final collected = _collected.contains(index);
                  return _LetterTile(
                    letter: item['letter'] ?? '',
                    name: item['name'] ?? '',
                    collected: collected,
                    onTap: () => _onCollect(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterTile extends StatefulWidget {
  final String letter;
  final String name;
  final bool collected;
  final VoidCallback onTap;

  const _LetterTile({
    required this.letter,
    required this.name,
    required this.collected,
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
                color: widget.collected ? Colors.white.withOpacity(0.35) : AppColors.surface,
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
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.letter,
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.name,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
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


