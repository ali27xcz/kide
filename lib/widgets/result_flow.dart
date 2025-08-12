import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/game_utils.dart';
import '../services/audio_service.dart';
import 'star_collect_overlay.dart';
import 'game_result_views.dart';

class ResultFlow {
  static Future<void> showStarsThenResult({
    required BuildContext context,
    required int score,
    required int maxScore,
    required VoidCallback onPlayAgain,
    VoidCallback? onBackToMenu,
  }) async {
    if (maxScore <= 0) return;
    final int stars = GameUtils.computeStars(score: score, maxScore: maxScore);

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    final completer = Completer<void>();
    entry = OverlayEntry(
      builder: (_) => StarCollectOverlay(
        stars: stars,
        onCompleted: () {
          entry.remove();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    overlay.insert(entry);
    await completer.future;

    final bool success = (score / maxScore) >= AppConstants.passScoreRatio;
    try {
      final audio = await AudioService.getInstance();
      // Do not await audio; start playback while navigating to results
      unawaited(audio.playGameEndSequence(success));
    } catch (_) {}

    await Navigator.of(context).push(PageRouteBuilder(
      opaque: true,
      barrierDismissible: false,
      pageBuilder: (_, __, ___) {
        final view = success
            ? SuccessResultView(
                score: score,
                maxScore: maxScore,
                stars: stars,
                onRetry: () {
                  Navigator.of(context).pop();
                  onPlayAgain();
                },
                onBack: () {
                  Navigator.of(context).pop();
                  if (onBackToMenu != null) onBackToMenu();
                },
              )
            : FailureResultView(
                score: score,
                maxScore: maxScore,
                stars: stars,
                onRetry: () {
                  Navigator.of(context).pop();
                  onPlayAgain();
                },
                onBack: () {
                  Navigator.of(context).pop();
                  if (onBackToMenu != null) onBackToMenu();
                },
              );
        return Scaffold(body: view);
      },
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(opacity: curved, child: child);
      },
    ));
  }
}


