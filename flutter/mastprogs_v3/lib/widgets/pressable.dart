// 버튼·링크 공용 바탕: 키보드 포커스 표시(:focus-visible), 가리킴·누름 상태, Enter/Space 실행, 접근성 이름.
// AI-NOTE: 원본 CSS 규칙 `:focus-visible { outline: 2px solid var(--orange); outline-offset: 3px }` 을 그대로 옮긴다.
// 포커스 테두리는 키보드로 이동할 때만 보인다(마우스 클릭 때는 숨김). 밝은 판 안에서는 FocusRingColor 로 테두리 색을 바꾼다.
// ariaDisabled: 원본의 aria-disabled 처럼 포커스는 남기고(경계에서 포커스가 사라지지 않게) 실행만 막는다.
// enabled=false 는 원본 disabled 처럼 포커스도 받지 않는다.
// AI-NOTE: 링크는 원본 <a href> 처럼 실제 목적지(linkUrl)를 접근성 노드에 싣는다(웹 엔진이 <a href> 로 그림). 이동 자체는 그대로
// onPressed(라우터·새 탭)가 한 번만 하고, 브라우저 기본 이동은 platform_web 의 클릭 가드가 막는다.
// radio=true 는 원본 role="radio"(aria-checked, 상호 배타 묶음), 아니면 checked/toggled 는 role="switch" 로 나간다.
// 보조 설명(tooltip)은 보기 전용(HintTooltip)이라 접근성 이름에 겹쳐 붙지 않는다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/palette.dart';
import 'hint_tooltip.dart';

class PressState {
  const PressState({required this.hovered, required this.pressed, required this.focused, required this.disabled});

  final bool hovered;
  final bool pressed;

  /// 키보드 포커스 표시 중(:focus-visible).
  final bool focused;
  final bool disabled;
}

/// 하위 Pressable 의 포커스 테두리 색(밝은 판 안에서는 stage 잉크 등).
class FocusRingColor extends InheritedWidget {
  const FocusRingColor({super.key, required this.color, required super.child});

  final Color color;

  static Color? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<FocusRingColor>()?.color;

  @override
  bool updateShouldNotify(FocusRingColor oldWidget) => color != oldWidget.color;
}

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.builder,
    this.onPressed,
    this.enabled = true,
    this.ariaDisabled = false,
    this.semanticLabel,
    this.tooltip,
    this.isLink = false,
    this.linkUrl,
    this.toggled,
    this.selected,
    this.checked,
    this.radio = false,
    this.plain = false,
    this.semanticValue,
    this.focusNode,
    this.autofocus = false,
    this.radius = const BorderRadius.all(Radius.circular(999)),
    this.focusOffset = 3,
    this.focusColor,
    this.focusWidth = 2,
    this.excludeChildSemantics = false,
    this.onFocusChange,
  });

  final Widget Function(BuildContext context, PressState state) builder;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool ariaDisabled;
  final String? semanticLabel;
  final String? tooltip;
  final bool isLink;

  /// 링크의 실제 목적지(href). 같은 출처 해시 경로('/#/workflow'), 앵커('/#/?anchor=about'), 허용된 외부 주소만 넘긴다.
  final Uri? linkUrl;

  /// aria-pressed.
  final bool? toggled;

  /// aria-current·aria-selected.
  final bool? selected;

  /// role=switch/radio 의 aria-checked.
  final bool? checked;

  /// role=radio(상호 배타 묶음 안의 하나). checked 를 radio 의 선택 상태로 쓴다.
  final bool radio;

  /// 역할 없는 포커스 칸(원본 tabIndex=0 인 <pre> 등). 버튼·링크로 알리지 않는다.
  final bool plain;

  /// 접근성 값(읽기 전용 내용). plain 칸의 글 내용처럼 이름과 따로 읽힐 때.
  final String? semanticValue;
  final FocusNode? focusNode;
  final bool autofocus;
  final BorderRadius radius;
  final double focusOffset;
  final Color? focusColor;
  final double focusWidth;
  final bool excludeChildSemantics;
  final ValueChanged<bool>? onFocusChange;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focusVisible = false;

  bool get _actionable => widget.enabled && !widget.ariaDisabled && widget.onPressed != null;

  void _activate() {
    if (_actionable) widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ringColor = widget.focusColor ?? FocusRingColor.of(context) ?? palette.orange;
    final state = PressState(hovered: _hovered, pressed: _pressed, focused: _focusVisible, disabled: !widget.enabled || widget.ariaDisabled);
    Widget child = widget.builder(context, state);
    // 접근성 노드는 조작 하나에 하나: 아래 Semantics(container) 가 이름·역할·tap 을 갖고, Focus 의 focusable/focused 가 거기에 합쳐진다.
    // GestureDetector 의 tap 은 위 onTap 과 겹쳐(같은 동작) 이름 없는 tap 노드가 따로 생기므로 접근성에서 뺀다.
    // excludeChildSemantics 는 보이는 글자·아이콘만 빼고 포커스 정보는 남기도록 FocusableActionDetector 안쪽에서 자른다.
    if (widget.excludeChildSemantics) child = ExcludeSemantics(child: child);
    child = CustomPaint(
      foregroundPainter: _focusVisible
          ? _FocusRingPainter(color: ringColor, radius: widget.radius, offset: widget.focusOffset, width: widget.focusWidth)
          : null,
      child: child,
    );
    child = FocusableActionDetector(
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: !widget.enabled || widget.ariaDisabled || widget.onPressed == null
          ? (widget.ariaDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.basic)
          : SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _activate())},
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focusVisible = value),
      onFocusChange: widget.onFocusChange,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: _actionable ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _actionable ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _actionable ? () => setState(() => _pressed = false) : null,
        onTap: _actionable ? _activate : null,
        child: child,
      ),
    );
    child = Semantics(
      container: true,
      button: !widget.isLink && !widget.radio && !widget.plain,
      link: widget.isLink,
      linkUrl: widget.isLink ? widget.linkUrl : null,
      enabled: widget.plain ? null : widget.enabled && !widget.ariaDisabled,
      label: widget.semanticLabel,
      value: widget.semanticValue,
      checked: widget.radio ? (widget.checked ?? false) : null,
      inMutuallyExclusiveGroup: widget.radio ? true : null,
      toggled: widget.radio ? null : (widget.checked ?? widget.toggled),
      selected: widget.selected,
      onTap: _actionable ? _activate : null,
      child: child,
    );
    final tooltip = widget.tooltip;
    if (tooltip != null) {
      child = HintTooltip(message: tooltip, waitDuration: const Duration(milliseconds: 600), child: child);
    }
    return child;
  }
}

class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({required this.color, required this.radius, required this.offset, required this.width});

  final Color color;
  final BorderRadius radius;
  final double offset;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    // outline-offset 만큼 바깥으로, 모서리 반지름도 같은 만큼 커진다(브라우저 outline 과 같은 모양).
    final rrect = radius.resolve(TextDirection.ltr).toRRect(Offset.zero & size).inflate(offset + width / 2);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius || offset != oldDelegate.offset || width != oldDelegate.width;
}
