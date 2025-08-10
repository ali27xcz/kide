import 'package:flutter/material.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/child_profile.dart';
import '../services/local_storage.dart';
import '../services/audio_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/game_button.dart';
import '../widgets/progress_bar.dart';
import '../widgets/animated_character.dart';
import 'games_menu_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_switch_button.dart';
import '../widgets/parent_gate.dart';
import 'daily_plan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  LocalStorageService? _storage;
  AudioService? _audioService;
  ChildProfile? _childProfile;
  bool _isLoading = true;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _initializeServices() async {
    try {
      // Try to initialize storage service
      try {
        _storage = await LocalStorageService.getInstance();
        
        // Try to get child profile
        _childProfile = await _storage!.getChildProfile();
        _hasProfile = _childProfile != null;
      } catch (e) {
        print('Error initializing storage service: $e');
        // Continue without storage - use default values
        _hasProfile = false;
      }
      
      // Show UI immediately
      setState(() {
        _isLoading = false;
      });

      // Start animations
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _slideController.forward();

      // Initialize audio after UI appears (fire-and-forget)
      // Avoid blocking the first frame due to MediaPlayer on emulators
      // ignore: unawaited_futures
      Future.microtask(() async {
        try {
          _audioService = await AudioService.getInstance();
          await _audioService!.preloadSounds();
          await _audioService!.playBackgroundMusic();
        } catch (e) {
          print('Error initializing audio service: $e');
        }
      });
    } catch (e) {
      print('Error initializing home screen: $e');
      // Even if everything fails, still show the UI
      setState(() {
        _isLoading = false;
        _hasProfile = false; // Default to welcome screen
      });
      
      // Start animations anyway
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
            child: SlideTransition(
              position: _slideAnimation,
              child: _hasProfile ? _buildMainContent() : _buildWelcomeContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Header
        _buildHeader(),
        
        // Main Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Character Welcome
                _buildCharacterSection(),
                
                const SizedBox(height: 30),
                
                // Progress Section + Summary Card
                if (_childProfile != null) ...[
                  _buildProgressSection(),
                  const SizedBox(height: 16),
                  _buildStatsSummaryCard(),
                ],
                
                const SizedBox(height: 30),
                
                // Quick Actions
                _buildQuickActions(),
                
                const SizedBox(height: 30),
                
                // Recent Activity
                _buildRecentActivity(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummaryCard() {
    final totalStarsIcon = Icons.star;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatTile(
              icon: Icons.emoji_events,
              label: AppLocalizations.of(context)?.totalPoints ?? 'النقاط',
              value: '${_childProfile!.totalPoints}',
              color: AppColors.funOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatTile(
              icon: Icons.games,
              label: AppLocalizations.of(context)?.gamesPlayed ?? 'الألعاب',
              value: '${_childProfile!.totalGamesPlayed}',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatTile(
              icon: totalStarsIcon,
              label: AppLocalizations.of(context)?.achievements ?? 'الإنجازات',
              value: '${_childProfile!.achievements.length}',
              color: AppColors.goldStar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
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
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeContent() {
    return Column(
      children: [
        // Header
        _buildSimpleHeader(),
        
        // Welcome Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Welcome Character
                AnimatedCharacter(
                  state: CharacterState.waving,
                  size: 150,
                  message: AppLocalizations.of(context)?.welcomeMessage ?? 'مرحباً! هيا ننشئ ملفك الشخصي',
                  motionStyle: MotionStyle.gentle,
                ),
                
                const SizedBox(height: 40),
                
                // Welcome Text
                Text(
                  AppLocalizations.of(context)?.welcomeMessage ?? 'أهلاً وسهلاً في عالم التعلم!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  AppLocalizations.of(context)?.welcomeMessage ?? 'لنبدأ رحلة التعلم الممتعة معاً\nأولاً، دعنا ننشئ ملفك الشخصي',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Create Profile Button
                GameButton(
                  text: AppLocalizations.of(context)?.createProfile ?? 'إنشاء ملف شخصي',
                  onPressed: _navigateToCreateProfile,
                  width: 250,
                  height: 60,
                  icon: Icons.person_add,
                ),
                
                const SizedBox(height: 20),
                
                // Skip Button
                TextButton(
                  onPressed: _skipProfileCreation,
                  child: Text(
                    AppLocalizations.of(context)?.skip ?? 'تخطي الآن',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Profile Avatar
          GestureDetector(
            onTap: _navigateToProfile,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _childProfile?.avatarPath.isNotEmpty == true
                  ? ClipOval(
                      child: _childProfile!.avatarPath.endsWith('.svg')
                          ? FutureBuilder<String>(
                              future: _loadSvgAsset(_childProfile!.avatarPath),
                              builder: (context, snapshot) {
                                if (snapshot.hasError || !snapshot.hasData) {
                                  return Image.asset(
                                    'assets/images/avatars/avatar1.png',
                                    fit: BoxFit.cover,
                                    width: 50,
                                    height: 50,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 30,
                                      );
                                    },
                                  );
                                }
                          return SvgPicture.asset(
                                  _childProfile!.avatarPath,
                                  fit: BoxFit.cover,
                                  width: 50,
                                  height: 50,
                                );
                              },
                            )
                           : (_childProfile!.avatarPath.startsWith('assets/')
                              ? Image.asset(
                                  _childProfile!.avatarPath,
                                  fit: BoxFit.cover,
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 30,
                                    );
                                  },
                                )
                              : SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: BoringAvatars(
                                    name: _childProfile!.avatarPath,
                                  ),
                                )
                            ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Greeting and Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _childProfile?.name ?? AppLocalizations.of(context)?.littleWorld ?? 'عالم صغير',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Settings Button
          GameIconButton(
            icon: Icons.settings,
            onPressed: _openSettings,
            size: 45,
            backgroundColor: AppColors.surface,
            iconColor: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // App Logo
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(
              Icons.school,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          // App Name
          Expanded(
            child: Text(
              AppConstants.appName(context),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          
          // Language Switcher
          const LanguageIconButton(size: 20),
          
          const SizedBox(width: 8),
          
          // Settings Button
          GameIconButton(
            icon: Icons.settings,
            onPressed: _openSettings,
            size: 45,
            backgroundColor: AppColors.surface,
            iconColor: AppColors.textSecondary,
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
      child: Column(
        children: [
          AnimatedCharacter(
            state: CharacterState.happy,
            size: 100,
            message: _getWelcomeMessage(),
            onTap: _showCharacterDialog,
            motionStyle: MotionStyle.gentle,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GameButton(
                  text: 'العب',
                  onPressed: _navigateToGames,
                  backgroundColor: AppColors.primary,
                  icon: Icons.play_arrow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GameButton(
                  text: 'خطة اليوم',
                  onPressed: _navigateToDailyPlan,
                  backgroundColor: AppColors.info,
                  icon: Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return LevelProgressBar(
      currentLevel: _childProfile!.getCurrentLevel(),
      progressToNextLevel: _childProfile!.getProgressToNextLevel(),
      totalPoints: _childProfile!.totalPoints,
      levelTitle: _childProfile!.getLevelTitle(),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                  Text(
            AppLocalizations.of(context)?.favoriteGames ?? 'الألعاب المفضلة',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: GameCard(
                title: AppLocalizations.of(context)?.numbersGame ?? 'العد',
                subtitle: AppLocalizations.of(context)?.learnNumbers ?? 'تعلم الأرقام',
                icon: Icons.looks_one,
                backgroundColor: AppColors.funBlue,
                onTap: () => _navigateToSpecificGame(AppConstants.countingGame),
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: GameCard(
                title: AppLocalizations.of(context)?.additionGame ?? 'الجمع',
                subtitle: AppLocalizations.of(context)?.learnAddition ?? 'عمليات بسيطة',
                icon: Icons.add,
                backgroundColor: AppColors.funGreen,
                onTap: () => _navigateToSpecificGame(AppConstants.additionGame),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: GameCard(
                title: AppLocalizations.of(context)?.shapesGame ?? 'الأشكال',
                subtitle: AppLocalizations.of(context)?.learnShapes ?? 'تعرف على الأشكال',
                icon: Icons.category,
                backgroundColor: AppColors.funYellow,
                onTap: () => _navigateToSpecificGame(AppConstants.shapesGame),
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: GameCard(
                title: AppLocalizations.of(context)?.colorsGame ?? 'الألوان',
                subtitle: AppLocalizations.of(context)?.learnColors ?? 'عالم الألوان',
                icon: Icons.palette,
                backgroundColor: AppColors.funRed,
                onTap: () => _navigateToSpecificGame(AppConstants.colorsGame),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
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
                    Text(
            AppLocalizations.of(context)?.recentActivity ?? 'النشاط الأخير',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (_childProfile != null) ...[
            _buildActivityItem(
              icon: Icons.emoji_events,
                              title: AppLocalizations.of(context)?.totalPoints ?? 'إجمالي النقاط',
              value: '${_childProfile!.totalPoints}',
              color: AppColors.goldStar,
            ),
            
            const SizedBox(height: 12),
            
            _buildActivityItem(
              icon: Icons.games,
                              title: AppLocalizations.of(context)?.gamesPlayed ?? 'الألعاب المكتملة',
              value: '${_childProfile!.totalGamesPlayed}',
              color: AppColors.primary,
            ),
            
            const SizedBox(height: 12),
            
            _buildActivityItem(
              icon: Icons.access_time,
                              title: AppLocalizations.of(context)?.timePlayed ?? 'وقت اللعب',
                value: '${_childProfile!.totalTimePlayedMinutes} ${AppLocalizations.of(context)?.minutes ?? 'دقيقة'}',
              color: AppColors.info,
            ),
          ] else
            Text(
              AppLocalizations.of(context)?.noRecentActivity ?? 'لا يوجد نشاط بعد',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return AppLocalizations.of(context)?.goodMorning ?? 'صباح الخير';
    } else if (hour < 17) {
      return AppLocalizations.of(context)?.goodAfternoon ?? 'مساء الخير';
    } else {
      return AppLocalizations.of(context)?.goodEvening ?? 'مساء الخير';
    }
  }

  String _getWelcomeMessage() {
          final messages = [
        AppLocalizations.of(context)?.welcomeMessage ?? 'مرحباً! هيا نتعلم شيئاً جديداً اليوم!',
        AppLocalizations.of(context)?.welcomeMessage ?? 'أهلاً بك! جاهز للمغامرة؟',
        AppLocalizations.of(context)?.welcomeMessage ?? 'يا أهلاً! دعنا نلعب ونتعلم معاً!',
        AppLocalizations.of(context)?.welcomeMessage ?? 'مرحباً صديقي! وقت المرح والتعلم!',
      ];
    
    final index = DateTime.now().day % messages.length;
    return messages[index];
  }

  void _navigateToGames() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GamesMenuScreen(),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    ).then((_) {
      // Always refresh the screen after returning from profile
      _refreshProfile();
    });
  }

  void _navigateToCreateProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(isCreating: true),
      ),
    ).then((_) {
      // Refresh the screen after profile creation
      _refreshProfile();
    });
  }

  Future<void> _refreshProfile() async {
    try {
      if (_storage != null) {
        final updatedProfile = await _storage!.getChildProfile();
        setState(() {
          _childProfile = updatedProfile;
          _hasProfile = updatedProfile != null;
        });
      } else {
        // Try to reinitialize storage if it failed before
        try {
          _storage = await LocalStorageService.getInstance();
          final updatedProfile = await _storage!.getChildProfile();
          setState(() {
            _childProfile = updatedProfile;
            _hasProfile = updatedProfile != null;
          });
        } catch (e) {
          print('Error reinitializing storage: $e');
        }
      }
    } catch (e) {
      print('Error refreshing profile: $e');
    }
  }

  void _navigateToSpecificGame(String gameType) {
    // This will be implemented when game screens are created
    _navigateToGames();
  }

  void _skipProfileCreation() async {
    // Create a default profile
    final defaultProfile = ChildProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: AppLocalizations.of(context)?.newChild ?? 'طفل جديد',
      age: 5,
      parentId: 'default_parent', // إضافة parentId
    );
    
    try {
      if (_storage != null) {
        await _storage!.saveChildProfile(defaultProfile);
      } else {
        // Try to initialize storage
        _storage = await LocalStorageService.getInstance();
        await _storage!.saveChildProfile(defaultProfile);
      }
      
      setState(() {
        _childProfile = defaultProfile;
        _hasProfile = true;
      });
    } catch (e) {
      print('Error saving default profile: $e');
      // Still update UI even if saving fails
      setState(() {
        _childProfile = defaultProfile;
        _hasProfile = true;
      });
    }
  }

  void _openSettings() {
    _openSettingsWithParentGate();
  }

  void _showCharacterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.welcomeMessage ?? 'مرحباً!'),
          content: Text(
            AppLocalizations.of(context)?.welcomeMessage ?? 'أنا هنا لمساعدتك في التعلم واللعب. هل أنت مستعد للمغامرة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)?.yes ?? 'حسناً'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSettingsWithParentGate() async {
    final ok = await ParentGate.show(context);
    if (!ok) return;

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _navigateToDailyPlan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DailyPlanScreen(),
      ),
    );
  }

  Future<String> _loadSvgAsset(String path) async {
    try {
      // Try to load the SVG asset
      await DefaultAssetBundle.of(context).loadString(path);
      return path;
    } catch (e) {
      // If SVG loading fails, throw error to trigger fallback
      throw Exception('SVG asset not found: $path');
    }
  }
}

