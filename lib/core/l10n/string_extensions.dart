import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/language_provider.dart';
import 'app_translations.dart';

extension TranslationExtension on String {
  /// Traduit une clé en fonction de la langue actuelle
  /// 
  /// Utilisation :
  /// ```dart
  /// Text("welcome_back".tr(context))
  /// ```
  String tr(BuildContext context) {
    try {
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      
      final currentLang = languageProvider.currentLanguage;
      
      return AppTranslations.get(this, currentLang);
      
    } catch (e) {
      print('Translation error for key "$this": $e');
      return this;
    }
  }
}