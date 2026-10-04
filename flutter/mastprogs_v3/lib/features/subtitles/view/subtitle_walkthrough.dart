// 처리 원리를 단계별로 따라가는 예시(React SubtitleWalkthrough.jsx 이식). 데이터는 WALKTHROUGH_FIXTURE(가상 대사)이고 buildWalkthrough 결과만 읽는다.
// AI-NOTE: 실제 음성 인식·정렬·AI 호출·오디오 재생·업로드·저장은 없다. 재생은 사용자가 누를 때만 단계를 차례로 넘기고(자동 시작 없음),
// 2600ms 간격으로 단계마다 타이머 하나를 예약·정리하며 끝에서 멈춘다(반복 없음). 끝에서 재생하면 처음부터 한 번 다시. 탭이 가려지면 멈춘다.
// 이전·다음·단계 고르기는 멈춘다. 속도 선택은 이 재생기에 없다. 사람의 수락·보류는 이 화면 상태로만 남고 새로 고치면 사라진다.
// 시간축의 모든 경계는 단어 정렬 시각에서 나온다(AI 응답에는 시간이 없다).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../core/js_compat.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/hint_tooltip.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/readable_text.dart';
import '../model/subtitles_content.dart';
import '../model/subtitles_model.dart';

String _sec(int ms) => (ms / 1000).toStringAsFixed(2);

class SubtitleWalkthrough extends StatefulWidget {
  const SubtitleWalkthrough({super.key, required this.content, required this.walk});

  final SubtitlesContent content;
  final Walkthrough walk;

  @override
  State<SubtitleWalkthrough> createState() => _SubtitleWalkthroughState();
}

class _SubtitleWalkthroughState extends State<SubtitleWalkthrough> {
  StageState _state = const StageState(stage: 0, playing: false);
  Map<String, String> _decisions = const {};
  String _message = '';
  Timer? _timer;
  ValueNotifier<bool>? _hidden;

