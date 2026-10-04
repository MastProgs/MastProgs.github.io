// 레인 보드(React LaneBoard.jsx + SpecPanel.jsx + TaskPlanPanel.jsx 이식): Master 배정 → WORK SPEC → (병렬) Task Planning → Seed 규칙 →
// 배정선 → 레인 → 합류선 → 병합 게이트 → 통합·Wiki.
// AI-NOTE: 첫 화면에서 레인이 모두 펼쳐져 보인다(아코디언 없음, 모바일도 위아래로 모두 펼침). Master AI 가 지시를 배정하는 순간
// 배정선이 레인 순서대로(140ms 간격) 내려가며 레인이 활성화된다(한 번만, 동작 줄이기면 즉시). 순차(레인 1개)는 가운데 세로선 하나만 남긴다.
// 병렬 Task Planning: 작업축 제안 → 독립성 검토 → Task Contract 동결(task:split|review|freeze). 검토 승인 뒤에만 검토 항목이,
// 동결 뒤에만 병합 순서가 나온다(되감으면 사라짐). 병합 게이트는 모든 레인 QA 통과 전까지 잠겨 있다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/dashed.dart';
import '../../../widgets/k_text.dart';
import '../controller/workflow_player_controller.dart';
import '../model/workflow_content.dart';
import '../model/workflow_scenario.dart';
import 'frame_scope.dart';
import 'lane_column.dart';
import 'workflow_panels.dart';

class LaneBoard extends StatelessWidget {
  const LaneBoard({super.key, required this.content, required this.frame, required this.showSeed});

  final WorkflowContent content;
  final WorkflowFrame frame;
  final bool showSeed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final lanes = frame.lanes;
    final single = lanes.length == 1;
    final dispatched = frame.dispatched;
    final stackLanes = metrics.atMost(Breakpoints.narrow);
    final copy = content.copy;

    final master = FrameNode(
      id: 'master',
      radius: 16,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: palette.orangeTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.orange, width: 1.5),
        ),
        child: Wrap(
          spacing: 14,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: palette.orange, shape: BoxShape.circle),
                  child: Icon(PhosphorIconsRegular.robot, size: 24, color: palette.orangeInk),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KText(
                          copy['dispatcherHeading']!,
                          style: textStyle(size: 17, weight: FontWeight.w700, color: palette.ink),
                        ),
                        KText(dispatched ? copy['dispatcherDone']! : copy['dispatcherIdle']!, style: textStyle(size: 14, color: palette.inkHi)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsRegular.arrowsSplit, size: 18, color: palette.orangeText),
                const SizedBox(width: 6),
                Text(
                  lanes.map((lane) => lane.key).join(' · '),
                  style: textStyle(size: 14, weight: FontWeight.w700, color: palette.orangeText),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final laneWidgets = [for (final (i, lane) in lanes.indexed) LaneColumn(content: content, lane: lane, index: i, showSeed: showSeed)];

    final Widget laneArea;
    if (stackLanes) {
      laneArea = Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, lane) in laneWidgets.indexed) ...[if (i > 0) const SizedBox(height: 14), lane],
          ],
        ),
      );
    } else if (single) {
      laneArea = Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: laneWidgets.first),
      );
    } else {
      laneArea = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, lane) in laneWidgets.indexed) ...[if (i > 0) const SizedBox(width: 14), Expanded(child: lane)],
          ],
        ),
      );
    }

    return Semantics(
      container: true,
      label: copy['boardLabel'],
      child: Container(
        padding: EdgeInsets.all(metrics.mobile ? 12 : 20),
        decoration: BoxDecoration(color: palette.panel, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: master),
            if (frame.spec != null) SpecPanel(content: content, spec: frame.spec!),
            if (frame.taskPlan != null) TaskPlanPanel(content: content, plan: frame.taskPlan!),
            if (showSeed)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(PhosphorIconsRegular.eye, size: 16, color: palette.inkSoft),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KText(content.seedCopy['rule'] as String, style: textStyle(size: 13, color: palette.inkSoft, height: 1.5)),
                    ),
                  ],
                ),
              ),
            if (!stackLanes) _FanOut(count: lanes.length, dispatched: dispatched, single: single),
            laneArea,
            if (!stackLanes) _Join(lanes: lanes, single: single),
            _Gate(content: content, frame: frame),
          ],
        ),
      ),
    );
  }
}

