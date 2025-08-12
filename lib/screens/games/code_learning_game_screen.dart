import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../utils/colors.dart';
import '../../services/audio_service.dart';
import '../../utils/constants.dart';
import '../../services/local_storage.dart';
import '../../models/game_progress.dart';
import '../../widgets/result_flow.dart';
import '../../utils/game_utils.dart';

class CodeLearningGameScreen extends StatefulWidget {
  const CodeLearningGameScreen({Key? key}) : super(key: key);

  @override
  State<CodeLearningGameScreen> createState() => _CodeLearningGameScreenState();
}

class _CodeLearningGameScreenState extends State<CodeLearningGameScreen> {
  static const List<String> languages = ['Python', 'JavaScript', 'Dart'];
  String _selectedLanguage = 'Python';

  // مستويات مبسطة: ترتيب خطوات، اختيار التعليمة الصحيحة، إكمال الفراغ
  final List<_Challenge> _challenges = [
    // تحدي ترتيب خطوات برمجية بدل خطوات الطبخ
    _Challenge(
      title: 'رتّب الخطوات لتنفيذ برنامج بسيط',
      type: ChallengeType.ordering,
      // ترتيب مبدئي عشوائي لخلق التحدي
      items: ['شغّل البرنامج', 'اكتب الكود', 'شاهد الناتج', 'اختر لغة البرمجة'],
      // الهدف الصحيح النهائي
      correctOrderStrings: ['اختر لغة البرمجة', 'اكتب الكود', 'شغّل البرنامج', 'شاهد الناتج'],
      initialItems: ['شغّل البرنامج', 'اكتب الكود', 'شاهد الناتج', 'اختر لغة البرمجة'],
    ),
    _Challenge(
      title: 'اختر التعليمة الصحيحة لطباعة مرحبًا',
      type: ChallengeType.multipleChoice,
      items: [
        "print('مرحبا')",
        "echo 'مرحبا'",
        "System.out.println('مرحبا')",
      ],
      correctIndexByLang: {
        'Python': 0,
        'JavaScript': 1,
        'Dart': 0,
      },
    ),
    _Challenge(
      title: 'أكمل التعليمة لطباعة العدد 5',
      type: ChallengeType.fillInBlank,
      snippetByLang: {
        'Python': 'print(___)',
        'JavaScript': 'console.log(___);',
        'Dart': 'print(___);',
      },
      acceptedAnswers: ['5', ' 5 '],
    ),
  ];

  int _index = 0;
  int _score = 0;
  late Stopwatch _timer;
  LocalStorageService? _storage;
  bool _completed = false;
  int? _orderingSelectedIndex; // لاختيار عنصر والتبديل بالنقر
  AudioService? _audioService;

  @override
  void initState() {
    super.initState();
    _timer = Stopwatch()..start();
    _init();
  }

  Future<void> _init() async {
    _storage = await LocalStorageService.getInstance();
    try { _audioService = await AudioService.getInstance(); } catch (_) {}
    setState(() {});
  }

  void _next() {
    setState(() {
      _index = min(_index + 1, _challenges.length - 1);
    });
  }

  Future<void> _finish() async {
    _timer.stop();
    final progress = GameProgress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      childId: 'local_child',
      gameType: AppConstants.codeLearningGame,
      level: 1,
      score: _score,
      maxScore: _challenges.length * 10,
      stars: _score >= (_challenges.length * 9) ? 3 : _score >= (_challenges.length * 7) ? 2 : _score >= (_challenges.length * 5) ? 1 : 0,
      timeSpentSeconds: _timer.elapsed.inSeconds,
      durationMinutes: (_timer.elapsed.inSeconds / 60).ceil(),
      isCompleted: true,
    );
    await _storage?.addGameProgress(progress);
    if (!mounted) return;
    setState(() {
      _completed = true;
    });
    // Unified star-then-result flow
    final maxScore = _challenges.length * 10;
    if (!mounted) return;
    await ResultFlow.showStarsThenResult(
      context: context,
      score: _score,
      maxScore: maxScore,
      onPlayAgain: () {
        setState(() {
          _completed = false;
          _score = 0;
          _index = 0;
          _timer.reset();
          _timer.start();
          for (final ch in _challenges) {
            if (ch.initialItems != null) {
              ch.items
                ..clear()
                ..addAll(List<String>.from(ch.initialItems!));
            }
          }
        });
      },
      onBackToMenu: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenges[_index];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: _completed
              ? _buildSummary()
              : Column(
                  children: [
                    _buildHeader(),
                    _buildLanguagePicker(),
                    const SizedBox(height: 8),
                    _buildChallenge(challenge),
                    const Spacer(),
                    _buildControls(challenge),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSummary() => const SizedBox.shrink();

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
          const SizedBox(width: 8),
          const Text('لعبة تعلّم البرمجة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('Score: $_score'),
        ],
      ),
    );
  }

