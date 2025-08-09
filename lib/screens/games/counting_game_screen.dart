import 'dart:math';

import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/progress_tracker.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/game_button.dart';

class CountingGameScreen extends StatefulWidget {
  const CountingGameScreen({Key? key}) : super(key: key);

  @override
  State<CountingGameScreen> createState() => _CountingGameScreenState();
}

class _CountingGameScreenState extends State<CountingGameScreen>
    with TickerProviderStateMixin {
  static const int _totalRounds = 10;
  static const int _maxItems = 12;

  final Random _random = Random();

  int _roundIndex = 0;
  int _correctCount = 0;
  int _score = 0;
  int _startTimeMs = 0;

  List<int> _options = [];
  int _answer = -1;
  bool _isAnswered = false;
  bool _isCompleted = false;

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
    
    _startNewGame();
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
    final correct = _random.nextInt(_maxItems - 2) + 3; // 3..12
    
    // Create a list of all possible wrong answers
    final allPossibleAnswers = <int>[];
    for (int i = 1; i <= _maxItems; i++) {
      if (i != correct) {
        allPossibleAnswers.add(i);
      }
    }
    
    // Shuffle and take first 2 as wrong answers
    allPossibleAnswers.shuffle(_random);
    final wrong1 = allPossibleAnswers[0];
    final wrong2 = allPossibleAnswers[1];

    final options = [correct, wrong1, wrong2]..shuffle(_random);

    _correctCount = correct;
    _options = options;
    _answer = -1;
    _isAnswered = false;
  }

  Future<void> _selectAnswer(int value) async {
    if (_isAnswered || _isCompleted) return;
    setState(() {
      _answer = value;
      _isAnswered = true;
    });

    final isCorrect = value == _correctCount;
    if (isCorrect) {
      _score += AppConstants.pointsPerCorrectAnswer;
      await _audioService?.playCorrectSound();
    } else {
      await _audioService?.playIncorrectSound();
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (_roundIndex + 1 >= _totalRounds) {
      await _finishGame();
    } else {
      setState(() {
        _roundIndex++;
        _generateRound();
      });
    }
  }

  Future<void> _finishGame() async {
    final elapsedSeconds = ((DateTime.now().millisecondsSinceEpoch - _startTimeMs) / 1000).round();
    setState(() {
      _isCompleted = true;
    });

    // Record progress if tracker is available
    try {
      if (_progressTracker != null) {
        await _progressTracker!.recordGameProgress(
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

    // Play end sequence if audio is available
    try {
      if (_audioService != null) {
        await _audioService!.playGameEndSequence(true);
      }
    } catch (e) {
      print('Error playing end sequence: $e');
      // Continue anyway
    }
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayArea() {
    return Column(
      children: [
        // Items grid
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = min(constraints.maxWidth, constraints.maxHeight) * 0.8;
                final crossAxisCount = _correctCount <= 6 ? 3 : 4;
                return SizedBox(
                  width: size,
                  height: size,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _correctCount,
                    itemBuilder: (_, i) => _buildItemBubble(i),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Options row
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
                        child: Text(
                          '$opt',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildItemBubble(int index) {
    final palette = [
      AppColors.funRed,
      AppColors.funBlue,
      AppColors.funYellow,
      AppColors.funGreen,
      AppColors.funOrange,
      AppColors.funPurple,
    ];
    final color = palette[index % palette.length];
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.9),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: const Center(
        child: Icon(Icons.circle, size: 0, color: Colors.transparent),
      ),
    );
  }

  Widget _buildResult() {
    final maxScore = _totalRounds * AppConstants.pointsPerCorrectAnswer;
    final percent = maxScore > 0 ? _score / maxScore : 0.0;
    int stars = 0;
    if (percent >= 0.9) {
      stars = 3;
    } else if (percent >= 0.7) {
      stars = 2;
    } else if (percent >= 0.5) {
      stars = 1;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'أحسنت!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => Icon(i < stars ? Icons.star : Icons.star_border, color: AppColors.goldStar, size: 28)),
        ),
        const SizedBox(height: 12),
        Text('نتيجتك: $_score / $maxScore', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        GameButton(
          text: 'العب مجدداً',
          onPressed: _startNewGame,
          backgroundColor: AppColors.primary,
          icon: Icons.refresh,
        ),
      ],
    );
  }
}