/// 배정선: Master 아래 가로선 + 레인마다 내려가는 선. 배정되면 레인 순서대로 주황으로 채워진다.
class _FanOut extends StatelessWidget {
  const _FanOut({required this.count, required this.dispatched, required this.single});

  final int count;
  final bool dispatched;
  final bool single;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduced = ReducedMotion.of(context);
    final color = dispatched ? palette.orange : palette.line2;
    Widget body = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final column = (width - 14 * (count - 1)) / count;
        return SizedBox(
          height: 34,
          child: Stack(
            children: [
              // Master 줄기(가운데 위 12px).
              Positioned(
                left: width / 2 - 1,
                top: 0,
                width: 2,
                height: 12,
                child: ColoredBox(color: color),
              ),
              if (!single)
                Positioned(
                  left: width / 6,
                  right: width / 6,
                  top: 12,
                  height: 2,
                  child: ColoredBox(color: color),
                ),
              for (var i = 0; i < count; i += 1)
                Positioned(
                  left: i * (column + 14) + column / 2 - 1,
                  top: 12,
                  bottom: 0,
                  width: 2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: palette.line2),
                      _DropFill(
                        dispatched: dispatched,
                        delay: Duration(milliseconds: 140 * i),
                        reduced: reduced,
                        color: palette.orange,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (single) {
      body = Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: body),
      );
    }
    return ExcludeSemantics(child: body);
  }
}

class _DropFill extends StatefulWidget {
  const _DropFill({required this.dispatched, required this.delay, required this.reduced, required this.color});

  final bool dispatched;
  final Duration delay;
  final bool reduced;
  final Color color;

  @override
  State<_DropFill> createState() => _DropFillState();
}

class _DropFillState extends State<_DropFill> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 360), value: widget.dispatched ? 1 : 0);
  }

  @override
  void didUpdateWidget(_DropFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dispatched == oldWidget.dispatched) return;
    _delay?.cancel();
    if (widget.reduced) {
      _controller.value = widget.dispatched ? 1 : 0;
    } else if (widget.dispatched) {
      _delay = Timer(widget.delay, () {
        if (mounted && widget.dispatched) _controller.forward();
      });
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: Motion.easeOut.transform(_controller.value),
        child: ColoredBox(color: widget.color),
      ),
    ),
  );
}

/// 합류선: 레인에서 병합 게이트로. READY·병합·완료된 레인은 초록.
class _Join extends StatelessWidget {
  const _Join({required this.lanes, required this.single});

