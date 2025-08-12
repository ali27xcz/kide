import 'package:flutter/material.dart';

/// Utility class for optimized navigation transitions
class NavigationUtils {
  /// Fast fade transition for better performance
  static Route<T> createFadeRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 250),
    String? heroTag,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        if (heroTag != null) {
          return Hero(
            tag: heroTag,
            child: page,
          );
        }
        return page;
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }

  /// Slide transition with hero support
  static Route<T> createSlideRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    String? heroTag,
    Offset beginOffset = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        if (heroTag != null) {
          return Hero(
            tag: heroTag,
            child: page,
          );
        }
        return page;
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));
        
        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
    );
  }

  /// Scale transition for games
  static Route<T> createScaleRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    String? heroTag,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        if (heroTag != null) {
          return Hero(
            tag: heroTag,
            child: page,
          );
        }
        return page;
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }

  /// Navigate to page with fade transition
  static Future<T?> navigateWithFade<T extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 250),
    String? heroTag,
  }) {
    return Navigator.of(context).push<T>(
      createFadeRoute<T>(page, duration: duration, heroTag: heroTag),
    );
  }

  /// Navigate to page with slide transition
  static Future<T?> navigateWithSlide<T extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    String? heroTag,
    Offset beginOffset = const Offset(1.0, 0.0),
  }) {
    return Navigator.of(context).push<T>(
      createSlideRoute<T>(page, duration: duration, heroTag: heroTag, beginOffset: beginOffset),
    );
  }

  /// Navigate to page with scale transition (good for games)
  static Future<T?> navigateWithScale<T extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    String? heroTag,
  }) {
    return Navigator.of(context).push<T>(
      createScaleRoute<T>(page, duration: duration, heroTag: heroTag),
    );
  }
}

