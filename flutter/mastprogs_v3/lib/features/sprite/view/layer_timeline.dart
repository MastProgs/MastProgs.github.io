// Aseprite 식 "레이어 × 프레임" 표(React LayerTimeline.jsx 이식).
// AI-NOTE: 행 = 원본 레이어 20개(위가 앞, Aseprite 처럼 위에서부터), 열 = 현재 모션의 프레임. 칸은 실제 셀 데이터에서 나온다:
// 채운 칸 = 새 셀(직전 프레임과 위치·픽셀이 다름), 빈 테두리 = 직전과 같은 셀, 표시 없음 = 셀 없음, 점선 = 합성 참조.
// 현재 열(재생 헤드)은 재생 커서 하나를 그대로 따른다. 칸을 누르면 그 레이어를 고르고 그 프레임에서 멈춘다(포인터용 보조;
// 키보드는 위 프레임 번호 버튼과 행의 레이어 이름 버튼으로 같은 일을 한다). 표는 자기 영역(최대 440px) 안에서만 스크롤하고,
// 프레임 번호 줄과 레이어 이름 열은 스크롤해도 제자리에 남는다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../widgets/dashed.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/pressable.dart';
import '../controller/pixel_studio_controller.dart';
import '../model/pixel_layers.dart';
import 'pixel_controls.dart';

const double _row = 44;

class LayerTimeline extends StatefulWidget {
  const LayerTimeline({super.key, required this.controller});

  final PixelStudioController controller;

  @override
  State<LayerTimeline> createState() => _LayerTimelineState();
}

