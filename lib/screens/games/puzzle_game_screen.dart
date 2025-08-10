import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/progress_tracker.dart';
import '../../services/data_service.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/game_button.dart';

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({Key? key}) : super(key: key);

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen>
    with TickerProviderStateMixin {
  static const int _totalPuzzles = 10;
  
  // Educational puzzles data loaded from JSON
  List<Map<String, dynamic>> _puzzles = [];


  final Random _random = Random();
  late AnimationController _puzzleAnimationController;
  late AnimationController _feedbackAnimationController;
  late AnimationController _hintAnimationController;
  late Animation<double> _puzzleSlideAnimation;
  late Animation<double> _puzzleFadeAnimation;
  late Animation<double> _feedbackScaleAnimation;
  late Animation<double> _hintShakeAnimation;

  int _puzzleIndex = 0;
  int _correctAnswers = 0;
  int _score = 0;
  int _startTimeMs = 0;
  int _hintsUsed = 0;
  
  // Current puzzle data
  Map<String, dynamic> _currentPuzzle = {};
  String _selectedAnswer = '';
  bool _isAnswered = false;
  bool _isCompleted = false;
  bool _isCorrect = false;
  bool _showHint = false;
  List<Map<String, dynamic>> _gamePuzzles = [];

  AudioService? _audioService;
  ProgressTracker? _progressTracker;
  DataService? _dataService;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initialize();
  }

  void _initializeAnimations() {
    _puzzleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _hintAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _puzzleSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _puzzleAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _puzzleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _puzzleAnimationController,
      curve: Curves.easeInOut,
    ));

    _feedbackScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.elasticOut,
    ));

    _hintShakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hintAnimationController,
      curve: Curves.elasticInOut,
    ));
  }

  Future<void> _initialize() async {
    try {
      _audioService = await AudioService.getInstance();
    } catch (e) {
      print('Error initializing audio service in puzzle game: $e');
    }
    
    try {
      _progressTracker = await ProgressTracker.getInstance();
    } catch (e) {
      print('Error initializing progress tracker in puzzle game: $e');
    }
    
    try {
      _dataService = DataService.instance;
      _puzzles = await _dataService!.loadPuzzlesData();
    } catch (e) {
      print('Error loading puzzles data: $e');
    }
    
    _startNewGame();
  }

  void _startNewGame() {
    _puzzleIndex = 0;
    _correctAnswers = 0;
    _score = 0;
    _hintsUsed = 0;
    _isCompleted = false;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    
    // Select random puzzles for this game
    _gamePuzzles = List.from(_puzzles);
    _gamePuzzles.shuffle(_random);
    _gamePuzzles = _gamePuzzles.take(_totalPuzzles).toList();
    
    _loadPuzzle();
    setState(() {});
  }

  void _loadPuzzle() {
    _currentPuzzle = _gamePuzzles[_puzzleIndex];
    _selectedAnswer = '';
    _isAnswered = false;
    _isCorrect = false;
    _showHint = false;
    
    // Shuffle options
    final options = List<String>.from(_currentPuzzle['options']);
    options.shuffle(_random);
    _currentPuzzle = Map.from(_currentPuzzle);
    _currentPuzzle['options'] = options;
    
    // Start animations
    _puzzleAnimationController.reset();
    _puzzleAnimationController.forward();
  }

  Future<void> _selectAnswer(String answer) async {
    if (_isAnswered || _isCompleted) return;
    
    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
      _isCorrect = answer == _currentPuzzle['answer'];
    });

    if (_isCorrect) {
      _correctAnswers++;
      final basePoints = AppConstants.pointsPerCorrectAnswer;
      final hintPenalty = _showHint ? (basePoints * 0.3).round() : 0;
      _score += basePoints - hintPenalty;
      await _audioService?.playCorrectSound();
    } else {
      await _audioService?.playIncorrectSound();
    }

    // Start feedback animation
    _feedbackAnimationController.reset();
    _feedbackAnimationController.forward();

    await Future.delayed(const Duration(milliseconds: 1500));

    if (_puzzleIndex + 1 >= _totalPuzzles) {
      await _finishGame();
    } else {
      setState(() {
        _puzzleIndex++;
        _loadPuzzle();
      });
    }
  }

  void _showHintAnimation() {
    if (!_showHint && !_isAnswered) {
      setState(() {
        _showHint = true;
        _hintsUsed++;
      });
      _hintAnimationController.reset();
      _hintAnimationController.forward();
    }
  }

  Future<void> _finishGame() async {
    final elapsedSeconds = ((DateTime.now().millisecondsSinceEpoch - _startTimeMs) / 1000).round();
    setState(() {
      _isCompleted = true;
    });

    try {
      if (_progressTracker != null) {
        await _progressTracker!.recordGameProgress(
          gameType: AppConstants.puzzleGame,
          level: 1,
          score: _score,
          maxScore: _totalPuzzles * AppConstants.pointsPerCorrectAnswer,
          timeSpentSeconds: elapsedSeconds,
          gameData: {
            'puzzles': _totalPuzzles,
            'correctAnswers': _correctAnswers,
            'hintsUsed': _hintsUsed,
          },
        );
      }
    } catch (e) {
      print('Error recording game progress: $e');
    }

    try {
      if (_audioService != null) {
        await _audioService!.playGameEndSequence(_score > _totalPuzzles * AppConstants.pointsPerCorrectAnswer / 2);
      }
    } catch (e) {
      print('Error playing end sequence: $e');
    }
  }

  @override
  void dispose() {
    _puzzleAnimationController.dispose();
    _feedbackAnimationController.dispose();
    _hintAnimationController.dispose();
    super.dispose();
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
                const SizedBox(height: 20),
                Expanded(
                  child: _isCompleted ? _buildResult() : _buildPlayArea(),
                ),
                const SizedBox(height: 20),
                if (_isCompleted)
                  Row(
                    children: [
                      Expanded(
                        child: GameButton(
                          text: 'العودة للقائمة',
                          onPressed: () => Navigator.of(context).pop(),
                          backgroundColor: AppColors.buttonSecondary,
                          textColor: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GameButton(
                          text: 'العب مجدداً',
                          onPressed: _startNewGame,
                          backgroundColor: AppColors.primary,
                          icon: Icons.refresh,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: GameButton(
                          text: 'تلميح',
                          onPressed: _showHint || _isAnswered ? () {} : _showHintAnimation,
                          backgroundColor: AppColors.warning,
                          icon: Icons.lightbulb_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GameButton(
                          text: 'تخطي',
                          onPressed: _isAnswered
                              ? () {
                                  if (_puzzleIndex + 1 >= _totalPuzzles) {
                                    _finishGame();
                                  } else {
                                    setState(() {
                                      _puzzleIndex++;
                                      _loadPuzzle();
                                    });
                                  }
                                }
                              : () {}, // Empty function instead of null
                          backgroundColor: AppColors.buttonSecondary,
                          icon: Icons.skip_next,
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
    final maxScore = _totalPuzzles * AppConstants.pointsPerCorrectAnswer;
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
                'الألغاز التعليمية',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'اللغز ${_puzzleIndex + 1} / $_totalPuzzles · النقاط $_score / $maxScore',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayArea() {
    return AnimatedBuilder(
      animation: _puzzleAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_puzzleSlideAnimation.value * MediaQuery.of(context).size.width, 0),
          child: FadeTransition(
            opacity: _puzzleFadeAnimation,
            child: Column(
              children: [
                // Category and image
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentPuzzle['image'] ?? '🧩',
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentPuzzle['category'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Question
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentPuzzle['question'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Hint section
                if (_showHint)
                  AnimatedBuilder(
                    animation: _hintAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          sin(_hintShakeAnimation.value * pi * 4) * 5,
                          0,
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _currentPuzzle['hint'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFB7791F), // Darker warning color
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                
                const SizedBox(height: 30),
                
                // Options
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.0,
                    ),
                    itemCount: (_currentPuzzle['options'] as List).length,
                    itemBuilder: (context, index) {
                      final option = (_currentPuzzle['options'] as List)[index];
                      final isSelected = _selectedAnswer == option;
                      final isCorrect = option == _currentPuzzle['answer'];
                      
                      Color backgroundColor;
                      Color textColor;
                      Color borderColor;
                      
                      if (!_isAnswered) {
                        backgroundColor = AppColors.surface;
                        textColor = AppColors.textPrimary;
                        borderColor = AppColors.primary;
                      } else if (isCorrect) {
                        backgroundColor = AppColors.correct;
                        textColor = Colors.white;
                        borderColor = AppColors.correct;
                      } else if (isSelected) {
                        backgroundColor = AppColors.incorrect;
                        textColor = Colors.white;
                        borderColor = AppColors.incorrect;
                      } else {
                        backgroundColor = AppColors.buttonSecondary;
                        textColor = AppColors.textSecondary;
                        borderColor = AppColors.buttonSecondary;
                      }
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Material(
                          elevation: _isAnswered && isCorrect ? 8 : 2,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _isAnswered ? null : () => _selectAnswer(option),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: borderColor,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  option,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Feedback
                if (_isAnswered)
                  AnimatedBuilder(
                    animation: _feedbackAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _feedbackScaleAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isCorrect ? AppColors.correct : AppColors.incorrect,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isCorrect ? Icons.check_circle : Icons.cancel,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isCorrect ? 'ممتاز! إجابة صحيحة' : 'الإجابة الصحيحة: ${_currentPuzzle['answer']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResult() {
    final maxScore = _totalPuzzles * AppConstants.pointsPerCorrectAnswer;
    final percent = maxScore > 0 ? _score / maxScore : 0.0;
    int stars = 0;
    if (percent >= 0.9) {
      stars = 3;
    } else if (percent >= 0.7) {
      stars = 2;
    } else if (percent >= 0.5) {
      stars = 1;
    }
    
    String performanceText = '';
    if (percent >= 0.9) {
      performanceText = 'أداء ممتاز! أنت عبقري صغير!';
    } else if (percent >= 0.7) {
      performanceText = 'أداء جيد جداً! تحسن رائع!';
    } else if (percent >= 0.5) {
      performanceText = 'أداء جيد! استمر في التعلم!';
    } else {
      performanceText = 'لا تيأس! المحاولة مرة أخرى ستحسن أداءك!';
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                '🧩',
                style: TextStyle(fontSize: 50),
              ),
              const SizedBox(height: 16),
              const Text(
                'مبروك!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                performanceText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: AppColors.goldStar,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'النتيجة:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$_score / $maxScore',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجابات الصحيحة:',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$_correctAnswers / $_totalPuzzles',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'التلميحات المستخدمة:',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$_hintsUsed',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
