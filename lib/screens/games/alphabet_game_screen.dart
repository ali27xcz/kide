import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/progress_tracker.dart';
import '../../services/data_service.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/game_button.dart';

class AlphabetGameScreen extends StatefulWidget {
  const AlphabetGameScreen({Key? key}) : super(key: key);

  @override
  State<AlphabetGameScreen> createState() => _AlphabetGameScreenState();
}

class _AlphabetGameScreenState extends State<AlphabetGameScreen>
    with TickerProviderStateMixin {
  static const int _totalRounds = 15;
  
  // Arabic alphabet data loaded from JSON
  List<Map<String, String>> _arabicLetters = [];

  final Random _random = Random();
  late AnimationController _letterAnimationController;
  late AnimationController _feedbackAnimationController;
  late Animation<double> _letterScaleAnimation;
  late Animation<double> _letterFadeAnimation;
  late Animation<double> _feedbackScaleAnimation;

  int _roundIndex = 0;
  int _correctAnswers = 0;
  int _score = 0;
  int _startTimeMs = 0;
  
  // Current round data
  Map<String, String> _currentLetter = {};
  List<String> _options = [];
  String _selectedAnswer = '';
  bool _isAnswered = false;
  bool _isCompleted = false;
  bool _isCorrect = false;
  
  // Game modes
  GameMode _currentMode = GameMode.letterToName;

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
    _letterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _letterScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _letterAnimationController,
      curve: Curves.elasticOut,
    ));

    _letterFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _letterAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _feedbackScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _initialize() async {
    try {
      _audioService = await AudioService.getInstance();
    } catch (e) {
      print('Error initializing audio service in alphabet game: $e');
    }
    
    try {
      _progressTracker = await ProgressTracker.getInstance();
    } catch (e) {
      print('Error initializing progress tracker in alphabet game: $e');
    }
    
    try {
      _dataService = DataService.instance;
      _arabicLetters = await _dataService!.loadAlphabetData();
    } catch (e) {
      print('Error loading alphabet data: $e');
    }
    
    _startNewGame();
  }

  void _startNewGame() {
    _roundIndex = 0;
    _correctAnswers = 0;
    _score = 0;
    _isCompleted = false;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _generateRound();
    setState(() {});
  }

  void _generateRound() {
    // Randomly select game mode
    final modes = GameMode.values;
    _currentMode = modes[_random.nextInt(modes.length)];
    
    // Select random letter
    _currentLetter = _arabicLetters[_random.nextInt(_arabicLetters.length)];
    
    // Generate options based on mode
    _generateOptions();
    
    _selectedAnswer = '';
    _isAnswered = false;
    _isCorrect = false;
    
    // Start animations
    _letterAnimationController.reset();
    _letterAnimationController.forward();
  }

  void _generateOptions() {
    final correctAnswer = _getCorrectAnswer();
    final allPossibleAnswers = <String>[];
    
    // Generate all possible wrong answers
    for (final letter in _arabicLetters) {
      final option = _getAnswerFromLetter(letter);
      if (option != correctAnswer) {
        allPossibleAnswers.add(option);
      }
    }
    
    // Shuffle and take 3 wrong answers
    allPossibleAnswers.shuffle(_random);
    final wrongAnswers = allPossibleAnswers.take(3).toList();
    
    // Combine and shuffle
    _options = [correctAnswer, ...wrongAnswers];
    _options.shuffle(_random);
  }

  String _getCorrectAnswer() {
    switch (_currentMode) {
      case GameMode.letterToName:
        return _currentLetter['name']!;
      case GameMode.letterToWord:
        return _currentLetter['word']!;
      case GameMode.nameToLetter:
        return _currentLetter['letter']!;
      case GameMode.wordToLetter:
        return _currentLetter['letter']!;
    }
  }

  String _getAnswerFromLetter(Map<String, String> letter) {
    switch (_currentMode) {
      case GameMode.letterToName:
        return letter['name']!;
      case GameMode.letterToWord:
        return letter['word']!;
      case GameMode.nameToLetter:
        return letter['letter']!;
      case GameMode.wordToLetter:
        return letter['letter']!;
    }
  }

  String _getQuestionText() {
    if (_currentLetter.isEmpty) return 'جاري التحميل...';
    
    switch (_currentMode) {
      case GameMode.letterToName:
        return 'ما اسم هذا الحرف؟';
      case GameMode.letterToWord:
        return 'أي كلمة تبدأ بهذا الحرف؟';
      case GameMode.nameToLetter:
        return 'أي حرف اسمه "${_currentLetter['name'] ?? ''}"؟';
      case GameMode.wordToLetter:
        return 'أي حرف تبدأ به كلمة "${_currentLetter['word'] ?? ''}"؟';
    }
  }

  String _getDisplayText() {
    if (_currentLetter.isEmpty) return '';
    
    switch (_currentMode) {
      case GameMode.letterToName:
      case GameMode.letterToWord:
        return _currentLetter['letter'] ?? '';
      case GameMode.nameToLetter:
        return _currentLetter['name'] ?? '';
      case GameMode.wordToLetter:
        return _currentLetter['word'] ?? '';
    }
  }

  Future<void> _selectAnswer(String answer) async {
    if (_isAnswered || _isCompleted) return;
    
    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
      _isCorrect = answer == _getCorrectAnswer();
    });

    if (_isCorrect) {
      _correctAnswers++;
      _score += AppConstants.pointsPerCorrectAnswer;
      await _audioService?.playCorrectSound();
    } else {
      await _audioService?.playIncorrectSound();
    }

    // Start feedback animation
    _feedbackAnimationController.reset();
    _feedbackAnimationController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));

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

    try {
      if (_progressTracker != null) {
        await _progressTracker!.recordGameProgress(
          gameType: AppConstants.alphabetGame,
          level: 1,
          score: _score,
          maxScore: _totalRounds * AppConstants.pointsPerCorrectAnswer,
          timeSpentSeconds: elapsedSeconds,
          gameData: {
            'rounds': _totalRounds,
            'correctAnswers': _correctAnswers,
          },
        );
      }
    } catch (e) {
      print('Error recording game progress: $e');
    }

    try {
      if (_audioService != null) {
        await _audioService!.playGameEndSequence(_score > _totalRounds * AppConstants.pointsPerCorrectAnswer / 2);
      }
    } catch (e) {
      print('Error playing end sequence: $e');
    }
  }

  @override
  void dispose() {
    _letterAnimationController.dispose();
    _feedbackAnimationController.dispose();
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
                'تعلم الحروف',
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
        // Question
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _getQuestionText(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Letter/Word display
        Expanded(
          flex: 2,
          child: Center(
            child: AnimatedBuilder(
              animation: _letterAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _letterScaleAnimation.value,
                  child: FadeTransition(
                    opacity: _letterFadeAnimation,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getDisplayText(),
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Arabic',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Options
        Expanded(
          flex: 2,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _options.length,
            itemBuilder: (context, index) {
              final option = _options[index];
              final isSelected = _selectedAnswer == option;
              final isCorrect = option == _getCorrectAnswer();
              
              Color backgroundColor;
              Color textColor;
              
              if (!_isAnswered) {
                backgroundColor = AppColors.primary;
                textColor = Colors.white;
              } else if (isCorrect) {
                backgroundColor = AppColors.correct;
                textColor = Colors.white;
              } else if (isSelected) {
                backgroundColor = AppColors.incorrect;
                textColor = Colors.white;
              } else {
                backgroundColor = AppColors.buttonSecondary;
                textColor = AppColors.textSecondary;
              }
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: _isAnswered ? null : () => _selectAnswer(option),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: textColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isAnswered && isCorrect ? 8 : 4,
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                        _isCorrect ? 'ممتاز!' : 'حاول مرة أخرى',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
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
                'أحسنت!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 20),
              Text(
                'نتيجتك: $_score / $maxScore',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الإجابات الصحيحة: $_correctAnswers / $_totalRounds',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum GameMode {
  letterToName,    // Show letter, choose name
  letterToWord,    // Show letter, choose word
  nameToLetter,    // Show name, choose letter
  wordToLetter,    // Show word, choose letter
}
