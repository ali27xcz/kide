import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/local_storage.dart';
import '../../services/audio_service.dart';
import '../../models/game_progress.dart';
import '../../widgets/result_flow.dart';

class EnglishSpellingBeeScreen extends StatefulWidget {
  const EnglishSpellingBeeScreen({Key? key}) : super(key: key);

  @override
  State<EnglishSpellingBeeScreen> createState() => _EnglishSpellingBeeScreenState();
}

class _EnglishSpellingBeeScreenState extends State<EnglishSpellingBeeScreen> {
  final List<String> _wordBank = [
    'apple', 'banana', 'tiger', 'river', 'purple', 'school', 'planet',
    'butterfly', 'friend', 'pencil', 'doctor', 'music', 'garden', 'mountain',
  ];
  late String _currentWord;
  String _typed = '';
  int _score = 0;
  int _round = 1;
  late Stopwatch _stopwatch;
  LocalStorageService? _storage;
  String? _feedback; // 'correct' | 'wrong' | null
  AudioService? _audioService;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _currentWord = (_wordBank..shuffle()).first;
    _init();
  }

  Future<void> _init() async {
    try {
      _storage = await LocalStorageService.getInstance();
    } catch (_) {}
    try { _audioService = await AudioService.getInstance(); } catch (_) {}
  }

  void _onKeyTap(String ch) {
    setState(() => _typed += ch);
  }

  void _onBackspace() {
    if (_typed.isEmpty) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  Future<void> _submit() async {
    final bool correct = _typed.trim().toLowerCase() == _currentWord.toLowerCase();
    if (correct) {
      setState(() {
        _feedback = 'correct';
        _score += 10;
      });
      // Skip delay on the final question to transition immediately
      if (_round >= 10) {
        await _finish();
      } else {
        await Future.delayed(const Duration(milliseconds: 400));
        setState(() {
          _feedback = null;
          _round += 1;
          _typed = '';
          _currentWord = (_wordBank..shuffle()).first;
        });
      }
    } else {
      setState(() {
        _feedback = 'wrong';
      });
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _feedback = null; // keep same word; user can try again
      });
    }
  }

  Future<void> _finish() async {
    _stopwatch.stop();
    final progress = GameProgress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      childId: 'local_child',
      gameType: AppConstants.englishSpellingBeeGame,
      level: 1,
      score: _score,
      maxScore: 100,
      stars: _score >= 90 ? 3 : _score >= 70 ? 2 : _score >= 40 ? 1 : 0,
      timeSpentSeconds: _stopwatch.elapsed.inSeconds,
      durationMinutes: (_stopwatch.elapsed.inSeconds / 60).ceil(),
      isCompleted: true,
    );
    try {
      await _storage?.addGameProgress(progress);
    } catch (_) {}
    if (!mounted) return;
    if (!mounted) return;
    await ResultFlow.showStarsThenResult(
      context: context,
      score: _score,
      maxScore: 100,
      onPlayAgain: () {
        setState(() {
          _score = 0;
          _round = 1;
          _typed = '';
          _currentWord = (_wordBank..shuffle()).first;
          _stopwatch
            ..reset()
            ..start();
        });
      },
      onBackToMenu: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildPromptCard(),
              const SizedBox(height: 24),
              _buildKeyboard(),
              const Spacer(),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Text('Spelling Bee (EN)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('Score: $_score'),
        ],
      ),
    );
  }

  Widget _buildPromptCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            const Text('Type this word:', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              _currentWord,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _feedback == 'correct' ? Colors.green : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _typed.isEmpty ? '_' : _typed,
                  style: TextStyle(
                    fontSize: 24,
                    color: _feedback == 'wrong' ? Colors.red : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
            if (_feedback == 'wrong') ...[
              const SizedBox(height: 8),
              const Text('Try again!', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    const int keysPerRow = 7;
    const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    // قسّم الأحرف إلى أسطر من 7 أحرف، مع ملء الفراغات لتصبح كل سطر 7 مفاتيح بالضبط
    final List<String> rows = [];
    for (int i = 0; i < alphabet.length; i += keysPerRow) {
      final end = (i + keysPerRow) > alphabet.length ? alphabet.length : (i + keysPerRow);
      final chunk = alphabet.substring(i, end);
      final remaining = keysPerRow - chunk.length;
      if (remaining > 0) {
        final leftPad = remaining ~/ 2;
        final rightPad = remaining - leftPad;
        rows.add((' ' * leftPad) + chunk + (' ' * rightPad));
      } else {
        rows.add(chunk);
      }
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double horizontalPadding = 16 * 2;
          const double gap = 8;
          final double maxWidth = constraints.maxWidth - horizontalPadding;
          final double approxKeyWidth = maxWidth / keysPerRow;
          final double keyHeight = approxKeyWidth.clamp(60.0, 80.0);
          final double fontSize = (approxKeyWidth * 0.5).clamp(20.0, 26.0);

          Widget buildRow(String letters) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: List.generate(keysPerRow, (index) {
                  final String c = letters[index];
                  final bool isPlaceholder = c.trim().isEmpty;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: gap / 2),
                      child: SizedBox(
                        height: keyHeight,
                        child: isPlaceholder
                            ? const SizedBox.shrink()
                            : ElevatedButton(
                                onPressed: () => _onKeyTap(c.toLowerCase()),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    c,
                                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }

          return Column(
            children: rows.map(buildRow).toList(),
          );
        },
      ),
    );
  }

  Widget _key(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () => _onKeyTap(label.toLowerCase()),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          minimumSize: const Size(36, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _onBackspace,
              icon: const Icon(Icons.backspace),
              label: const Text('Back'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}


