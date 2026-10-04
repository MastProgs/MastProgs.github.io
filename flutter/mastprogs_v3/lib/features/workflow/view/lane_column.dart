// 레인 하나(React LaneColumn.jsx + SeedLineage.jsx 이식).
// AI-NOTE: lane:<id> 는 Seed 준비 프레임, stage:<id>:<단계> 는 단계 행 프레임 id 다. is-frame(방금 실행된 단계)과 is-active(다음에 실행될 단계)는
// 서로 다른 표시다. 되돌림 연결선은 행마다 그리는 세로 점선 조각(시작·중간·끝)이라 행 높이가 줄바꿈으로 달라져도 끊기지 않으며,
// 반려가 해결(재검수 승인·QA 통과)될 때까지 남는다. 되돌림 이동 표식은 새 반려 이벤트에서만 오른쪽 → 왼쪽으로 한 번 미끄러지고(무한 반복 없음),
// 되돌아갈 단계 행은 같은 시점에 한 번 강조된다. 동작 줄이기에서는 표식이 도착 위치에 정지해 있다. 진행 중 아이콘은 회전시키지 않는다.
// Seed 계보: 읽기 전용 Seed 아래로 Planning/Development sibling 두 개가 갈라진다. 재작업은 같은 child 를 resume 하므로 Seed 는 다시 나타나지 않는다.
// QA·Wiki 는 계보 밖 독립 세션이다(QA 재시도는 같은 레인 QA 세션 resume). 속도·캐시·비용 수치는 만들지 않는다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../widgets/dashed.dart';
import '../../../widgets/k_text.dart';
import '../model/workflow_content.dart';
import '../model/workflow_scenario.dart';
import 'frame_scope.dart';
import 'workflow_panels.dart';

const Map<String, String> laneStatusText = {
  'queued': '배정 대기',
  'seeding': 'Seed 준비 중',
  'running': '진행 중',
  'returned': '되돌림 수정 중',
  'ready': 'READY · 다른 레인 대기',
  'merged': '병합됨',
  'done': 'QA 통과 · 완료',
};

const Map<String, IconData> _laneStatusIcon = {
  'queued': PhosphorIconsBold.circleDashed,
  'seeding': PhosphorIconsBold.eye,
  'running': PhosphorIconsBold.circleNotch,
  'returned': PhosphorIconsBold.warning,
  'ready': PhosphorIconsBold.hourglass,
  'merged': PhosphorIconsBold.gitMerge,
  'done': PhosphorIconsBold.checkCircle,
};

bool _isVerdictStage(String id) => id == 'plan-review' || id == 'dev-review' || id == 'qa';

String stageText(StageState stage, LaneCurrent? current) {
  final qa = stage.id == 'qa';
  if (stage.status == 'returned') {
    if (stage.isActive) return qa ? '재시도 중 · ${current?.attempt}회차' : '재검수 중 · ${current?.attempt}회차';
    return '${qa ? verdictLabel['failed'] : verdictLabel['rejected']} ${stage.rejections}회';
  }
  if (stage.isActive) return current != null && current.attempt > 1 ? '${current.attempt}회차 진행 중' : '진행 중';
  if (stage.status == 'done') {
    final word = stage.id == 'ready'
        ? 'READY'
        : qa
        ? verdictLabel['passed']!
        : _isVerdictStage(stage.id)
        ? verdictLabel['approved']!
        : '완료';
    return stage.attempts > 1 ? '$word · ${stage.attempts}회차' : word;
  }
  return '대기';
}

enum _ReturnPart { none, start, mid, end }

_ReturnPart _returnPart(int index, ReturnConnector? connector) {
  if (connector == null) return _ReturnPart.none;
  final to = laneStages.indexWhere((stage) => stage.id == connector.to);
  final from = laneStages.indexWhere((stage) => stage.id == connector.from);
  if (index == to) return _ReturnPart.start;
  if (index == from) return _ReturnPart.end;
  if (index > to && index < from) return _ReturnPart.mid;
  return _ReturnPart.none;
}

class LaneColumn extends StatelessWidget {
  const LaneColumn({super.key, required this.content, required this.lane, required this.index, required this.showSeed});

