import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/local_storage.dart';
import '../../models/game_progress.dart';

class SentenceBuilderGameScreen extends StatefulWidget {
  const SentenceBuilderGameScreen({Key? key}) : super(key: key);

  @override
  State<SentenceBuilderGameScreen> createState() => _SentenceBuilderGameScreenState();
}

class _SentenceBuilderGameScreenState extends State<SentenceBuilderGameScreen> {
  final List<List<String>> _levels = [
    ['cat', 'the', 'is', 'sleeping'],
    ['play', 'we', 'together'],
    ['carrots', 'rabbits', 'eat'],
    ['teacher', 'our', 'kind', 'is'],
  ];
  int _levelIndex = 0;
  List<String> _pool = [];
  List<String> _answer = [];
  int _score = 0;
  late Stopwatch _timer;
  LocalStorageService? _storage;

  @override
  void initState() {
    super.initState();
    _timer = Stopwatch()..start();
    _init();
    _loadLevel();
  }

  Future<void> _init() async {
    _storage = await LocalStorageService.getInstance();
  }

  void _loadLevel() {
    _answer.clear();
    _pool = List<String>.from(_levels[_levelIndex])..shuffle();
    setState(() {});
  }

  void _addWord(String w) {
    setState(() {
      _pool.remove(w);
      _answer.add(w);
    });
  }

  void _removeWord(String w) {
    setState(() {
      _answer.remove(w);
      _pool.add(w);
    });
  }

  Future<void> _check() async {
    final target = _levels[_levelIndex].join(' ');
    final current = _answer.join(' ');
    final correct = target == current;
    if (correct) _score += 25;
    if (_levelIndex < _levels.length - 1) {
      _levelIndex++;
      _loadLevel();
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    _timer.stop();
    final progress = GameProgress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      childId: 'local_child',
      gameType: AppConstants.sentenceBuilderGame,
      level: 1,
      score: _score,
      maxScore: 100,
      stars: _score >= 90 ? 3 : _score >= 70 ? 2 : _score >= 40 ? 1 : 0,
      timeSpentSeconds: _timer.elapsed.inSeconds,
      durationMinutes: (_timer.elapsed.inSeconds / 60).ceil(),
      isCompleted: true,
    );
    await _storage?.addGameProgress(progress);
    if (!mounted) return;
    Navigator.of(context).pop();
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
              const SizedBox(height: 12),
              _buildDropArea(),
              const SizedBox(height: 12),
              _buildPool(),
              const Spacer(),
              _buildControls(),
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
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
          const SizedBox(width: 8),
          const Text('Sentence Builder (EN)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('Score: $_score'),
        ],
      ),
    );
  }

  Widget _buildDropArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _answer
            .map((w) => Chip(
                  label: Text(w),
                  onDeleted: () => _removeWord(w),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPool() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _pool
            .map((w) => ActionChip(
                  label: Text(w),
                  onPressed: () => _addWord(w),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _check,
              icon: const Icon(Icons.check),
              label: const Text('تحقق'),
            ),
          ),
        ],
      ),
    );
  }
}


