// 공용 조작 요소(원본 CSS 의 .btn·.theme-toggle·둥근 아이콘 버튼·.tag·스위치·범위 입력 모양).
// AI-NOTE: 누를 곳은 모두 44px 이상이다. 모든 전환은 동작 줄이기 설정에서 즉시 처리된다(motionDuration).
// 아이콘은 Phosphor(phosphor_flutter) 정적 IconData 만 쓴다(장식 SVG·이모지 없음).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../app/layout.dart';
import '../app/theme/palette.dart';
import '../app/theme/typography.dart';
import 'k_text.dart';
import 'pressable.dart';

enum PillTone {
  /// .btn--primary: 주황 바탕 + 주황 잉크.
  primary,

  /// .btn--dark: 밝은 판 위 어두운 버튼(두 테마 모두 같은 대비).
  dark,

  /// .case-detail__link: 주황 바탕, 높이 44.
  primarySmall,
}

/// .btn 계열 알약 버튼(아이콘은 글자 뒤).
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconSize = 18,
    this.tone = PillTone.primary,
    this.semanticLabel,
    this.isLink = true,
    this.linkUrl,
    this.expand = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double iconSize;
  final PillTone tone;
  final String? semanticLabel;
  final bool isLink;

  /// 링크 목적지(href). onPressed 가 실제로 여는 주소와 같은 값.
  final Uri? linkUrl;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final small = tone == PillTone.primarySmall;
    return Pressable(
      onPressed: onPressed,
      isLink: isLink,
      linkUrl: linkUrl,
      semanticLabel: semanticLabel ?? label,
      excludeChildSemantics: true,
      builder: (context, state) {
        final Color bg;
        final Color fg;
        switch (tone) {
          case PillTone.primary:
            bg = state.hovered ? AppPalette.primaryHover : palette.orange;
            fg = palette.orangeInk;
          case PillTone.primarySmall:
            bg = state.hovered ? palette.orangeDeep : palette.orange;
            fg = palette.orangeInk;
          case PillTone.dark:
            bg = state.hovered ? AppPalette.darkButtonHover : palette.stageInk;
            fg = AppPalette.white;
        }
        return AnimatedContainer(
          duration: motionDuration(context, Motion.fast),
          curve: Motion.easeOut,
          transform: Matrix4.translationValues(0, state.pressed && !small ? 1 : 0, 0),
          constraints: BoxConstraints(minHeight: small ? 44 : 48),
          padding: EdgeInsets.symmetric(horizontal: small ? 18 : 24),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: KText(
                  label,
                  style: textStyle(size: small ? 16 : 17, weight: FontWeight.w700, color: fg, em: small ? 0 : -0.02, height: 1.2),
                ),
              ),
              if (icon != null) ...[SizedBox(width: small ? 8 : 8), Icon(icon, size: iconSize, color: fg)],
            ],
          ),
        );
      },
    );
  }
}

/// 테두리만 있는 둥근 아이콘 버튼(44px, .rail-controls__btn·.modal__close·메뉴 버튼).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.ariaDisabled = false,
    this.size = 44,
    this.iconSize = 20,
    this.background,
    this.hoverBackground,
    this.borderColor,
    this.iconColor,
    this.tooltip = true,
    this.focusNode,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool ariaDisabled;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? hoverBackground;
  final Color? borderColor;
  final Color? iconColor;
  final bool tooltip;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onPressed: onPressed,
      ariaDisabled: ariaDisabled,
      semanticLabel: label,
      tooltip: tooltip ? label : null,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, state) {
        final hover = state.hovered && !ariaDisabled;
        return AnimatedOpacity(
          duration: motionDuration(context, Motion.fast),
          opacity: ariaDisabled ? 0.35 : 1,
          child: AnimatedScale(
            duration: motionDuration(context, Motion.fast),
            scale: state.pressed ? 0.94 : 1,
            child: AnimatedContainer(
              duration: motionDuration(context, Motion.fast),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hover ? (hoverBackground ?? palette.hoverWash) : (background ?? Colors.transparent),
                border: Border.all(color: hover ? palette.line4 : (borderColor ?? palette.line2)),
              ),
              child: Icon(icon, size: iconSize, color: iconColor ?? palette.ink),
            ),
          ),
        );
      },
    );
  }
}