  final WorkflowContent content;
  final LaneState lane;
  final int index;
  final bool showSeed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    final connector = lane.connector;
    final resolved = [
      for (final item in lane.returns)
        if (item.resolvedBy != null || item.supersededBy != null) item,
    ];
    final borderColor = switch (lane.status) {
      'returned' => palette.faultLine,
      'ready' => palette.warnLine,
      'merged' || 'done' => palette.okLine,
      _ => palette.tileLine,
    };
    final statusColors = switch (lane.status) {
      'running' => (palette.orange, palette.orangeText),
      'returned' => (palette.fault, palette.faultText),
      'ready' => (palette.warnLine, palette.warnText),
      'merged' => (palette.okLine, palette.lime),
      _ => (palette.line3, palette.inkHi),
    };

    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: palette.orange, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  lane.key,
                  style: textStyle(size: 16, weight: FontWeight.w800, color: palette.orangeInk, height: 1),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    container: true,
                    header: true,
                    headingLevel: 3,
                    label: '레인 ${lane.key}, ${lane.title}',
                    excludeSemantics: true,
                    child: KText(
                      lane.title,
                      style: textStyle(size: 17, weight: FontWeight.w700, color: palette.ink, height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(lane.owns, style: textStyle(size: 12.5, mono: true, color: palette.ink3)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: motionDuration(context, Motion.med),
          constraints: const BoxConstraints(minHeight: 26),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: statusColors.$1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_laneStatusIcon[lane.status], size: 15, color: statusColors.$2),
              const SizedBox(width: 6),
              Flexible(
                child: KText(
                  laneStatusText[lane.status]!,
                  style: textStyle(size: 13, weight: FontWeight.w600, color: statusColors.$2),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final stages = Semantics(
      container: true,
      label: '레인 ${lane.key} 단계',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, stage) in lane.stages.indexed)
            _StageRow(
              lane: lane,
              stage: stage,
              part: _returnPart(i, connector),
              flash: connector != null && connector.fresh && stage.id == connector.to ? connector.eventId : null,
            ),
        ],
      ),
    );

