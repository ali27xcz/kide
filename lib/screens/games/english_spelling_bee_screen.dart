import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/local_storage.dart';
import '../../models/game_progress.dart';

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
  }

  void _onKeyTap(String ch) {
    setState(() => _typed += ch);
  }

  void _onBackspace() {
    if (_typed.isEmpty) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  Future<void> _submit() async {
    final bool correct = _typed.toLowerCase() == _currentWord.toLowerCase();
    setState(() {
      _score += correct ? 10 : 0;
      _round += 1;
      _typed = '';
      _currentWord = (_wordBank..shuffle()).first;
    });
    if (_round > 10) {
      await _finish();
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Great Job!'),
        content: Text('Score: $_score/100'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    ).then((_) => Navigator.of(context).pop());
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
      child: Column(
        children: [
          const Text('Type this word:', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(_currentWord, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
            child: Text(_typed.isEmpty ? '_' : _typed, style: const TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    const rows = [
      'QWERTYUIOP',
      'ASDFGHJKL',
      'ZXCVBNM',
    ];
    return Column(
      children: rows.map((r) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: r.split('').map((c) => _key(c)).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _key(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () => _onKeyTap(label.toLowerCase()),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
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


