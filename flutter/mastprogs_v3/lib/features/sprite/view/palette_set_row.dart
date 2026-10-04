// 2행 팔레트 세트·적용 비율(React PaletteSetRow.jsx 이식). 1행(포인트 색 프리셋·직접 고르기·추가 외곽선)을 대신하지 않는다.
// AI-NOTE: 원본 내장 팔레트 10종 전체를 고르고 "팔레트 적용 비율"(0..100%)로 세트 색까지 얼마나 옮길지 정한다. 세트 색 견본(현재 프레임에
// 실제로 쓰인 색 표시)과 현재 출력의 색 점유율로 비율의 뜻을 바로 보여 준다. 목록 맨 앞 '원본 색상'(SOURCE_SET_ID)은 포인트 색·외곽선 결과 다음의
// 세트 매핑을 건너뛰는 뜻이며 1행의 '원본'(포인트 색 프리셋)과 다르다. 이때 비율 슬라이더는 비활성(값은 보존), 견본은 현재 출력 색이다.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../widgets/dashed.dart';
import '../../../widgets/hint_tooltip.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/pressable.dart';
import '../controller/pixel_studio_controller.dart';
import 'pixel_controls.dart';

const int _shareRows = 8;

String _pct(double value) {
  final rounded = (value * 1000).round() / 10;
  return '${rounded == rounded.truncateToDouble() ? rounded.toInt() : rounded}%';
}

class PaletteSetRow extends StatelessWidget {
  const PaletteSetRow({super.key, required this.controller});

  final PixelStudioController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final content = controller.page.content;
    final copy = content.copy;
    final sets = controller.studio!.sets;
    final resolved = controller.palette;
    final isSource = resolved.mode == 'source';
    final set = resolved.set;
    final ratio = controller.style.ratio;
    final shares = controller.shares;
    final used = {for (final entry in shares.entries) entry.hex};
    final usedCount = set == null ? 0 : set.colors.where(used.contains).length;
    final top = shares.entries.take(_shareRows).toList();

