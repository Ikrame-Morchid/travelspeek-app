import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('fr');
  bool _isInitialized = false;

  Locale get currentLocale => _currentLocale;
  Locale get locale => _currentLocale; // ✅ Alias pour MaterialApp
  String get currentLanguage => _currentLocale.languageCode;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'fr';
      
      _currentLocale = Locale(languageCode);
      _isInitialized = true;
      
      print('Language initialized: $languageCode');
      notifyListeners();
    } catch (e) {
      print('Error loading language: $e');
      _currentLocale = const Locale('fr');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;
    
    print('Changing language: ${_currentLocale.languageCode} → ${locale.languageCode}');
    
    _currentLocale = locale;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
      print('Language saved: ${locale.languageCode}');
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  bool isCurrentLanguage(String code) {
    return _currentLocale.languageCode == code;
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      case 'es':
        return 'Español';
      default:
        return code;
    }
  }

  String getLanguageFlag(String code) {
    switch (code) {
      case 'en':
        return '🇬🇧';
      case 'fr':
        return '🇫🇷';
      case 'ar':
        return '🇸🇦';
      case 'es':
        return '🇪🇸';
      default:
        return '🌍';
    }
  }
}