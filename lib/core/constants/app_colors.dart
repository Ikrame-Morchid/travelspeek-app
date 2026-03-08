import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Prevent instantiation

  // ========================
  //COULEURS PRINCIPALES (Basées sur Figma)
  // ========================
  static const Color primary = Color(0xFF5FB4B4); // Turquoise principal
  static const Color primaryDark = Color(0xFF4A9494); // Turquoise foncé
  static const Color primaryLight = Color(0xFF7DC8C8); // Turquoise clair
  
  static const Color secondary = Color(0xFF2D4A4A); // Gris-bleu foncé (backgrounds)
  static const Color secondaryLight = Color(0xFF3D5A5A);
  
  static const Color accent = Color(0xFFFF6B6B); // Rouge accent (favoris, erreurs)
  static const Color accentLight = Color(0xFFFF9999);
  
  // ========================
  // BACKGROUNDS
  // ========================
  static const Color background = Color(0xFFF5F7FA); // Gris très clair
  static const Color surface = Color(0xFFFFFFFF); // Blanc pur
  static const Color cardBackground = Color(0xFFFAFBFC); // Blanc cassé
  static const Color darkBackground = Color(0xFF2D4A4A); // Pour cards sombres (Welcome screen)
  
  // ========================
  // ÉTATS
  // ========================
  static const Color success = Color(0xFF4CAF50); // Vert
  static const Color error = Color(0xFFFF6B6B); // Rouge
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color info = Color(0xFF5FB4B4); // Turquoise (même que primary)
  
  // ========================
  // TEXTE
  // ========================
  static const Color textPrimary = Color(0xFF1A1A1A); // Noir profond
  static const Color textSecondary = Color(0xFF6B7280); // Gris moyen
  static const Color textHint = Color(0xFFB0B7C3); // Gris clair
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Blanc sur turquoise
  static const Color textOnDark = Color(0xFFFFFFFF); // Blanc sur fond sombre
  
  // ========================
  // BORDURES & DIVIDERS
  // ========================
  static const Color border = Color(0xFFE5E7EB); // Gris clair
  static const Color divider = Color(0xFFEEEEEE); // Gris très clair
  static const Color inputBorder = Color(0xFFDFE4EA); // Bordure inputs
  
  // ========================
  // NAVIGATION BAR
  // ========================
  static const Color navBarBackground = Color(0xFF2D4A4A); // Gris-bleu foncé
  static const Color navBarSelected = Color(0xFF5FB4B4); // Turquoise
  static const Color navBarUnselected = Color(0xFF8A9BA8); // Gris
  
  // ========================
  // BADGES & CHIPS
  // ========================
  static const Color badgeOrange = Color(0xFFFF9F66); // Badge "DISCOVERY"
  static const Color chipBackground = Color(0xFFF0F4F8);
  static const Color chipSelected = Color(0xFF5FB4B4);
  
  // ========================
  // GRADIENTS (Basés sur Figma)
  // ========================
  
  // Gradient principal (Welcome screen, buttons)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5FB4B4), Color(0xFF4A9494)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Gradient pour fond sombre (Welcome, cards)
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF2D4A4A), Color(0xFF3D5A5A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Gradient pour cards de monuments
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Gradient overlay pour images
  static LinearGradient imageOverlay = LinearGradient(
    colors: [
      Colors.black.withOpacity(0.6),
      Colors.transparent,
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
  
  // ========================
  // SHADOWS (Ombres douces)
  // ========================
  
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF5FB4B4).withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 15,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: const Color(0xFF5FB4B4).withOpacity(0.25),
      blurRadius: 12,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];
  
  // ========================
  // OPACITY HELPERS
  // ========================
  
  static Color primaryWithOpacity(double opacity) {
    return primary.withOpacity(opacity);
  }
  
  static Color textWithOpacity(double opacity) {
    return textPrimary.withOpacity(opacity);
  }
}