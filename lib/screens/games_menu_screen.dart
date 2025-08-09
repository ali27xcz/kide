import 'package:flutter/material.dart';
import 'games/counting_game_screen.dart';
import 'games/alphabet_game_screen.dart';
import 'games/shapes_game_screen.dart';
import 'games/colors_game_screen.dart';
import 'games/puzzle_game_screen.dart';
import 'games/memory_game_screen.dart';
import '../models/child_profile.dart';
import '../models/game_progress.dart';
import '../services/local_storage.dart';
import '../services/audio_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/game_button.dart';
import '../widgets/animated_character.dart';
import '../widgets/achievement_badge.dart';

class GamesMenuScreen extends StatefulWidget {
  const GamesMenuScreen({Key? key}) : super(key: key);

  @override
  State<GamesMenuScreen> createState() => _GamesMenuScreenState();
}

class _GamesMenuScreenState extends State<GamesMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  
  LocalStorageService? _storage;
  AudioService? _audioService;
  ChildProfile? _childProfile;
  List<GameProgress> _gameProgress = [];
  bool _isLoading = true;

  final List<GameInfo> _games = [
    GameInfo(
      id: AppConstants.countingGame,
      title: 'لعبة العد',
      subtitle: 'تعلم العد من 1 إلى 20',
      description: 'اعد الكائنات واستمع للأرقام',
      icon: Icons.looks_one,
      color: Color(0xFF2196F3), // أزرق زاهي
      difficulty: 'سهل',
      estimatedTime: '5-10 دقائق',
      skills: ['العد', 'الأرقام', 'التركيز'],
    ),
    GameInfo(
      id: AppConstants.alphabetGame,
      title: 'تعلم الحروف',
      subtitle: 'الأبجدية العربية كاملة',
      description: 'تعلم الحروف العربية وأسماءها',
      icon: Icons.text_fields,
      color: Color(0xFF4CAF50), // أخضر زاهي
      difficulty: 'سهل',
      estimatedTime: '8-12 دقيقة',
      skills: ['الحروف', 'القراءة', 'التذكر'],
    ),
    GameInfo(
      id: AppConstants.shapesGame,
      title: 'تعلم الأشكال',
      subtitle: 'الأشكال الهندسية الأساسية',
      description: 'تعرف على الأشكال وخصائصها',
      icon: Icons.category,
      color: Color(0xFFFFC107), // أصفر ذهبي
      difficulty: 'سهل',
      estimatedTime: '6-10 دقائق',
      skills: ['الأشكال', 'الهندسة', 'التصنيف'],
    ),
    GameInfo(
      id: AppConstants.colorsGame,
      title: 'تعلم الألوان',
      subtitle: 'الألوان والأشياء الملونة',
      description: 'تعلم الألوان وربطها بالأشياء',
      icon: Icons.palette,
      color: Color(0xFFE91E63), // وردي زاهي
      difficulty: 'سهل',
      estimatedTime: '7-12 دقيقة',
      skills: ['الألوان', 'الربط', 'الذاكرة'],
    ),
    GameInfo(
      id: AppConstants.puzzleGame,
      title: 'الألغاز التعليمية',
      subtitle: 'أسئلة تعليمية ممتعة',
      description: 'ألغاز تعليمية تنمي الذكاء',
      icon: Icons.extension,
      color: Color(0xFFFF5722), // برتقالي قوي
      difficulty: 'متوسط',
      estimatedTime: '10-15 دقيقة',
      skills: ['التفكير', 'المنطق', 'المعرفة العامة'],
    ),
    GameInfo(
      id: AppConstants.memoryGame,
      title: 'لعبة الذاكرة',
      subtitle: 'تطوير الذاكرة والتركيز',
      description: 'اعثر على الأزواج المتطابقة',
      icon: Icons.psychology,
      color: Color(0xFF9C27B0), // بنفسجي زاهي
      difficulty: 'متوسط',
      estimatedTime: '5-15 دقيقة',
      skills: ['الذاكرة', 'التركيز', 'الصبر'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  Future<void> _initializeData() async {
    try {
      // Try to initialize storage
      try {
        _storage = await LocalStorageService.getInstance();
        _childProfile = await _storage!.getChildProfile();
        _gameProgress = await _storage!.getGameProgress();
      } catch (e) {
        print('Error initializing storage in games menu: $e');
        // Continue without storage - use default values
      }
      
      // Try to initialize audio service (non-blocking)
      try {
        _audioService = await AudioService.getInstance();
      } catch (e) {
        print('Error initializing audio service in games menu: $e');
        // Continue without audio
      }
      
      setState(() {
        _isLoading = false;
      });
      
      _fadeController.forward();
      _staggerController.forward();
      
    } catch (e) {
      print('Error initializing games menu: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Start animations anyway
      _fadeController.forward();
      _staggerController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildCharacterSection(),
                        const SizedBox(height: 30),
                        _buildGamesGrid(),
                        const SizedBox(height: 30),
                        _buildProgressSummary(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GameIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
            size: 45,
            backgroundColor: AppColors.surface,
            iconColor: AppColors.textSecondary,
          ),
          
          const SizedBox(width: 16),
          
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الألعاب',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'اختر لعبتك المفضلة',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Profile Level Badge
          if (_childProfile != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'المستوى ${_childProfile!.getCurrentLevel()}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCharacterSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const AnimatedCharacter(
            state: CharacterState.encouraging,
            size: 80,
            showMessage: false,
          ),
          
          const SizedBox(width: 16),
          
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أي لعبة تريد أن تلعب اليوم؟',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'كل لعبة ستعلمك شيئاً جديداً ومفيداً!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الألعاب المتاحة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _games.length,
          itemBuilder: (context, index) {
            return AnimatedBuilder(
              animation: _staggerController,
              builder: (context, child) {
                final delay = index * 0.1;
                final animationValue = Curves.easeOut.transform(
                  (_staggerController.value - delay).clamp(0.0, 1.0),
                );
                
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - animationValue)),
                  child: Opacity(
                    opacity: animationValue,
                    child: _buildGameCard(_games[index]),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGameCard(GameInfo game) {
    final gameStats = _getGameStats(game.id);
    final isLocked = _isGameLocked(game);
    
    return Card(
      elevation: isLocked ? 2 : 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isLocked ? null : () => _navigateToGame(game),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isLocked ? null : LinearGradient(
              colors: [
                game.color,
                game.color.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: isLocked ? Colors.grey[200] : null,
          ),
          child: Column(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isLocked ? Colors.grey[300] : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  game.icon,
                  size: 32,
                  color: isLocked ? Colors.grey[600] : Colors.white,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Title
              Text(
                game.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey[600] : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 4),
              
              // Subtitle
              Text(
                game.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isLocked ? Colors.grey[500] : Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Stats or Lock
              if (isLocked)
                Icon(
                  Icons.lock,
                  color: Colors.grey[600],
                  size: 20,
                )
              else if (gameStats['stars'] > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Icon(
                      index < gameStats['stars'] ? Icons.star : Icons.star_border,
                      color: AppColors.goldStar,
                      size: 16,
                    );
                  }),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'جديد',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    if (_childProfile == null) return const SizedBox.shrink();
    
    final completedGames = _gameProgress.length;
    final totalStars = _gameProgress.fold<int>(0, (sum, progress) => sum + progress.stars);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إحصائياتك',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.games,
                  title: 'الألعاب المكتملة',
                  value: '$completedGames',
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: _buildStatItem(
                  icon: Icons.star,
                  title: 'إجمالي النجوم',
                  value: '$totalStars',
                  color: AppColors.goldStar,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.emoji_events,
                  title: 'النقاط',
                  value: '${_childProfile!.totalPoints}',
                  color: AppColors.funOrange,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time,
                  title: 'وقت اللعب',
                  value: '${_childProfile!.totalTimePlayedMinutes}د',
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getGameStats(String gameId) {
    final gameProgress = _gameProgress.where((p) => p.gameType == gameId).toList();
    
    if (gameProgress.isEmpty) {
      return {'stars': 0, 'bestScore': 0, 'timesPlayed': 0};
    }
    
    final bestProgress = gameProgress.reduce((a, b) => a.score > b.score ? a : b);
    
    return {
      'stars': bestProgress.stars,
      'bestScore': bestProgress.score,
      'timesPlayed': gameProgress.length,
    };
  }

  bool _isGameLocked(GameInfo game) {
    // For now, all games are unlocked
    // In the future, you can implement level-based unlocking
    return false;
  }

  void _navigateToGame(GameInfo game) async {
    if (_audioService != null) {
      await _audioService!.playButtonClickSound();
    }
    
    // Show game info dialog first
    final shouldPlay = await _showGameInfoDialog(game);
    
    if (shouldPlay == true) {
      Widget? gameScreen;
      
      switch (game.id) {
        case AppConstants.countingGame:
          gameScreen = const CountingGameScreen();
          break;
        case AppConstants.alphabetGame:
          gameScreen = const AlphabetGameScreen();
          break;
        case AppConstants.shapesGame:
          gameScreen = const ShapesGameScreen();
          break;
        case AppConstants.colorsGame:
          gameScreen = const ColorsGameScreen();
          break;
        case AppConstants.puzzleGame:
          gameScreen = const PuzzleGameScreen();
          break;
        case AppConstants.memoryGame:
          gameScreen = const MemoryGameScreen();
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('سيتم تنفيذ ${game.title} لاحقاً'),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
      }
      
      if (gameScreen != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => gameScreen!),
        );
      }
    }
  }

  Future<bool?> _showGameInfoDialog(GameInfo game) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Game Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: game.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  game.icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Game Title
              Text(
                game.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Game Description
              Text(
                game.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Game Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('الصعوبة:', game.difficulty),
                    const SizedBox(height: 8),
                    _buildDetailRow('الوقت المتوقع:', game.estimatedTime),
                    const SizedBox(height: 8),
                    _buildDetailRow('المهارات:', game.skills.join(', ')),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: GameButton(
                      text: 'إلغاء',
                      onPressed: () => Navigator.of(context).pop(false),
                      backgroundColor: AppColors.buttonSecondary,
                      textColor: AppColors.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: GameButton(
                      text: 'ابدأ اللعب',
                      onPressed: () => Navigator.of(context).pop(true),
                      backgroundColor: game.color,
                      icon: Icons.play_arrow,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        
        const SizedBox(width: 8),
        
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class GameInfo {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String difficulty;
  final String estimatedTime;
  final List<String> skills;

  GameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.difficulty,
    required this.estimatedTime,
    required this.skills,
  });
}

