import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/kid_avatar.dart';
import '../models/child_profile.dart';
import '../services/local_storage.dart';
import '../services/audio_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/game_button.dart';
import '../widgets/progress_bar.dart';
// Removed animated_character usage
import 'package:lottie/lottie.dart';
import '../utils/lottie_cache.dart';
import '../utils/navigation_utils.dart';
import 'games_menu_screen.dart';
import 'games/counting_game_screen.dart';
import 'games/alphabet_game_screen.dart';
import 'games/shapes_game_screen.dart';
import 'games/colors_game_screen.dart';
import 'games/puzzle_game_screen.dart';
import 'games/memory_game_screen.dart';
import 'games/match_pairs_game_screen.dart';
import 'games/drag_drop_categories_game_screen.dart';
import 'games/sound_recognition_game_screen.dart';
import 'games/magical_letters_adventure_screen.dart';
import 'games/addition_game_screen.dart';
import 'games/english_spelling_bee_screen.dart';
import 'games/sentence_builder_game_screen.dart';
import 'games/phonics_blending_game_screen.dart';
import 'games/telling_time_game_screen.dart';
import 'games/logic_path_programming_game_screen.dart';
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showHero = false; // تأجيل عرض لوتّي الثقيلة لما بعد أول إطار
  
  LocalStorageService? _storage;
  AudioService? _audioService;
  ChildProfile? _childProfile;
  bool _isLoading = true;
  bool _hasProfile = false;
  double _loadingProgress = 0.12; // ensure visible immediately
  Timer? _loadingTimer;

  // Rotating motivational phrases for the main character section
  final List<String> _motivationalPhrases = const [
    '🌟 "أنت بطل اليوم!"',
    '🎯 "هيا نبدأ مغامرة جديدة!"',
    '🚀 "جاهز للانطلاق نحو النجوم؟"',
    '🏆 "كل تحدي يجعلك أقوى!"',
    '🐾 "خطوة جديدة نحو النجاح!"',
    '✨ "أنت مبدع ورائع دائماً!"',
    '🧠 "ذكاؤك يضيء كالنجم!"',
    '🎨 "أطلق خيالك وابدع!"',
    '💡 "أفكارك مدهشة حقاً!"',
    '📚 "كل يوم هو فرصة جديدة!"',
  ];
  int _currentPhraseIndex = 0;
  Timer? _phraseTimer;
  final math.Random _random = math.Random();
  late final List<Color> _motivationalColors = [
    Colors.black,
    Colors.indigo.shade900,
    Colors.blueGrey.shade900,
    Colors.brown.shade800,
    Colors.deepPurple.shade900,
    Colors.teal.shade900,
    Colors.red.shade900,
    Colors.blue.shade900,
    Colors.green.shade900,
    Colors.orange.shade900,
    AppColors.textPrimary,
  ];

  List<InlineSpan> _buildColoredWordSpans(String text) {
    final words = text.split(RegExp(r"\s+"));
    return [
      for (int i = 0; i < words.length; i++)
        TextSpan(
          text: i < words.length - 1 ? '${words[i]} ' : words[i],
          style: TextStyle(
            color: _motivationalColors[_random.nextInt(_motivationalColors.length)],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        )
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Start loading progress immediately so the bar appears on first frame
    _startLoadingProgress();
    _startPhraseRotation();
    // Defer heavy initialization until after first frame so loading UI shows instantly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeServices();
    });
    // أظهر الرسوم فوراً - إزالة التأخير لمنع الشاشة البيضاء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showHero = true);
    });
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

    // Pulse animation for Play button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startLoadingProgress() {
    _loadingProgress = 0.12; // start clearly visible
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        // ease towards 0.9 max during init
        if (_loadingProgress < 0.9) {
          _loadingProgress = (_loadingProgress + 0.03).clamp(0.0, 0.9);
        }
      });
    });
  }

  Future<void> _endLoadingProgress({bool forceWelcome = false}) async {
    // complete progress immediately
    _loadingTimer?.cancel();
    setState(() {
      _loadingProgress = 1.0;
      _isLoading = false;
      if (forceWelcome) {
        _hasProfile = false;
      }
    });
    
    // Start animations immediately
    _fadeController.forward();
    if (mounted) {
      _slideController.forward();
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Don't wait for anything - show UI immediately and load in background
      unawaited(_initializeStorageInBackground());
      unawaited(_initializeAudioInBackground());
      
      // Finish loading progress immediately
      await _endLoadingProgress();
      
    } catch (e) {
      print('Error initializing home screen: $e');
      // Even if everything fails, still show the UI
      await _endLoadingProgress(forceWelcome: true);
    }
  }

  Future<void> _initializeStorageInBackground() async {
    try {
      _storage = await LocalStorageService.getInstance();
      
      // Get child profile
      final profile = await _storage!.getChildProfile();
      final hasProfile = profile != null;

      // Ensure avatar path uses only local asset avatars
      await _storage!.fixAvatarPaths();
      final updatedProfile = await _storage!.getChildProfile();
      
      // Update UI only if still mounted
      if (mounted) {
        setState(() {
          _childProfile = updatedProfile;
          _hasProfile = updatedProfile != null;
        });
      }
    } catch (e) {
      print('Error initializing storage service: $e');
      if (mounted) {
        setState(() {
          _hasProfile = false;
        });
      }
    }
  }

  Future<void> _initializeAudioInBackground() async {
    try {
      _audioService = await AudioService.getInstance();
      await Future.wait([
        _audioService!.setSoundEnabled(true),
        _audioService!.setMusicEnabled(true),
        _audioService!.preloadSounds(),
      ]);
      // Start general music only if we are not already in menu context
      unawaited(_audioService!.playBackgroundMusic());
    } catch (e) {
      print('Error initializing audio service: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _loadingTimer?.cancel();
    _phraseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show only the background while loading; no dialog, no text/progress bar
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildMainContent(),
            ),
          ),
        ),
      ),
    );
  }

  void _startPhraseRotation() {
    // pick an initial random index
    _currentPhraseIndex = _random.nextInt(_motivationalPhrases.length);
    _phraseTimer?.cancel();
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      int nextIndex = _random.nextInt(_motivationalPhrases.length);
      if (nextIndex == _currentPhraseIndex) {
        nextIndex = (nextIndex + 1) % _motivationalPhrases.length;
      }
      setState(() {
        _currentPhraseIndex = nextIndex;
      });
    });
  }

  // Extract leading emoji (before first space) and remaining text
  ({String emoji, String text}) _extractEmojiAndText(String input) {
    final int spaceIndex = input.indexOf(' ');
    if (spaceIndex > 0) {
      final String emoji = input.substring(0, spaceIndex);
      final String text = input.substring(spaceIndex + 1).trim();
      return (emoji: emoji, text: text);
    }
    return (emoji: '', text: input);
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

  // Removed old welcome/create-profile content permanently

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Profile Avatar
          GestureDetector(
            onTap: _navigateToProfile,
            child: KidAvatar(
              avatarValue: _childProfile?.avatarPath ?? '',
              size: 50,
              showRing: true,
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
          
          // Settings Button (Lottie)
          GestureDetector(
            onTap: _handleSettingsTap,
            child: Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
              ),
              padding: const EdgeInsets.all(6),
              child: LottiePreloader.getCachedLottie(
                'assets/lottie/Setting Icon.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
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
          
          // Settings Button (Lottie)
          GestureDetector(
            onTap: _handleSettingsTap,
            child: Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
              ),
              padding: const EdgeInsets.all(6),
              child: LottiePreloader.getCachedLottie(
                'assets/lottie/Setting Icon.json',
                fit: BoxFit.contain,
                repeat: true,
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
      child: Column(
        children: [
          GestureDetector(
            onTap: _showCharacterDialog,
            child: SizedBox(
              height: 190,
              child: _showHero
                  ? const RepaintBoundary(
                      child: _HeroLottie(),
                    )
                  : const _HeroPlaceholder(),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: Builder(
              key: ValueKey(_currentPhraseIndex),
              builder: (_) {
                final parts = _extractEmojiAndText(_motivationalPhrases[_currentPhraseIndex]);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered text
                    Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: Text.rich(
                        TextSpan(children: _buildColoredWordSpans(parts.text)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Emoji pinned to the far left of the available width
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            parts.emoji,
                            textAlign: TextAlign.left,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play Button - simple gradient button with Play icon (no Lottie)
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'ابدأ اللعب',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handlePlayTap,
                      borderRadius: BorderRadius.circular(16),
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 14,
                                spreadRadius: 0,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFFFFF), Color(0xFFF1F1F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.white70, width: 1),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 66,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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
    NavigationUtils.navigateWithFade(
      context,
      const GamesMenuScreen(),
      heroTag: 'games_button',
      duration: const Duration(milliseconds: 200),
    );
  }

  void _navigateToProfile() {
    NavigationUtils.navigateWithSlide(
      context,
      const ProfileScreen(),
      heroTag: 'profile_button',
      duration: const Duration(milliseconds: 200),
      beginOffset: const Offset(1.0, 0.0),
    ).then((_) {
      // Always refresh the screen after returning from profile
      _refreshProfile();
    });
  }

  // Removed create-profile navigation permanently

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
    // انتقل مباشرة إلى اللعبة المطلوبة بدلاً من فتح قائمة الألعاب
    Widget? screen;
    switch (gameType) {
      case AppConstants.countingGame:
        screen = const CountingGameScreen();
        break;
      case AppConstants.alphabetGame:
        screen = const AlphabetGameScreen();
        break;
      case AppConstants.shapesGame:
        screen = const ShapesGameScreen();
        break;
      case AppConstants.colorsGame:
        screen = const ColorsGameScreen();
        break;
      case AppConstants.additionGame:
        screen = const AdditionGameScreen();
        break;
      case AppConstants.puzzleGame:
        screen = const PuzzleGameScreen();
        break;
      case AppConstants.memoryGame:
        screen = const MemoryGameScreen();
        break;
      case AppConstants.matchPairsGame:
        screen = const MatchPairsGameScreen();
        break;
      case AppConstants.dragDropCategoriesGame:
        screen = const DragDropCategoriesGameScreen();
        break;
      case AppConstants.soundRecognitionGame:
        screen = const SoundRecognitionGameScreen();
        break;
      case AppConstants.magicalLettersAdventure:
        screen = const MagicalLettersAdventureScreen();
        break;
      case AppConstants.englishSpellingBeeGame:
        screen = const EnglishSpellingBeeScreen();
        break;
      case AppConstants.sentenceBuilderGame:
        screen = const SentenceBuilderGameScreen();
        break;
      case AppConstants.phonicsBlendingGame:
        screen = const PhonicsBlendingGameScreen();
        break;
      case AppConstants.tellingTimeGame:
        screen = const TellingTimeGameScreen();
        break;
      case AppConstants.logicPathProgrammingGame:
        screen = const LogicPathProgrammingGameScreen();
        break;
    }
    if (screen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen!));
    } else {
      _navigateToGames();
    }
  }

  // Removed skip profile creation flow

  void _openSettings() {
    _openSettingsWithParentGate();
  }

  Future<void> _handleSettingsTap() async {
    try {
      _audioService ??= await AudioService.getInstance();
      await _audioService?.playButtonClickSound();
    } catch (_) {}
    if (!mounted) return;
    _openSettings();
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
    if (!mounted) return;
    await NavigationUtils.navigateWithSlide(
      context,
      const SettingsScreen(),
      heroTag: 'settings_button',
      duration: const Duration(milliseconds: 200),
      beginOffset: const Offset(0.0, -1.0),
    );
  }

  void _navigateToDailyPlan() {
    NavigationUtils.navigateWithFade(
      context,
      const DailyPlanScreen(),
      heroTag: 'daily_plan_button',
      duration: const Duration(milliseconds: 200),
    );
  }

  Future<void> _handlePlayTap() async {
    try {
      _audioService ??= await AudioService.getInstance();
      await _audioService?.playButtonClickSound();
    } catch (_) {}
    if (!mounted) return;
    _navigateToGames();
  }

  // Removed unused SVG loader
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _HeroLottie extends StatelessWidget {
  const _HeroLottie();
  @override
  Widget build(BuildContext context) {
    return LottiePreloader.getCachedLottie(
      'assets/lottie/mainscreen.json',
      repeat: true,
      fit: BoxFit.contain,
    );
  }
}

