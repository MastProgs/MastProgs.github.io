// 섹션 등장(한 번만) 애니메이션(React useRevealOnce + CSS [data-reveal] 이식).
// AI-NOTE: 콘텐츠는 기본으로 보이는 상태다. 등장 효과가 켜져 있고(?state=target 이 아님) 동작 줄이기가 아닐 때만 처음 그릴 때 숨겼다가
// 화면 아래 8% 안쪽으로 들어오면 한 번 나타난다(되돌아가지 않음). 섹션 전체(fade+18px)와 항목 순차(경력 60ms·사례 80ms 간격) 두 가지다.
import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/layout.dart';

/// 섹션 하나의 등장 신호. child 안의 [StaggerReveal] 들이 같은 신호를 따른다.
class RevealOnce extends StatefulWidget {
  const RevealOnce({super.key, required this.enabled, required this.child, this.animateSelf = true});

  final bool enabled;
  final Widget child;

  /// false 면 섹션 자체는 그대로 보이고 안쪽 항목만 순차로 나타난다(경력·학력·사례 레일).
  final bool animateSelf;

  @override
  State<RevealOnce> createState() => _RevealOnceState();
}

class _RevealOnceState extends State<RevealOnce> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ValueNotifier<bool> _shown = ValueNotifier(false);
  ScrollPosition? _position;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Motion.slow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = widget.enabled && !ReducedMotion.of(context);
    if (!active) {
      _active = false;
      _detach();
      _controller.value = 1;
      _shown.value = true;
      return;
    }
    if (_shown.value) return;
    _active = true;
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _detach();
      _position = position;
      _position?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _detach() {
    _position?.removeListener(_check);
    _position = null;
  }

  void _check() {
    if (!mounted || !_active || _shown.value) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final viewport = MediaQuery.sizeOf(context).height;
    // rootMargin: 0 0 -8% 0, threshold 0 → 위쪽 끝이 화면 아래 92% 선 위로 올라오면.
    if (top < viewport * 0.92 && top + box.size.height > 0) {
      _shown.value = true;
      _controller.forward();
      _detach();
    }
  }

  @override
  void dispose() {
    _detach();
    _controller.dispose();
    _shown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = _RevealSignal(notifier: _shown, child: widget.child);
    if (!widget.animateSelf) return child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Motion.easeOut.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child),
        );
      },
      child: child,
    );
  }
}

class _RevealSignal extends InheritedNotifier<ValueNotifier<bool>> {
  const _RevealSignal({required ValueNotifier<bool> super.notifier, required super.child});
}

enum StaggerStyle {
  /// opacity 0 → 1, translateY(16px) → 0.
  rise,

  /// 사례 카드: perspective(1200px) rotateX(8deg) translateY(28px) → 원래.
  tilt,
}

/// 항목 순차 등장. 바깥 [RevealOnce] 의 신호를 받아 index × delay 뒤에 한 번 재생한다.
class StaggerReveal extends StatefulWidget {
  const StaggerReveal({super.key, required this.index, required this.child, this.delay = Duration.zero, this.style = StaggerStyle.rise});

  final int index;
  final Duration delay;
  final StaggerStyle style;
  final Widget child;

  @override
  State<StaggerReveal> createState() => _StaggerRevealState();
}

class _StaggerRevealState extends State<StaggerReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ValueNotifier<bool>? _signal;
  Timer? _delay;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Motion.slow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final signal = context.dependOnInheritedWidgetOfExactType<_RevealSignal>()?.notifier;
    if (signal != _signal) {
      _signal?.removeListener(_onSignal);
      _signal = signal;
      _signal?.addListener(_onSignal);
    }
    if (ReducedMotion.of(context) || signal == null) {
      _controller.value = 1;
      _started = true;
      return;
    }
    if (signal.value && !_started) {
      // 처음부터 보이는 상태(등장 효과 꺼짐)면 즉시 끝 상태.
      _controller.value = 1;
      _started = true;
    }
  }

  void _onSignal() {
    if (_started || !(_signal?.value ?? false)) return;
    _started = true;
    _delay = Timer(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _signal?.removeListener(_onSignal);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Motion.easeOut.transform(_controller.value);
        if (widget.style == StaggerStyle.rise) {
          return Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
          );
        }
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 1 / 1200)
          ..rotateX(8 * (1 - t) * 3.141592653589793 / 180)
          ..translateByDouble(0, 28 * (1 - t), 0, 1);
        return Opacity(
          opacity: t,
          child: Transform(alignment: Alignment.center, transform: matrix, child: child),
        );
      },
      child: widget.child,
    );
  }
}
