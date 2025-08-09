import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static String appName(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'كيدي'
        : 'Kedy';
  }
  static const String appVersion = '1.0.0';
  
  // Game Settings
  static const int maxLevel = 20;
  static const int pointsPerCorrectAnswer = 10;
  static const int starsForPerfectScore = 3;
  static const int starsForGoodScore = 2;
  static const int starsForPassingScore = 1;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 1000);
  
  // Game Types
  static const String countingGame = 'counting';
  static const String additionGame = 'addition';
  static const String shapesGame = 'shapes';
  static const String colorsGame = 'colors';
  static const String patternsGame = 'patterns';
  static const String alphabetGame = 'alphabet';
  static const String puzzleGame = 'puzzle';
  static const String memoryGame = 'memory';
  
  // Difficulty Levels
  static const String easyLevel = 'easy';
  static const String mediumLevel = 'medium';
  static const String hardLevel = 'hard';
  
  // Storage Keys
  static const String childProfileKey = 'child_profile';
  static const String gameProgressKey = 'game_progress';
  static const String achievementsKey = 'achievements';
  static const String settingsKey = 'settings';
  
  // Audio Files
  static const String backgroundMusic = 'sounds/background_music.mp3';
  static const String correctSound = 'sounds/correct.mp3';
  static const String incorrectSound = 'sounds/incorrect.mp3';
  static const String celebrationSound = 'sounds/celebration.mp3';
  static const String clickSound = 'sounds/click.mp3';
  
  // Image Assets
  static const String mascotImage = 'images/mascot.png';
  static const String splashLogo = 'images/splash_logo.png';
  
  // Shapes
  static const List<String> shapes = [
    'circle',
    'square',
    'triangle',
    'rectangle',
    'star'
  ];
  
  // Colors
  static const List<String> colors = [
    'red',
    'blue',
    'yellow',
    'green',
    'orange',
    'purple'
  ];
  
  // Counting Objects
  static const List<String> countingObjects = [
    'apple',
    'star',
    'car',
    'ball',
    'flower',
    'butterfly'
  ];
}

