import 'package:flutter/material.dart';

class GradientPainter extends CustomPainter {
  final bool isHovering;
  final Offset? mousePosition;
  final Animation<double> animation;
  final bool isDarkMode;

  GradientPainter({
    required this.isHovering,
    this.mousePosition,
    required this.animation,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isHovering) return;

    final Rect rect = Offset.zero & size;
    final center = mousePosition ?? Offset(size.width / 2, size.height / 2);

    // 여러 개의 원을 그려 연속적인 파동 효과 생성
    for (var i = 0; i < 3; i++) {
      final animationValue = (animation.value + i / 3) % 1.0;
      final gradient = RadialGradient(
        center: Alignment((center.dx / size.width) * 2 - 1,
            (center.dy / size.height) * 2 - 1),
        radius: animationValue * 2.5,
        colors: isDarkMode
            ? [
                Colors.purple.shade900.withOpacity(0.3 * (1 - animationValue)),
                Colors.blue.shade900.withOpacity(0.2 * (1 - animationValue)),
                Colors.red.shade900.withOpacity(0.1 * (1 - animationValue)),
                Colors.transparent,
              ]
            : [
                Colors.blue.withOpacity(0.3 * (1 - animationValue)),
                Colors.green.withOpacity(0.2 * (1 - animationValue)),
                Colors.pink.withOpacity(0.1 * (1 - animationValue)),
                Colors.transparent,
              ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      );

      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
