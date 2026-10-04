// 프레임 강조(방금 바뀐 노드) 공용: frame id → 위치 키, 강조 테두리.
// AI-NOTE: 원본 data-frame-id 와 같은 id 규칙(msg:<eventId> · spec · task:<…> · master · lane:<laneId> · stage:<laneId>:<stage> ·
// integration:<stage> · gate · direct:<step>)으로 노드를 찾는다(문구 검색 금지). 강조는 다음 단계 표시(is-active)와 구분되는
// 주황 2px 테두리(바깥 2px)이며 위치 이동만 하므로 반복 동작이 없다.
import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../model/workflow_frames.dart';

class FrameKeys {
  final Map<String, GlobalKey> _keys = {};

  GlobalKey keyFor(String id) => _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'frame-$id'));

  BuildContext? contextOf(String id) => _keys[id]?.currentContext;
}

class FrameScope extends InheritedWidget {
  const FrameScope({super.key, required this.targets, required this.keys, required super.child});

  final FrameTargets targets;
  final FrameKeys keys;

  static FrameScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<FrameScope>()!;

  @override
  bool updateShouldNotify(FrameScope oldWidget) => targets != oldWidget.targets || keys != oldWidget.keys;
}

/// frame id 를 가진 노드. 이번 프레임에 바뀌었으면 주황 테두리를 그린다.
class FrameNode extends StatelessWidget {
  const FrameNode({super.key, required this.id, required this.child, this.radius = 0});

  final String id;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = FrameScope.of(context);
    final on = scope.targets.has(id);
    final palette = context.palette;
    return KeyedSubtree(
      key: scope.keys.keyFor(id),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: on ? 1 : 0),
        duration: motionDuration(context, Motion.med),
        curve: Motion.easeOut,
        builder: (context, t, child) => CustomPaint(
          foregroundPainter: t == 0
              ? null
              : _FramePainter(
                  color: palette.orange.withValues(alpha: t),
                  radius: radius,
                ),
          child: child,
        ),
        child: child,
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    // outline: 2px, outline-offset: 2px.
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).inflate(3);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => color != oldDelegate.color || radius != oldDelegate.radius;
}
