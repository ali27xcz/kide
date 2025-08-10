import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../services/audio_service.dart';
import '../../services/data_service.dart';
import '../../services/progress_tracker.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/game_button.dart';

class MatchPairsGameScreen extends StatefulWidget {
  const MatchPairsGameScreen({Key? key}) : super(key: key);

  @override
  State<MatchPairsGameScreen> createState() => _MatchPairsGameScreenState();
}

class _MatchPairsGameScreenState extends State<MatchPairsGameScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();
  late AnimationController _matchAnimationController;
  late Animation<double> _matchScaleAnimation;

  AudioService? _audioService;
  ProgressTracker? _progressTracker;
  DataService? _dataService;

  // Data
  List<Map<String, dynamic>> _pairsData = [];
  List<_PairCard> _cards = [];
  List<int> _flippedIndexes = [];
  int _matches = 0;
  int _moves = 0;
  int _score = 0;
  bool _isCompleted = false;
  int _startTimeMs = 0;

  @override
  void initState() {
    super.initState();
    _matchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _matchScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _matchAnimationController, curve: Curves.elasticOut),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _audioService = await AudioService.getInstance();
    } catch (_) {}
    try {
      _progressTracker = await ProgressTracker.getInstance();
    } catch (_) {}
    try {
      _dataService = DataService.instance;
      _pairsData = await _dataService!.loadMatchPairsData();
    } catch (_) {}
    _startNewGame();
  }

  void _startNewGame() {
    _matches = 0;
    _moves = 0;
    _score = 0;
    _isCompleted = false;
    _flippedIndexes.clear();
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _buildDeck();
    setState(() {});
  }

  void _buildDeck() {
    _cards.clear();
    if (_pairsData.isEmpty) return;

    // Pick up to 8 pairs per round
    final list = List<Map<String, dynamic>>.from(_pairsData);
    list.shuffle(_random);
    final selected = list.take(8).toList();
    final isArabic = context.read<LanguageProvider>().isArabic;

    final temp = <_PairCard>[];
    for (final item in selected) {
      final String label = isArabic ? (item['word_ar'] ?? '') : (item['word_en'] ?? '');
      final String emoji = item['emoji'] ?? '❓';

      temp.add(_PairCard(id: item['id'].toString(), type: _CardType.emoji, display: emoji));
      temp.add(_PairCard(id: item['id'].toString(), type: _CardType.word, display: label));
    }

    temp.shuffle(_random);
    _cards = temp;
  }

  Future<void> _onCardTap(int index) async {
    if (_isCompleted) return;
    final card = _cards[index];
    if (card.isMatched || card.isFlipped) return;

    setState(() => card.isFlipped = true);
    _flippedIndexes.add(index);

    if (_flippedIndexes.length == 2) {
      _moves++;
      final a = _cards[_flippedIndexes[0]];
      final b = _cards[_flippedIndexes[1]];
      if (a.id == b.id && a.type != b.type) {
        setState(() {
          a.isMatched = true;
          b.isMatched = true;
          _matches++;
          _score += AppConstants.pointsPerCorrectAnswer;
        });
        _matchAnimationController.forward(from: 0);
        await _audioService?.playCorrectSound();
        if (_matches * 2 >= _cards.length) {
          await _finishGame();
        }
      } else {
        await _audioService?.playIncorrectSound();
        await Future.delayed(const Duration(milliseconds: 600));
        setState(() {
          a.isFlipped = false;
          b.isFlipped = false;
        });
      }
      _flippedIndexes.clear();
    }
  }

  Future<void> _finishGame() async {
    setState(() => _isCompleted = true);
    final elapsedSeconds =
        ((DateTime.now().millisecondsSinceEpoch - _startTimeMs) / 1000).round();
    try {
      await _progressTracker?.recordGameProgress(
        gameType: AppConstants.matchPairsGame,
        level: 1,
        score: _score,
        maxScore: (_cards.length ~/ 2) * AppConstants.pointsPerCorrectAnswer,
        timeSpentSeconds: elapsedSeconds,
        gameData: {
          'moves': _moves,
          'pairs': _cards.length ~/ 2,
        },
      );
    } catch (_) {}
    await _audioService?.playGameEndSequence(true);
  }

  @override
  void dispose() {
    _matchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Expanded(child: _isCompleted ? _buildResult() : _buildGrid()),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GameButton(
                        text: _isCompleted ? 'العودة للقائمة' : 'لعبة جديدة',
                        onPressed: _isCompleted
                            ? () => Navigator.of(context).pop()
                            : _startNewGame,
                        backgroundColor: _isCompleted
                            ? AppColors.buttonSecondary
                            : AppColors.primary,
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
        Expanded(
          child: Text(
            context.read<LanguageProvider>().isArabic
                ? 'طابق الصورة مع الكلمة'
                : 'Match Picture with Word',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = 4;
      final spacing = 8.0;
      final cardSize = min(
        (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount,
        (constraints.maxHeight - 3 * spacing) / 4,
      );
      return Center(
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(_cards.length, (index) {
            final card = _cards[index];
            return AnimatedBuilder(
              animation: _matchAnimationController,
              builder: (context, child) {
                final scale = card.isMatched ? _matchScaleAnimation.value : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: GestureDetector(
                    onTap: () => _onCardTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: cardSize,
                      height: cardSize,
                      decoration: BoxDecoration(
                        color: card.isFlipped || card.isMatched
                            ? AppColors.surface
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: card.isMatched
                            ? Border.all(color: AppColors.correct, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: card.isFlipped || card.isMatched
                              ? Text(
                                  card.display,
                                  key: ValueKey('f-${index}'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize:
                                        card.type == _CardType.emoji ? cardSize * 0.46 : 16,
                                    fontWeight: card.type == _CardType.word
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.help_outline,
                                  key: ValueKey('b-${index}'),
                                  color: Colors.white,
                                  size: cardSize * 0.34,
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      );
    });
  }

  Widget _buildResult() {
    final maxScore = (_cards.length ~/ 2) * AppConstants.pointsPerCorrectAnswer;
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
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'أحسنت! أنهيت اللعبة',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text('النتيجة: $_score / $maxScore · الحركات: $_moves',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

enum _CardType { emoji, word }

class _PairCard {
  final String id;
  final _CardType type;
  final String display;
  bool isFlipped;
  bool isMatched;

  _PairCard({
    required this.id,
    required this.type,
    required this.display,
    this.isFlipped = false,
    this.isMatched = false,
  });
}


