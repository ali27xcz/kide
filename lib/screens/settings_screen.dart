import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/audio_service.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../l10n/app_localizations.dart';
import 'auth/login_screen.dart';
import 'package:lottie/lottie.dart';
import '../utils/lottie_cache.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _musicEnabled = true;
  bool _soundEnabled = true;
  bool _darkMode = false; // placeholder

  AudioService? _audioService;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      _audioService = await AudioService.getInstance();
      if (mounted) {
        setState(() {
          _musicEnabled = _audioService!.isMusicEnabled;
          _soundEnabled = _audioService!.isSoundEnabled;
        });
      }
    } catch (e) {
      print('Error initializing audio service in settings: $e');
      // Continue with default values
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settingsTitle ?? 'الإعدادات'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9FBFF), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          _buildSectionTitle(AppLocalizations.of(context)?.language ?? 'اللغة'),
          _DecoratedCard(
            child: SwitchListTile.adaptive(
              title: Text('${AppLocalizations.of(context)?.interface ?? 'الواجهة'}: ${languageProvider.getLanguageName()}'),
              subtitle: Text(AppLocalizations.of(context)?.switchBetweenArabicAndEnglish ?? 'بدّل بين العربية والإنجليزية'),
              value: languageProvider.isArabic,
              onChanged: (_) => languageProvider.switchLanguage(),
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle(AppLocalizations.of(context)?.soundEffects ?? 'الصوت'),
          _DecoratedCard(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  title: Text(AppLocalizations.of(context)?.music ?? 'الموسيقى'),
                  subtitle: Text('قد لا تعمل على بعض الأجهزة'),
                  value: _musicEnabled,
                  onChanged: (v) async {
                    setState(() => _musicEnabled = v);
                    await _audioService?.setMusicEnabled(v);
                    if (v && _audioService != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تفعيل الموسيقى - إن لم تسمع صوتًا، قد يكون هناك تعارض مع الجهاز')),
                      );
                    }
                  },
                ),
                const Divider(height: 0),
                SwitchListTile.adaptive(
                  title: Text(AppLocalizations.of(context)?.soundEffects ?? 'المؤثرات الصوتية'),
                  subtitle: Text('قد لا تعمل على بعض الأجهزة'),
                  value: _soundEnabled,
                  onChanged: (v) async {
                    setState(() => _soundEnabled = v);
                    await _audioService?.setSoundEnabled(v);
                    if (v && _audioService != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تفعيل المؤثرات الصوتية - إن لم تسمع صوتًا، قد يكون هناك تعارض مع الجهاز')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle(AppLocalizations.of(context)?.appearance ?? 'المظهر'),
          _DecoratedCard(
            child: ListTile(
              leading: SizedBox(
                width: 48,
                height: 48,
                child: LottiePreloader.getCachedLottie(
                  'assets/lottie/Dark Mode Button.json',
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              title: Text(AppLocalizations.of(context)?.darkModeComingSoon ?? 'الوضع الداكن (قريباً)'),
              subtitle: const Text('قريباً'),
              onTap: () {
                setState(() => _darkMode = !_darkMode);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)?.darkModeComingSoon ?? 'ميزة الوضع الداكن ستتوفر قريباً')),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle(AppLocalizations.of(context)?.account ?? 'الحساب'),
          _DecoratedCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person, color: AppColors.primary),
                  title: Text(AppLocalizations.of(context)?.account ?? 'معلومات الحساب'),
                  subtitle: Text(
                    authProvider.currentUser?.email ?? 'غير مسجل الدخول',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    final email = authProvider.currentUser?.email;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(AppLocalizations.of(context)?.account ?? 'معلومات الحساب'),
                        content: Text(email ?? 'غير مسجل الدخول'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(AppLocalizations.of(context)?.close ?? 'حسناً'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.incorrect),
                  title: Text(AppLocalizations.of(context)?.logout ?? 'تسجيل الخروج'),
                  onTap: () async {
                    await authProvider.signOut();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _DecoratedCard extends StatelessWidget {
  final Widget child;
  const _DecoratedCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE9EEF8)),
      ),
      child: child,
    );
  }
}