    final children = <Widget>[
      head,
      if (showSeed && lane.lineage.seeded) _SeedLineage(content: content, lineage: lane.lineage, laneKey: lane.key),
      stages,
      if (connector != null)
        RiseIn(
          key: ValueKey('return-${connector.eventId}'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: palette.faultTint, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(PhosphorIconsBold.arrowBendUpLeft, size: 16, color: palette.fault),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KText(
                        '${stageLabel(connector.from)} ${connector.from == 'qa' ? '실패' : '반려'} → ${content.returnTargetLabel[connector.to]} 되돌림',
                        style: textStyle(size: 13.5, weight: FontWeight.w700, color: palette.faultTextHi, height: 1.5),
                      ),
                      _ReturnTrack(key: ValueKey(connector.eventId), connector: connector),
                      KText(
                        '${connector.issueId != null ? '${connector.issueId} · ' : ''}사유: ${connector.reason}',
                        style: textStyle(size: 13.5, color: palette.faultTextHi, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
      else
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 42),
          child: KText(
            lane.lastEvent?.text ??
                (lane.status == 'queued'
                    ? 'Master AI 배정을 기다립니다.'
                    : lane.status == 'seeding'
                    ? 'Seed가 규칙·구조를 읽는 중입니다.'
                    : '시작'),
            style: textStyle(size: 13.5, color: palette.inkSoft, height: 1.5),
          ),
        ),
      if (lane.issues.isNotEmpty)
        Semantics(
          container: true,
          label: '레인 ${lane.key} QA 지적 원장',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final issue in lane.issues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        issue.status == 'resolved' ? PhosphorIconsFill.checkCircle : PhosphorIconsBold.bug,
                        size: 14,
                        color: issue.status == 'resolved' ? palette.inkSoft : palette.faultTextHi,
                      ),
                      Text(
                        issue.id,
                        style: textStyle(size: 13, weight: FontWeight.w700, color: issue.status == 'resolved' ? palette.inkSoft : palette.faultTextHi),
                      ),
                      KText(
                        '${issue.status == 'resolved' ? '독립 QA 통과로 해결' : '열림'} · 재현 ${issue.occurrences}회',
                        style: textStyle(size: 13, height: 1.45, color: issue.status == 'resolved' ? palette.inkSoft : palette.faultTextHi),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      Row(
        children: [
          for (final (i, (label, value)) in [('기획 검수', lane.counts.planReview), ('개발 검수', lane.counts.devReview), ('QA', lane.counts.qa)].indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: palette.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KText(label, style: textStyle(size: 12, color: palette.ink3)),
                    Text(
                      '$value회',
                      style: textStyle(size: 15, weight: FontWeight.w700, color: palette.ink, tabular: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      if (resolved.isNotEmpty)
        Semantics(
          container: true,
          label: '레인 ${lane.key} 해결된 되돌림',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in resolved)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(item.resolvedBy != null ? PhosphorIconsFill.checkCircle : PhosphorIconsBold.arrowBendUpLeft, size: 14, color: palette.lime),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: KText(_historyText(item), style: textStyle(size: 12.5, color: palette.inkSoft, height: 1.45)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
    ];

    final card = Container(
      padding: EdgeInsets.all(mobile ? 12 : 16),
      decoration: lane.status == 'seeding'
          ? BoxDecoration(color: palette.tile, borderRadius: BorderRadius.circular(16))
          : BoxDecoration(
              color: palette.tile,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[if (i > 0) const SizedBox(height: 12), child],
        ],
      ),
    );

    // 원본 <section aria-labelledby="레인 제목">: 레인 전체는 자식 노드를 따로 가진 묶음이고, 제목(h3)은 그 안의 한 노드다.
    // (container 가 없으면 제목의 header·단계가 위로 합쳐져, 레인 하나짜리 보드에서 본문 전체가 h3 하나로 읽혔다.)
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: FrameNode(
        id: 'lane:${lane.id}',
        radius: 16,
        child: _LaneEntrance(
          queued: lane.status == 'queued',
          index: index,
          child: lane.status == 'seeding' ? DashedBox(color: palette.tileLine, radius: 16, child: card) : card,
        ),
      ),
    );
  }

  String _historyText(ReturnRecord item) {
    final failed = item.verdict == 'failed';
    final head = '${stageLabel(item.from)} ${failed ? '실패' : '반려'} ${item.attempt}회차 → ';
    final tail = item.resolvedBy != null
        ? '${item.resolvedAttempt}회차 ${failed ? '${verdictLabel['passed']}로' : '${verdictLabel['approved']}으로'} 해결'
        : '${failed ? '재시도' : '재검수'}에서 다시 되돌림';
    return '$head$tail: ${item.reason}';
  }
}

/// 배정 순간 레인이 레인 순서대로(140ms × 순서 + 120ms 지연) 나타난다(배정 전: 흐림 0.6, 위로 6px). 한 번만, 동작 줄이기면 즉시.
class _LaneEntrance extends StatefulWidget {
  const _LaneEntrance({required this.queued, required this.index, required this.child});

  final bool queued;
  final int index;
  final Widget child;

  @override
  State<_LaneEntrance> createState() => _LaneEntranceState();
}

class _LaneEntranceState extends State<_LaneEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 360), value: widget.queued ? 0 : 1);
  }

  @override
  void didUpdateWidget(_LaneEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.queued == oldWidget.queued) return;
    _delay?.cancel();
    if (ReducedMotion.read(context)) {
      _controller.value = widget.queued ? 0 : 1;
      return;
    }
    if (widget.queued) {
      _controller.reverse();
    } else {
      _delay = Timer(Duration(milliseconds: 140 * widget.index + 120), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ReducedMotion.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Motion.easeOut.transform(_controller.value);
        return Opacity(
          opacity: 0.6 + 0.4 * t,
          child: Transform.translate(offset: Offset(0, reduced ? 0 : -6 * (1 - t)), child: child),
        );
      },
      child: widget.child,
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.lane, required this.stage, required this.part, required this.flash});

  final LaneState lane;
  final StageState stage;
  final _ReturnPart part;

  /// 새 되돌림의 대상 단계면 그 반려 이벤트 id(한 번 강조).
  final String? flash;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final returned = stage.status == 'returned';
    final active = stage.isActive;
    final Color border = returned ? palette.fault : (active ? palette.orange : palette.line);
    final Color background = returned ? palette.faultTint : (active ? palette.orangeTint : palette.surface2);
    final Color accent = returned ? palette.faultText : (active ? palette.orangeText : palette.inkMute);
    final IconData icon;
    Color iconColor;
    if (returned) {
      icon = stage.id == 'qa' ? PhosphorIconsFill.xCircle : PhosphorIconsBold.arrowBendUpLeft;
      iconColor = palette.faultText;
    } else if (active) {
      icon = PhosphorIconsBold.circleNotch;
      iconColor = palette.orangeText;
    } else if (stage.status == 'done') {
      icon = PhosphorIconsFill.checkCircle;
      iconColor = palette.lime;
    } else {
      icon = PhosphorIconsRegular.circleDashed;
      iconColor = palette.inkFaint;
    }
    final labelColor = stage.status == 'pending' && !active ? palette.inkMute : palette.ink;
    final cardWidget = AnimatedContainer(
      duration: motionDuration(context, Motion.med),
      curve: Motion.easeOut,
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: KText(
              stage.label,
              style: textStyle(size: 15, weight: FontWeight.w700, color: labelColor),
            ),
          ),
          const SizedBox(width: 10),
          // grid: auto | 1fr | auto — 상태 글은 제 너비로 오른쪽에 붙는다.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: KText(
              stageText(stage, lane.current),
              textAlign: TextAlign.right,
              style: textStyle(size: 13, color: returned || active ? accent : palette.inkMute),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      selected: active,
      child: FrameNode(
        id: 'stage:${lane.id}:${stage.id}',
        radius: 11,
        child: CustomPaint(
          painter: part == _ReturnPart.none ? null : _ReturnConnectorPainter(part: part, color: palette.fault),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 3, 0, 3),
            child: flash == null ? cardWidget : _ReturnFlash(key: ValueKey(flash), child: cardWidget),
          ),
        ),
      ),
    );
  }
}