  int get _total => widget.content.stages.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hidden = PageVisibility.notifierOf(context);
    if (hidden != _hidden) {
      _hidden?.removeListener(_onVisibility);
      _hidden = hidden;
      _hidden?.addListener(_onVisibility);
    }
  }

  void _onVisibility() {
    if (_hidden?.value ?? false) _apply(const StagePause());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hidden?.removeListener(_onVisibility);
    super.dispose();
  }

  void _apply(StageAction action) {
    final next = stageReducer(_state, action, _total);
    if (next == _state) return;
    setState(() => _state = next);
    _schedule();
  }

  // 재생 중이면 단계마다 타이머 하나(useEffect [playing, stage]).
  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!_state.playing) return;
    _timer = Timer(const Duration(milliseconds: stageIntervalMs), () => _apply(const StageTick()));
  }

  // 직접 단계를 옮겼을 때만 알린다(자동 넘김 중에는 알리지 않음).
  void _go(StageAction action) {
    final next = stageReducer(_state, action, _total);
    if (next.stage != _state.stage) {
      final stage = widget.content.stages[next.stage];
      _message = '${padZero(next.stage + 1)} ${stage.label}: ${stage.title}';
    }
    _apply(action);
  }

  void _decide(String id, String value) => setState(() => _decisions = {..._decisions, id: value});

  void _undo(String id) => setState(() => _decisions = {..._decisions}..remove(id));

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final copy = widget.content.walkCopy;
    final stages = widget.content.stages;
    final stage = _state.stage;
    final playing = _state.playing;
    final atEnd = stage == _total - 1;
    final meta = stages[stage];
    final playLabel = playing ? copy['pause']! : (atEnd ? copy['restart']! : copy['play']!);
    final columns = metrics.mobile ? 2 : (metrics.atMost(Breakpoints.desktop) ? 3 : 6);

    final stageButtons = Semantics(
      container: true,
      label: copy['stageList'],
      child: EqualColumns(
        columns: columns,
        gap: 6,
        children: [
          for (final (index, item) in stages.indexed)
            Pressable(
              onPressed: () => _go(StageSeek(index)),
              selected: index == stage,
              semanticLabel: '${padZero(index + 1)} ${item.label}',
              excludeChildSemantics: true,
              radius: BorderRadius.circular(12),
              builder: (context, state) {
                final current = index == stage;
                final past = index < stage;
                return AnimatedContainer(
                  duration: motionDuration(context, Motion.fast),
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: current ? palette.orangeTint : (state.hovered ? palette.hoverWash : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: current ? palette.orange : (past ? palette.line3 : palette.line2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(padZero(index + 1), style: textStyle(size: 11.5, color: palette.ink3, tabular: true)),
                      const SizedBox(height: 2),
                      KText(
                        item.label,
                        style: textStyle(size: 14, weight: FontWeight.w600, color: current || past ? palette.ink : palette.ink2),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );

    final transport = Semantics(
      container: true,
      label: copy['transportLabel'],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: palette.surface2,
          borderRadius: BorderRadius.circular(metrics.mobile ? 16 : 999),
          border: Border.all(color: palette.line2),
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _RoundButton(icon: PhosphorIconsBold.caretLeft, label: copy['prev']!, ariaDisabled: stage == 0, onPressed: () => _go(const StagePrev())),
            _RoundButton(
              icon: playing ? PhosphorIconsFill.pause : PhosphorIconsFill.play,
              label: playLabel,
              primary: true,
              onPressed: () => _go(playing ? const StagePause() : const StagePlay()),
            ),
            _RoundButton(icon: PhosphorIconsBold.caretRight, label: copy['next']!, ariaDisabled: atEnd, onPressed: () => _go(const StageNext())),
            _RoundButton(
              icon: PhosphorIconsRegular.arrowCounterClockwise,
              label: copy['reset']!,
              quiet: true,
              ariaDisabled: stage == 0 && !playing,
              onPressed: () => _go(const StageReset()),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(
                    '${padZero(stage + 1)} / ${padZero(_total)}',
                    style: textStyle(size: 15, weight: FontWeight.w700, color: palette.ink, tabular: true),
                  ),
                  KText(copy['fixtureLabel']!, style: textStyle(size: 13, color: palette.ink3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final panel = Container(
      padding: metrics.mobile ? const EdgeInsets.fromLTRB(12, 14, 12, 16) : const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            headingLevel: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(padZero(stage + 1), style: textStyle(size: 14, color: palette.orangeText, tabular: true)),
                const SizedBox(width: 10),
                Expanded(
                  child: KText(
                    meta.title,
                    style: textStyle(size: 19, weight: FontWeight.w700, em: -0.02, color: palette.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          KText(meta.text, style: textStyle(size: 15, color: palette.ink2, height: 1.6)),
          const SizedBox(height: 14),
          _Timeline(copy: copy, walk: widget.walk, stage: stage),
          const SizedBox(height: 14),
          _StageDetail(content: widget.content, walk: widget.walk, stageId: meta.id, decisions: _decisions, onDecide: _decide, onUndo: _undo),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [stageButtons, const SizedBox(height: 14), transport, ScreenReaderOnly(_message, liveRegion: true), const SizedBox(height: 14), panel],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onPressed, this.primary = false, this.quiet = false, this.ariaDisabled = false});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool quiet;
  final bool ariaDisabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final size = primary ? 52.0 : 44.0;
    return Pressable(
      onPressed: onPressed,
      ariaDisabled: ariaDisabled,
      semanticLabel: label,
      tooltip: label,
      excludeChildSemantics: true,
      builder: (context, state) {
        final hover = state.hovered && !ariaDisabled;
        return AnimatedOpacity(
          duration: motionDuration(context, Motion.fast),
          opacity: ariaDisabled ? 0.35 : 1,
          child: AnimatedScale(
            duration: motionDuration(context, Motion.fast),
            scale: state.pressed && !ariaDisabled ? 0.94 : 1,
            child: Container(
              width: size,
              height: size,
              margin: EdgeInsets.only(left: quiet ? 4 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary ? (hover ? AppPalette.primaryHover : palette.orange) : (hover ? palette.line1 : Colors.transparent),
              ),
              child: Icon(icon, size: primary ? 22 : 20, color: primary ? palette.orangeInk : (quiet ? palette.inkSoft : palette.ink)),
            ),
          ),
        );
      },
    );
  }
}

/// 공용 시간축. 단계가 올라갈수록 행이 더해지고, 그 단계에서 새로 생긴 행은 강조한다. 위치는 모두 시간 / 구간 길이 비율이다.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.copy, required this.walk, required this.stage});

  final Map<String, String> copy;
  final Walkthrough walk;
  final int stage;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    final labelWidth = mobile ? 64.0 : 128.0;
    final duration = walk.durationMs;
    final showWords = stage >= 1;
    final showVad = stage >= 2;
    final showCuts = stage >= 3;
    final cues = showCuts ? walk.cues : (stage == 2 ? [walk.whole] : const <SubtitleCue>[]);
    final seconds = [for (var s = 0; s <= duration ~/ 1000; s += 1) s];
    double pct(int ms) => ms / duration;

    // track: 트랙 너비를 받아 그 안 요소의 위치를 계산한다.
    Widget row({required String label, required List<Widget> Function(double width) track, bool fresh = false, double height = 34, double bottom = 0}) =>
        AnimatedContainer(
          duration: motionDuration(context, Motion.med),
          margin: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(color: fresh ? palette.orangeTint : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              SizedBox(
                width: labelWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: KText(
                    label,
                    style: textStyle(size: mobile ? 11 : 12.5, color: palette.ink2, height: 1.3),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    border: Border.symmetric(vertical: BorderSide(color: palette.line3)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(clipBehavior: Clip.none, children: track(constraints.maxWidth)),
                  ),
                ),
              ),
            ],
          ),
        );

    final rows = <Widget>[
      Padding(
        padding: EdgeInsets.only(left: labelWidth),
        child: SizedBox(
          height: 16,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              clipBehavior: Clip.none,
              children: [
                for (final s in seconds)
                  Positioned(
                    left: pct(s * 1000) * constraints.maxWidth,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Text('$s', style: textStyle(size: 11, color: palette.ink3, tabular: true, height: 1.4)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ];

    if (stage == 3) {
      rows.add(
        row(
          label: copy['levels']!,
          fresh: true,
          track: (width) => [
            Positioned.fill(
              child: ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, level) in walk.levels.indexed) ...[
                      if (i > 0) const SizedBox(width: 1),
                      Expanded(
                        child: FractionallySizedBox(
                          heightFactor: level / 9,
                          alignment: Alignment.bottomCenter,
                          child: ColoredBox(color: palette.infoText.withValues(alpha: 0.8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (showVad) {
      rows.add(
        row(
          label: copy['vad']!,
          fresh: stage == 2,
          track: (width) => [
            for (final seg in walk.vad)
              Positioned(
                left: pct(seg.startMs) * width,
                width: pct(seg.endMs - seg.startMs) * width,
                top: 12,
                height: 10,
                child: HintTooltip(
                  message: '${_sec(seg.startMs)}–${_sec(seg.endMs)}',
                  child: Container(
                    decoration: BoxDecoration(color: palette.okLine, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    rows.add(
      row(
        label: showWords ? copy['words']! : '인식 구간',
        fresh: stage == 1,
        bottom: showCuts ? 14 : 0,
        track: (width) => [
          if (showWords)
            for (final word in walk.words)
              Positioned(
                left: pct(word.startMs) * width,
                width: pct(word.endMs - word.startMs) * width,
                top: 5,
                bottom: 5,
                child: HintTooltip(
                  message: '${word.text} ${_sec(word.startMs)}–${_sec(word.endMs)}',
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: word.risk != null && (stage <= 1 || stage == 4) ? palette.warnTint : palette.line4,
                      borderRadius: BorderRadius.circular(4),
                      border: word.risk != null && (stage <= 1 || stage == 4) ? Border.all(color: palette.warnText, width: 2) : null,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: mobile
                        ? null
                        : Text(
                            word.text,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: textStyle(size: 11, color: word.risk != null && (stage <= 1 || stage == 4) ? palette.warnText : palette.inkMax),
                          ),
                  ),
                ),
              )
          else
            Positioned(
              left: 0,
              right: 0,
              top: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(color: palette.line2, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  walk.rawText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle(size: 13, color: palette.ink),
                ),
              ),
            ),
          if (showCuts)
            for (final pause in walk.pauses)
              Positioned(
                left: pct((pause.startMs + pause.endMs) ~/ 2) * width,
                top: 34 - 4,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: palette.surface3, borderRadius: BorderRadius.circular(4)),
                    child: Text('${copy['pauseMark']} ${_sec(pause.ms)}', style: textStyle(size: 11, color: palette.infoText, height: 1.4)),
                  ),
                ),
              ),
        ],
      ),
    );
    if (cues.isNotEmpty) {
      rows.add(
        row(
          label: '${copy['raw']} · ${copy['display']}',
          fresh: stage == 2 || stage == 3,
          height: 30,
          track: (width) => [
            for (final cue in cues) ...[
              Positioned(
                left: pct(cue.displayStart) * width,
                width: pct(cue.displayEnd - cue.displayStart) * width,
                top: 4,
                bottom: 4,
                child: HintTooltip(
                  message: '${copy['display']} ${_sec(cue.displayStart)}–${_sec(cue.displayEnd)}',
                  child: _DashedCue(color: palette.orange),
                ),
              ),
              Positioned(
                left: pct(cue.startMs) * width,
                width: pct(cue.endMs - cue.startMs) * width,
                top: 9,
                bottom: 9,
                child: HintTooltip(
                  message: '${copy['raw']} ${_sec(cue.startMs)}–${_sec(cue.endMs)}',
                  child: Container(
                    decoration: BoxDecoration(color: palette.orange, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
            if (showCuts)
              for (final cut in walk.split.cuts)
                Positioned(
                  left: pct(walk.words[cut].endMs) * width - 1,
                  top: -6,
                  bottom: -6,
                  width: 2,
                  child: walk.split.disputed.contains(cut) ? _DashedVertical(color: palette.ink) : ColoredBox(color: palette.ink),
                ),
          ],
        ),
      );
    }

    final legend = Padding(
      padding: EdgeInsets.only(left: labelWidth),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Key(color: palette.line4),
          _legendText(copy['words']!, palette),
          if (showVad) ...[
            _Key(color: palette.okLine),
            _legendText(copy['vad']!, palette),
            _Key(color: palette.orange),
            _legendText(copy['raw']!, palette),
            _Key(color: null, border: palette.orange),
            _legendText(copy['display']!, palette),
          ],
          if (showCuts) ...[Container(width: 2, height: 12, margin: const EdgeInsets.only(left: 6), color: palette.ink), _legendText(copy['cut']!, palette)],
        ],
      ),
    );

    return Semantics(
      container: true,
      label: copy['timelineLabel'],
      child: Container(
        padding: mobile ? const EdgeInsets.symmetric(horizontal: 8, vertical: 10) : const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(color: palette.surface3, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, child) in [...rows, legend].indexed) ...[if (i > 0) const SizedBox(height: 8), child],
          ],
        ),
      ),
    );
  }

  Widget _legendText(String text, AppPalette palette) => KText(text, style: textStyle(size: 12, color: palette.ink3));
}

class _Key extends StatelessWidget {
  const _Key({required this.color, this.border});

  final Color? color;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
    width: 14,
    height: 8,
    margin: const EdgeInsets.only(left: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
      border: border == null ? null : Border.all(color: border!),
    ),
  );
}

class _DashedCue extends StatelessWidget {
  const _DashedCue({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashedRect(color));
}

class _DashedRect extends CustomPainter {
  const _DashedRect(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), const Radius.circular(6)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRect oldDelegate) => color != oldDelegate.color;
}

class _DashedVertical extends StatelessWidget {
  const _DashedVertical({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashedVerticalPainter(color));
}

class _DashedVerticalPainter extends CustomPainter {
  const _DashedVerticalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width;
    for (var y = 0.0; y < size.height; y += 12) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, (y + 6).clamp(0, size.height)), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedVerticalPainter oldDelegate) => color != oldDelegate.color;
}

class _StageDetail extends StatelessWidget {
  const _StageDetail({required this.content, required this.walk, required this.stageId, required this.decisions, required this.onDecide, required this.onUndo});

  final SubtitlesContent content;
  final Walkthrough walk;
  final String stageId;
  final Map<String, String> decisions;
  final void Function(String id, String value) onDecide;
  final ValueChanged<String> onUndo;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final copy = content.walkCopy;
    final fixture = content.fixture;
    final risky = walk.words.firstWhere((word) => word.risk != null);
    final body = textStyle(size: 14.5, color: palette.ink, height: 1.55);
    switch (stageId) {
      case 'asr':
        return _Facts(
          rows: [
            ('${fixture.referenceModel} 원문', _Quote(walk.rawText)),
            (
              '위험 표시',
              KRich([
                kSpan('${fixture.referenceModel}와 ${fixture.compareModel} 결과의 단어 내용이 다릅니다: '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _Mark(text: risky.text, alt: false),
                ),
                const TextSpan(text: ' / '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _Mark(text: risky.risk!, alt: true),
                ),
              ], style: body),
            ),
          ],
        );
      case 'align':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              label: copy['words'],
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final word in walk.words)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: word.risk != null ? palette.warnText : palette.line2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            word.text,
                            style: textStyle(size: 14, weight: FontWeight.w600, color: palette.ink),
                          ),
                          const SizedBox(height: 2),
                          Text('${_sec(word.startMs)}–${_sec(word.endMs)}', style: textStyle(size: 12, color: palette.ink3, tabular: true)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Facts(rows: [(copy['spoken']!, _Quote(walk.rawText)), (copy['displayText']!, _Quote(fixture.displayTexts.join(' ')))]),
          ],
        );
      case 'pad':
        final cue = walk.whole;
        final dim = textStyle(size: 14.5, color: palette.ink3, height: 1.55);
        return _Facts(
          grid: true,
          rows: [
            (copy['raw']!, Text('${_sec(cue.startMs)}–${_sec(cue.endMs)}초', style: body)),
            (
              copy['display']!,
              KRich([
                kSpan('${_sec(cue.displayStart)}–${_sec(cue.displayEnd)}초 '),
                kSpan('(앞 ${formatSeconds(cue.startMs - cue.displayStart)} · 뒤 ${formatSeconds(cue.displayEnd - cue.endMs)}, 최대 0.30초)', dim),
              ], style: body),
            ),
            (
              '길이',
              KRich([
                kSpan('${formatSeconds(cue.displayEnd - cue.displayStart)} · ${walk.rawText.replaceAll(RegExp(r'\s'), '').length}자 '),
                kSpan('(6초·30자 기준을 넘어 나누기 대상)', dim),
              ], style: body),
            ),
          ],
        );
      case 'split':
        return _SplitDetail(copy: copy, walk: walk);
      case 'review':
        return _ProposalCards(content: content, walk: walk, decisions: decisions, onDecide: onDecide, onUndo: onUndo);
      case 'srt':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: palette.surface3, borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ReadableText(
              toSrt(finalCues(walk, decisions)),
              label: 'SRT 결과',
              style: textStyle(size: 14, color: palette.ink, height: 1.6, mono: true),
            ),
          ),
        );
    }
    return const SizedBox.shrink();
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.rows, this.grid = false});

  final List<(String, Widget)> rows;
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    Widget item(String label, Widget value) => mobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KText(label, style: textStyle(size: 13, color: palette.ink3)),
              const SizedBox(height: 2),
              value,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: grid ? 110 : 140,
                child: KText(label, style: textStyle(size: 13, color: palette.ink3, height: 1.7)),
              ),
              const SizedBox(width: 12),
              Expanded(child: value),
            ],
          );
    final items = [for (final (label, value) in rows) item(label, value)];
    if (grid && !mobile) return EqualColumns(columns: 2, gap: 10, stretch: false, children: items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in items.indexed) ...[if (i > 0) const SizedBox(height: 10), child],
      ],
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface3,
        border: Border(left: BorderSide(color: palette.line4, width: 3)),
      ),
      child: KText(text, style: textStyle(size: 14.5, color: palette.ink, height: 1.55)),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.text, required this.alt});

  final String text;
  final bool alt;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: alt ? palette.surface3 : palette.warnTint, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: textStyle(size: 14.5, color: alt ? palette.ink : palette.warnText, height: 1.4)),
    );
  }
}

class _SplitDetail extends StatelessWidget {
  const _SplitDetail({required this.copy, required this.walk});

  final Map<String, String> copy;
  final Walkthrough walk;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    final split = walk.split;
    final dim = textStyle(size: 14, color: palette.ink3, height: 1.55);
    final sides = [
      for (final (who, cuts, reason) in [('Codex', split.codexCuts, split.codexReason), ('Claude', split.claudeCuts, split.claudeReason)])
        Semantics(
          container: true,
          label: '$who 문장 나누기',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.line2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  who,
                  style: textStyle(size: 16, weight: FontWeight.w700, color: palette.ink),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final cut in cuts)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: palette.surface3,
                          borderRadius: BorderRadius.circular(999),
                          border: split.disputed.contains(cut) ? Border.all(color: palette.infoText) : null,
                        ),
                        child: Text('${walk.words[cut].text} | ${walk.words[cut + 1].text}', style: textStyle(size: 13.5, color: palette.ink)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                KText(reason, style: dim),
              ],
            ),
          ),
        ),
    ];
    final listStyle = textStyle(size: 14, color: palette.ink, height: 1.55);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mobile)
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [sides[0], const SizedBox(height: 10), sides[1]])
        else
          EqualColumns(columns: 2, gap: 10, children: sides),
        const SizedBox(height: 12),
        Semantics(
          container: true,
          label: '${copy['round']} 기록',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final round in split.debate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: KRich([
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: palette.surface3, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          '${copy['round']} ${round.round}',
                          style: textStyle(size: 12.5, weight: FontWeight.w700, color: palette.infoText),
                        ),
                      ),
                    ),
                    kSpan('Claude ${round.claude} · ${round.reason}'),
                  ], style: listStyle),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          container: true,
          label: copy['cut'],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final cut in split.cuts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: KRich([
                    kSpan(
                      '${walk.words[cut].text} | ${walk.words[cut + 1].text}: 앞 자막 끝 ${_sec(walk.words[cut].endMs)}초 · 다음 자막 시작 ${_sec(walk.words[cut + 1].startMs)}초',
                    ),
                    kSpan(' (${split.disputed.contains(cut) ? '토론 후 합의' : copy['agree']}, 단어 시각에서)', dim),
                  ], style: listStyle),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// 바뀐 어절만 표시한다(같은 위치 어절 비교, 예시 문장은 어절 수가 같다).