/// .tag: 작은 테두리 알약.
class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key, this.lineHeight});

  final String label;
  final double? lineHeight;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: KText(
        label,
        style: textStyle(size: 12.5, color: palette.inkSoft, height: lineHeight != null ? lineHeight! / 12.5 : 1.5),
      ),
    );
  }
}

/// 스위치 모양(.wfd-switch 48×28, .pixel-switch 44×26). 글자를 누르거나 Enter/Space 로도 바뀐다.
class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.enabled = true,
    this.large = false,
    this.labelStyle,
    this.disabledOpacity = 0.45,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  /// true = .wfd-switch(48×28, 손잡이 19), false = .pixel-switch(44×26, 손잡이 17).
  final bool large;
  final TextStyle? labelStyle;
  final double disabledOpacity;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final width = large ? 48.0 : 44.0;
    final height = large ? 28.0 : 26.0;
    final knob = large ? 19.0 : 17.0;
    final travel = large ? 20.0 : 18.0;
    return Opacity(
      opacity: enabled ? 1 : disabledOpacity,
      child: Pressable(
        onPressed: enabled ? () => onChanged(!value) : null,
        enabled: enabled,
        checked: value,
        semanticLabel: label,
        excludeChildSemantics: true,
        radius: BorderRadius.circular(12),
        builder: (context, state) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!large) const SizedBox(width: 4),
              AnimatedContainer(
                duration: motionDuration(context, Motion.fast),
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: value ? palette.orange : palette.tile,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: value ? palette.orange : palette.line4, width: 1.5),
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: motionDuration(context, Motion.fast),
                      curve: Motion.easeOut,
                      top: 3 - 1.5,
                      left: (value ? 3 + travel : 3) - 1.5,
                      child: Container(
                        width: knob,
                        height: knob,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: value ? palette.orangeInk : palette.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: KText(
                  label,
                  style: labelStyle ?? textStyle(size: 14, weight: FontWeight.w600, color: palette.ink),
                ),
              ),
              if (!large) const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// 정수 범위 입력(가로 슬라이더). 높이 44 의 누를 영역 안에 얇은 트랙, 지나온 구간 채움, 둥근 손잡이.
/// 키보드: 왼쪽/아래 −step, 오른쪽/위 +step, PageUp/PageDown ±10%, Home/End 처음·끝(브라우저 기본 range 와 같음).
class RangeInput extends StatefulWidget {
  const RangeInput({
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
    this.trackHeight = 6,
    this.thumbSize = 18,
    this.fillColor,
    this.trackColor,
    this.thumbColor,
  });

  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final String? label;
  final String? valueText;

  /// 임의 값의 읽는 글(이웃 값 increasedValue·decreasedValue 를 지금 값과 같은 형식으로 알릴 때). 없으면 숫자.
  final String Function(double value)? valueTextOf;
  final double trackHeight;
  final double thumbSize;
  final Color? fillColor;
  final Color? trackColor;
  final Color? thumbColor;

  @override
  State<RangeInput> createState() => _RangeInputState();
}

class _RangeInputState extends State<RangeInput> {
  bool _focusVisible = false;

  double _snap(double raw) {
    final clamped = raw.clamp(widget.min, widget.max).toDouble();
    final steps = ((clamped - widget.min) / widget.step).round();
    return math.min(widget.max, widget.min + steps * widget.step);
  }

  void _emit(double raw) {
    final next = _snap(raw);
    if (next != widget.value) widget.onChanged(next);
  }

  final GlobalKey _trackKey = GlobalKey();

  void _fromPosition(Offset local) {
    final width = (_trackKey.currentContext?.findRenderObject() as RenderBox?)?.size.width ?? 0;
    final usable = math.max(1.0, width - widget.thumbSize);
    final ratio = ((local.dx - widget.thumbSize / 2) / usable).clamp(0.0, 1.0);
    _emit(widget.min + ratio * (widget.max - widget.min));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final range = widget.max - widget.min;
    final ratio = range <= 0 ? 0.0 : ((widget.value - widget.min) / range).clamp(0.0, 1.0);
    final big = math.max(widget.step, range / 10);
    final control = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (details) => _fromPosition(details.localPosition) : null,
      onHorizontalDragStart: widget.enabled ? (details) => _fromPosition(details.localPosition) : null,
      onHorizontalDragUpdate: widget.enabled ? (details) => _fromPosition(details.localPosition) : null,
      child: SizedBox(
        key: _trackKey,
        height: 44,
        width: double.infinity,
        child: CustomPaint(
          painter: _RangePainter(
            ratio: ratio,
            trackHeight: widget.trackHeight,
            thumbSize: widget.thumbSize,
            fill: widget.fillColor ?? palette.orange,
            track: widget.trackColor ?? palette.line2,
            thumb: widget.thumbColor ?? palette.inkMax,
            focus: _focusVisible ? palette.orange : null,
          ),
        ),
      ),
    );
    // AI-NOTE: 웹 엔진(SemanticIncrementable)은 aria-valuenow/min/max 를 1 근처의 대리 숫자로 두고, 지금 값은 aria-valuetext(=value)로만
    // 내보낸다. increasedValue/decreasedValue 는 "더 갈 수 있는지"(비면 끝)와 변경 감지에 쓰이므로, 지금 값과 같은 형식의 이웃 값을 주고
    // 범위 끝에서는 빈 문자열로 둔다(예전 round() 숫자는 0.35±0.05 가 모두 '0', 끝에서도 늘 이동 가능으로 보였다).
    // 엔진 한계(설치 SDK 소스): 포인터 이벤트 뒤 500ms 동안(pointerEvents 모드) 바뀐 값은 aria-valuetext 에 쓰이지 않고, 모드가 돌아와도
    // 변경 표시가 없어 다시 쓰지 않는다. 또 이름(aria-label)은 바깥 flt-semantics 에 붙고 <input> 자체에는 붙지 않는다. 앱 코드로는 고칠 수 없다.
    String textOf(double v) => widget.valueTextOf?.call(v) ?? '${v.round()}';
    final up = _snap(widget.value + widget.step);
    final down = _snap(widget.value - widget.step);
    return Opacity(
      opacity: widget.enabled ? 1 : 0.5,
      // 자기 노드(container): 감싸는 이름 붙은 패널에 합쳐지면 웹 입력이 패널 전체 크기·이름 없음·지난 값으로 남는다.
      child: Semantics(
        container: true,
        slider: true,
        label: widget.label,
        value: widget.valueText ?? textOf(widget.value),
        enabled: widget.enabled,
        // 끝에서는 그 방향 동작 자체를 빼야 한다(프레임워크 규칙: increase 동작이 있으면 increasedValue 가 비면 안 됨, semantics.dart 3739).
        increasedValue: up > widget.value ? textOf(up) : null,
        decreasedValue: down < widget.value ? textOf(down) : null,
        onIncrease: widget.enabled && up > widget.value ? () => _emit(widget.value + widget.step) : null,
        onDecrease: widget.enabled && down < widget.value ? () => _emit(widget.value - widget.step) : null,
        child: FocusableActionDetector(
          enabled: widget.enabled,
          mouseCursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onShowFocusHighlight: (value) => setState(() => _focusVisible = value),
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.arrowRight): _RangeIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowUp): _RangeIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowLeft): _RangeIntent(-1),
            SingleActivator(LogicalKeyboardKey.arrowDown): _RangeIntent(-1),
            SingleActivator(LogicalKeyboardKey.pageUp): _RangeIntent(10),
            SingleActivator(LogicalKeyboardKey.pageDown): _RangeIntent(-10),
            SingleActivator(LogicalKeyboardKey.home): _RangeIntent.home(),
            SingleActivator(LogicalKeyboardKey.end): _RangeIntent.end(),
          },
          actions: {
            _RangeIntent: CallbackAction<_RangeIntent>(
              onInvoke: (intent) {
                if (intent.edge == -1) {
                  _emit(widget.min);
                } else if (intent.edge == 1) {
                  _emit(widget.max);
                } else if (intent.delta.abs() == 10) {
                  _emit(widget.value + big * intent.delta.sign);
                } else {
                  _emit(widget.value + widget.step * intent.delta);
                }
                return null;
              },
            ),
          },
          child: ExcludeSemantics(child: control),
        ),
      ),
    );
  }
}

