import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/colors.dart';

class LanguageSwitchButton extends StatelessWidget {
  final bool showText;
  final double? size;
  
  const LanguageSwitchButton({
    Key? key,
    this.showText = true,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        print('LanguageSwitchButton rebuilding with locale: ${languageProvider.currentLocale}');
        return GestureDetector(
          onTap: () {
            print('Language switch button tapped. Current language: ${languageProvider.getLanguageCode()}, Locale: ${languageProvider.currentLocale}');
            languageProvider.switchLanguage();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flag
                Text(
                  languageProvider.getLanguageFlag(),
                  style: TextStyle(
                    fontSize: size ?? 16,
                  ),
                ),
                
                if (showText) ...[
                  const SizedBox(width: 8),
                  
                  // Language name
                  Text(
                    languageProvider.getLanguageName(),
                    style: TextStyle(
                      fontSize: size != null ? size! - 2 : 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(width: 4),
                  
                  // Arrow icon
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: size != null ? size! - 4 : 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// Alternative: Simple icon button
class LanguageIconButton extends StatelessWidget {
  final double? size;
  
  const LanguageIconButton({
    Key? key,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return IconButton(
          onPressed: () => languageProvider.switchLanguage(),
          icon: Text(
            languageProvider.getLanguageFlag(),
            style: TextStyle(
              fontSize: size ?? 20,
            ),
          ),
          tooltip: languageProvider.getLanguageName(),
        );
      },
    );
  }
}

// Alternative: Dropdown menu
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return PopupMenuButton<String>(
          onSelected: (languageCode) {
            languageProvider.setLanguage(languageCode);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'ar',
              child: Row(
                children: [
                  const Text('🇸🇦'),
                  const SizedBox(width: 8),
                  const Text('العربية'),
                  if (languageProvider.isArabic)
                    const Spacer(),
                  if (languageProvider.isArabic)
                    const Icon(Icons.check, size: 16),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'en',
              child: Row(
                children: [
                  const Text('🇺🇸'),
                  const SizedBox(width: 8),
                  const Text('English'),
                  if (languageProvider.isEnglish)
                    const Spacer(),
                  if (languageProvider.isEnglish)
                    const Icon(Icons.check, size: 16),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languageProvider.getLanguageFlag(),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  languageProvider.getLanguageName(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