List<(String, bool)> _diffWords(String before, String after) {
  final a = before.split(' ');
  return [for (final (i, word) in after.split(' ').indexed) (word, i >= a.length || word != a[i])];
}

class _ProposalCards extends StatelessWidget {
  const _ProposalCards({required this.content, required this.walk, required this.decisions, required this.onDecide, required this.onUndo});

  final SubtitlesContent content;
  final Walkthrough walk;
  final Map<String, String> decisions;
  final void Function(String id, String value) onDecide;
  final ValueChanged<String> onUndo;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final copy = content.walkCopy;
    final fixture = content.fixture;
    final cues = finalCues(walk, decisions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final proposal in walk.proposals)
          () {
            final original = walk.cues.firstWhere((cue) => cue.id == proposal.id);
            final decision = decisions[proposal.id] ?? 'pending';
            final result = cues.firstWhere((cue) => cue.id == proposal.id);
            final statusText = decision == 'accepted' ? '수락됨' : (decision == 'held' ? '보류됨' : '결정 전');
            final dim = textStyle(size: 15, color: palette.ink3);
            return Semantics(
              container: true,
              label: '교정 제안 ${proposal.id}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: decision == 'accepted' ? palette.orange : palette.line2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '교정 제안 · ${proposal.id}',
                              style: textStyle(size: 16, weight: FontWeight.w700, color: palette.ink),
                            ),
                            KText(
                              'Codex ${fixture.proposalOpinions['codex']} · Claude ${fixture.proposalOpinions['claude']} · ${copy['agree']}',
                              style: textStyle(size: 13, weight: FontWeight.w500, color: palette.ink3),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: decision == 'accepted' ? palette.orange : palette.surface3,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusText,
                            style: textStyle(size: 12.5, weight: FontWeight.w700, color: decision == 'accepted' ? palette.orangeInk : palette.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    KRich([TextSpan(text: '지금 ', style: dim), kSpan(original.text!)], style: textStyle(size: 15, color: palette.ink)),
                    const SizedBox(height: 4),
                    KRich([
                      TextSpan(text: '제안 ', style: dim),
                      for (final (i, (word, changed)) in _diffWords(original.text!, proposal.text).indexed) ...[
                        if (i > 0) const TextSpan(text: ' '),
                        if (changed)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(color: palette.orangeTint, borderRadius: BorderRadius.circular(3)),
                              child: Text(
                                word,
                                style: textStyle(size: 15, weight: FontWeight.w700, color: palette.orangeText),
                              ),
                            ),
                          )
                        else
                          kSpan(word),
                      ],
                    ], style: textStyle(size: 15, color: palette.ink)),
                    const SizedBox(height: 12),
                    _Facts(
                      grid: true,
                      rows: [
                        ('reason', KText(proposal.reason, style: textStyle(size: 14.5, color: palette.ink, height: 1.55))),
                        ('source', KText(proposal.source, style: textStyle(size: 14.5, color: palette.ink, height: 1.55))),
                        ('uncertainty', KText(proposal.uncertainty, style: textStyle(size: 14.5, color: palette.ink, height: 1.55))),
                        ('needsReview', Text(proposal.needsReview ? '예' : '아니요', style: textStyle(size: 14.5, color: palette.ink, height: 1.55))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DecisionButton(
                          label: copy['accept']!,
                          primary: true,
                          pressed: decision == 'accepted',
                          onPressed: () => onDecide(proposal.id, 'accepted'),
                        ),
                        _DecisionButton(label: copy['hold']!, pressed: decision == 'held', onPressed: () => onDecide(proposal.id, 'held')),
                        _DecisionButton(
                          label: copy['undo']!,
                          icon: PhosphorIconsRegular.arrowCounterClockwise,
                          quiet: true,
                          ariaDisabled: decision == 'pending',
                          onPressed: () => onUndo(proposal.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: KText(
                        result.alignmentStale == true ? copy['stale']! : '시간은 바뀌지 않습니다. 제안 형식에 시간 필드가 없습니다.',
                        style: textStyle(size: 14.5, color: palette.ink3, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }(),
      ],
    );
  }
}

/// .srt-btn: 44px 알약. primary 이고 눌린(수락) 상태면 주황 바탕.
class SrtButton extends StatelessWidget {
  const SrtButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.pressed,
    this.primary = false,
    this.quiet = false,
    this.ariaDisabled = false,
    this.onStage = false,
    this.focusNode,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool? pressed;
  final bool primary;
  final bool quiet;
  final bool ariaDisabled;

  /// 밝은 소개 판 위의 버튼(stage 잉크 고정).
  final bool onStage;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final on = pressed ?? false;
    return Pressable(
      onPressed: onPressed,
      ariaDisabled: ariaDisabled,
      toggled: pressed,
      focusNode: focusNode,
      semanticLabel: label,
      excludeChildSemantics: true,
      builder: (context, state) {
        final hover = state.hovered && !ariaDisabled;
        Color bg = Colors.transparent;
        Color border = quiet ? Colors.transparent : palette.line2;
        Color fg = quiet ? palette.ink2 : palette.ink;
        if (on) {
          border = palette.orange;
          fg = palette.orangeText;
          if (primary) {
            bg = palette.orange;
            fg = palette.orangeInk;
          }
        }
        if (onStage) {
          bg = Colors.transparent;
          border = hover || state.focused ? palette.stageInk3 : palette.stageLine;
          fg = palette.stageInk;
        } else if (hover && !(on && primary)) {
          bg = palette.hoverWash;
        }
        return AnimatedOpacity(
          duration: motionDuration(context, Motion.fast),
          opacity: ariaDisabled ? 0.4 : 1,
          child: AnimatedContainer(
            duration: motionDuration(context, Motion.fast),
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 8)],
                Text(
                  label,
                  style: textStyle(size: 14.5, weight: FontWeight.w600, color: fg),
                ),
                if (trailingIcon != null) ...[const SizedBox(width: 8), Icon(trailingIcon, size: 16, color: fg)],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.pressed,
    this.primary = false,
    this.quiet = false,
    this.ariaDisabled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool? pressed;
  final bool primary;
  final bool quiet;
  final bool ariaDisabled;

  @override
  Widget build(BuildContext context) =>
      SrtButton(label: label, onPressed: onPressed, icon: icon, pressed: pressed, primary: primary, quiet: quiet, ariaDisabled: ariaDisabled);
}
