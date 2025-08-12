import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import '../utils/colors.dart';

class SuccessResultView extends StatefulWidget {
  final int score;
  final int maxScore;
  final int stars;
  final String title;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const SuccessResultView({super.key, required this.score, required this.maxScore, required this.stars, this.title = 'أحسنت!', this.onRetry, this.onBack});

  @override
  State<SuccessResultView> createState() => _SuccessResultViewState();
}

class _SuccessResultViewState extends State<SuccessResultView> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _confettiController;
  late final Animation<double> _entryScale;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();
    // Repeat confetti indefinitely until the page is dismissed
    _confettiController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _entryScale = CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Lottie confetti background (from assets/lottie/Confetti.json)
        Positioned.fill(
          child: IgnorePointer(
            child: Lottie.asset(
              'assets/lottie/Confetti.json',
              repeat: true,
              fit: BoxFit.cover,
              frameRate: FrameRate.max,
            ),
          ),
        ),
        // Card
        Align(
          alignment: Alignment.center,
          child: ScaleTransition(
            scale: _entryScale,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  _StarsRow(active: widget.stars, activeColor: AppColors.goldStar),
                  const SizedBox(height: 20),
                  Text('نتيجتك: ${widget.score} / ${widget.maxScore}', style: const TextStyle(fontSize: 18, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (widget.onBack != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onBack,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonSecondary, foregroundColor: AppColors.textSecondary),
                            child: const Text('العودة للقائمة'),
                          ),
                        ),
                      if (widget.onBack != null && widget.onRetry != null) const SizedBox(width: 12),
                      if (widget.onRetry != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onRetry,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            child: const Text('العب مجدداً'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FailureResultView extends StatefulWidget {
  final int score;
  final int maxScore;
  final int stars;
  final String title;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const FailureResultView({super.key, required this.score, required this.maxScore, required this.stars, this.title = 'يجب عليك الاجتهاد والمحاولة مرة أخرى', this.onRetry, this.onBack});

  @override
  State<FailureResultView> createState() => _FailureResultViewState();
}

class _FailureResultViewState extends State<FailureResultView> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _entryScale;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _entryScale = CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dim red backdrop to convey failure state (no floating shards)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.red.withOpacity(0.08), Colors.transparent],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: ScaleTransition(
            scale: _entryScale,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 16),
                  _StarsRow(active: widget.stars, activeColor: Colors.red),
                  const SizedBox(height: 20),
                  Text('نتيجتك: ${widget.score} / ${widget.maxScore}', style: const TextStyle(fontSize: 18, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (widget.onBack != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onBack,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonSecondary, foregroundColor: AppColors.textSecondary),
                            child: const Text('العودة للقائمة'),
                          ),
                        ),
                      if (widget.onBack != null && widget.onRetry != null) const SizedBox(width: 12),
                      if (widget.onRetry != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onRetry,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            child: const Text('حاول مجدداً'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StarsRow extends StatelessWidget {
  final int active;
  final Color activeColor;
  const _StarsRow({required this.active, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final delay = i * 120;
        return _PulsingChild(
          delayMs: delay,
          child: Icon(i < active ? Icons.star : Icons.star_border, color: activeColor, size: 32),
        );
      }),
    );
  }
}

class _PulsingChild extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _PulsingChild({required this.child, this.delayMs = 0});

  @override
  State<_PulsingChild> createState() => _PulsingChildState();
}

class _PulsingChildState extends State<_PulsingChild> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _a = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _a, child: widget.child);
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t; // 0..1
  _ConfettiPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final colors = [
      AppColors.funRed,
      AppColors.funBlue,
      AppColors.funYellow,
      AppColors.funGreen,
      AppColors.funPurple,
      AppColors.funOrange,
      Colors.cyan,
      Colors.pinkAccent,
      Colors.lime,
      Colors.tealAccent,
      Colors.amber,
    ];
    for (int i = 0; i < 160; i++) {
      final p = rnd.nextDouble();
      final baseX = rnd.nextDouble() * size.width;
      // continuous vertical flow
      final y = (p * size.height + t * size.height) % size.height;
      // gentle horizontal drift for more life
      final drift = math.sin((t * 2 * math.pi) + i) * 10.0;
      final x = (baseX + drift).clamp(0.0, size.width).toDouble();
      final paint = Paint()..color = colors[i % colors.length].withOpacity(0.7);
      final w = 3.0 + (i % 3) * 2.0;
      final h = 6.0 + (i % 4) * 3.0;
      final rect = Rect.fromCenter(center: Offset(x.toDouble(), y.toDouble()), width: w, height: h);
      canvas.save();
      canvas.translate(x.toDouble(), y.toDouble());
      canvas.rotate((i * 17) * math.pi / 180 * (0.5 + 0.5 * t));
      canvas.translate(-x.toDouble(), -y.toDouble());
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}

class _FallingShardsPainter extends CustomPainter {
  final double t; // 0..1
  _FallingShardsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final paint = Paint()..color = Colors.red.withOpacity(0.2);
    for (int i = 0; i < 60; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = (rnd.nextDouble() * size.height + t * size.height) % size.height;
      final w = 2.0 + rnd.nextDouble() * 3.0;
      final h = 6.0 + rnd.nextDouble() * 8.0;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rnd.nextDouble() * math.pi);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), const Radius.circular(1)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FallingShardsPainter oldDelegate) => true;
}


