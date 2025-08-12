import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/progress_tracker.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/game_button.dart';
import '../../widgets/star_collect_overlay.dart';
import '../../utils/game_utils.dart';
import '../../widgets/game_result_views.dart';
import '../../l10n/app_localizations.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({Key? key}) : super(key: key);

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with TickerProviderStateMixin {
  static const int _gridSize = 4; // 4x4 grid = 16 cards (8 pairs)
  static const int _totalPairs = 8;
  
  // Memory card emojis for matching
  static const List<String> _cardEmojis = [
    '🐱', '🐶', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
    '🐨', '🐯', '🦁', '🐸', '🐵', '🐣', '🐧', '🦆',
    '🦋', '🐛', '🐝', '🐞', '🦗', '🕷️', '🐢', '🐍',
    '🌸', '🌺', '🌻', '🌷', '🌹', '💐', '🌳', '🌲',
  ];

  final Random _random = Random();
  late AnimationController _cardAnimationController;
  late AnimationController _matchAnimationController;
  late AnimationController _gameEndController;
  late Animation<double> _cardFlipAnimation;
  late Animation<double> _matchScaleAnimation;
  late Animation<double> _gameEndScaleAnimation;

  List<MemoryCard> _cards = [];
  List<int> _flippedCards = [];
  int _matches = 0;
  int _score = 0;
  int _moves = 0;
  int _startTimeMs = 0;
  bool _canFlip = true;
  bool _isCompleted = false;
  GameDifficulty _difficulty = GameDifficulty.easy;

  AudioService? _audioService;
  ProgressTracker? _progressTracker;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initialize();
  }

  void _initializeAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _matchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _gameEndController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardFlipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    ));

    _matchScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _matchAnimationController,
      curve: Curves.elasticOut,
    ));

    _gameEndScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gameEndController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _initialize() async {
    try {
      _audioService = await AudioService.getInstance();
    } catch (e) {
      print('Error initializing audio service in memory game: $e');
    }
    
    try {
      _progressTracker = await ProgressTracker.getInstance();
    } catch (e) {
      print('Error initializing progress tracker in memory game: $e');
    }
    
    _startNewGame();
  }

  void _startNewGame() {
    _matches = 0;
    _score = 0;
    _moves = 0;
    _isCompleted = false;
    _flippedCards.clear();
    _canFlip = true;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    
    _createCards();
    setState(() {});
  }

  void _createCards() {
    _cards.clear();
    
    // Select emojis for this game based on difficulty
    int pairsCount;
    switch (_difficulty) {
      case GameDifficulty.easy:
        pairsCount = 6; // 3x4 grid
        break;
      case GameDifficulty.medium:
        pairsCount = 8; // 4x4 grid
        break;
      case GameDifficulty.hard:
        pairsCount = 12; // 6x4 grid
        break;
    }
    
    final selectedEmojis = List.from(_cardEmojis);
    selectedEmojis.shuffle(_random);
    final gameEmojis = selectedEmojis.take(pairsCount).toList();
    
    // Create pairs
    final cardEmojis = <String>[];
    for (final emoji in gameEmojis) {
      cardEmojis.add(emoji);
      cardEmojis.add(emoji);
    }
    
    // Shuffle cards
    cardEmojis.shuffle(_random);
    
    // Create card objects
    for (int i = 0; i < cardEmojis.length; i++) {
      _cards.add(MemoryCard(
        id: i,
        emoji: cardEmojis[i],
        isFlipped: false,
        isMatched: false,
      ));
    }
  }

  int get _gridColumns {
    switch (_difficulty) {
      case GameDifficulty.easy:
        return 3;
      case GameDifficulty.medium:
        return 4;
      case GameDifficulty.hard:
        return 4;
    }
  }

  int get _gridRows {
    switch (_difficulty) {
      case GameDifficulty.easy:
        return 4;
      case GameDifficulty.medium:
        return 4;
      case GameDifficulty.hard:
        return 6;
    }
  }

  Future<void> _onCardTapped(int cardId) async {
    if (!_canFlip || _isCompleted) return;
    
    final card = _cards[cardId];
    if (card.isFlipped || card.isMatched) return;
    
    setState(() {
      card.isFlipped = true;
      _flippedCards.add(cardId);
    });

    try {
      await _audioService?.playCorrectSound();
    } catch (e) {
      print('Error playing click sound: $e');
    }

    if (_flippedCards.length == 2) {
      _canFlip = false;
      _moves++;
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final firstCard = _cards[_flippedCards[0]];
      final secondCard = _cards[_flippedCards[1]];
      
      if (firstCard.emoji == secondCard.emoji) {
        // Match found!
        setState(() {
          firstCard.isMatched = true;
          secondCard.isMatched = true;
          _matches++;
          _score += _getScoreForMatch();
        });
        
        await _audioService?.playCorrectSound();
        _matchAnimationController.reset();
        _matchAnimationController.forward();
        
        // Check if game is complete
        if (_matches >= _cards.length / 2) {
          await _finishGame();
        }
      } else {
        // No match
        await _audioService?.playIncorrectSound();
        await Future.delayed(const Duration(milliseconds: 800));
        
        setState(() {
          firstCard.isFlipped = false;
          secondCard.isFlipped = false;
        });
      }
      
      _flippedCards.clear();
      _canFlip = true;
    }
  }

  int _getScoreForMatch() {
    final baseScore = AppConstants.pointsPerCorrectAnswer;
    final difficultyMultiplier = _difficulty == GameDifficulty.hard ? 1.5 : 
                                _difficulty == GameDifficulty.medium ? 1.2 : 1.0;
    
    // Bonus for efficiency (fewer moves)
    final moveEfficiency = (_cards.length / 2) / max(_moves, 1);
    final efficiencyBonus = moveEfficiency > 1.0 ? (baseScore * 0.5).round() : 0;
    
    return (baseScore * difficultyMultiplier).round() + efficiencyBonus;
  }

  Future<void> _finishGame() async {
    final elapsedSeconds = ((DateTime.now().millisecondsSinceEpoch - _startTimeMs) / 1000).round();
    
    // Defer marking completed until after stars + end sequence

    _gameEndController.reset();
    _gameEndController.forward();

    // Time bonus
    final timeBonus = max(0, (120 - elapsedSeconds) * 2); // 2 points per second under 2 minutes
    _score += timeBonus;

    try {
      if (_progressTracker != null) {
        // تشغيل في الخلفية حتى لا يحجب الانتقال إلى النجوم
        _progressTracker!.recordGameProgress(
          gameType: AppConstants.memoryGame,
          level: _difficulty.index + 1,
          score: _score,
          maxScore: (_cards.length ~/ 2) * AppConstants.pointsPerCorrectAnswer,
          timeSpentSeconds: elapsedSeconds,
          gameData: {
            'difficulty': _difficulty.name,
            'moves': _moves,
            'matches': _matches,
            'timeBonus': timeBonus,
          },
        );
      }
    } catch (e) {
      print('Error recording game progress: $e');
    }

    try {
      final mx = (_cards.length ~/ 2) * AppConstants.pointsPerCorrectAnswer;
      final success = mx > 0 ? (_score / mx) >= AppConstants.passScoreRatio : true;
      await _showStarsThenResult(mx, success);
    } catch (e) {
      print('Error showing stars/result: $e');
    }
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
          setState(() { _isCompleted = true; });
        },
      ),
    );
    Overlay.of(context)?.insert(entry);
  }

  void _changeDifficulty(GameDifficulty newDifficulty) {
    if (_difficulty != newDifficulty && !_isCompleted) {
      setState(() {
        _difficulty = newDifficulty;
      });
      _startNewGame();
    }
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _matchAnimationController.dispose();
    _gameEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildDifficultySelector(),
                const SizedBox(height: 20),
                Expanded(
                  child: _isCompleted ? _buildResult() : _buildGameGrid(),
                ),
                const SizedBox(height: 20),
                if (_isCompleted)
                  Row(
                    children: [
                      Expanded(
                        child: GameButton(
                          text: 'العودة للقائمة',
                          onPressed: () => Navigator.of(context).pop(),
                          backgroundColor: AppColors.buttonSecondary,
                          textColor: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GameButton(
                          text: 'العب مجدداً',
                          onPressed: _startNewGame,
                          backgroundColor: AppColors.primary,
                          icon: Icons.refresh,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: GameButton(
                          text: 'لعبة جديدة',
                          onPressed: _startNewGame,
                          backgroundColor: AppColors.warning,
                          icon: Icons.refresh,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'الحركات: $_moves',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'المطابقات: $_matches/${_cards.length ~/ 2}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
              const Text(
                'لعبة الذاكرة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'النقاط: $_score',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: GameDifficulty.values.map((difficulty) {
          final isSelected = _difficulty == difficulty;
          return Expanded(
            child: GestureDetector(
              onTap: () => _changeDifficulty(difficulty),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getDifficultyName(difficulty),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getDifficultyName(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return 'سهل (3×4)';
      case GameDifficulty.medium:
        return 'متوسط (4×4)';
      case GameDifficulty.hard:
        return 'صعب (4×6)';
    }
  }

  Widget _buildGameGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = min(
          (constraints.maxWidth - (_gridColumns - 1) * 8) / _gridColumns,
          (constraints.maxHeight - (_gridRows - 1) * 8) / _gridRows,
        );
        
        return Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cards.map((card) {
              final isFlipped = card.isFlipped || card.isMatched;
              
              return AnimatedBuilder(
                animation: card.isMatched ? _matchAnimationController : _cardAnimationController,
                builder: (context, child) {
                  final scale = card.isMatched ? _matchScaleAnimation.value : 1.0;
                  
                  return Transform.scale(
                    scale: scale,
                    child: GestureDetector(
                      onTap: () => _onCardTapped(card.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: cardSize,
                        height: cardSize,
                        decoration: BoxDecoration(
                          color: isFlipped 
                              ? (card.isMatched ? AppColors.correct : AppColors.surface)
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: card.isMatched 
                              ? Border.all(color: AppColors.correct, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: isFlipped
                                ? Text(
                                    card.emoji,
                                    key: ValueKey('emoji-${card.id}'),
                                    style: TextStyle(
                                      fontSize: cardSize * 0.4,
                                    ),
                                  )
                                : Icon(
                                    Icons.help_outline,
                                    key: ValueKey('question-${card.id}'),
                                    color: Colors.white,
                                    size: cardSize * 0.3,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildResult() {
    final maxScore = (_cards.length ~/ 2) * AppConstants.pointsPerCorrectAnswer;
    final success = maxScore > 0 ? (_score / maxScore) >= AppConstants.passScoreRatio : false;
    final stars = GameUtils.computeStars(score: _score, maxScore: maxScore);
    return AnimatedBuilder(
      animation: _gameEndController,
      builder: (_, __) {
        return Transform.scale(
          scale: _gameEndScaleAnimation.value,
          child: success
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
                ),
        );
      },
    );
  }
}

enum GameDifficulty { easy, medium, hard }

class MemoryCard {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.emoji,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
