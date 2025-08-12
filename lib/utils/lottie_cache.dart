import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Utility class to preload and cache Lottie animations for better performance
class LottiePreloader {
  static final Map<String, LottieComposition> _cache = {};
  static bool _isInitialized = false;
  
  /// Preload common Lottie animations
  static Future<void> preloadAnimations() async {
    if (_isInitialized) return;
    
    final animationsToPreload = [
      'assets/lottie/mainscreen.json',
      'assets/lottie/Setting Icon.json',
      'assets/lottie/profile.json',
      'assets/lottie/Super Hero Charging.json',
      'assets/lottie/Play Button.json',
      'assets/lottie/Dark Mode Button.json',
      'assets/lottie/math.json',
      'assets/lottie/english.json',
      'assets/lottie/shapes.json',
      'assets/lottie/color.json',
      'assets/lottie/memory.json',
      'assets/lottie/Puzzle.json',
    ];
    
    try {
      // Preload all animations in parallel
      final futures = animationsToPreload.map((path) async {
        try {
          final composition = await AssetLottie(path).load();
          _cache[path] = composition;
        } catch (e) {
          print('Failed to preload Lottie animation: $path - $e');
        }
      });
      
      await Future.wait(futures);
      _isInitialized = true;
      print('Lottie animations preloaded: ${_cache.length} animations');
    } catch (e) {
      print('Error preloading Lottie animations: $e');
    }
  }
  
  /// Get a cached Lottie widget or fallback to regular loading
  static Widget getCachedLottie(
    String path, {
    BoxFit? fit,
    bool repeat = false,
    double? width,
    double? height,
    Widget? fallback,
  }) {
    final composition = _cache[path];
    
    if (composition != null) {
      return Lottie(
        composition: composition,
        fit: fit,
        repeat: repeat,
        width: width,
        height: height,
      );
    }
    
    // Fallback to regular Lottie loading
    return Lottie.asset(
      path,
      fit: fit,
      repeat: repeat,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return fallback ?? Container(
          width: width ?? 50,
          height: height ?? 50,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.animation, color: Colors.grey),
        );
      },
    );
  }
  
  /// Clear cache to free memory
  static void clearCache() {
    _cache.clear();
    _isInitialized = false;
  }
  
  /// Get cache status
  static bool get isInitialized => _isInitialized;
  static int get cachedAnimationsCount => _cache.length;
}
