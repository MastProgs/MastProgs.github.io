// CSS `border: … dashed` 모양(둥근 상자 테두리, 가로·세로 선). 점선 길이는 브라우저 기본(굵기의 약 3배)에 맞춘다.
import 'package:flutter/widgets.dart';

class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.color, required this.child, this.radius = 0, this.width = 1, this.padding});

  final Color color;
  final double radius;
  final double width;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: DashedRRectPainter(color: color, radius: radius, width: width),
    child: padding == null ? child : Padding(padding: padding!, child: child),
  );
}

class DashedRRectPainter extends CustomPainter {
  const DashedRRectPainter({required this.color, this.radius = 0, this.width = 1});

  final Color color;
  final double radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(width / 2), Radius.circular(radius)));
    _dash(canvas, path, color, width);
  }

  @override
  bool shouldRepaint(DashedRRectPainter oldDelegate) => color != oldDelegate.color || radius != oldDelegate.radius || width != oldDelegate.width;
}

/// 가로(또는 세로) 점선 한 줄.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, required this.color, this.width = 1, this.vertical = false, this.length});

  final Color color;
  final double width;
  final bool vertical;
  final double? length;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: vertical ? width : length ?? double.infinity,
    height: vertical ? length ?? double.infinity : width,
    child: CustomPaint(
      painter: _DashedLinePainter(color: color, width: width, vertical: vertical),
    ),
  );
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color, required this.width, required this.vertical});

  final Color color;
  final double width;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (vertical) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width / 2, size.height);
    } else {
      path
        ..moveTo(0, size.height / 2)
        ..lineTo(size.width, size.height / 2);
    }
    _dash(canvas, path, color, width);
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => color != oldDelegate.color || width != oldDelegate.width || vertical != oldDelegate.vertical;
}

void _dash(Canvas canvas, Path path, Color color, double width) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;
  final dash = width * 3;
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
      distance += dash * 2;
    }
  }
}
