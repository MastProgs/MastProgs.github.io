// /sprite 작업 화면 공용 조작 요소(원본 .pixel-btn · .pixel-seg · .pixel-swatch · .pixel-range 모양). 모두 44px 이상.
import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/pressable.dart';

/// .pixel-btn: 둥근 테두리 버튼(아이콘 또는 아이콘+글자). chip 이고 pressed 면 주황 테두리·글자.
class PixelButton extends StatelessWidget {
  const PixelButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.label,
    this.semanticLabel,
    this.tooltip,
    this.pressed,
    this.ariaDisabled = false,
    this.primary = false,
    this.current = false,
  });

  final VoidCallback onPressed;
  final IconData? icon;
  final String? label;
  final String? semanticLabel;
  final String? tooltip;

  /// aria-pressed(칩).
  final bool? pressed;
  final bool ariaDisabled;

  /// .pixel-btn--primary: 48px 주황 원.
  final bool primary;

  /// .is-current(자동 색 칩).
  final bool current;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final on = pressed ?? false;
    return Pressable(
      onPressed: onPressed,
      ariaDisabled: ariaDisabled,
      toggled: pressed,
      semanticLabel: semanticLabel ?? label,
      tooltip: tooltip,
      excludeChildSemantics: true,
      builder: (context, state) {
        final hover = state.hovered && !ariaDisabled;
        final Color bg = primary ? (hover ? palette.orangeDeep : palette.orange) : (hover ? palette.hoverWash : Colors.transparent);
        final Color border = primary ? Colors.transparent : (on ? palette.orange : palette.line2);
        final Color fg = primary ? palette.orangeInk : (on ? palette.orangeText : palette.ink);
        return AnimatedOpacity(
          duration: motionDuration(context, Motion.fast),
          opacity: ariaDisabled ? 0.4 : 1,
          child: AnimatedScale(
            duration: motionDuration(context, Motion.fast),
            scale: state.pressed && !ariaDisabled ? 0.95 : 1,
            child: AnimatedContainer(
              duration: motionDuration(context, Motion.fast),
              constraints: BoxConstraints(minWidth: primary ? 48 : 44, minHeight: primary ? 48 : 44),
              padding: EdgeInsets.symmetric(horizontal: primary || label == null ? 0 : 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) Icon(icon, size: primary ? 20 : 18, color: fg),
                  if (icon != null && label != null) const SizedBox(width: 6),
                  if (label != null)
                    Flexible(
                      child: KText(
                        label!,
                        style: textStyle(size: 14, weight: FontWeight.w600, color: current && !on ? palette.ink : fg),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// .pixel-seg: 모션 선택 묶음(현재 항목은 반전색).
class PixelSegment extends StatelessWidget {
  const PixelSegment({super.key, required this.items, required this.current, required this.onSelect});

  final List<(String id, String label)> items;
  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line2),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final (id, label) in items)
            Pressable(
              onPressed: () => onSelect(id),
              toggled: id == current,
              semanticLabel: label,
              excludeChildSemantics: true,
              radius: BorderRadius.circular(9),
              builder: (context, state) => AnimatedContainer(
                duration: motionDuration(context, Motion.med),
                constraints: const BoxConstraints(minWidth: 72, minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: id == current ? palette.ink : Colors.transparent, borderRadius: BorderRadius.circular(9)),
                // 글자 너비로 줄어들되(widthFactor 1) 최소 72×44 안에서 가운데.
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    style: textStyle(size: 14, weight: id == current ? FontWeight.w700 : FontWeight.w400, color: id == current ? palette.bg : palette.ink2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// .pixel-swatch: 색 칩 + 이름 알약. leading 은 22px 칩 또는 28px 색 입력 칸.
class PixelSwatch extends StatelessWidget {
  const PixelSwatch({super.key, required this.label, required this.leading, required this.onPressed, required this.current, this.pressed});

  final String label;
  final Widget leading;
  final VoidCallback onPressed;
  final bool current;
  final bool? pressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onPressed: onPressed,
      toggled: pressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      builder: (context, state) => AnimatedContainer(
        duration: motionDuration(context, Motion.fast),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
        decoration: BoxDecoration(
          color: state.hovered ? palette.hoverWash : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: current ? palette.orange : palette.line2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 8),
            Flexible(
              child: KText(
                label,
                style: textStyle(size: 13.5, weight: current ? FontWeight.w600 : FontWeight.w400, color: current ? palette.ink : palette.ink2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 프리셋 색 칩(22px). 원본 프리셋은 바꾸지 않음을 뜻하는 대각선.
class PresetChip extends StatelessWidget {
  const PresetChip({super.key, required this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.line3),
      ),
      child: color == null ? CustomPaint(painter: _DiagonalPainter(palette.ink3)) : null,
    );
  }
}

class _DiagonalPainter extends CustomPainter {
  const _DiagonalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // linear-gradient(135deg, transparent 45%, ink3 45% 55%, transparent 55%)
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.1 * 1.41;
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(5)));
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_DiagonalPainter oldDelegate) => color != oldDelegate.color;
}

/// 색 입력 칸(28px, 현재 색).
class ColorWell extends StatelessWidget {
  const ColorWell({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: context.palette.line3),
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    ),
  );
}

/// .pixel-range: 주황 강조색의 범위 입력(높이 44).
class PixelRange extends StatelessWidget {
  const PixelRange({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.enabled = true,
    this.label,
    this.valueText,
    this.valueTextOf,
  });

  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final String? label;
  final String? valueText;
  final String Function(double value)? valueTextOf;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return RangeInput(
      value: value,
      min: min,
      max: max,
      step: step,
      enabled: enabled,
      label: label,
      valueText: valueText,
      valueTextOf: valueTextOf,
      onChanged: onChanged,
      trackHeight: 6,
      thumbSize: 16,
      fillColor: palette.orange,
      trackColor: palette.line3,
      thumbColor: palette.orange,
    );
  }
}

/// 색 문자열(#rrggbb) → Color.
Color hexColor(String hex) => Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

/// 라벨(.pixel-controls__label)과 힌트(.pixel-controls__hint) 글자 모양.
TextStyle pixelLabelStyle(AppPalette palette) => textStyle(size: 12.5, weight: FontWeight.w600, color: palette.ink3);

TextStyle pixelHintStyle(AppPalette palette) => textStyle(size: 12.5, color: palette.ink3, height: 1.5);

/// 체크무늬 바탕(투명 영역 표시).
class CheckerBackground extends StatelessWidget {
  const CheckerBackground({super.key, required this.cell, required this.radius, required this.child});

  final double cell;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _CheckerPainter(cell: cell, light: palette.surface2, dark: palette.surface3),
        child: child,
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter({required this.cell, required this.light, required this.dark});

  final double cell;
  final Color light;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = dark);
    // 원본: 45° 삼각형 두 겹으로 만든 체크무늬(한 칸 = cell/2 정사각형 두 개). 같은 모양의 정사각 체크무늬로 그린다.
    final half = cell / 2;
    final paint = Paint()..color = light;
    for (var y = 0.0; y < size.height; y += half) {
      for (var x = 0.0; x < size.width; x += half) {
        if (((x / half).round() + (y / half).round()).isEven) canvas.drawRect(Rect.fromLTWH(x, y, half, half), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter oldDelegate) => cell != oldDelegate.cell || light != oldDelegate.light || dark != oldDelegate.dark;
}
