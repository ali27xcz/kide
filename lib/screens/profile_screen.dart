import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../models/achievement.dart';
import '../services/local_storage.dart';
import '../services/progress_tracker.dart';
import '../utils/colors.dart';
import '../widgets/game_button.dart';
import '../widgets/progress_bar.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/animated_character.dart';

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
  
  // Form controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedAvatar = '';

  final List<String> _avatarOptions = [
    'images/avatars/boy1.png',
    'images/avatars/girl1.png',
    'images/avatars/boy2.png',
    'images/avatars/girl2.png',
    'images/avatars/robot.png',
    'images/avatars/cat.png',
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
      _storage = await LocalStorageService.getInstance();
      _progressTracker = await ProgressTracker.getInstance();
      
      _childProfile = await _storage!.getChildProfile();
      _achievements = await _storage!.getAchievements();
      _statistics = await _progressTracker!.getDetailedStatistics();
      
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
        
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _avatarOptions.length,
            itemBuilder: (context, index) {
              final avatar = _avatarOptions[index];
              final isSelected = avatar == _selectedAvatar;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = avatar),
                child: Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: ClipOval(
                    child: Container(
                      color: AppColors.cardBackground,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
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
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _childProfile?.avatarPath.isNotEmpty == true
                ? ClipOval(
                    child: Container(
                      color: AppColors.cardBackground,
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 50,
                  ),
          ),
          
          const SizedBox(height: 16),
          
          // Name
          Text(
            _childProfile?.name ?? 'عالم صغير',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
        const SnackBar(
          content: Text('يرجى إدخال الاسم'),
          backgroundColor: AppColors.incorrect,
        ),
      );
      return;
    }
    
    final age = int.tryParse(ageText);
    if (age == null || age < 3 || age > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال عمر صحيح (3-12 سنة)'),
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
      );
      
      await _storage!.saveChildProfile(profile);
      
      setState(() {
        _childProfile = profile;
        _isEditing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الملف الشخصي بنجاح!'),
          backgroundColor: AppColors.correct,
        ),
      );
      
      if (widget.isCreating) {
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ في حفظ الملف الشخصي'),
          backgroundColor: AppColors.incorrect,
        ),
      );
    }
  }

  void _showDetailedReport() {
    // This will be implemented later
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('التقرير المفصل قريباً!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openSettings() {
    // This will be implemented later
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('الإعدادات قريباً!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

