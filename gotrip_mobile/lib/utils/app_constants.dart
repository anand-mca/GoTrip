import 'package:flutter/material.dart';

class AppColors {
  // Primary Airtel Red Theme
  static const Color primary = Color(0xFFE40000);       // Airtel Red
  static const Color primaryDark = Color(0xFFCC0000);   // Darker Red for contrast
  static const Color accent = Color(0xFFE40000);        // Same red for accent
  static const Color accentLight = Color(0xFFFFD700);   // Gold for stars/ratings
  
  // Dark Mode Theme Colors (Orange and Black)
  static const Color darkPrimary = Color(0xFF2596BE);   // Dark mode orange/teal
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  
  static const Color background = Color(0xFFFFFFFF);    // Pure white background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF8F8F8);    // Light grey for cards
  
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);
  
  static const Color border = Color(0xFFE40000);        // Red border for cards
  static const Color divider = Color(0xFFECF0F1);
  static const Color shadow = Color(0x1A000000);
  
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE40000);         // Red for errors too
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double circle = 999.0;
}

class AppElevation {
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
}
