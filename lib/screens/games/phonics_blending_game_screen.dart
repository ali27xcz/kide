import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/local_storage.dart';
import '../../models/game_progress.dart';

class PhonicsBlendingGameScreen extends StatefulWidget {
  const PhonicsBlendingGameScreen({Key? key}) : super(key: key);

  @override
  State<PhonicsBlendingGameScreen> createState() => _PhonicsBlendingGameScreenState();
}

class _PhonicsBlendingGameScreenState extends State<PhonicsBlendingGameScreen> {
  final List<List<String>> _questions = [
    ['c', 'a', 't', 'cat'],
    ['d', 'o', 'g', 'dog'],
    ['s', 'u', 'n', 'sun'],
    ['b', 'u', 's', 'bus'],
  ];
  int _index = 0;
  List<String> _picked = [];
  int _score = 0;
  LocalStorageService? _storage;
  late Stopwatch _timer;

  @override
  void initState() {
    super.initState();
    _timer = Stopwatch()..start();
    _init();
  }

  Future<void> _init() async {
    _storage = await LocalStorageService.getInstance();
  }

  void _toggleSound(String s) {
    setState(() {
      if (_picked.contains(s)) {
        _picked.remove(s);
      } else {
        _picked.add(s);
      }
    });
  }

  Future<void> _check() async {
    final target = _questions[_index][3];
    if (_picked.join('') == target) _score += 25;
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _picked.clear();
      });
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    _timer.stop();
    final progress = GameProgress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      childId: 'local_child',
      gameType: AppConstants.phonicsBlendingGame,
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
    final q = _questions[_index];
    final sounds = q.take(3).toList();
    final target = q[3];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
                    const SizedBox(width: 8),
                    const Text('Phonics Blending', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('Score: $_score'),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('Blend the sounds to form the word'),
                    const SizedBox(height: 8),
                    Text(target, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: sounds
                    .map((s) => FilterChip(
                          label: Text(s),
                          selected: _picked.contains(s),
                          onSelected: (_) => _toggleSound(s),
                        ))
                    .toList(),
              ),
              const Spacer(),
              Padding(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}


