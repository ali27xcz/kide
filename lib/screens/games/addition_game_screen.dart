import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/progress_tracker.dart';
import '../../services/audio_service.dart';
import '../../widgets/result_flow.dart';

class AdditionGameScreen extends StatefulWidget {
  const AdditionGameScreen({Key? key}) : super(key: key);

  @override
  State<AdditionGameScreen> createState() => _AdditionGameScreenState();
}

class _AdditionGameScreenState extends State<AdditionGameScreen>
    with TickerProviderStateMixin {
  static const int _totalRounds = 10;
  static const int _perQuestionSeconds = 12; // للتحدي الزمني

  final Random _random = Random();

  int _a = 1;
  int _b = 1;
  int _c = 0; // للمرحلة الصعبة (ثلاثة أعداد)
  bool _useThreeNumbers = false;

  int _roundIndex = 0;
  int _score = 0;
  int _startTimeMs = 0;
  bool _isAnswered = false;
  bool _isCompleted = false;
  bool _isCorrect = false;

  final _controller = TextEditingController();

  ProgressTracker? _progressTracker;
  AudioService? _audioService;

  late AnimationController _feedbackAnimationController;
  late Animation<double> _feedbackScaleAnimation;

  Timer? _countdown;
  int _remainingSeconds = _perQuestionSeconds;

  _AddDifficulty _difficulty = _AddDifficulty.easy;

  @override
  void initState() {
    super.initState();
    _init();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _feedbackScaleAnimation = Tween<double>(begin: 0.0, end: 1.1).animate(
      CurvedAnimation(parent: _feedbackAnimationController, curve: Curves.elasticOut),
    );
  }

  Future<void> _init() async {
    try {
      _audioService = await AudioService.getInstance();
    } catch (_) {}
    try {
      _progressTracker = await ProgressTracker.getInstance();
    } catch (_) {}
    _startNewGame();
  }

  void _startNewGame() {
    _roundIndex = 0;
    _score = 0;
    _isCompleted = false;
    _isAnswered = false;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _generateQuestion();
    _restartCountdown();
    setState(() {});
  }

  void _restartCountdown() {
    _countdown?.cancel();
    _remainingSeconds = _perQuestionSeconds;
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted || _isCompleted) {
        t.cancel();
        return;
      }
      if (_isAnswered) return; // توقف العد أثناء عرض التغذية الراجعة
      setState(() => _remainingSeconds = (_remainingSeconds - 1).clamp(0, _perQuestionSeconds));
      if (_remainingSeconds <= 0) {
        // انتهى الوقت
        await _onAnswered(correct: false);
      }
    });
  }

  void _generateQuestion() {
    _controller.clear();
    _useThreeNumbers = false;
    switch (_difficulty) {
      case _AddDifficulty.easy:
        _a = 1 + _random.nextInt(10);
        _b = 1 + _random.nextInt(10);
        _c = 0;
        break;
      case _AddDifficulty.medium:
        // أعداد أكبر مع احتمال الحمل
        int aUnits = 1 + _random.nextInt(9);
        int bUnits = (10 - aUnits) + _random.nextInt(1 + aUnits); // يزيد احتمال الحمل
        _a = 10 + _random.nextInt(40); // 10..49
        _a = (_a ~/ 10) * 10 + aUnits;
        _b = 10 + _random.nextInt(40);
        _b = (_b ~/ 10) * 10 + (bUnits % 10);
        _c = 0;
        break;
      case _AddDifficulty.hard:
        // ثلاثة أعداد 1..30
        _useThreeNumbers = true;
        _a = 5 + _random.nextInt(26);
        _b = 5 + _random.nextInt(26);
        _c = 5 + _random.nextInt(26);
        break;
    }
  }

  Future<void> _submit() async {
    if (_isCompleted || _isAnswered) return;
    final ans = int.tryParse(_controller.text.trim());
    final target = _useThreeNumbers ? (_a + _b + _c) : (_a + _b);
    final correct = ans != null && ans == target;
    await _onAnswered(correct: correct);
  }

  Future<void> _onAnswered({required bool correct}) async {
    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
      if (correct) {
        _score += AppConstants.pointsPerCorrectAnswer;
      }
    });

    // صوت وتغذية راجعة
    try {
      if (correct) {
        await _audioService?.playCorrectSound();
      } else {
        await _audioService?.playIncorrectSound();
      }
    } catch (_) {}
    _feedbackAnimationController
      ..reset()
      ..forward();

    await Future.delayed(const Duration(milliseconds: 900));

    if (_roundIndex + 1 >= _totalRounds) {
      await _finishGame();
    } else {
      setState(() {
        _roundIndex++;
        _isAnswered = false;
        _isCorrect = false;
        _generateQuestion();
        _restartCountdown();
      });
    }
  }

  Future<void> _finishGame() async {
    _countdown?.cancel();
    final elapsedSeconds =
        ((DateTime.now().millisecondsSinceEpoch - _startTimeMs) / 1000).round();
    setState(() => _isCompleted = true);

    try {
      if (_progressTracker != null) {
        // تشغيل في الخلفية حتى لا يحجب الانتقال إلى النجوم
        _progressTracker!.recordGameProgress(
          gameType: AppConstants.additionGame,
          level: _difficulty.index + 1,
          score: _score,
          maxScore: _totalRounds * AppConstants.pointsPerCorrectAnswer,
          timeSpentSeconds: elapsedSeconds,
          gameData: {
            'difficulty': _difficulty.name,
            'rounds': _totalRounds,
            'timed': true,
          },
        );
      }
    } catch (_) {}
    final maxScore = _totalRounds * AppConstants.pointsPerCorrectAnswer;
    if (!mounted) return;
    await ResultFlow.showStarsThenResult(
      context: context,
      score: _score,
      maxScore: maxScore,
      onPlayAgain: _startNewGame,
      onBackToMenu: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: _isCompleted ? _buildResult() : _buildPlayArea(),
                ),
                const SizedBox(height: 12),
                if (!_isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check),
                      label: const Text('تحقق'),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('العودة للقائمة'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startNewGame,
                          icon: const Icon(Icons.refresh),
                          label: const Text('العب مجدداً'),
                        ),
                      ),
                    ],
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
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
        const Text('لعبة الجمع', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$_score / $maxScore'),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, size: 18, color: Colors.white),
              const SizedBox(width: 4),
              Text('$_remainingSeconds', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<_AddDifficulty>(
          value: _difficulty,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: _AddDifficulty.easy, child: Text('سهل')),
            DropdownMenuItem(value: _AddDifficulty.medium, child: Text('متوسط')),
            DropdownMenuItem(value: _AddDifficulty.hard, child: Text('صعب')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _difficulty = v);
            _startNewGame();
          },
        ),
      ],
    );
  }

  Widget _buildPlayArea() {
    final expression = _useThreeNumbers
        ? '$_a + $_b + $_c = ?'
        : '$_a + $_b = ?';
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(expression, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: _remainingSeconds / _perQuestionSeconds,
              backgroundColor: Colors.black.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: 'الإجابة',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: 12),
        if (_isAnswered)
          AnimatedBuilder(
            animation: _feedbackAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _feedbackScaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isCorrect ? AppColors.correct : AppColors.incorrect,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isCorrect ? Icons.check_circle : Icons.cancel, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(_isCorrect ? 'أحسنت!' : 'حاول مرة أخرى',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildResult() => const SizedBox.shrink();

  @override
  void dispose() {
    _countdown?.cancel();
    _feedbackAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }
}


enum _AddDifficulty { easy, medium, hard }


