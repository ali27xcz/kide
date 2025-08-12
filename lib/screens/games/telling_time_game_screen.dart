import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/local_storage.dart';
import '../../services/audio_service.dart';
import '../../models/game_progress.dart';
import '../../widgets/result_flow.dart';

class TellingTimeGameScreen extends StatefulWidget {
  const TellingTimeGameScreen({Key? key}) : super(key: key);

  @override
  State<TellingTimeGameScreen> createState() => _TellingTimeGameScreenState();
}

class _TellingTimeGameScreenState extends State<TellingTimeGameScreen> {
  late TimeOfDay _target;
  int _score = 0;
  int _round = 1;
  LocalStorageService? _storage;
  late Stopwatch _timer;
  AudioService? _audioService;

  @override
  void initState() {
    super.initState();
    _timer = Stopwatch()..start();
    _randomize();
    _init();
  }

  Future<void> _init() async {
    _storage = await LocalStorageService.getInstance();
    try { _audioService = await AudioService.getInstance(); } catch (_) {}
  }

  void _randomize() {
    final rand = Random();
    _target = TimeOfDay(hour: rand.nextInt(12), minute: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55][rand.nextInt(12)]);
  }

  Future<void> _submit(int hour, int minute) async {
    final correct = hour % 12 == _target.hour && minute == _target.minute;
    if (correct) _score += 20;
    if (_round < 5) {
      setState(() {
        _round++;
        _randomize();
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
      gameType: AppConstants.tellingTimeGame,
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
          _score = 0;
          _round = 1;
          _timer
            ..reset()
            ..start();
          _randomize();
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
                    const Text('Telling Time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('Target: ${_target.format(context)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ClockFace(time: _target),
              const Spacer(),
              _TimePicker(onSubmit: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockFace extends StatelessWidget {
  final TimeOfDay time;
  const _ClockFace({required this.time});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(220, 220),
      painter: _ClockPainter(time),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final TimeOfDay time;
  _ClockPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final bg = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius, bg);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = AppColors.primary;
    canvas.drawCircle(center, radius, border);

    // hour marks
    final tick = Paint()
      ..strokeWidth = 2
      ..color = AppColors.textSecondary;
    for (int i = 0; i < 60; i++) {
      final angle = 2 * pi * (i / 60);
      final length = i % 5 == 0 ? 12.0 : 6.0;
      final p1 = center + Offset(cos(angle), sin(angle)) * (radius - 6);
      final p2 = center + Offset(cos(angle), sin(angle)) * (radius - 6 - length);
      canvas.drawLine(p1, p2, tick);
    }

    // hands
    final hourAngle = 2 * pi * ((time.hour % 12 + time.minute / 60) / 12);
    final minuteAngle = 2 * pi * (time.minute / 60);
    final hourPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final minutePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + Offset(cos(hourAngle - pi / 2), sin(hourAngle - pi / 2)) * (radius * 0.5), hourPaint);
    canvas.drawLine(center, center + Offset(cos(minuteAngle - pi / 2), sin(minuteAngle - pi / 2)) * (radius * 0.75), minutePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TimePicker extends StatefulWidget {
  final Future<void> Function(int hour, int minute) onSubmit;
  const _TimePicker({required this.onSubmit});

  @override
  State<_TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<_TimePicker> {
  int _hour = 0;
  int _minute = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _spinner('Hour', 0, 11, (v) => _hour = v)),
              const SizedBox(width: 12),
              Expanded(child: _spinner('Minute', 0, 55, (v) => _minute = v, step: 5)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.onSubmit(_hour, _minute),
              icon: const Icon(Icons.check),
              label: const Text('تحقق'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _spinner(String label, int min, int max, void Function(int) onChanged, {int step = 1}) {
    final values = [for (int i = min; i <= max; i += step) i];
    int selected = values.first;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          DropdownButton<int>(
            value: selected,
            isExpanded: true,
            items: values.map((v) => DropdownMenuItem(value: v, child: Text(v.toString()))).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                selected = v;
                onChanged(v);
              });
            },
          ),
        ],
      ),
    );
  }
}


