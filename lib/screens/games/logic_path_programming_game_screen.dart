import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/audio_service.dart';
import '../../services/local_storage.dart';
import '../../models/game_progress.dart';
import '../../widgets/result_flow.dart';

class LogicPathProgrammingGameScreen extends StatefulWidget {
  const LogicPathProgrammingGameScreen({Key? key}) : super(key: key);

  @override
  State<LogicPathProgrammingGameScreen> createState() => _LogicPathProgrammingGameScreenState();
}

class _LogicPathProgrammingGameScreenState extends State<LogicPathProgrammingGameScreen> {
  static const int _gridSize = 5;
  final List<String> _commands = [];
  final List<String> _program = [];
  final List<Offset> _obstacles = [const Offset(2, 2), const Offset(3, 1)];
  final Offset _goal = const Offset(4, 4);
  Offset _robot = const Offset(0, 0);
  int _score = 0;
  LocalStorageService? _storage;
  late Stopwatch _timer;
  AudioService? _audioService;

  @override
  void initState() {
    super.initState();
    _timer = Stopwatch()..start();
    _commands.addAll(['UP', 'DOWN', 'LEFT', 'RIGHT', 'REPEAT 2', 'REPEAT 3']);
    _init();
  }

  Future<void> _init() async {
    _storage = await LocalStorageService.getInstance();
    try { _audioService = await AudioService.getInstance(); } catch (_) {}
  }

  void _add(String cmd) {
    setState(() => _program.add(cmd));
  }

  void _clear() {
    setState(() {
      _program.clear();
      _robot = const Offset(0, 0);
    });
  }

  Future<void> _run() async {
    Offset pos = _robot;
    for (final cmd in _program) {
      if (cmd.startsWith('REPEAT')) {
        final times = int.parse(cmd.split(' ').last);
        // repeat the last simple command
        if (_program.isNotEmpty) {
          final prevIndex = _program.indexOf(cmd) - 1;
          if (prevIndex >= 0) {
            final prev = _program[prevIndex];
            for (int i = 0; i < times; i++) {
              pos = _apply(prev, pos);
            }
          }
        }
      } else {
        pos = _apply(cmd, pos);
      }
      if (!_isInside(pos) || _obstacles.contains(pos)) {
        _fail();
        return;
      }
    }
    setState(() => _robot = pos);
    if (pos == _goal) {
      _score = 100;
      await _finish();
    } else {
      _fail();
    }
  }

  Offset _apply(String cmd, Offset pos) {
    switch (cmd) {
      case 'UP':
        return Offset(pos.dx, pos.dy - 1);
      case 'DOWN':
        return Offset(pos.dx, pos.dy + 1);
      case 'LEFT':
        return Offset(pos.dx - 1, pos.dy);
      case 'RIGHT':
        return Offset(pos.dx + 1, pos.dy);
    }
    return pos;
  }

  bool _isInside(Offset p) => p.dx >= 0 && p.dy >= 0 && p.dx < _gridSize && p.dy < _gridSize;

  void _fail() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اصطدمت بعائق! حاول مجدداً')));
  }

  Future<void> _finish() async {
    _timer.stop();
    final progress = GameProgress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      childId: 'local_child',
      gameType: AppConstants.logicPathProgrammingGame,
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
    if (!mounted) return;
    await ResultFlow.showStarsThenResult(
      context: context,
      score: _score,
      maxScore: 100,
      onPlayAgain: () {
        setState(() {
          _program.clear();
          _robot = const Offset(0, 0);
          _score = 0;
          _timer
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
                    const SizedBox(width: 8),
                    const Text('Logic Path Programming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(child: _buildGrid()),
              _buildPalette(),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _gridSize),
          itemCount: _gridSize * _gridSize,
          itemBuilder: (_, i) {
            final x = i % _gridSize;
            final y = i ~/ _gridSize;
            final p = Offset(x.toDouble(), y.toDouble());
            final isRobot = p == _robot;
            final isGoal = p == _goal;
            final isObstacle = _obstacles.contains(p);
            return Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isGoal
                    ? Colors.greenAccent
                    : isObstacle
                        ? Colors.redAccent
                        : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black12),
              ),
              child: isRobot
                  ? const Icon(Icons.smart_toy, color: AppColors.primary)
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPalette() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Wrap(
        spacing: 8,
        children: _commands
            .map((c) => ActionChip(label: Text(c), onPressed: () => _add(c)))
            .toList(),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(onPressed: _run, icon: const Icon(Icons.play_arrow), label: const Text('تشغيل')),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(onPressed: _clear, icon: const Icon(Icons.delete), label: const Text('مسح')),
          ),
        ],
      ),
    );
  }
}