class _RangeIntent extends Intent {
  const _RangeIntent(this.delta) : edge = 0;
  const _RangeIntent.home() : delta = 0, edge = -1;
  const _RangeIntent.end() : delta = 0, edge = 1;

  final int delta;
  final int edge;
}

class _RangePainter extends CustomPainter {
  const _RangePainter({
    required this.ratio,
    required this.trackHeight,
    required this.thumbSize,
    required this.fill,
    required this.track,
    required this.thumb,
    required this.focus,
  });

  final double ratio;
  final double trackHeight;
  final double thumbSize;
  final Color fill;
  final Color track;
  final Color thumb;
  final Color? focus;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final r = Radius.circular(trackHeight / 2);
    final trackRect = Rect.fromLTWH(0, cy - trackHeight / 2, size.width, trackHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(trackRect, r), Paint()..color = track);
    final usable = size.width - thumbSize;
    final cx = thumbSize / 2 + usable * ratio;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(0, trackRect.top, cx, trackRect.bottom), r), Paint()..color = fill);
    canvas.drawCircle(Offset(cx, cy), thumbSize / 2, Paint()..color = thumb);
    if (focus != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-2, cy - 12, size.width + 4, 24), const Radius.circular(999)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = focus!,
      );
    }
  }

  @override
  bool shouldRepaint(_RangePainter oldDelegate) =>
      ratio != oldDelegate.ratio ||
      fill != oldDelegate.fill ||
      track != oldDelegate.track ||
      thumb != oldDelegate.thumb ||
      focus != oldDelegate.focus ||
      thumbSize != oldDelegate.thumbSize;
}

