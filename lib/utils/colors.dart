import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6B73FF);
  static const Color primaryLight = Color(0xFF9FA8FF);
  static const Color primaryDark = Color(0xFF3F51B5);
  
  // Secondary Colors
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color secondaryLight = Color(0xFFFF9FCE);
  static const Color secondaryDark = Color(0xFFE91E63);
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF5F7FF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);
  
  // Game Colors
  static const Color correct = Color(0xFF48BB78);
  static const Color incorrect = Color(0xFFE53E3E);
  static const Color warning = Color(0xFFED8936);
  static const Color info = Color(0xFF3182CE);
  
  // Fun Colors for Games
  static const Color funRed = Color(0xFFFF6B6B);
  static const Color funBlue = Color(0xFF4ECDC4);
  static const Color funYellow = Color(0xFFFFE66D);
  static const Color funGreen = Color(0xFF95E1D3);
  static const Color funOrange = Color(0xFFFFB347);
  static const Color funPurple = Color(0xFFB19CD9);
  
  // Star Colors
  static const Color goldStar = Color(0xFFFFD700);
  static const Color silverStar = Color(0xFFC0C0C0);
  static const Color bronzeStar = Color(0xFFCD7F32);
  
  // Button Colors
  static const Color buttonPrimary = Color(0xFF6B73FF);
  static const Color buttonSecondary = Color(0xFFE2E8F0);
  static const Color buttonSuccess = Color(0xFF48BB78);
  static const Color buttonDanger = Color(0xFFE53E3E);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8F9FF), Color(0xFFE6F3FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Game Color Map
  static const Map<String, Color> gameColors = {
    'red': funRed,
    'blue': funBlue,
    'yellow': funYellow,
    'green': funGreen,
    'orange': funOrange,
    'purple': funPurple,
  };
  
  // Helper Methods
  static Color getGameColor(String colorName) {
    return gameColors[colorName] ?? primary;
  }
  
  static Color getStarColor(int stars) {
    switch (stars) {
      case 3:
        return goldStar;
      case 2:
        return silverStar;
      case 1:
        return bronzeStar;
      default:
        return textLight;
    }
  }
}

