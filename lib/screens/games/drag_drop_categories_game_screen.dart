import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/data_service.dart';
import '../../services/progress_tracker.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/game_button.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class DragDropCategoriesGameScreen extends StatefulWidget {
  const DragDropCategoriesGameScreen({Key? key}) : super(key: key);

  @override
  State<DragDropCategoriesGameScreen> createState() => _DragDropCategoriesGameScreenState();
}

class _DragDropCategoriesGameScreenState extends State<DragDropCategoriesGameScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();
  AudioService? _audioService;
  ProgressTracker? _progressTracker;
  DataService? _dataService;

  // Data
  List<Map<String, dynamic>> _categories = [];
  List<_DraggableItem> _items = [];
  int _score = 0;
  int _placed = 0;
  int _startTimeMs = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try { _audioService = await AudioService.getInstance(); } catch (_) {}
    try { _progressTracker = await ProgressTracker.getInstance(); } catch (_) {}
    try {
      _dataService = DataService.instance;
      // Reuse categories.json. Format: { id, category_ar, category_en, items: [ {label_ar,label_en,emoji,category_id} ] }
      _categories = await _dataService!.loadCategoriesData();
    } catch (_) {}
    _startNewGame();
  }

  void _startNewGame() {
    _score = 0;
    _placed = 0;
    _isCompleted = false;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _buildRound();
    setState(() {});
  }

  void _buildRound() {
    _items.clear();
    if (_categories.isEmpty) return;
    // pick 2 categories per round, 8 items total
    final shuffled = List<Map<String, dynamic>>.from(_categories)..shuffle(_random);
    final selectedCats = shuffled.take(2).toList();
    final catIds = selectedCats.map((c) => c['id'].toString()).toList();
    final pool = <Map<String, dynamic>>[];
    for (final c in selectedCats) {
      final items = List<Map<String, dynamic>>.from(c['items'] ?? []);
      items.shuffle(_random);
      pool.addAll(items.take(4));
    }
    pool.shuffle(_random);
    _items = pool
        .map((e) => _DraggableItem(
              id: e['id'].toString(),
              labelAr: e['label_ar'] ?? '',
              labelEn: e['label_en'] ?? '',
              emoji: e['emoji'] ?? '❓',
              categoryId: e['category_id'].toString(),
            ))
        .toList();
  }

  Future<void> _onAcceptItem(_DraggableItem item, String targetCategoryId) async {
    if (_isCompleted || item.placed) return;
    final isCorrect = item.categoryId == targetCategoryId;
    setState(() {
      item.placed = true;
      _placed++;
      if (isCorrect) _score += AppConstants.pointsPerCorrectAnswer;
    });
    if (isCorrect) {
      await _audioService?.playCorrectSound();
    } else {
      await _audioService?.playIncorrectSound();
    }
    if (_placed >= _items.length) {
      await _finishGame();
    }
  }

  Future<void> _finishGame() async {
    setState(() => _isCompleted = true);
    final elapsedSeconds =
        ((DateTime.now().millisecondsSinceEpoch - _startTimeMs) / 1000).round();
    try {
      await _progressTracker?.recordGameProgress(
        gameType: AppConstants.dragDropCategoriesGame,
        level: 1,
        score: _score,
        maxScore: _items.length * AppConstants.pointsPerCorrectAnswer,
        timeSpentSeconds: elapsedSeconds,
        gameData: {
          'items': _items.length,
        },
      );
    } catch (_) {}
    await _audioService?.playGameEndSequence(true);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCats = _categories.take(2).toList();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: _isCompleted
                      ? _buildResult()
                      : Row(
                          children: [
                            // Left: items
                            Expanded(child: _buildItemsList()),
                            const SizedBox(width: 12),
                            // Right: targets
                            Expanded(child: _buildTargets(selectedCats)),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GameButton(
                        text: _isCompleted ? 'العودة للقائمة' : 'لعبة جديدة',
                        onPressed: _isCompleted
                            ? () => Navigator.of(context).pop()
                            : _startNewGame,
                        backgroundColor:
                            _isCompleted ? AppColors.buttonSecondary : AppColors.primary,
                        textColor:
                            _isCompleted ? AppColors.textSecondary : Colors.white,
                        icon: _isCompleted ? null : Icons.refresh,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GameIconButton(
          icon: Icons.close,
          onPressed: () => Navigator.of(context).pop(),
          size: 45,
          backgroundColor: AppColors.surface,
          iconColor: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'اسحب وأسقط إلى الفئة الصحيحة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _items.map((item) {
          if (item.placed) {
            return const SizedBox.shrink();
          }
          return Draggable<_DraggableItem>(
            data: item,
            feedback: _ItemChip(item: item, elevated: true),
            childWhenDragging: _ItemChip(item: item, faded: true),
            child: _ItemChip(item: item),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTargets(List<Map<String, dynamic>> cats) {
    final isArabic = context.read<LanguageProvider>().isArabic;
    return Column(
      children: List.generate(2, (i) {
        final cat = cats.length > i ? cats[i] : null;
        final catId = cat?['id'].toString() ?? '';
        final catLabel = isArabic ? (cat?['category_ar'] ?? '') : (cat?['category_en'] ?? '');
        return Expanded(
          child: DragTarget<_DraggableItem>(
            onWillAccept: (data) => true,
            onAccept: (data) => _onAcceptItem(data, catId),
            builder: (context, candidateData, rejectedData) {
              final isActive = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withOpacity(0.08)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.25),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          catLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: _items
                            .where((it) => it.placed && it.categoryId == catId)
                            .map((it) => _ItemChip(item: it))
                            .toList(),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildResult() {
    final maxScore = _items.length * AppConstants.pointsPerCorrectAnswer;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            children: [
              const Text('🗂️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'رائع! أنهيت التصنيف',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text('النتيجة: $_score / $maxScore',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemChip extends StatelessWidget {
  final _DraggableItem item;
  final bool faded;
  final bool elevated;
  const _ItemChip({required this.item, this.faded = false, this.elevated = false});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.read<LanguageProvider>().isArabic;
    return Material(
      elevation: elevated ? 8 : 0,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: faded ? 0.3 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                isArabic ? item.labelAr : item.labelEn,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraggableItem {
  final String id;
  final String labelAr;
  final String labelEn;
  final String emoji;
  final String categoryId;
  bool placed;
  _DraggableItem({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.emoji,
    required this.categoryId,
    this.placed = false,
  });
}