    final list = LayoutBuilder(
      builder: (context, constraints) {
        // grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)), gap 6.
        final columns = math.max(1, ((constraints.maxWidth + 6) / (150 + 6)).floor());
        final width = (constraints.maxWidth - 6 * (columns - 1)) / columns;
        final items = <Widget>[
          _SetButton(
            name: copy['sourceSet']!,
            count: copy['sourceSetMeta']!,
            current: isSource,
            colors: null,
            onPressed: () => controller.selectSet(content.sourceSetId),
          ),
          for (final item in sets)
            _SetButton(
              name: item.name,
              count: '${item.colors.length}${copy['colorsUnit']}',
              current: !isSource && set != null && item.id == set.id,
              colors: item.colors,
              onPressed: () => controller.selectSet(item.id),
            ),
        ];
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final item in items) SizedBox(width: width, child: item)],
        );
      },
    );

    final ratioLabel = Text(
      copy['ratio']!,
      style: textStyle(size: 13.5, weight: FontWeight.w600, color: palette.ink),
    );
    final ratioSlider = PixelRange(
      value: ratio.toDouble(),
      min: 0,
      max: 100,
      enabled: !isSource,
      label: copy['ratio'],
      valueText: isSource ? copy['sourceSetMeta'] : '${set!.name} $ratio%',
      valueTextOf: isSource ? null : (value) => '${set!.name} ${value.round()}%',
      onChanged: (value) => controller.setRatio(value.round()),
    );
    final ratioValue = SizedBox(
      width: 13.5 * 3.5,
      child: Text(
        isSource ? '—' : '$ratio%',
        textAlign: TextAlign.right,
        style: textStyle(size: 13.5, color: palette.ink, tabular: true),
      ),
    );
    final ratioRow = Opacity(
      opacity: isSource ? 0.55 : 1,
      child: metrics.mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ratioLabel,
                Row(
                  children: [
                    Expanded(child: ratioSlider),
                    const SizedBox(width: 10),
                    ratioValue,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                ratioLabel,
                const SizedBox(width: 10),
                Expanded(child: ratioSlider),
                const SizedBox(width: 10),
                ratioValue,
              ],
            ),
    );

    final swatches = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSource
              ? '${copy['sourceSet']} · ${copy['sourceColors']} ${shares.entries.length}${copy['colorsUnit']}'
              : '${copy['setColors']} ${set!.colors.length} · ${copy['setUsed']} $usedCount',
          style: textStyle(size: 12.5, color: palette.ink3, tabular: true),
        ),
        const SizedBox(height: 6),
        Semantics(
          container: true,
          label: isSource ? '${copy['sourceSet']} ${copy['sourceColors']}' : '${set!.name} ${copy['setColors']}',
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (isSource)
                for (final entry in shares.entries) _SwatchCell(hex: entry.hex, used: true, label: entry.hex)
              else
                for (final hex in set!.colors) _SwatchCell(hex: hex, used: used.contains(hex), label: used.contains(hex) ? '$hex · ${copy['setUsed']}' : hex),
            ],
          ),
        ),
      ],
    );

    final sharesView = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${copy['sharesTitle']}(${shares.entries.length}${copy['colorsUnit']})'),
              if (!isSource) ...[
                TextSpan(text: ' · ${copy['inSetShare']} '),
                TextSpan(
                  text: _pct(shares.inSetShare),
                  style: textStyle(size: 12.5, weight: FontWeight.w700, color: palette.ink, tabular: true),
                ),
              ],
            ],
          ),
          style: textStyle(size: 12.5, color: palette.ink3, tabular: true),
        ),
        const SizedBox(height: 6),
        ExcludeSemantics(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: palette.line2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in shares.entries)
                  Expanded(
                    flex: entry.count,
                    child: ColoredBox(color: hexColor(entry.hex)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          runSpacing: 3,
          children: [
            for (final entry in top)
              FractionallySizedBox(
                widthFactor: 0.5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: hexColor(entry.hex),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: palette.line3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 좁은 화면(390)에서 반 칸이 모자라면 넘치지 않고 잘린다(넓은 화면은 그대로).
                      Flexible(
                        child: Text(
                          entry.hex,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: textStyle(size: 12, mono: true, color: entry.inSet ? palette.ink : palette.ink3),
                        ),
                      ),
                      const Spacer(),
                      Text(_pct(entry.share), style: textStyle(size: 12, tabular: true, color: entry.inSet ? palette.ink : palette.ink3)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.line1)),
      ),
      child: Semantics(
        container: true,
        label: copy['setGroup'],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(child: Text(copy['setGroup']!, style: pixelLabelStyle(palette))),
            const SizedBox(height: 6),
            list,
            const SizedBox(height: 6),
            ratioRow,
            const SizedBox(height: 6),
            KText(isSource ? '${copy['sourceSetHint']} ${copy['ratioDisabled']}' : '${copy['ratioHint']} ${copy['setHint']}', style: pixelHintStyle(palette)),
            const SizedBox(height: 6),
            if (metrics.mobile)
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [swatches, const SizedBox(height: 14), sharesView])
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: swatches),
                  const SizedBox(width: 18),
                  Expanded(child: sharesView),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SetButton extends StatelessWidget {
  const _SetButton({required this.name, required this.count, required this.current, required this.colors, required this.onPressed});

  final String name;
  final String count;
  final bool current;
  final List<String>? colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onPressed: onPressed,
      toggled: current,
      semanticLabel: '$name $count',
      excludeChildSemantics: true,
      radius: BorderRadius.circular(10),
      builder: (context, state) => AnimatedContainer(
        duration: motionDuration(context, Motion.fast),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
        decoration: BoxDecoration(
          color: state.hovered ? palette.hoverWash : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: current ? palette.orange : palette.line2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle(size: 13, weight: current ? FontWeight.w600 : FontWeight.w400, color: current ? palette.ink : palette.ink2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(count, style: textStyle(size: 11.5, color: palette.ink3, tabular: true)),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 8,
              child: colors == null
                  ? DashedBox(color: palette.line3, radius: 3, child: const SizedBox.expand())
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [for (final hex in colors!) Expanded(child: ColoredBox(color: hexColor(hex)))],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsedOutlinePainter extends CustomPainter {
  const _UsedOutlinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)).inflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_UsedOutlinePainter oldDelegate) => color != oldDelegate.color;
}

class _SwatchCell extends StatelessWidget {
  const _SwatchCell({required this.hex, required this.used, required this.label});

  final String hex;
  final bool used;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return HintTooltip(
      message: hex,
      waitDuration: const Duration(milliseconds: 600),
      child: Semantics(
        label: label,
        child: Opacity(
          opacity: used ? 1 : 0.55,
          // 실제로 쓰인 색: 바깥 1px 띄운 2px 테두리(outline 2px, offset 1px). 테두리는 배치 크기에 넣지 않는다(원본 outline 과 같음).
          child: CustomPaint(
            foregroundPainter: used ? _UsedOutlinePainter(palette.ink) : null,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: hexColor(hex),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: palette.line2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
