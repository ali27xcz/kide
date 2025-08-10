import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../services/local_storage.dart';
import '../services/progress_tracker.dart';
import '../widgets/game_button.dart';
import 'games/counting_game_screen.dart';
import 'games/alphabet_game_screen.dart';
import 'games/colors_game_screen.dart';
import 'games/shapes_game_screen.dart';
import 'games/puzzle_game_screen.dart';

class DailyPlanScreen extends StatefulWidget {
  const DailyPlanScreen({Key? key}) : super(key: key);

  @override
  State<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends State<DailyPlanScreen> {
  bool _loading = true;
  List<_PlanItem> _plan = [];

  @override
  void initState() {
    super.initState();
    _buildPlan();
  }

  Future<void> _buildPlan() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final progress = await storage.getGameProgress();
      final tracker = await ProgressTracker.getInstance();
      final stats = await tracker.getDetailedStatistics();

      // Heuristic: choose 3 short activities based on weakest areas
      final Map<String, int> counts = {};
      for (final p in progress) {
        counts[p.gameType] = (counts[p.gameType] ?? 0) + (p.needsImprovement ? 2 : 1);
      }

      final gameTypes = <String>[
        AppConstants.countingGame,
        AppConstants.alphabetGame,
        AppConstants.colorsGame,
        AppConstants.shapesGame,
        AppConstants.puzzleGame,
      ];

      gameTypes.sort((a, b) => (counts[a] ?? 0).compareTo(counts[b] ?? 0));
      final selected = gameTypes.take(3).toList();

      _plan = selected
          .map((g) => _PlanItem(
                gameType: g,
                title: _titleFor(g),
                minutes: 5,
                hint: 'تمرين قصير لتعزيز المهارة',
              ))
          .toList();
    } catch (_) {
      _plan = [
        _PlanItem(gameType: AppConstants.countingGame, title: 'العد', minutes: 5, hint: 'نشاط قصير'),
        _PlanItem(gameType: AppConstants.alphabetGame, title: 'الحروف', minutes: 5, hint: 'نشاط قصير'),
        _PlanItem(gameType: AppConstants.colorsGame, title: 'الألوان', minutes: 5, hint: 'نشاط قصير'),
      ];
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _titleFor(String g) {
    switch (g) {
      case AppConstants.countingGame:
        return 'العد';
      case AppConstants.alphabetGame:
        return 'الحروف';
      case AppConstants.colorsGame:
        return 'الألوان';
      case AppConstants.shapesGame:
        return 'الأشكال';
      case AppConstants.puzzleGame:
        return 'ألغاز تعليمية';
      default:
        return g;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemBuilder: (context, index) => _buildPlanTile(_plan[index]),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: _plan.length,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: GameButton(
                        text: 'ابدأ الخطة',
                        icon: Icons.play_arrow,
                        onPressed: _startPlan,
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GameIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
            size: 45,
            backgroundColor: AppColors.surface,
            iconColor: AppColors.textSecondary,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'خطة اليوم',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTile(_PlanItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.schedule, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.hint,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${item.minutes} د', style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Future<void> _startPlan() async {
    if (_plan.isEmpty) return;
    await _runPlanSequentially();
  }

  Future<void> _openGameByType(String gameType) async {
    Widget? game;
    switch (gameType) {
      case AppConstants.countingGame:
        game = const CountingGameScreen();
        break;
      case AppConstants.alphabetGame:
        game = const AlphabetGameScreen();
        break;
      case AppConstants.colorsGame:
        game = const ColorsGameScreen();
        break;
      case AppConstants.shapesGame:
        game = const ShapesGameScreen();
        break;
      case AppConstants.puzzleGame:
        game = const PuzzleGameScreen();
        break;
      default:
        break;
    }
    if (game != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => game!),
      );
    }
  }

  Future<void> _runPlanSequentially() async {
    for (final item in _plan) {
      await _openGameByType(item.gameType);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('أحسنت! لقد أنهيت خطة اليوم'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _PlanItem {
  final String gameType;
  final String title;
  final int minutes;
  final String hint;
  _PlanItem({required this.gameType, required this.title, required this.minutes, required this.hint});
}