class _LayerTimelineState extends State<LayerTimeline> {
  final ScrollController _names = ScrollController();
  final ScrollController _cells = ScrollController();
  final ScrollController _horizontal = ScrollController();
  final ScrollController _header = ScrollController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _names.addListener(() => _sync(_names, _cells));
    _cells.addListener(() => _sync(_cells, _names));
    _horizontal.addListener(() => _sync(_horizontal, _header));
  }

  void _sync(ScrollController from, ScrollController to) {
    if (_syncing || !to.hasClients || !from.hasClients) return;
    _syncing = true;
    to.jumpTo(from.offset.clamp(to.position.minScrollExtent, to.position.maxScrollExtent));
    _syncing = false;
  }

  @override
  void dispose() {
    _names.dispose();
    _cells.dispose();
    _horizontal.dispose();
    _header.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final controller = widget.controller;
    final copy = controller.page.content.copy;
    final model = controller.model;
    final steps = controller.steps;
    final cursor = controller.playback.frame;
    final loop = controller.loop;
    final length = steps.length;
    final frame = model.frames[controller.frameIndex];
    final motionLabel = controller.motion.label;
    final atStart = !loop && cursor == 0;
    final atEnd = !loop && cursor == length - 1;
    final rows = model.layers.reversed.toList();
    final effective = controller.effectiveVisibility;
    int? previousStep(int step) => step > 0 ? steps[step - 1] : (loop ? steps[length - 1] : null);

    final buttons = [
      PixelButton(
        icon: PhosphorIconsBold.caretLeft,
        semanticLabel: copy['prevFrame'],
        tooltip: copy['prevFrame'],
        ariaDisabled: atStart,
        onPressed: () => controller.stepFrameBy(-1),
      ),
      const SizedBox(width: 8),
      PixelButton(
        icon: controller.playing ? PhosphorIconsFill.pause : PhosphorIconsFill.play,
        semanticLabel: controller.playing ? copy['pause'] : copy['play'],
        tooltip: controller.playing ? copy['pause'] : copy['play'],
        onPressed: controller.togglePlay,
      ),
      const SizedBox(width: 8),
      PixelButton(
        icon: PhosphorIconsBold.caretRight,
        semanticLabel: copy['nextFrame'],
        tooltip: copy['nextFrame'],
        ariaDisabled: atEnd,
        onPressed: () => controller.stepFrameBy(1),
      ),
      const SizedBox(width: 8),
    ];
    final slider = PixelRange(
      value: cursor.toDouble(),
      min: 0,
      max: (length - 1).toDouble(),
      label: copy['frameSlider'],
      valueText: '$motionLabel ${cursor + 1}/$length · ${frame.ms}ms',
      valueTextOf: (value) {
        final step = value.round().clamp(0, length - 1);
        return '$motionLabel ${step + 1}/$length · ${model.frames[steps[step]].ms}ms';
      },
      onChanged: (value) => controller.selectFrame(value.round()),
    );
    final position = Text('${cursor + 1}/$length · ${frame.ms}ms · ${frame.key}', style: textStyle(size: 12.5, color: palette.ink3, tabular: true));
    // flex-wrap: 슬라이더(최소 140px)가 들어갈 자리가 없으면 위치 글은 다음 줄로.
    final transport = LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 480
          ? Row(
              children: [
                ...buttons,
                Expanded(child: slider),
                const SizedBox(width: 8),
                position,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...buttons,
                    Expanded(child: slider),
                  ],
                ),
                const SizedBox(height: 6),
                position,
              ],
            ),
    );

    Widget nameCell(PixelLayer layer) {
      final label = controller.page.content.layerLabel(layer.name);
      final shown = effective[layer.index];
      final selected = layer.index == controller.selectedLayer;
      final visible = controller.visibility[layer.index];
      final eye = layer.isComposite
          ? SizedBox(width: 44, height: 44, child: Icon(PhosphorIconsRegular.eyeSlash, size: 16, color: palette.ink3))
          : Pressable(
              onPressed: () => controller.toggleLayer(layer.index),
              enabled: !controller.isolated,
              toggled: visible,
              semanticLabel: '$label ${visible ? copy['hideLayer'] : copy['showLayer']}',
              tooltip: '$label ${visible ? copy['hideLayer'] : copy['showLayer']}',
              excludeChildSemantics: true,
              radius: BorderRadius.circular(6),
              builder: (context, state) => Opacity(
                opacity: controller.isolated ? 0.4 : 1,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(visible ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash, size: 16, color: palette.ink2),
                ),
              ),
            );
      final name = layer.isComposite
          ? Text(copy['compositeRow']!, style: textStyle(size: 13, color: palette.ink3, height: 1.2))
          : Pressable(
              onPressed: () => controller.selectLayer(layer.index),
              toggled: selected,
              semanticLabel: '$label ${layer.name}',
              excludeChildSemantics: true,
              radius: BorderRadius.circular(6),
              builder: (context, state) => Opacity(
                opacity: shown ? 1 : 0.45,
                child: SizedBox(
                  height: 44,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      KText(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle(size: 13, color: palette.ink, height: 1.2),
                      ),
                      Text(
                        layer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle(size: 10.5, mono: true, color: palette.ink3, height: 1.2),
                      ),
                    ],
                  ),
                ),
              ),
            );
      return Container(
        height: _row,
        decoration: BoxDecoration(
          color: selected ? palette.surface2 : palette.surface,
          border: Border(
            right: BorderSide(color: palette.line2),
            bottom: BorderSide(color: palette.line1),
            left: selected ? BorderSide(color: palette.orange, width: 3) : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            eye,
            Expanded(child: name),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final firstColumn = constraints.maxWidth < 420 ? 170.0 : 200.0;
        final available = constraints.maxWidth - firstColumn - 2;
        final columnWidth = math.max(44.0, available / length);
        final cellsWidth = columnWidth * length;
        final gridHeight = math.min(440.0 - 2, _row * (rows.length + 1));

        Widget frameHeader() => Row(
          children: [
            for (var step = 0; step < length; step += 1)
              Pressable(
                onPressed: () => controller.selectFrame(step),
                toggled: step == cursor,
                semanticLabel: '$motionLabel ${step + 1}',
                excludeChildSemantics: true,
                radius: BorderRadius.zero,
                builder: (context, state) => Container(
                  width: columnWidth,
                  height: _row,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: step == cursor ? palette.orange : palette.surface,
                    border: Border(bottom: BorderSide(color: palette.line2)),
                  ),
                  child: Text(
                    '${step + 1}',
                    style: textStyle(
                      size: 12.5,
                      weight: step == cursor ? FontWeight.w700 : FontWeight.w400,
                      color: step == cursor ? palette.orangeInk : palette.ink3,
                      tabular: true,
                    ),
                  ),
                ),
              ),
          ],
        );

        final cells = Column(
          children: [
            for (final layer in rows)
              SizedBox(
                height: _row,
                child: Row(
                  children: [
                    for (var step = 0; step < length; step += 1)
                      _Cell(
                        width: columnWidth,
                        state: celState(model, steps[step], layer.index, previousStep(step)),
                        current: step == cursor,
                        selected: layer.index == controller.selectedLayer,
                        hidden: !effective[layer.index],
                        reference: layer.isComposite,
                        onTap: layer.isComposite ? null : () => controller.selectCell(layer.index, step),
                      ),
                  ],
                ),
              ),
          ],
        );

        final grid = Container(
          height: gridHeight + 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.line2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            container: true,
            label: copy['timeline'],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: firstColumn,
                  child: Column(
                    children: [
                      Container(
                        height: _row,
                        padding: const EdgeInsets.only(left: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: palette.surface,
                          border: Border(
                            bottom: BorderSide(color: palette.line2),
                            right: BorderSide(color: palette.line2),
                          ),
                        ),
                        child: Text(
                          copy['layerColumn']!,
                          style: textStyle(size: 12.5, weight: FontWeight.w600, color: palette.ink3),
                        ),
                      ),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                          child: ListView(controller: _names, padding: EdgeInsets.zero, children: [for (final layer in rows) nameCell(layer)]),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: _row,
                        child: SingleChildScrollView(
                          controller: _header,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: frameHeader(),
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _horizontal,
                          child: SingleChildScrollView(
                            controller: _horizontal,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: cellsWidth,
                              child: Scrollbar(
                                controller: _cells,
                                child: SingleChildScrollView(controller: _cells, child: cells),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            transport,
            const SizedBox(height: 10),
            grid,
            const SizedBox(height: 10),
            KText(copy['timelineLegend']!, style: pixelHintStyle(palette)),
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.width,
    required this.state,
    required this.current,
    required this.selected,
    required this.hidden,
    required this.reference,
    required this.onTap,
  });

  final double width;

  /// empty | same | key
  final String state;
  final bool current;
  final bool selected;
  final bool hidden;
  final bool reference;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget? marker;
    if (reference) {
      marker = DashedBox(color: palette.line4, radius: 3, width: 1.5, child: const SizedBox(width: 12, height: 12));
    } else if (state == 'key') {
      marker = Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: current ? palette.ink : palette.ink2, borderRadius: BorderRadius.circular(3)),
      );
    } else if (state == 'same') {
      marker = Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: palette.ink3, width: 1.5),
        ),
      );
    }
    final color = current ? palette.orangeTint : (selected ? palette.surface2 : Colors.transparent);
    return MouseRegion(
      cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      // 원본 칸은 aria-hidden(마우스 지름길). 키보드·보조 기술은 프레임 머리칸과 레이어 이름 버튼으로 같은 일을 한다.
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        child: Container(
          width: width,
          height: _row,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            border: Border(bottom: BorderSide(color: palette.line1)),
          ),
          child: marker == null
              ? null
              : Opacity(
                  opacity: hidden ? 0.35 : 1,
                  child: ExcludeSemantics(child: marker),
                ),
        ),
      ),
    );
  }
}