  final List<LaneState> lanes;
  final bool single;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget row = SizedBox(
      height: 22,
      child: Row(
        children: [
          for (final (i, lane) in lanes.indexed) ...[
            if (i > 0) const SizedBox(width: 14),
            Expanded(
              child: Center(
                child: AnimatedContainer(
                  duration: motionDuration(context, Motion.med),
                  width: 2,
                  color: const ['ready', 'merged', 'done'].contains(lane.status) ? palette.lime : palette.line2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (single) {
      row = Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: row),
      );
    }
    return ExcludeSemantics(child: row);
  }
}

String _gateText(MergeGateState gate) {
  if (gate.status == 'merged') return '모든 레인 QA 통과 · 병합 완료';
  if (gate.status == 'open') return '모든 레인 READY · 통합 기획 시작';
  final ready = gate.readyLanes.isNotEmpty ? '${gate.readyLanes.join('·')} 통과, ' : '';
  return '잠김 — $ready${gate.waitingFor.join('·')} QA 통과 대기';
}

class _Gate extends StatelessWidget {
  const _Gate({required this.content, required this.frame});

  final WorkflowContent content;
  final WorkflowFrame frame;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final gate = frame.gate;
    final status = gate?.status ?? 'single';
    final copy = content.copy;
    final columns = metrics.mobile ? 1 : (metrics.atMost(Breakpoints.desktop) ? 2 : 4);
    final headColor = switch (status) {
      'open' => palette.orangeText,
      'merged' => palette.lime,
      _ => palette.warnText,
    };
    final steps = [
      for (final item in frame.integration)
        FrameNode(
          id: 'integration:${item.id}',
          radius: 11,
          child: Semantics(
            selected: item.isActive,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: item.isActive ? palette.orangeTint : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: item.isActive ? palette.orange : palette.tileLine),
              ),
              child: Row(
                children: [
                  Icon(
                    item.status == 'done' ? PhosphorIconsFill.checkCircle : (item.isActive ? PhosphorIconsBold.circleNotch : PhosphorIconsBold.circleDashed),
                    size: 16,
                    color: item.status == 'done' ? palette.lime : (item.isActive ? palette.orangeText : palette.inkMute),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KText(
                          item.label,
                          style: textStyle(size: 14.5, weight: FontWeight.w700, color: palette.ink),
                        ),
                        const SizedBox(height: 2),
                        KText(
                          item.status == 'done' ? item.text : (item.isActive ? '진행 중' : '대기'),
                          style: textStyle(size: 12.5, height: 1.4, color: item.isActive ? palette.orangeText : palette.inkMute),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
    final solid = status == 'open' || status == 'merged';
    final borderColor = switch (status) {
      'open' => palette.orange,
      'merged' => palette.okLine,
      _ => palette.warnLine,
    };
    final inner = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (gate != null) ...[
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  switch (gate.status) {
                    'open' => PhosphorIconsBold.lockOpen,
                    'merged' => PhosphorIconsBold.gitMerge,
                    _ => PhosphorIconsBold.lock,
                  },
                  size: 20,
                  color: headColor,
                ),
                Text(
                  copy['mergeHeading']!,
                  style: textStyle(size: 16, weight: FontWeight.w700, color: headColor),
                ),
                KText(_gateText(gate), style: textStyle(size: 14, color: palette.inkHi)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Semantics(
            container: true,
            label: copy['integrationHeading'],
            child: EqualColumns(columns: columns, gap: 8, children: steps),
          ),
        ],
      ),
    );
    return FrameNode(
      id: 'gate',
      radius: 16,
      child: solid
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: inner,
            )
          : DashedBox(color: borderColor, radius: 16, width: 1.5, child: inner),
    );
  }
}

const Map<String, String> _specStatus = {'written': '작성됨', 'frozen': '동결 · 지시 배정됨'};

class SpecPanel extends StatelessWidget {
  const SpecPanel({super.key, required this.content, required this.spec});

  final WorkflowContent content;
  final SpecState spec;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final copy = content.specCopy;
    final idle = spec.status == 'idle';
    final head = Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(spec.status == 'frozen' ? PhosphorIconsBold.lockSimple : PhosphorIconsRegular.clipboardText, size: 18, color: palette.ink),
        Text(
          copy['heading']!,
          style: textStyle(size: 14, weight: FontWeight.w800, em: 0.04, color: palette.ink),
        ),
        KText(idle ? copy['idle']! : _specStatus[spec.status]!, style: textStyle(size: 14, color: palette.inkSoft)),
      ],
    );
    if (idle) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: FrameNode(
          id: 'spec',
          radius: 14,
          child: DashedBox(color: palette.line4, radius: 14, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: head),
        ),
      );
    }
    TextStyle cell() => textStyle(size: 13.5, color: palette.ink, height: 1.5);
    Widget bullets(List<String> lines) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 2),
            child: KText(line, style: cell()),
          ),
      ],
    );
    Widget column(String title, Widget body) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: KText(
            title,
            style: textStyle(size: 13.5, weight: FontWeight.w700, color: palette.orange),
          ),
        ),
        body,
      ],
    );
    final owns = spec.lanes.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final lane in spec.lanes)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 2),
                  child: KRich([
                    TextSpan(
                      text: lane.key,
                      style: textStyle(size: 13.5, weight: FontWeight.w700, color: palette.ink, height: 1.5),
                    ),
                    kSpan(' ${lane.title} '),
                    TextSpan(
                      text: lane.owns,
                      style: textStyle(size: 13.5, mono: true, color: palette.inkSoft, height: 1.5),
                    ),
                  ], style: cell()),
                ),
            ],
          )
        : KText(copy['ownsByTask']!, style: cell().copyWith(color: palette.inkSoft));
    final grid = EqualColumns(
      columns: metrics.mobile ? 1 : 3,
      gap: 16,
      runGap: 10,
      stretch: false,
      children: [column(copy['scope']!, bullets(spec.scope)), column(copy['criteria']!, bullets(spec.criteria)), column(copy['owns']!, owns)],
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: FrameNode(
        id: 'spec',
        radius: 14,
        child: RiseIn(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: spec.status == 'frozen' ? palette.warnLine : palette.orange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                head,
                const SizedBox(height: 10),
                grid,
                if (spec.axisNote != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: palette.line)),
                    ),
                    child: KRich([
                      TextSpan(
                        text: '${copy['axis']!}  ',
                        style: textStyle(size: 13.5, weight: FontWeight.w700, color: palette.orange, height: 1.55),
                      ),
                      kSpan(spec.axisNote!),
                    ], style: textStyle(size: 13.5, color: palette.inkHi, height: 1.55)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TaskPlanPanel extends StatelessWidget {
  const TaskPlanPanel({super.key, required this.content, required this.plan});

  final WorkflowContent content;
  final TaskPlanState plan;

  static const Map<String, IconData> _stepIcon = {
    'split': PhosphorIconsFill.arrowsSplit,
    'review': PhosphorIconsFill.sealCheck,
    'freeze': PhosphorIconsFill.lockSimple,
  };

  bool _stepDone(String id) => switch (id) {
    'split' => plan.status != 'idle',
    'review' => plan.status == 'approved' || plan.status == 'frozen',
    _ => plan.status == 'frozen',
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final narrow = ScreenMetrics.of(context).atMost(Breakpoints.narrow);
    final planning = content.taskPlanning;
    final idle = plan.status == 'idle';
    final frozen = plan.status == 'frozen';

    final steps = [
      for (final step in planning.steps)
        FrameNode(
          id: 'task:${step.id}',
          radius: 11,
          child: AnimatedContainer(
            duration: motionDuration(context, Motion.med),
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _stepDone(step.id) ? palette.orangeTint : palette.surface2,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _stepDone(step.id) ? palette.orange : palette.tileLine),
            ),
            child: Row(
              children: [
                Icon(
                  _stepDone(step.id) ? _stepIcon[step.id]! : PhosphorIconsBold.circleDashed,
                  size: 18,
                  color: _stepDone(step.id) ? palette.orangeText : palette.inkMute,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KText(
                        step.label,
                        style: textStyle(size: 14, weight: FontWeight.w700, color: palette.ink),
                      ),
                      KText(step.actor, style: textStyle(size: 12, color: _stepDone(step.id) ? palette.orangeText : palette.inkMute)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];

    Widget stepRow;
    if (narrow) {
      stepRow = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, step) in steps.indexed) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 2, height: 8, color: _stepDone(planning.steps[i - 1].id) ? palette.orange : palette.line2),
                ),
              ),
            step,
          ],
        ],
      );
    } else {
      stepRow = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, step) in steps.indexed) ...[
              if (i > 0)
                SizedBox(
                  width: 8,
                  child: Center(child: Container(height: 2, color: _stepDone(planning.steps[i - 1].id) ? palette.orange : palette.line2)),
                ),
              Expanded(child: step),
            ],
          ],
        ),
      );
    }

    final cards = [for (final (i, task) in plan.tasks.indexed) _TaskCard(key: ValueKey(task.id), content: content, task: task, index: i, frozen: frozen)];

    final ordered = plan.mergeOrder == null
        ? const <String>[]
        : (plan.tasks.where((task) => plan.mergeOrder!.contains(task.id)).toList()
                ..sort((a, b) => plan.mergeOrder!.indexOf(a.id) - plan.mergeOrder!.indexOf(b.id)))
              .map((task) => task.key)
              .toList();

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Semantics(
              header: true,
              headingLevel: 3,
              child: KText(
                planning.heading,
                style: textStyle(size: 14, weight: FontWeight.w800, em: 0.04, color: palette.ink),
              ),
            ),
            KText(planning.status[plan.status]!, style: textStyle(size: 13.5, color: palette.inkSoft)),
          ],
        ),
        const SizedBox(height: 12),
        KText(planning.lead, style: textStyle(size: 13, color: palette.inkSoft, height: 1.5)),
        const SizedBox(height: 12),
        stepRow,
        const SizedBox(height: 12),
        Center(
          child: Opacity(
            opacity: idle ? 0.6 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: palette.line3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIconsRegular.arrowsSplit, size: 16, color: palette.inkHi),
                  const SizedBox(width: 6),
                  KText(
                    planning.source,
                    style: textStyle(size: 13, weight: FontWeight.w600, color: palette.inkHi),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (cards.isNotEmpty) ...[
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label: '제안된 작업축',
            child: narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, card) in cards.indexed) ...[if (i > 0) const SizedBox(height: 10), card],
                    ],
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, card) in cards.indexed) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: card)],
                      ],
                    ),
                  ),
          ),
        ],
        if (plan.checks.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.line)),
            ),
            child: Semantics(
              container: true,
              label: 'Task Planning Reviewer 검토 항목',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, check) in plan.checks.indexed)
                    _Staggered(
                      key: ValueKey(check),
                      delay: Duration(milliseconds: 70 * i),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Icon(PhosphorIconsFill.checkCircle, size: 15, color: palette.lime),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: KText(check, style: textStyle(size: 13, color: palette.inkHi, height: 1.5)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (plan.mergeOrder != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: BadgePop(
              duration: const Duration(milliseconds: 260),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.warnLine),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsBold.lockSimple, size: 16, color: palette.warnText),
                    const SizedBox(width: 8),
                    Flexible(
                      child: KText(
                        'Task Contract 동결 · 병합 순서 ${ordered.join(' → ')}',
                        style: textStyle(size: 13.5, weight: FontWeight.w700, color: palette.warnText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );

    final borderColor = idle ? palette.line4 : (frozen ? palette.warnLine : palette.orange);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: idle
          ? DashedBox(color: borderColor, radius: 14, padding: const EdgeInsets.all(14), child: body)
          : Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: body,
            ),
    );
  }
}

