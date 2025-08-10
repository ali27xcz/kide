import 'package:flutter/material.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import '../models/child_profile.dart';
import '../models/achievement.dart';
import '../services/local_storage.dart';
import '../services/progress_tracker.dart';
import '../utils/colors.dart';
import '../widgets/game_button.dart';
import 'settings_screen.dart';
import '../widgets/parent_gate.dart';
import '../widgets/progress_bar.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/animated_character.dart';
import '../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  final bool isCreating;
  
  const ProfileScreen({
    Key? key,
    this.isCreating = false,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  LocalStorageService? _storage;
  ProgressTracker? _progressTracker;
  ChildProfile? _childProfile;
  List<Achievement> _achievements = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  bool _isEditing = false;
  bool _hasChanges = false;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedAvatar = '';

  // 10 cartoon avatar seeds using boring_avatars (procedural, خفيفة وجميلة)
  final List<String> _avatarOptions = [
    'kedy-fox',
    'kedy-bunny',
    'kedy-bear',
    'kedy-panda',
    'kedy-kitty',
    'kedy-lion',
    'kedy-tiger',
    'kedy-unicorn',
    'kedy-dino',
    'kedy-robot',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.isCreating) {
      _isEditing = true;
      _isLoading = false;
      _selectedAvatar = _avatarOptions.first;
    } else {
      _initializeData();
    }
  }

  Widget _buildAvatarImage(String value) {
    // Use procedural avatar when not an asset path
    final isAsset = value.startsWith('assets/');
    if (isAsset) {
      return SizedBox.expand(
        child: Image.asset(
          value,
          fit: BoxFit.cover,
        ),
      );
    }
    return SizedBox.expand(
      child: BoringAvatars(
        name: value,
      ),
    );
  }

  Widget _buildCircularAvatar(String value, double size, {bool highlight = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: highlight
            ? LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.grey[200]!, Colors.grey[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: ClipOval(
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: value.isNotEmpty
                  ? SizedBox(
                      width: size - 6,
                      height: size - 6,
                      child: _buildAvatarImage(value),
                    )
                  : Container(
                      color: AppColors.cardBackground,
                      child: Icon(
                        Icons.person,
                        size: size * 0.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _fadeController.forward();
  }

  Future<void> _initializeData() async {
    try {
      // Try to initialize storage
      try {
        _storage = await LocalStorageService.getInstance();
        _childProfile = await _storage!.getChildProfile();
        _achievements = await _storage!.getAchievements();
      } catch (e) {
        print('Error initializing storage in profile screen: $e');
        // Continue without storage - use default values
        _achievements = [];
      }
      
      // Try to initialize progress tracker
      try {
        _progressTracker = await ProgressTracker.getInstance();
        _statistics = await _progressTracker!.getDetailedStatistics();
      } catch (e) {
        print('Error initializing progress tracker in profile screen: $e');
        // Continue without progress tracker - use default statistics
        _statistics = {};
      }
      
      // Set up form data if profile exists
      if (_childProfile != null) {
        _nameController.text = _childProfile!.name;
        _ageController.text = _childProfile!.age.toString();
        _selectedAvatar = _childProfile!.avatarPath.isNotEmpty 
            ? _childProfile!.avatarPath 
            : _avatarOptions.first;
      }
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error initializing profile screen: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _ageController.dispose();
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
                    child: _isEditing ? _buildEditForm() : _buildProfileContent(),
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
          if (!widget.isCreating)
            GameIconButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.of(context).pop(),
              size: 45,
              backgroundColor: AppColors.surface,
              iconColor: AppColors.textSecondary,
            ),
          
          if (!widget.isCreating) const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isCreating ? 'إنشاء ملف شخصي' : 'الملف الشخصي',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.isCreating 
                      ? 'أخبرنا عن نفسك' 
                      : 'معلوماتك وإنجازاتك',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          if (!widget.isCreating && !_isEditing)
            GameIconButton(
              icon: Icons.edit,
              onPressed: () => setState(() => _isEditing = true),
              size: 45,
              backgroundColor: AppColors.primary,
              iconColor: Colors.white,
            ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        // Character
        const AnimatedCharacter(
          state: CharacterState.encouraging,
          size: 100,
          message: 'أخبرني عن نفسك!',
          motionStyle: MotionStyle.gentle,
        ),
        
        const SizedBox(height: 30),
        
        // Avatar Selection
        _buildAvatarSelection(),
        
        const SizedBox(height: 30),
        
        // Name Input
        _buildInputField(
          controller: _nameController,
          label: 'الاسم',
          hint: 'اكتب اسمك هنا',
          icon: Icons.person,
        ),
        
        const SizedBox(height: 20),
        
        // Age Input
        _buildInputField(
          controller: _ageController,
          label: 'العمر',
          hint: 'كم عمرك؟',
          icon: Icons.cake,
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: 40),
        
        // Action Buttons
        Row(
          children: [
            if (!widget.isCreating) ...[
              Expanded(
                child: GameButton(
                  text: 'إلغاء',
                  onPressed: _cancelEdit,
                  backgroundColor: AppColors.buttonSecondary,
                  textColor: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
            ],
            
            Expanded(
              child: GameButton(
                text: widget.isCreating ? 'إنشاء الملف' : 'حفظ التغييرات',
                onPressed: _saveProfile,
                backgroundColor: AppColors.primary,
                icon: Icons.save,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileContent() {
    return Column(
      children: [
        // Profile Header
        _buildProfileHeader(),
        
        const SizedBox(height: 30),
        
        // Level Progress
        if (_childProfile != null) _buildLevelSection(),
        
        const SizedBox(height: 30),
        
        // Statistics
        _buildStatisticsSection(),
        
        const SizedBox(height: 30),
        
        // Achievements
        _buildAchievementsSection(),
        
        const SizedBox(height: 30),
        
        // Parent Section
        _buildParentSection(),
      ],
    );
  }

  Widget _buildAvatarSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر صورتك المفضلة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Grid instead of horizontal list for better presentation
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: _avatarOptions.length,
          itemBuilder: (context, index) {
            final avatar = _avatarOptions[index];
            final isSelected = avatar == _selectedAvatar;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedAvatar = avatar),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: _buildCircularAvatar(avatar, 70, highlight: isSelected),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 8),
        
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textLight,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.primary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with enhanced styling
          Stack(
            children: [
              _buildCircularAvatar(_childProfile?.avatarPath ?? '', 120, highlight: true),
              if (widget.isCreating == true)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Name with improved styling
          Text(
            _childProfile?.name ?? 'عالم صغير',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Age and Level
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_childProfile?.age ?? 6} سنوات',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldStar.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _childProfile?.getLevelTitle() ?? 'مبتدئ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.goldStar,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSection() {
    return LevelProgressBar(
      currentLevel: _childProfile!.getCurrentLevel(),
      progressToNextLevel: _childProfile!.getProgressToNextLevel(),
      totalPoints: _childProfile!.totalPoints,
      levelTitle: _childProfile!.getLevelTitle(),
    );
  }

  Widget _buildStatisticsSection() {
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
            'الإحصائيات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                icon: Icons.games,
                title: 'الألعاب',
                value: '${_statistics['totalGames'] ?? 0}',
                color: AppColors.primary,
              ),
              _buildStatCard(
                icon: Icons.star,
                title: 'النجوم',
                value: '${_achievements.where((a) => a.isUnlocked).length}',
                color: AppColors.goldStar,
              ),
              _buildStatCard(
                icon: Icons.access_time,
                title: 'وقت اللعب',
                value: '${_statistics['totalTimeMinutes'] ?? 0}د',
                color: AppColors.info,
              ),
              _buildStatCard(
                icon: Icons.trending_up,
                title: 'المتوسط',
                value: '${((_statistics['averageScore'] ?? 0.0) * 100).round()}%',
                color: AppColors.correct,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsSection() {
    final unlockedAchievements = _achievements.where((a) => a.isUnlocked).toList();
    
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإنجازات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              Text(
                '${unlockedAchievements.length}/${_achievements.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (unlockedAchievements.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: unlockedAchievements.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AchievementBadge(
                      achievement: unlockedAchievements[index],
                      size: 60,
                      showProgress: false,
                      showTitle: true,
                      showDescription: false,
                    ),
                  );
                },
              ),
            )
          else
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'لا توجد إنجازات بعد',
                    style: TextStyle(
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

  Widget _buildParentSection() {
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
            'للآباء',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          GameButton(
            text: 'تقرير مفصل',
            onPressed: _showDetailedReport,
            backgroundColor: AppColors.info,
            icon: Icons.assessment,
            width: double.infinity,
          ),
          
          const SizedBox(height: 12),
          
          GameButton(
            text: 'إعدادات التطبيق',
            onPressed: _openSettings,
            backgroundColor: AppColors.buttonSecondary,
            textColor: AppColors.textSecondary,
            icon: Icons.settings,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      if (_childProfile != null) {
        _nameController.text = _childProfile!.name;
        _ageController.text = _childProfile!.age.toString();
        _selectedAvatar = _childProfile!.avatarPath.isNotEmpty 
            ? _childProfile!.avatarPath 
            : _avatarOptions.first;
      }
    });
  }

  void _saveProfile() async {
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
                          content: Text(AppLocalizations.of(context)?.pleaseEnterName ?? 'يرجى إدخال الاسم'),
          backgroundColor: AppColors.incorrect,
        ),
      );
      return;
    }
    
    final age = int.tryParse(ageText);
    if (age == null || age < 3 || age > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
                          content: Text(AppLocalizations.of(context)?.pleaseEnterValidAge ?? 'يرجى إدخال عمر صحيح (3-12 سنة)'),
          backgroundColor: AppColors.incorrect,
        ),
      );
      return;
    }
    
    try {
      final profile = _childProfile?.copyWith(
        name: name,
        age: age,
        avatarPath: _selectedAvatar,
      ) ?? ChildProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        age: age,
        avatarPath: _selectedAvatar,
        parentId: 'default_parent',
      );
      
      // Try to save profile if storage is available
      if (_storage != null) {
        try {
          await _storage!.saveChildProfile(profile);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                              content: Text(AppLocalizations.of(context)?.profileSaved ?? 'تم حفظ الملف الشخصي بنجاح!'),
              backgroundColor: AppColors.correct,
            ),
          );
        } catch (e) {
          print('Error saving profile to storage: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء الملف الشخصي مؤقتاً (لن يُحفظ نهائياً)'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } else {
        // Storage not available - create profile temporarily
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.profileCreatedTemporary ?? 'تم إنشاء الملف الشخصي مؤقتاً (لن يُحفظ نهائياً)'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      
      setState(() {
        _childProfile = profile;
        _isEditing = false;
        _hasChanges = true;
      });
      
      if (widget.isCreating) {
        Navigator.of(context).pop(true);
      }
      
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.errorSavingProfile ?? 'حدث خطأ في حفظ الملف الشخصي'),
          backgroundColor: AppColors.incorrect,
        ),
      );
    }
  }

  void _showDetailedReport() {
    _openDetailedReportWithParentGate();
  }

  void _openSettings() {
    _openSettingsWithParentGate();
  }

  Future<void> _openSettingsWithParentGate() async {
    final ok = await ParentGate.show(context);
    if (!ok || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  Future<void> _openDetailedReportWithParentGate() async {
    final ok = await ParentGate.show(context);
    if (!ok || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _DetailedReportScreen(),
      ),
    );
  }
}

class _DetailedReportScreen extends StatefulWidget {
  const _DetailedReportScreen({Key? key}) : super(key: key);

  @override
  State<_DetailedReportScreen> createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends State<_DetailedReportScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final tracker = await ProgressTracker.getInstance();
      final stats = await tracker.getDetailedStatistics();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
          child: Column(
            children: [
              // Header
              Container(
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
                      child: Text(
                        'تقرير مفصل',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _stats == null
                        ? const Center(
                            child: Text(
                              'لا توجد بيانات بعد',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOverviewCards(),
                                const SizedBox(height: 20),
                                _buildGameTypeStats(),
                                const SizedBox(height: 20),
                                _buildTrendAndStreak(),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final items = [
      _StatItem(Icons.games, 'الألعاب', '${_stats!['totalGames'] ?? 0}', AppColors.primary),
      _StatItem(Icons.emoji_events, 'النقاط', '${_stats!['totalPoints'] ?? 0}', AppColors.funOrange),
      _StatItem(Icons.access_time, 'الوقت (د)', '${_stats!['totalTimeMinutes'] ?? 0}', AppColors.info),
      _StatItem(Icons.star, 'إنجازات', '${_stats!['unlockedAchievements'] ?? 0}', AppColors.goldStar),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: items
          .map((e) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: e.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: e.color.withOpacity(0.25)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(e.icon, color: e.color, size: 22),
                    const SizedBox(height: 6),
                    Text(e.value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: e.color,
                        )),
                    const SizedBox(height: 2),
                    Text(e.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildGameTypeStats() {
    final Map<String, dynamic> gameTypeStats =
        (_stats!['gameTypeStats'] as Map<String, dynamic>? ?? {});
    if (gameTypeStats.isEmpty) {
      return const SizedBox.shrink();
    }
    final entries = gameTypeStats.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أداء حسب نوع اللعبة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...entries.map((e) {
          final v = e.value as Map<String, dynamic>;
          final avg = ((v['averageScore'] ?? 0.0) * 100).round();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          )),
                      const SizedBox(height: 6),
                      Text('عدد اللعب: ${v['totalPlayed'] ?? 0}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text('أفضل نتيجة: ${v['bestScore'] ?? 0}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$avg%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrendAndStreak() {
    final trend = _stats!['progressTrend'] ?? 'stable';
    final streak = _stats!['winStreak'] ?? 0;
    final playDays = _stats!['playDays'] ?? 0;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('الاتجاه', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(
                  trend == 'improving' ? 'تحسّن' : trend == 'declining' ? 'تراجع' : 'مستقر',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('سلسلة الفوز', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text('$streak',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('أيام اللعب', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text('$playDays',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  _StatItem(this.icon, this.label, this.value, this.color);
}

