// 처리 원리 도식(원본 앱 화면 캡처가 없는 사례: Voice to SRT). React CaseDiagram.jsx 이식.
// AI-NOTE: 실제 화면처럼 보이게 꾸미지 않고, 처리 순서를 의미 있는 목록과 Phosphor 아이콘으로만 그린다(장식 그림 없음).
// 사례 카드(compact)와 대화상자·메인 요약이 같은 데이터를 쓴다. 단계 사이 흐름선은 같은 줄의 다음 칸으로만 이어진다.
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../core/js_compat.dart';
import '../../../widgets/k_text.dart';
import '../portfolio_content.dart';

const Map<String, IconData> _stepIcons = {
  'audio': PhosphorIconsRegular.waveform,
  'asr': PhosphorIconsRegular.microphone,
  'align': PhosphorIconsRegular.ruler,
  'split': PhosphorIconsRegular.scissors,
  'review': PhosphorIconsRegular.chatsCircle,
  'human': PhosphorIconsRegular.userCheck,
};

class CaseDiagram extends StatelessWidget {
  const CaseDiagram({super.key, required this.diagram, this.compact = false, this.columns = 3});

  final CaseDiagramData diagram;
  final bool compact;

  /// 한 줄 칸 수(기본 3, 좁은 화면 2). 흐름선은 3열일 때만 그린다(원본 CSS 와 같음).
  final int columns;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    const gap = 10.0;
    final rows = <Widget>[];
    for (var start = 0; start < diagram.steps.length; start += columns) {
      final cells = <Widget>[];
      for (var c = 0; c < columns; c += 1) {
        final index = start + c;
        if (c > 0) cells.add(const SizedBox(width: gap));
        if (index >= diagram.steps.length) {
          cells.add(const Expanded(child: SizedBox.shrink()));
          continue;
        }
        final step = diagram.steps[index];
        final connector = columns == 3 && (index + 1) % 3 != 0 && index != diagram.steps.length - 1;
        cells.add(
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                _StepCard(step: step, number: index + 1, compact: compact),
                if (connector)
                  Positioned(
                    right: -gap,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(width: gap, height: 2, color: palette.orangeDeep),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells),
        ),
      );
    }
    final list = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    return DefaultTextStyle.merge(
      style: TextStyle(color: palette.stageInk),
      child: compact ? ExcludeSemantics(child: list) : Semantics(label: diagram.label, container: true, child: list),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.number, required this.compact});

  final DiagramStep step;
  final int number;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: compact ? const EdgeInsets.all(10) : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.stage,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.stageLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            padZero(number),
            style: textStyle(size: 11.5, weight: FontWeight.w700, color: palette.stageInk3, tabular: true),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(_stepIcons[step.id] ?? PhosphorIconsRegular.waveform, size: compact ? 18 : 22, color: palette.orangeDeep),
              const SizedBox(width: 8),
              Expanded(
                child: KText(
                  step.label,
                  style: textStyle(size: compact ? 13 : 14, weight: FontWeight.w700, color: palette.stageInk, height: 1.3, em: -0.02),
                ),
              ),
            ],
          ),
          if (!compact) ...[const SizedBox(height: 4), KText(step.note, style: textStyle(size: 12.5, color: palette.stageInk2, height: 1.4))],
        ],
      ),
    );
  }
}
