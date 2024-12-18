import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingAnimation extends StatelessWidget {
  final Color? color;
  final double size;

  const LoadingAnimation({
    super.key,
    this.color,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actualColor = color ?? theme.colorScheme.primary;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: actualColor.withOpacity(0.2),
                width: 4,
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .scale(
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
              )
              .then()
              .scale(
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
                begin: const Offset(1.2, 1.2),
                end: const Offset(0.8, 0.8),
              ),

          // Inner circle
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: actualColor.withOpacity(0.5),
                width: 4,
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .scale(
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
                begin: const Offset(1.2, 1.2),
                end: const Offset(0.8, 0.8),
              )
              .then()
              .scale(
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
              ),

          // Center dot
          Container(
            width: size * 0.2,
            height: size * 0.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: actualColor,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .scale(
                duration: 750.ms,
                curve: Curves.easeInOut,
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.5, 1.5),
              )
              .then()
              .scale(
                duration: 750.ms,
                curve: Curves.easeInOut,
                begin: const Offset(1.5, 1.5),
                end: const Offset(0.5, 0.5),
              ),
        ],
      ),
    );
  }
}
