import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/data_service.dart';
import '../../services/progress_tracker.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/game_button.dart';
import '../../widgets/star_collect_overlay.dart';
import '../../utils/game_utils.dart';
import '../../widgets/game_result_views.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class SoundRecognitionGameScreen extends StatefulWidget {
  const SoundRecognitionGameScreen({Key? key}) : super(key: key);

  @override
  State<SoundRecognitionGameScreen> createState() => _SoundRecognitionGameScreenState();
}

class _SoundRecognitionGameScreenState extends State<SoundRecognitionGameScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();
  AudioService? _audioService;
  ProgressTracker? _progressTracker;
  DataService? _dataService;

  List<Map<String, dynamic>> _bank = [];
  List<Map<String, dynamic>> _round = [];
  Map<String, dynamic>? _current;
  int _score = 0;
  int _startTimeMs = 0;
  bool _isCompleted = false;
  int _questionIndex = 0;
  static const int _totalQuestions = 8;

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
      _bank = await _dataService!.loadSoundRecognitionData();
    } catch (_) {}
    _startNewGame();
  }

  void _startNewGame() {
    _score = 0;
    _questionIndex = 0;
    _isCompleted = false;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _buildRound();
    setState(() {});
    _playCurrent();
  }

  void _buildRound() {
    final list = List<Map<String, dynamic>>.from(_bank);
    list.shuffle(_random);
    _round = list.take(_totalQuestions).toList();
    _current = _round.isNotEmpty ? _round[0] : null;
  }

  Future<void> _playCurrent() async {
    final soundPath = _current?['sound'] ?? '';
    if (soundPath is String && soundPath.isNotEmpty) {
      await _audioService?.playSound(soundPath);
    }
  }

  Future<void> _onSelect(Map<String, dynamic> option) async {
    if (_isCompleted || _current == null) return;
    final isCorrect = option['id'].toString() == _current!['id'].toString();
    if (isCorrect) {
      _score += AppConstants.pointsPerCorrectAnswer;
      await _audioService?.playCorrectSound();
    } else {
      await _audioService?.playIncorrectSound();
    }
    // Skip delay on the final question to transition immediately
    if (_questionIndex + 1 >= _totalQuestions) {
      await _finishGame();
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _questionIndex++;
        _current = _round[_questionIndex];
      });
      await _playCurrent();
    }
  }

  Future<void> _finishGame() async {
    final elapsedSeconds =
        ((DateTime.now().millisecondsSinceEpoch - _startTimeMs) / 1000).round();
    try {
      // تشغيل في الخلفية حتى لا يحجب الانتقال إلى النجوم
      _progressTracker?.recordGameProgress(
        gameType: AppConstants.soundRecognitionGame,
        level: 1,
        score: _score,
        maxScore: _totalQuestions * AppConstants.pointsPerCorrectAnswer,
        timeSpentSeconds: elapsedSeconds,
        gameData: {
          'questions': _totalQuestions,
        },
      );
    } catch (_) {}
    try {
      final mx = _totalQuestions * AppConstants.pointsPerCorrectAnswer;
      final success = mx > 0 ? (_score / mx) >= AppConstants.passScoreRatio : true;
      await _showStarsThenResult(mx, success);
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
                const SizedBox(height: 12),
                if (!_isCompleted) _buildQuestionCard(),
                const SizedBox(height: 20),
                Expanded(child: _isCompleted ? _buildResult() : _buildOptions()),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GameButton(
                        text: _isCompleted ? 'العودة للقائمة' : 'إعادة الصوت',
                        onPressed: _isCompleted
                            ? () => Navigator.of(context).pop()
                            : _playCurrent,
                        backgroundColor:
                            _isCompleted ? AppColors.buttonSecondary : AppColors.primary,
                        textColor:
                            _isCompleted ? AppColors.textSecondary : Colors.white,
                        icon: _isCompleted ? null : Icons.volume_up,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
            'التعرف على الصوت',
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

  Widget _buildQuestionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.volume_up, color: AppColors.primary, size: 40),
          const SizedBox(height: 8),
          Text(
            context.read<LanguageProvider>().isArabic
                ? 'استمع للصوت ثم اختر الصورة الصحيحة'
                : 'Listen and choose the correct picture',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    // Build 4 options per question: the correct + 3 random others
    final correct = _current;
    if (correct == null) return const SizedBox.shrink();
    final pool = List<Map<String, dynamic>>.from(_bank);
    pool.removeWhere((e) => e['id'].toString() == correct['id'].toString());
    pool.shuffle(_random);
    final options = [correct, ...pool.take(3)].toList();
    options.shuffle(_random);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final opt = options[index];
        final emoji = opt['emoji'] ?? '❓';
        final isArabic = context.read<LanguageProvider>().isArabic;
        final label = isArabic ? (opt['label_ar'] ?? '') : (opt['label_en'] ?? '');
        return Material(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _onSelect(opt),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 42)),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResult() {
    final maxScore = _totalQuestions * AppConstants.pointsPerCorrectAnswer;
    final success = maxScore > 0 ? (_score / maxScore) >= AppConstants.passScoreRatio : true;
    final stars = GameUtils.computeStars(score: _score, maxScore: maxScore);
    return success
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


