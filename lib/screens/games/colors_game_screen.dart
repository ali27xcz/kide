import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/progress_tracker.dart';
import '../../services/data_service.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/game_button.dart';
import '../../widgets/star_collect_overlay.dart';
import '../../utils/game_utils.dart';
import '../../widgets/game_result_views.dart';

class ColorsGameScreen extends StatefulWidget {
  const ColorsGameScreen({Key? key}) : super(key: key);

  @override
  State<ColorsGameScreen> createState() => _ColorsGameScreenState();
}

class _ColorsGameScreenState extends State<ColorsGameScreen>
    with TickerProviderStateMixin {
  static const int _totalRounds = 15;
  
  // Colors data loaded from JSON
  List<Map<String, dynamic>> _colors = [];

  final Random _random = Random();
  late AnimationController _colorAnimationController;
  late AnimationController _feedbackAnimationController;
  late AnimationController _sparkleController;
  late Animation<double> _colorScaleAnimation;
  late Animation<double> _colorOpacityAnimation;
  late Animation<double> _feedbackScaleAnimation;
  late Animation<double> _sparkleAnimation;

  int _roundIndex = 0;
  int _correctAnswers = 0;
  int _score = 0;
  int _startTimeMs = 0;
  
  // Current round data
  Map<String, dynamic> _currentColor = {};
  List<String> _options = [];
  String _selectedAnswer = '';
  bool _isAnswered = false;
  bool _isCompleted = false;
  bool _isCorrect = false;
  String _selectedObjectForQuestion = '';
  
  // Game modes
  ColorGameMode _currentMode = ColorGameMode.colorToName;
  bool _mixingModeEnabled = true; // تحدي خلط الألوان
  _ColorMix? _currentMix;

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
    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _colorScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.elasticOut,
    ));

    _colorOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _feedbackScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.elasticOut,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _initialize() async {
    try {
      _audioService = await AudioService.getInstance();
    } catch (e) {
      print('Error initializing audio service in colors game: $e');
    }
    
    try {
      _progressTracker = await ProgressTracker.getInstance();
    } catch (e) {
      print('Error initializing progress tracker in colors game: $e');
    }
    
    try {
      _dataService = DataService.instance;
      final colorsData = await _dataService!.loadColorsData();
      _colors = colorsData.map((color) {
        // Convert color string to Color object
        final colorString = color['color'] as String;
        final colorValue = int.parse(colorString);
        return {
          ...color,
          'color': Color(colorValue),
        };
      }).toList();
    } catch (e) {
      print('Error loading colors data: $e');
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
    // Randomly select game mode (مع احتمال إدراج خلط الألوان)
    final baseModes = [
      ColorGameMode.colorToName,
      ColorGameMode.nameToColor,
      ColorGameMode.objectToColor,
      ColorGameMode.colorToObject,
    ];
    final includeMix = _mixingModeEnabled && _random.nextDouble() < 0.25; // 25%
    if (includeMix) {
      _currentMode = ColorGameMode.mixColors;
      _currentMix = _generateColorMixInstance(_colors, _random);
    } else {
      _currentMode = baseModes[_random.nextInt(baseModes.length)];
      _currentMix = null;
    }

    // Select random color for non-mix rounds
    if (_currentMode != ColorGameMode.mixColors) {
      _currentColor = _colors[_random.nextInt(_colors.length)];
    }

    // Generate options based on mode
    _generateOptions();

    _selectedAnswer = '';
    _isAnswered = false;
    _isCorrect = false;
    _selectedObjectForQuestion = '';

    // Start animations
    _colorAnimationController.reset();
    _colorAnimationController.forward();
  }

  void _generateOptions() {
    final correctAnswer = _getCorrectAnswer();
    final allPossibleAnswers = <String>[];
    
    // Generate wrong answers based on the current mode
    switch (_currentMode) {
      case ColorGameMode.colorToName:
      case ColorGameMode.nameToColor:
        // For color/name modes, use color names only
        for (final color in _colors) {
          final colorName = color['name']!;
          if (colorName != correctAnswer) {
            allPossibleAnswers.add(colorName);
          }
        }
        break;
        
      case ColorGameMode.objectToColor:
        // For object to color, answer should be color name
        for (final color in _colors) {
          final colorName = color['name']!;
          if (colorName != correctAnswer) {
            allPossibleAnswers.add(colorName);
          }
        }
        break;
        
      case ColorGameMode.colorToObject:
        // For color to object, answer should be object name
        for (final color in _colors) {
          final objects = color['objects'] as List<String>;
          for (final obj in objects) {
            if (obj != correctAnswer && !allPossibleAnswers.contains(obj)) {
              allPossibleAnswers.add(obj);
            }
          }
        }
        break;
      case ColorGameMode.mixColors:
        // Options are color names
        for (final color in _colors) {
          final colorName = color['name']!;
          if (colorName != correctAnswer) {
            allPossibleAnswers.add(colorName);
          }
        }
        break;
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
      case ColorGameMode.colorToName:
        return _currentColor['name']!;
      case ColorGameMode.nameToColor:
        return _currentColor['name']!;
      case ColorGameMode.objectToColor:
        // Return the color name when asking "what color is this object?"
        return _currentColor['name']!;
      case ColorGameMode.colorToObject:
        // Return one of the objects when asking "what can be this color?"
        final objects = _currentColor['objects'] as List<String>;
        return objects[_random.nextInt(objects.length)];
      case ColorGameMode.mixColors:
        return _currentMix?.resultName ?? '';
    }
  }

  List<String> _getAnswersFromColor(Map<String, dynamic> color) {
    switch (_currentMode) {
      case ColorGameMode.colorToName:
      case ColorGameMode.nameToColor:
        return [color['name']!];
      case ColorGameMode.objectToColor:
      case ColorGameMode.colorToObject:
        return List<String>.from(color['objects']);
      case ColorGameMode.mixColors:
        // Not used in current UI path
        return [];
    }
  }

  String _getQuestionText() {
    switch (_currentMode) {
      case ColorGameMode.colorToName:
        return 'ما اسم هذا اللون؟';
      case ColorGameMode.nameToColor:
        return 'أين اللون "${_currentColor['name']}"؟';
      case ColorGameMode.objectToColor:
        final objects = _currentColor['objects'] as List<String>;
        _selectedObjectForQuestion = objects[_random.nextInt(objects.length)];
        return 'ما لون $_selectedObjectForQuestion؟';
      case ColorGameMode.colorToObject:
        return 'أي شيء يمكن أن يكون بهذا اللون؟';
      case ColorGameMode.mixColors:
        final a = _currentMix?.aName ?? '';
        final b = _currentMix?.bName ?? '';
        return 'ما اللون الناتج من خلط $a + $b؟';
    }
  }

  String _getObjectForQuestion() {
    if (_currentMode == ColorGameMode.objectToColor) {
      final objects = _currentColor['objects'] as List<String>;
      return objects[_random.nextInt(objects.length)];
    }
    return '';
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
      _sparkleController.reset();
      _sparkleController.forward();
    } else {
      await _audioService?.playIncorrectSound();
    }

    // Start feedback animation
    _feedbackAnimationController.reset();
    _feedbackAnimationController.forward();

    // Skip delay on the final question to transition immediately
    if (_roundIndex + 1 >= _totalRounds) {
      await _finishGame();
    } else {
      await Future.delayed(const Duration(milliseconds: 1200));
      setState(() {
        _roundIndex++;
        _generateRound();
      });
    }
  }

  Future<void> _finishGame() async {
    final elapsedSeconds = ((DateTime.now().millisecondsSinceEpoch - _startTimeMs) / 1000).round();

    try {
      if (_progressTracker != null) {
        // تشغيل في الخلفية حتى لا يحجب الانتقال إلى النجوم
        _progressTracker!.recordGameProgress(
          gameType: AppConstants.colorsGame,
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
  void dispose() {
    _colorAnimationController.dispose();
    _feedbackAnimationController.dispose();
    _sparkleController.dispose();
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
                'تعلم الألوان',
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
        
        // Display based on game mode
        if (_currentMode == ColorGameMode.colorToName || _currentMode == ColorGameMode.colorToObject || _currentMode == ColorGameMode.mixColors)
          Expanded(
            flex: 2,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sparkle effect
                  if (_isCorrect && _isAnswered)
                    AnimatedBuilder(
                      animation: _sparkleController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(300, 300),
                          painter: SparklePainter(_sparkleAnimation.value),
                        );
                      },
                    ),
                  
                  // Main color/mix circle
                  AnimatedBuilder(
                    animation: _colorAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _colorScaleAnimation.value,
                        child: Opacity(
                          opacity: _colorOpacityAnimation.value,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentMode == ColorGameMode.mixColors
                                  ? _blendColors((_currentMix?.aColor ?? Colors.red), (_currentMix?.bColor ?? Colors.blue))
                                  : (_currentColor.isNotEmpty ? _currentColor['color'] as Color : AppColors.primary),
                              boxShadow: [
                                if (_currentMode != ColorGameMode.mixColors)
                                  BoxShadow(
                                    color: _currentColor.isNotEmpty ? (_currentColor['color'] as Color).withOpacity(0.4) : AppColors.primary.withOpacity(0.4),
                                    blurRadius: 25,
                                    offset: const Offset(0, 15),
                                  ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white,
                                width: 6,
                              ),
                            ),
                            child: Center(
                              child: _currentMode == ColorGameMode.mixColors
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _colorDot(_currentMix?.aColor ?? Colors.red),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.add, color: Colors.white),
                                        const SizedBox(width: 8),
                                        _colorDot(_currentMix?.bColor ?? Colors.blue),
                                      ],
                                    )
                                  : Icon(
                                      Icons.palette,
                                      size: 60,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        
        // For objectToColor mode, show the object name
        if (_currentMode == ColorGameMode.objectToColor && _selectedObjectForQuestion.isNotEmpty)
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  _selectedObjectForQuestion,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        
        const SizedBox(height: 30),
        
        // Options
        Expanded(
          flex: _currentMode == ColorGameMode.nameToColor ? 3 : 2,
          child: _currentMode == ColorGameMode.nameToColor
              ? _buildColorOptions()
              : _buildTextOptions(),
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

  Widget _buildTextOptions() {
    return GridView.builder(
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
    );
  }

  Widget _buildColorOptions() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _options.length,
      itemBuilder: (context, index) {
        final optionName = _options[index];
        final colorData = _colors.firstWhere((c) => c['name'] == optionName);
        final isSelected = _selectedAnswer == optionName;
        final isCorrect = optionName == _getCorrectAnswer();
        
        Color borderColor;
        double elevation;
        
        if (!_isAnswered) {
          borderColor = AppColors.primary;
          elevation = 4;
        } else if (isCorrect) {
          borderColor = AppColors.correct;
          elevation = 8;
        } else if (isSelected) {
          borderColor = AppColors.incorrect;
          elevation = 2;
        } else {
          borderColor = AppColors.buttonSecondary;
          elevation = 1;
        }
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Material(
            elevation: elevation,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _isAnswered ? null : () => _selectAnswer(optionName),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 3),
                  color: AppColors.surface,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorData['color'] as Color,
                        boxShadow: [
                          BoxShadow(
                            color: (colorData['color'] as Color).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                    ),
                    // Only show color name for non nameToColor mode to increase difficulty
                    if (_currentMode != ColorGameMode.nameToColor) ...[
                      const SizedBox(height: 8),
                      Text(
                        optionName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ] else 
                      const SizedBox(height: 8), // Keep spacing consistent
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResult() {
    final maxScore = _totalRounds * AppConstants.pointsPerCorrectAnswer;
    final success = maxScore > 0 ? (_score / maxScore) >= AppConstants.passScoreRatio : false;
    final stars = GameUtils.computeStars(score: _score, maxScore: maxScore);
    return success
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
  }
}

enum ColorGameMode { colorToName, nameToColor, objectToColor, colorToObject, mixColors }

class _ColorMix {
  final String aName;
  final String bName;
  final Color aColor;
  final Color bColor;
  final String resultName;
  _ColorMix({
    required this.aName,
    required this.bName,
    required this.aColor,
    required this.bColor,
    required this.resultName,
  });
}

Widget _colorDot(Color color) {
  return Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
      ],
    ),
  );
}

Color _blendColors(Color a, Color b) {
  return Color.lerp(a, b, 0.5) ?? a;
}

_ColorMix? _generateColorMixInstance(List<Map<String, dynamic>> colors, Random random) {
  Map<String, dynamic>? findBy(String name) {
    try {
      return colors.firstWhere((c) => (c['name'] as String).toLowerCase() == name);
    } catch (_) {
      return null;
    }
  }

  final red = findBy('red');
  final yellow = findBy('yellow');
  final blue = findBy('blue');
  final green = findBy('green');
  final orange = findBy('orange');
  final purple = findBy('purple');

  final options = <_ColorMix>[];
  if (red != null && yellow != null && orange != null) {
    options.add(_ColorMix(
      aName: red['name'],
      bName: yellow['name'],
      aColor: red['color'] as Color,
      bColor: yellow['color'] as Color,
      resultName: orange['name'],
    ));
  }
  if (red != null && blue != null && purple != null) {
    options.add(_ColorMix(
      aName: red['name'],
      bName: blue['name'],
      aColor: red['color'] as Color,
      bColor: blue['color'] as Color,
      resultName: purple['name'],
    ));
  }
  if (blue != null && yellow != null && green != null) {
    options.add(_ColorMix(
      aName: blue['name'],
      bName: yellow['name'],
      aColor: blue['color'] as Color,
      bColor: yellow['color'] as Color,
      resultName: green['name'],
    ));
  }
  if (options.isEmpty) return null;
  return options[random.nextInt(options.length)];
}

// Note: we call _generateColorMixInstance from inside the state to access local fields

class SparklePainter extends CustomPainter {
  final double animationValue;
  
  SparklePainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final random = Random(42); // Fixed seed for consistent animation
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    for (int i = 0; i < 15; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = animationValue * (40 + random.nextDouble() * 80);
      final x = centerX + distance * cos(angle);
      final y = centerY + distance * sin(angle);
      
      final sparkleSize = 2 + random.nextDouble() * 4;
      final opacity = (1 - animationValue) * (0.5 + random.nextDouble() * 0.5);
      
      paint.color = Colors.white.withOpacity(opacity);
      
      // Draw star-like sparkle
      _drawStar(canvas, Offset(x, y), sparkleSize, paint);
    }
  }
  
  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * pi / 5) - pi / 2;
      final x = center.dx + size * cos(angle);
      final y = center.dy + size * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Inner point
      final innerAngle = ((i + 0.5) * 2 * pi / 5) - pi / 2;
      final innerX = center.dx + (size * 0.4) * cos(innerAngle);
      final innerY = center.dy + (size * 0.4) * sin(innerAngle);
      path.lineTo(innerX, innerY);
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