/// 되돌아갈 단계 행 강조(1000ms 뒤 700ms 동안 바깥으로 퍼지는 빨간 그림자 한 번).
class _ReturnFlash extends StatelessWidget {
  const _ReturnFlash({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (ReducedMotion.of(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1700),
      curve: const Interval(1000 / 1700, 1, curve: Motion.easeOut),
      builder: (context, t, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          boxShadow: t <= 0 || t >= 1
              ? const []
              : [
                  BoxShadow(
                    color: AppPalette.returnFlash.withValues(alpha: 0.8 * (1 - t)),
                    spreadRadius: 8 * t,
                  ),
                ],
        ),
        child: child,
      ),
      child: child,
    );
  }
}

/// 반려·실패 단계(끝)에서 되돌아갈 단계(시작)까지 왼쪽 점선. 시작 행에는 화살촉을 붙인다.
class _ReturnConnectorPainter extends CustomPainter {
  const _ReturnConnectorPainter({required this.part, required this.color});

  final _ReturnPart part;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0 + 1;
    const right = 8.0 + 14;
    const radius = 8.0;
    final mid = size.height / 2;
    final path = Path();
    switch (part) {
      case _ReturnPart.start:
        path
          ..moveTo(left, size.height)
          ..lineTo(left, mid + radius)
          ..arcToPoint(Offset(left + radius, mid), radius: const Radius.circular(radius))
          ..lineTo(right, mid);
      case _ReturnPart.mid:
        path
          ..moveTo(left, 0)
          ..lineTo(left, size.height);
      case _ReturnPart.end:
        path
          ..moveTo(left, 0)
          ..lineTo(left, mid - radius)
          ..arcToPoint(Offset(left + radius, mid), radius: const Radius.circular(radius), clockwise: false)
          ..lineTo(right, mid);
      case _ReturnPart.none:
        return;
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 12;
      }
    }
    if (part == _ReturnPart.start) {
      final arrow = Path()
        ..moveTo(19, mid - 6)
        ..lineTo(26, mid)
        ..lineTo(19, mid + 6)
        ..close();
      canvas.drawPath(arrow, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_ReturnConnectorPainter oldDelegate) => part != oldDelegate.part || color != oldDelegate.color;
}

/// 되돌림 이동 표시: 반려 단계(오른쪽) → 되돌아갈 단계(왼쪽). 새 반려마다 한 번만 표식이 미끄러진다.
class _ReturnTrack extends StatefulWidget {
  const _ReturnTrack({super.key, required this.connector});

  final ReturnConnector connector;

  @override
  State<_ReturnTrack> createState() => _ReturnTrackState();
}

