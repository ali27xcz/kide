import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/colors.dart';

class StarCollectOverlay extends StatefulWidget {
  final int stars;
  final VoidCallback onCompleted;

  const StarCollectOverlay({super.key, required this.stars, required this.onCompleted});

  @override
  State<StarCollectOverlay> createState() => _StarCollectOverlayState();
}

class _StarCollectOverlayState extends State<StarCollectOverlay> with TickerProviderStateMixin {
  late final AnimationController _burstController;
  late final AnimationController _gatherController;

  @override
  void initState() {
    super.initState();
    // عودة التوقيتات الأصلية كما كانت سابقًا
    _burstController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _gatherController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    Future.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      await _gatherController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _burstController.dispose();
    _gatherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 3);
    final target = Offset(size.width / 2, size.height / 2);
    final starCount = 12;

    return Material(
      color: Colors.black.withOpacity(0.4),
      child: Stack(
        children: [
          // Burst stars
          AnimatedBuilder(
            animation: Listenable.merge([_burstController, _gatherController]),
            builder: (context, _) {
              final burstT = Curves.easeOut.transform(_burstController.value);
              final gatherT = Curves.easeInOut.transform(_gatherController.value);
              return Stack(
                children: List.generate(starCount, (i) {
                  final angle = (i / starCount) * 6.28318530718; // 2*pi
                  final radius = 140.0 * burstT * (1.0 - 0.2 * (i % 3));
                  final pos = Offset(
                    center.dx + radius * MathUtils.cos(angle),
                    center.dy + radius * MathUtils.sin(angle),
                  );
                  final animatedPos = Offset(
                    lerpDouble(pos.dx, target.dx, gatherT)!,
                    lerpDouble(pos.dy, target.dy, gatherT)!,
                  );
                  final scale = 0.6 + 0.4 * (1 - gatherT);
                  return Positioned(
                    left: animatedPos.dx - 12,
                    top: animatedPos.dy - 12,
                    child: Transform.scale(
                      scale: scale,
                      child: Icon(
                        Icons.star,
                        color: AppColors.goldStar.withOpacity(0.9),
                        size: 24,
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          // Central card showing collected stars
          Align(
            alignment: Alignment.center,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: _gatherController, curve: Curves.easeOutBack),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('النجوم:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) => Icon(
                        i < widget.stars ? Icons.star : Icons.star_border,
                        color: AppColors.goldStar,
                        size: 28,
                      )),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class MathUtils {
  static double cos(double v) => math.cos(v);
  static double sin(double v) => math.sin(v);
}

double? lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}


