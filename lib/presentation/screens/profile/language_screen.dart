import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../providers/language_provider.dart';
import '../../providers/monument_provider.dart';
import '../../providers/theme_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColor = isDark ? const Color(0xFF0F1923) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1A2530) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? const Color(0xFF2A3540) : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A2530) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'app_language'.tr(context),
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<LanguageProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildLanguageCard(
                context,
                languageCode: 'en',
                languageName: 'english'.tr(context),
                nativeName: 'English',
                isSelected: provider.isCurrentLanguage('en'),
                onTap: () => _changeLanguage(context, const Locale('en')),
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              
              _buildLanguageCard(
                context,
                languageCode: 'fr',
                languageName: 'french'.tr(context),
                nativeName: 'Français',
                isSelected: provider.isCurrentLanguage('fr'),
                onTap: () => _changeLanguage(context, const Locale('fr')),
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              
              _buildLanguageCard(
                context,
                languageCode: 'ar',
                languageName: 'arabic'.tr(context),
                nativeName: 'العربية',
                isSelected: provider.isCurrentLanguage('ar'),
                onTap: () => _changeLanguage(context, const Locale('ar')),
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              
              _buildLanguageCard(
                context,
                languageCode: 'es',
                languageName: 'spanish'.tr(context),
                nativeName: 'Español',
                isSelected: provider.isCurrentLanguage('es'),
                onTap: () => _changeLanguage(context, const Locale('es')),
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context, {
    required String languageCode,
    required String languageName,
    required String nativeName,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    required Color? subtitleColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 8,
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
                  Text(
                    languageName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? AppColors.primary 
                          : textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLanguage(BuildContext context, Locale locale) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final monumentProvider = Provider.of<MonumentProvider>(
      context,
      listen: false,
    );

    await languageProvider.setLocale(locale);
    await monumentProvider.loadMonuments(lang: locale.languageCode);

    if (context.mounted) {
      final langName = languageProvider.getLanguageName(locale.languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'language_changed_to'.tr(context).replaceAll('{lang}', langName),
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        if (context.mounted) {
          Navigator.pop(context);
        }
      });
    }
  }
}