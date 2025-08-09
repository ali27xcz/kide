import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/progress_tracker.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/game_button.dart';

class ShapesGameScreen extends StatefulWidget {
  const ShapesGameScreen({Key? key}) : super(key: key);

  @override
  State<ShapesGameScreen> createState() => _ShapesGameScreenState();
}

class _ShapesGameScreenState extends State<ShapesGameScreen>
    with TickerProviderStateMixin {
  static const int _totalRounds = 12;
  
  // Shapes data with Arabic names
  static const List<Map<String, dynamic>> _shapes = [
    {
      'name': 'دائرة',
      'shape': ShapeType.circle,
      'color': AppColors.funRed,
      'description': 'شكل مستدير ليس له زوايا'
    },
    {
      'name': 'مربع',
      'shape': ShapeType.square,
      'color': AppColors.funBlue,
      'description': 'له أربعة جوانب متساوية'
    },
    {
      'name': 'مثلث',
      'shape': ShapeType.triangle,
      'color': AppColors.funGreen,
      'description': 'له ثلاثة جوانب وثلاث زوايا'
    },
    {
      'name': 'مستطيل',
      'shape': ShapeType.rectangle,
      'color': AppColors.funYellow,
      'description': 'له أربعة جوانب، الجانبان المتقابلان متساويان'
    },
    {
      'name': 'نجمة',
      'shape': ShapeType.star,
      'color': AppColors.funOrange,
      'description': 'شكل يشبه النجوم في السماء'
    },
    {
      'name': 'قلب',
      'shape': ShapeType.heart,
      'color': AppColors.funPink,
      'description': 'شكل جميل يعبر عن الحب'
    },
    {
      'name': 'معين',
      'shape': ShapeType.diamond,
      'color': AppColors.funPurple,
      'description': 'مربع مائل له أربع زوايا حادة'
    },
    {
      'name': 'سداسي',
      'shape': ShapeType.hexagon,
      'color': AppColors.funCyan,
      'description': 'له ستة جوانب وست زوايا'
    },
  ];

  final Random _random = Random();
  late AnimationController _shapeAnimationController;
  late AnimationController _feedbackAnimationController;
  late AnimationController _particlesController;
  late Animation<double> _shapeScaleAnimation;
  late Animation<double> _shapeRotationAnimation;
  late Animation<double> _feedbackScaleAnimation;
  late Animation<double> _particlesAnimation;

  int _roundIndex = 0;
  int _correctAnswers = 0;
  int _score = 0;
  int _startTimeMs = 0;
  
  // Current round data
  Map<String, dynamic> _currentShape = {};
  List<String> _options = [];
  String _selectedAnswer = '';
  bool _isAnswered = false;
  bool _isCompleted = false;
  bool _isCorrect = false;
  
  // Game modes
  ShapeGameMode _currentMode = ShapeGameMode.shapeToName;

  AudioService? _audioService;
  ProgressTracker? _progressTracker;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initialize();
  }

  void _initializeAnimations() {
    _shapeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _particlesController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _shapeScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shapeAnimationController,
      curve: Curves.elasticOut,
    ));

    _shapeRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _shapeAnimationController,
      curve: Curves.easeInOut,
    ));

    _feedbackScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.elasticOut,
    ));

    _particlesAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particlesController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _initialize() async {
    try {
      _audioService = await AudioService.getInstance();
    } catch (e) {
      print('Error initializing audio service in shapes game: $e');
    }
    
    try {
      _progressTracker = await ProgressTracker.getInstance();
    } catch (e) {
      print('Error initializing progress tracker in shapes game: $e');
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
    final modes = ShapeGameMode.values;
    _currentMode = modes[_random.nextInt(modes.length)];
    
    // Select random shape
    _currentShape = _shapes[_random.nextInt(_shapes.length)];
    
    // Generate options based on mode
    _generateOptions();
    
    _selectedAnswer = '';
    _isAnswered = false;
    _isCorrect = false;
    
    // Start animations
    _shapeAnimationController.reset();
    _shapeAnimationController.forward();
  }

  void _generateOptions() {
    final correctAnswer = _getCorrectAnswer();
    final allPossibleAnswers = <String>[];
    
    // Generate all possible wrong answers
    for (final shape in _shapes) {
      final option = _getAnswerFromShape(shape);
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
      case ShapeGameMode.shapeToName:
        return _currentShape['name']!;
      case ShapeGameMode.nameToShape:
        return _currentShape['name']!;
      case ShapeGameMode.descriptionToName:
        return _currentShape['name']!;
    }
  }

  String _getAnswerFromShape(Map<String, dynamic> shape) {
    return shape['name']!;
  }

  String _getQuestionText() {
    switch (_currentMode) {
      case ShapeGameMode.shapeToName:
        return 'ما اسم هذا الشكل؟';
      case ShapeGameMode.nameToShape:
        return 'أين الشكل المسمى "${_currentShape['name']}"؟';
      case ShapeGameMode.descriptionToName:
        return 'أي شكل يطابق هذا الوصف؟';
    }
  }

  String _getDescriptionText() {
    if (_currentMode == ShapeGameMode.descriptionToName) {
      return _currentShape['description']!;
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
      _particlesController.reset();
      _particlesController.forward();
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
          gameType: AppConstants.shapesGame,
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
    _shapeAnimationController.dispose();
    _feedbackAnimationController.dispose();
    _particlesController.dispose();
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
                'تعلم الأشكال',
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
          child: Column(
            children: [
              Text(
                _getQuestionText(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_getDescriptionText().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _getDescriptionText(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Shape display (only for shape-to-name mode)
        if (_currentMode == ShapeGameMode.shapeToName)
          Expanded(
            flex: 2,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Particles effect
                  if (_isCorrect && _isAnswered)
                    AnimatedBuilder(
                      animation: _particlesController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(300, 300),
                          painter: ParticlesPainter(_particlesAnimation.value),
                        );
                      },
                    ),
                  
                  // Main shape
                  AnimatedBuilder(
                    animation: _shapeAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _shapeScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _shapeRotationAnimation.value,
                          child: _buildShape(
                            _currentShape['shape'] as ShapeType,
                            _currentShape['color'] as Color,
                            200,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        
        // Options
        Expanded(
          flex: _currentMode == ShapeGameMode.nameToShape ? 3 : 2,
          child: _currentMode == ShapeGameMode.nameToShape
              ? _buildShapeOptions()
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

  Widget _buildShapeOptions() {
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
        final shapeData = _shapes.firstWhere((s) => s['name'] == optionName);
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
                    _buildShape(
                      shapeData['shape'] as ShapeType,
                      shapeData['color'] as Color,
                      80,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      optionName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShape(ShapeType shapeType, Color color, double size) {
    switch (shapeType) {
      case ShapeType.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        );
      
      case ShapeType.square:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        );
      
      case ShapeType.triangle:
        return CustomPaint(
          size: Size(size, size),
          painter: TrianglePainter(color),
        );
      
      case ShapeType.rectangle:
        return Container(
          width: size * 1.3,
          height: size * 0.8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        );
      
      case ShapeType.star:
        return CustomPaint(
          size: Size(size, size),
          painter: StarPainter(color),
        );
      
      case ShapeType.heart:
        return CustomPaint(
          size: Size(size, size),
          painter: HeartPainter(color),
        );
      
      case ShapeType.diamond:
        return Transform.rotate(
          angle: pi / 4,
          child: Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
        );
      
      case ShapeType.hexagon:
        return CustomPaint(
          size: Size(size, size),
          painter: HexagonPainter(color),
        );
    }
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

enum ShapeType { circle, square, triangle, rectangle, star, heart, diamond, hexagon }

enum ShapeGameMode { shapeToName, nameToShape, descriptionToName }

// Custom painters for complex shapes
class TrianglePainter extends CustomPainter {
  final Color color;
  
  TrianglePainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawShadow(path, color.withOpacity(0.3), 5, true);
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarPainter extends CustomPainter {
  final Color color;
  
  StarPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;
    
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * pi / 5) - pi / 2;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Inner point
      final innerAngle = ((i + 0.5) * 2 * pi / 5) - pi / 2;
      final innerX = centerX + (radius * 0.4) * cos(innerAngle);
      final innerY = centerY + (radius * 0.4) * sin(innerAngle);
      path.lineTo(innerX, innerY);
    }
    path.close();
    
    canvas.drawShadow(path, color.withOpacity(0.3), 5, true);
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeartPainter extends CustomPainter {
  final Color color;
  
  HeartPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final width = size.width;
    final height = size.height;
    
    path.moveTo(width / 2, height);
    path.cubicTo(width / 4, height * 3 / 4, 0, height / 2, width / 8, height / 4);
    path.cubicTo(width / 8, height / 8, width / 4, 0, width / 2, height / 8);
    path.cubicTo(width * 3 / 4, 0, width * 7 / 8, height / 8, width * 7 / 8, height / 4);
    path.cubicTo(width, height / 2, width * 3 / 4, height * 3 / 4, width / 2, height);
    
    canvas.drawShadow(path, color.withOpacity(0.3), 5, true);
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HexagonPainter extends CustomPainter {
  final Color color;
  
  HexagonPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;
    
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawShadow(path, color.withOpacity(0.3), 5, true);
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ParticlesPainter extends CustomPainter {
  final double animationValue;
  
  ParticlesPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final random = Random(42); // Fixed seed for consistent animation
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = animationValue * (50 + random.nextDouble() * 100);
      final x = centerX + distance * cos(angle);
      final y = centerY + distance * sin(angle);
      
      final colors = [AppColors.funRed, AppColors.funBlue, AppColors.funYellow, AppColors.funGreen];
      paint.color = colors[i % colors.length].withOpacity(1 - animationValue);
      
      canvas.drawCircle(Offset(x, y), 3 + random.nextDouble() * 3, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