  Widget _buildLanguagePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('لغة البرمجة:'),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedLanguage,
            items: languages
                .map((l) => DropdownMenuItem<String>(
                      value: l,
                      child: Text(l),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedLanguage = v ?? 'Python'),
          ),
        ],
      ),
    );
  }

  Widget _buildChallenge(_Challenge c) {
    switch (c.type) {
      case ChallengeType.ordering:
        return _buildOrdering(c);
      case ChallengeType.multipleChoice:
        return _buildMultipleChoice(c);
      case ChallengeType.fillInBlank:
        return _buildFillInBlank(c);
    }
  }

  // ترتيب خطوات
  Widget _buildOrdering(_Challenge c) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('اسحب لإعادة الترتيب أو اضغط عنصرين للتبديل',
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 8),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final moving = c.items.removeAt(oldIndex);
                c.items.insert(newIndex, moving);
                _orderingSelectedIndex = null;
              });
            },
            children: [
              for (int i = 0; i < c.items.length; i++)
                Card(
                  key: ValueKey(c.items[i]),
                  color: i == _orderingSelectedIndex
                      ? AppColors.surface.withOpacity(0.9)
                      : null,
                  child: ListTile(
                    title: Text(c.items[i]),
                    selected: i == _orderingSelectedIndex,
                    onTap: () {
                      setState(() {
                        if (_orderingSelectedIndex == null) {
                          _orderingSelectedIndex = i;
                        } else if (_orderingSelectedIndex == i) {
                          _orderingSelectedIndex = null;
                        } else {
                          final a = _orderingSelectedIndex!;
                          final b = i;
                          final tmp = c.items[a];
                          c.items[a] = c.items[b];
                          c.items[b] = tmp;
                          _orderingSelectedIndex = null;
                        }
                      });
                    },
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: const Icon(Icons.drag_handle),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final target = c.correctOrderStrings ?? const <String>[];
              final ok = listEquals(c.items, target);
              if (ok) {
                setState(() => _score += 10);
                if (_index == _challenges.length - 1) {
                  _finish();
                } else {
                  _next();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الترتيب غير صحيح، حاول مرة أخرى')));
              }
            },
            child: const Text('تحقق'),
          ),
        ],
      ),
    );
  }

  // اختيار متعدد يكيّف الصياغة بحسب اللغة
  Widget _buildMultipleChoice(_Challenge c) {
    final lang = _selectedLanguage;
    final List<String> variants;
    if (lang == 'Python') {
      variants = ["print('مرحبا')", "console.log('مرحبا')", "System.out.println('مرحبا')"];
    } else if (lang == 'JavaScript') {
      variants = ["print('مرحبا')", "console.log('مرحبا')", "System.out.println('مرحبا')"];
    } else {
      variants = ["print('مرحبا')", "console.log('مرحبا')", "System.out.println('مرحبا')"];
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(variants.length, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ElevatedButton(
                onPressed: () {
                  final correctIdx = c.correctIndexByLang?[lang] ?? 0;
                  if (i == correctIdx) {
                    setState(() => _score += 10);
                    if (_index == _challenges.length - 1) {
                      _finish();
                    } else {
                      _next();
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حاول مرة أخرى')));
                  }
                },
                child: Text(variants[i]),
              ),
            );
          }),
        ],
      ),
    );
  }

  // إكمال الفراغ
  final TextEditingController _fillController = TextEditingController();
  Widget _buildFillInBlank(_Challenge c) {
    final lang = _selectedLanguage;
    final snippet = c.snippetByLang?[lang] ?? '';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(child: Text(snippet.replaceAll('___', '   ___   '))),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _fillController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(hintText: '___'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final ans = _fillController.text.trim();
              if (c.acceptedAnswers.contains(ans)) {
                setState(() => _score += 10);
                _fillController.clear();
                if (_index == _challenges.length - 1) {
                  _finish();
                } else {
                  _next();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إجابة غير صحيحة')));
              }
            },
            child: const Text('تحقق'),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(_Challenge c) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (_index == _challenges.length - 1)
                  ? null
                  : () {
                      _next();
                    },
              icon: const Icon(Icons.skip_next),
              label: const Text('تخطي'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _finish,
              child: const Text('إنهاء'),
            ),
          ),
        ],
      ),
    );
  }
}

enum ChallengeType { ordering, multipleChoice, fillInBlank }

class _Challenge {
  final String title;
  final ChallengeType type;
  final List<String> items; // للاستخدام العام
  final List<int>? correctOrder; // للترتيب
  final Map<String, int>? correctIndexByLang; // للاختيار المتعدد
  final Map<String, String>? snippetByLang; // لملء الفراغ
  final List<String> acceptedAnswers; // لملء الفراغ
  // حقول إضافية لتحدي الترتيب بالنص الكامل وإعادة التهيئة
  final List<String>? correctOrderStrings; // الهدف الصحيح كنصوص كاملة
  final List<String>? initialItems; // الحالة الابتدائية لإعادة اللعب

  _Challenge({
    required this.title,
    required this.type,
    this.items = const [],
    this.correctOrder,
    this.correctIndexByLang,
    this.snippetByLang,
    this.acceptedAnswers = const [],
    this.correctOrderStrings,
    this.initialItems,
  });
}


