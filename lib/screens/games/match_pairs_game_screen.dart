import 'dart:async';
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
import '../../widgets/star_collect_overlay.dart';
import '../../utils/game_utils.dart';
import '../../widgets/game_result_views.dart';

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
  
  // Add import dependencies at top of file if missing
  Timer? _countdownTimer;
  int _remainingSeconds = 90;
  bool _timedMode = true;
  _PairsDifficulty _difficulty = _PairsDifficulty.medium;

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
  bool _isSuccess = true;

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
    _isSuccess = true;
    _flippedIndexes.clear();
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _buildDeck();
    _restartTimer();
    setState(() {});
  }

  void _buildDeck() {
    _cards.clear();
    if (_pairsData.isEmpty) return;

    // Pick pairs based on difficulty
    final pairsCount = _difficulty == _PairsDifficulty.easy
        ? 6
        : _difficulty == _PairsDifficulty.medium
            ? 8
            : 10;
    final list = List<Map<String, dynamic>>.from(_pairsData);
    list.shuffle(_random);
    final selected = list.take(pairsCount).toList();
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

  void _restartTimer() {
    _countdownTimer?.cancel();
    if (!_timedMode) return;
    _remainingSeconds = _difficulty == _PairsDifficulty.easy
        ? 120
        : _difficulty == _PairsDifficulty.medium
            ? 90
            : 75;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || _isCompleted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds = (_remainingSeconds - 1).clamp(0, 9999));
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _isSuccess = false;
        await _finishGame(success: false);
      }
    });
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
          await _finishGame(success: true);
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

  Future<void> _finishGame({required bool success}) async {
    final elapsedSeconds =
        ((DateTime.now().millisecondsSinceEpoch - _startTimeMs) / 1000).round();
    _countdownTimer?.cancel();
    try {
      // تشغيل في الخلفية حتى لا يحجب الانتقال إلى النجوم
      _progressTracker?.recordGameProgress(
        gameType: AppConstants.matchPairsGame,
        level: 1,
        score: _score,
        maxScore: (_cards.length ~/ 2) * AppConstants.pointsPerCorrectAnswer,
        timeSpentSeconds: elapsedSeconds,
        gameData: {
          'moves': _moves,
          'pairs': _cards.length ~/ 2,
          'difficulty': _difficulty.name,
          'timed': _timedMode,
        },
      );
    } catch (_) {}
    try {
      final mx = (_cards.length ~/ 2) * AppConstants.pointsPerCorrectAnswer;
      final successByRatio = mx > 0 ? (_score / mx) >= AppConstants.passScoreRatio : success;
      await _showStarsThenResult(mx, successByRatio);
    } catch (_) {}
  }

  Future<void> _showStarsThenResult(int maxScore, bool success) async {
    if (!mounted) return;
    final int stars = GameUtils.computeStars(score: _score, maxScore: maxScore);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => StarCollectOverlay(
        stars: stars,
        onCompleted: () async {
          entry.remove();
          try { _audioService?.playGameEndSequence(success); } catch (_) {}
          if (!mounted) return;
          setState(() => _isCompleted = true);
        },
      ),
    );
    Overlay.of(context)?.insert(entry);
  }

  @override
  void dispose() {
    _matchAnimationController.dispose();
    _countdownTimer?.cancel();
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.read<LanguageProvider>().isArabic
                    ? 'طابق الصورة مع الكلمة'
                    : 'Match Picture with Word',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _timedMode ? '$_remainingSeconds ث' : 'وضع حر',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('حركات: $_moves', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<_PairsDifficulty>(
          value: _difficulty,
          underline: const SizedBox.shrink(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _difficulty = v);
            _startNewGame();
          },
          items: const [
            DropdownMenuItem(value: _PairsDifficulty.easy, child: Text('سهل')),
            DropdownMenuItem(value: _PairsDifficulty.medium, child: Text('متوسط')),
            DropdownMenuItem(value: _PairsDifficulty.hard, child: Text('صعب')),
          ],
        ),
        const SizedBox(width: 8),
        Switch(
          value: _timedMode,
          onChanged: (v) {
            setState(() => _timedMode = v);
            _restartTimer();
          },
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
    final successByRatio = maxScore > 0 ? (_score / maxScore) >= AppConstants.passScoreRatio : _isSuccess;
    final stars = GameUtils.computeStars(score: _score, maxScore: maxScore);
    return successByRatio
        ? SuccessResultView(
            score: _score,
            maxScore: maxScore,
            stars: stars,
            onRetry: _startNewGame,
            onBack: () => Navigator.of(context).pop(),
          )
        : FailureResultView(
            score: _score,
            maxScore: maxScore,
            stars: stars,
            onRetry: _startNewGame,
            onBack: () => Navigator.of(context).pop(),
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

enum _PairsDifficulty { easy, medium, hard }


