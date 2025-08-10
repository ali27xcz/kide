import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/local_storage.dart';
import '../../models/game_progress.dart';

class AdditionGameScreen extends StatefulWidget {
  const AdditionGameScreen({Key? key}) : super(key: key);

  @override
  State<AdditionGameScreen> createState() => _AdditionGameScreenState();
}

class _AdditionGameScreenState extends State<AdditionGameScreen> {
  int _a = 1;
  int _b = 1;
  int _score = 0;
  final _controller = TextEditingController();
  LocalStorageService? _storage;
  late Stopwatch _timer;

  @override
  void initState() {
    super.initState();
    _timer = Stopwatch()..start();
    _next();
    _init();
  }

  Future<void> _init() async {
    _storage = await LocalStorageService.getInstance();
  }

  void _next() {
    _controller.clear();
    _a = 1 + (DateTime.now().millisecondsSinceEpoch % 9);
    _b = 1 + (DateTime.now().microsecondsSinceEpoch % 9);
    setState(() {});
  }

  Future<void> _submit() async {
    final ans = int.tryParse(_controller.text.trim());
    if (ans != null && ans == _a + _b) {
      _score += 10;
    }
    if (_score >= 100) {
      await _finish();
    } else {
      _next();
    }
  }

  Future<void> _finish() async {
    _timer.stop();
    final progress = GameProgress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      childId: 'local_child',
      gameType: AppConstants.additionGame,
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text('لعبة الجمع', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('Score: $_score'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                child: Text('$_a + $_b = ?', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    hintText: 'الإجابة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check),
                    label: const Text('تحقق'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