/// 작업 카드: 가운데 "요청 1건"에서 갈라져 나오듯 순서대로 한 번만 펼쳐진다(420ms, 120ms 간격, 동작 줄이기면 즉시).
class _TaskCard extends StatelessWidget {
  const _TaskCard({super.key, required this.content, required this.task, required this.index, required this.frozen});

  final WorkflowContent content;
  final PlannedTask task;
  final int index;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final narrow = ScreenMetrics.of(context).atMost(Breakpoints.narrow);
    Widget fact(String label, Widget value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textStyle(size: 11.5, weight: FontWeight.w700, color: palette.ink3),
          ),
          value,
        ],
      ),
    );
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: frozen ? palette.warnLine : palette.tileLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: palette.orange, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  task.key,
                  style: textStyle(size: 14, weight: FontWeight.w800, color: palette.orangeInk, height: 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KText(
                  task.title,
                  style: textStyle(size: 15, weight: FontWeight.w700, color: palette.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          fact('소유 경로', Text(task.owns, style: textStyle(size: 12.5, mono: true, color: palette.inkHi, height: 1.45))),
          fact('인터페이스', KText(task.terms.interface, style: textStyle(size: 12.5, color: palette.inkHi, height: 1.45))),
          fact('수용 기준', KText(task.terms.acceptance, style: textStyle(size: 12.5, color: palette.inkHi, height: 1.45))),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.okLine),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsRegular.linkBreak, size: 14, color: palette.lime),
                const SizedBox(width: 5),
                KText(
                  content.taskPlanning.noDependency,
                  style: textStyle(size: 12, weight: FontWeight.w600, color: palette.lime),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (ReducedMotion.of(context)) return card;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + 120 * index),
      curve: Interval(120 * index / (420 + 120 * index), 1, curve: Motion.easeOut),
      builder: (context, t, child) {
        final dx = narrow ? 0.0 : (1 - index) * 0.6 * (1 - t);
        return Opacity(
          opacity: t,
          child: FractionalTranslation(
            translation: Offset(dx, 0),
            child: Transform.translate(
              offset: Offset(0, (narrow ? -12 : -14) * (1 - t)),
              child: Transform.scale(scale: narrow ? 1 : 0.92 + 0.08 * t, child: child),
            ),
          ),
        );
      },
      child: card,
    );
  }
}

class _Staggered extends StatelessWidget {
  const _Staggered({super.key, required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (ReducedMotion.of(context)) return child;
    final total = delay + const Duration(milliseconds: 260);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(delay.inMilliseconds / total.inMilliseconds, 1, curve: Motion.easeOut),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
