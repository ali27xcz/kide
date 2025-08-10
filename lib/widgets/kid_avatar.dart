import 'package:flutter/material.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import '../utils/colors.dart';

class KidAvatar extends StatelessWidget {
  final String avatarValue;
  final double size;
  final bool showRing;
  final VoidCallback? onTap;
  final Widget? badge;
  final Color? backgroundColor;

  const KidAvatar({
    Key? key,
    required this.avatarValue,
    this.size = 50,
    this.showRing = true,
    this.onTap,
    this.badge,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget avatarContent = _buildContent();
    final Widget result = showRing
        ? Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: ClipOval(child: avatarContent),
            ),
          )
        : ClipOval(child: SizedBox(width: size, height: size, child: avatarContent));

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          result,
          if (badge != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: badge!,
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final String value = (avatarValue.isEmpty) ? 'kedy-fallback' : avatarValue;
    if (value.startsWith('assets/')) {
      return Container(
        color: backgroundColor ?? Colors.white,
        child: Image.asset(
          value,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return BoringAvatars(name: 'kedy-fallback');
          },
        ),
      );
    }
    return Container(
      color: backgroundColor ?? Colors.white,
      child: BoringAvatars(name: value),
    );
  }
}