/// CSS grid repeat(n, minmax(0, 1fr)): 같은 너비 열, 행마다 높이를 맞춘다(align-items: stretch).
class EqualColumns extends StatelessWidget {
  const EqualColumns({super.key, required this.columns, required this.children, this.gap = 0, this.runGap, this.stretch = true});

  final int columns;
  final List<Widget> children;
  final double gap;
  final double? runGap;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[if (i > 0) SizedBox(height: runGap ?? gap), child],
        ],
      );
    }
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final cells = <Widget>[];
      for (var c = 0; c < columns; c += 1) {
        if (c > 0) cells.add(SizedBox(width: gap));
        final index = start + c;
        cells.add(Expanded(child: index < children.length ? children[index] : const SizedBox.shrink()));
      }
      final row = Row(crossAxisAlignment: stretch ? CrossAxisAlignment.stretch : CrossAxisAlignment.start, children: cells);
      if (rows.isNotEmpty) rows.add(SizedBox(height: runGap ?? gap));
      rows.add(stretch ? IntrinsicHeight(child: row) : row);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

/// 화면에는 보이지 않고 보조 기기에만 읽히는 글(.sr-only, aria-live 포함).
class ScreenReaderOnly extends StatelessWidget {
  const ScreenReaderOnly(this.text, {super.key, this.liveRegion = false});

  final String text;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) => Semantics(liveRegion: liveRegion, label: text, child: const SizedBox.shrink());
}
