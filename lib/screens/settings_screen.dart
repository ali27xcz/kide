import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/audio_service.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../l10n/app_localizations.dart';

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
    _audioService = await AudioService.getInstance();
    setState(() {
      _musicEnabled = _audioService!.isMusicEnabled;
      _soundEnabled = _audioService!.isSoundEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settingsTitle ?? 'الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(AppLocalizations.of(context)?.language ?? 'اللغة'),
          Card(
            child: SwitchListTile.adaptive(
              title: Text('${AppLocalizations.of(context)?.interface ?? 'الواجهة'}: ${languageProvider.getLanguageName()}'),
              subtitle: Text(AppLocalizations.of(context)?.switchBetweenArabicAndEnglish ?? 'بدّل بين العربية والإنجليزية'),
              value: languageProvider.isArabic,
              onChanged: (_) => languageProvider.switchLanguage(),
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle(AppLocalizations.of(context)?.soundEffects ?? 'الصوت'),
          Card(
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
          Card(
            child: SwitchListTile.adaptive(
              title: Text(AppLocalizations.of(context)?.darkModeComingSoon ?? 'الوضع الداكن (قريباً)'),
              value: _darkMode,
              onChanged: (v) {
                setState(() => _darkMode = v);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)?.darkModeComingSoon ?? 'ميزة الوضع الداكن ستتوفر قريباً')),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle(AppLocalizations.of(context)?.account ?? 'الحساب'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.incorrect),
              title: Text(AppLocalizations.of(context)?.logout ?? 'تسجيل الخروج'),
              onTap: () async {
                await authProvider.signOut();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ),
        ],
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