class _ReturnTrackState extends State<_ReturnTrack> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100), value: 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.connector.fresh && !ReducedMotion.of(context) && _controller.value == 1 && !_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final connector = widget.connector;
    Widget end(String text, {double opacity = 1}) => Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.fault),
        ),
        child: Text(
          text,
          style: textStyle(size: 12, weight: FontWeight.w700, color: palette.faultTextHi, height: 1.3),
        ),
      ),
    );
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            end(stageLabel(connector.to)),
            const SizedBox(width: 6),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48),
                child: SizedBox(
                  height: 22,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(left: 0, right: 0, top: 10, child: DashedLine(color: palette.fault, width: 2)),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          // 200ms 쉬고 900ms 동안 오른쪽 끝 → 왼쪽 끝.
                          final raw = ((_controller.value * 1100 - 200) / 900).clamp(0.0, 1.0);
                          final t = Motion.easeOut.transform(raw);
                          return Align(alignment: Alignment(1 - 2 * t, 0), child: child);
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(color: palette.fault, shape: BoxShape.circle),
                          child: const Icon(PhosphorIconsBold.arrowLeft, size: 14, color: AppPalette.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            end(stageLabel(connector.from), opacity: 0.7),
          ],
        ),
      ),
    );
  }
}

const List<(String, String, List<String>)> _seeds = [
  ('author-seed', 'authorSeed', ['plan-author', 'dev-author']),
  ('reviewer-seed', 'reviewerSeed', ['plan-reviewer', 'dev-reviewer']),
];

String _childText(LineageChild child) {
  if (child.runs == 0) return 'fork 대기';
  if (child.runs == 1) return 'fork됨';
  return '같은 child resume · ${child.runs}회 실행';
}

class _SeedLineage extends StatelessWidget {
  const _SeedLineage({required this.content, required this.lineage, required this.laneKey});

  final WorkflowContent content;
  final LaneLineage lineage;
  final String laneKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final copy = content.seedCopy;
    final childNames = (copy['children'] as Map).cast<String, String>();
    final byId = {for (final child in lineage.children) child.id: child};
    final ready = lineage.seedReady;
    final small = textStyle(size: 12.5, color: palette.inkMute, height: 1.45);
    final body = Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (seedId, labelKey, children) in _seeds) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(PhosphorIconsRegular.eye, size: 15, color: ready ? palette.orange : palette.ink),
                Text(
                  copy[labelKey] as String,
                  style: small.copyWith(fontWeight: FontWeight.w700, color: ready ? palette.orange : palette.ink),
                ),
                KText(ready ? '읽기 전용 · 준비됨' : '대기', style: small.copyWith(color: ready ? palette.orange : palette.inkMute)),
              ],
            ),
            Padding(
              key: ValueKey(seedId),
              padding: const EdgeInsets.only(left: 7, top: 4),
              child: Stack(
                children: [
                  Positioned(left: 0, top: 0, bottom: 0, child: DashedLine(color: palette.line3, width: 2, vertical: true)),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [for (final id in children) _SeedChild(name: childNames[id]!, child: byId[id]!, text: _childText(byId[id]!))],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.line)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(PhosphorIconsRegular.userCircle, size: 15, color: palette.inkSoft),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: KText(
                    '${copy['independent']}${lineage.qaRuns > 0 ? ' · QA ${lineage.qaRuns}회 실행(같은 QA 세션)' : ''}',
                    style: small.copyWith(color: palette.inkSoft),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: '레인 $laneKey ${copy['heading']}',
      child: ready
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.line2),
              ),
              child: body,
            )
          : DashedBox(color: palette.line3, radius: 12, child: body),
    );
  }
}

class _SeedChild extends StatelessWidget {
  const _SeedChild({required this.name, required this.child, required this.text});

  final String name;
  final LineageChild child;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final forked = child.runs > 0;
    final resumed = child.runs > 1;
    final color = forked ? palette.ink : palette.inkMute;
    final small = textStyle(size: 12.5, color: color, height: 1.45);
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // fork 선: Seed 줄기에서 child 로(fork 되면 주황 실선).
          Positioned(
            left: -14,
            top: 9,
            child: forked ? Container(width: 10, height: 2, color: palette.orange) : DashedLine(color: palette.line3, width: 2, length: 10),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                child.runs == 0 ? PhosphorIconsBold.circleDashed : (resumed ? PhosphorIconsBold.arrowClockwise : PhosphorIconsBold.gitFork),
                size: 14,
                color: resumed ? palette.lime : color,
              ),
              Text(name, style: small.copyWith(fontWeight: FontWeight.w700)),
              KText(text, style: small.copyWith(color: palette.inkMute)),
            ],
          ),
        ],
      ),
    );
    return forked ? RiseIn(key: ValueKey('${child.id}-forked'), child: row) : row;
  }
}
