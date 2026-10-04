// 같은 프레임 커서를 쓰는 보조 화면(React StudioInspector.jsx 이식).
// AI-NOTE: 선택 레이어의 실제 셀만 따로 그리고(같은 색 설정), 어니언·기준선을 켜고 끄며, 원본처럼 공통 기준점에 둔 결과와 "프레임마다 실루엣을 잘라
// 가운데 맞춘" 결과를 나란히 보여 준다. 오른쪽은 실제 프레임 픽셀을 실제 경계 상자로 옮긴 것이라 이동량(dx, dy)은 데이터에서 나온 값이다.
// 큰 RGBA 배열은 넘기지 않고 짧은 frameKey 로만 그림을 받는다.
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/dashed.dart';
import '../../../widgets/k_text.dart';
import '../controller/pixel_studio_controller.dart';
import '../model/pixel_layers.dart';
import 'pixel_controls.dart';
import 'pixel_image_view.dart';

class StudioInspector extends StatelessWidget {
  const StudioInspector({super.key, required this.controller});

  final PixelStudioController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    final copy = controller.page.content.copy;
    final model = controller.model;
    final layer = model.layers[controller.selectedLayer];
    final label = controller.page.content.layerLabel(layer.name);
    final bounds = celBounds(model, controller.frameIndex, controller.selectedLayer);
    final neighbors = controller.neighbors;
    final shift = controller.centering;
    String stepLabel(int? step) => step == null ? copy['onionNone']! : '${step + 1}';
    String signed(int value) => value > 0 ? '+$value' : '$value';
    final meta = pixelHintStyle(palette).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    final selectedCard = _Card(
      label: copy['selectedLayer']!,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${copy['selectedLayer']} '),
              TextSpan(
                text: label,
                style: textStyle(size: 13.5, weight: FontWeight.w700, color: palette.ink),
              ),
              TextSpan(
                text: '  ${layer.name}',
                style: textStyle(size: 11, mono: true, color: palette.ink3),
              ),
            ],
          ),
          style: textStyle(size: 13.5, weight: FontWeight.w600, color: palette.ink),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            _Mini(
              child: PixelImageView(
                controller: controller,
                kind: PixelImageKind.layer,
                frameKey: controller.frameKey(PixelImageKind.layer),
                semanticLabel: '${copy['selectedLayer']}: $label',
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(bounds != null ? 'x ${bounds.x} · y ${bounds.y} · ${bounds.w}×${bounds.h}' : copy['noCel']!, style: meta),
                const SizedBox(height: 4),
                ToggleSwitch(value: controller.isolated, label: copy['isolate']!, onChanged: (_) => controller.toggleIsolate()),
                const SizedBox(height: 4),
                PixelButton(icon: PhosphorIconsRegular.arrowCounterClockwise, label: copy['showAll'], onPressed: controller.resetLayers),
              ],
            ),
          ],
        ),
      ],
    );

    final onionCard = _Card(
      label: copy['onion']!,
      children: [
        ToggleSwitch(value: controller.onionOn, label: copy['onion']!, onChanged: (_) => controller.toggleOnion()),
        _RatioRow(
          label: copy['onionOpacity']!,
          value: (controller.onionOpacity * 100).roundToDouble(),
          min: 10,
          max: 100,
          step: 5,
          enabled: controller.onionOn,
          valueText: '${(controller.onionOpacity * 100).round()}%',
          valueTextOf: (value) => '${value.round()}%',
          onChanged: (value) => controller.setOnionOpacity(value / 100),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const _Chip(color: AppPalette.pixelOnionPrev),
            Text('${copy['onionPrev']} ${stepLabel(neighbors.prev)}', style: meta),
            const _Chip(color: AppPalette.pixelOnionNext),
            Text('${copy['onionNext']} ${stepLabel(neighbors.next)}', style: meta),
          ],
        ),
      ],
    );

    final guidesCard = _Card(
      label: copy['guides']!,
      children: [
        ToggleSwitch(value: controller.guidesOn, label: copy['guides']!, onChanged: (_) => controller.toggleGuides()),
        KText('${copy['guideReadout']} ${model.pivotX} · ${copy['soleRow']} ${model.soleRow} · ${copy['crownRow']} ${model.crownRow}', style: meta),
      ],
    );

    final guides = controller.guides;
    final w = controller.sprite.canvasWidth.toDouble();
    final h = controller.sprite.canvasHeight.toDouble();
    Widget guideMarks() => LayoutBuilder(
      builder: (context, constraints) {
        final pivot = (guides.pivotX + 0.5) / w * constraints.maxWidth;
        final sole = (guides.soleRow + 1) / h * constraints.maxHeight;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: pivot,
                top: 0,
                bottom: 0,
                child: DashedLine(color: palette.orange, vertical: true),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: sole,
                height: 1,
                child: ColoredBox(color: palette.orange),
              ),
            ],
          ),
        );
      },
    );

    final centerCard = _Card(
      label: copy['centerTitle']!,
      children: [
        Text(
          copy['centerTitle']!,
          style: textStyle(size: 13.5, weight: FontWeight.w600, color: palette.ink),
        ),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _Figure(
              mini: _Mini(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PixelImageView(
                      controller: controller,
                      kind: PixelImageKind.current,
                      frameKey: controller.frameKey(PixelImageKind.current),
                      semanticLabel: copy['centerCommon'],
                    ),
                    guideMarks(),
                  ],
                ),
              ),
              caption: [Text(copy['centerCommon']!, style: meta)],
            ),
            _Figure(
              mini: _Mini(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PixelImageView(
                      controller: controller,
                      kind: PixelImageKind.centered,
                      frameKey: controller.frameKey(PixelImageKind.centered),
                      semanticLabel: copy['centerTrim'],
                    ),
                    guideMarks(),
                  ],
                ),
              ),
              caption: [
                Text(copy['centerTrim']!, style: meta),
                Text('${copy['centerShift']} x ${signed(shift.dx)} · y ${signed(shift.dy)}', style: meta.copyWith(color: palette.ink)),
              ],
            ),
          ],
        ),
      ],
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, card) in [selectedCard, onionCard, guidesCard, centerCard].indexed) ...[if (i > 0) const SizedBox(height: 12), card],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        selectedCard,
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: onionCard),
              const SizedBox(width: 12),
              Expanded(child: guidesCard),
            ],
          ),
        ),
        const SizedBox(height: 12),
        centerCard,
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.line1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, child) in children.indexed) ...[if (i > 0) const SizedBox(height: 8), child],
          ],
        ),
      ),
    );
  }
}

/// 작은 캔버스(172px, 86:91, 체크무늬 16px).
class _Mini extends StatelessWidget {
  const _Mini({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 172,
    child: AspectRatio(
      aspectRatio: 86 / 91,
      child: CheckerBackground(cell: 16, radius: 8, child: child),
    ),
  );
}

class _Figure extends StatelessWidget {
  const _Figure({required this.mini, required this.caption});

  final Widget mini;
  final List<Widget> caption;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      mini,
      const SizedBox(height: 6),
      SizedBox(
        width: 172,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: caption),
      ),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    margin: const EdgeInsets.only(left: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
  );
}

/// .pixel-ratio: 라벨 | 슬라이더 | 값(3.5em, 오른쪽 정렬). 760px 이하에서는 라벨이 윗줄.
class _RatioRow extends StatelessWidget {
  const _RatioRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.valueText,
    this.valueTextOf,
    this.step = 1,
    this.enabled = true,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final bool enabled;
  final String valueText;
  final String Function(double value)? valueTextOf;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    final labelText = Text(
      label,
      style: textStyle(size: 13.5, weight: FontWeight.w600, color: palette.ink),
    );
    final slider = PixelRange(
      value: value,
      min: min,
      max: max,
      step: step,
      enabled: enabled,
      label: label,
      valueText: valueText,
      valueTextOf: valueTextOf,
      onChanged: onChanged,
    );
    final valueBox = SizedBox(
      width: 13.5 * 3.5,
      child: Text(
        valueText,
        textAlign: TextAlign.right,
        style: textStyle(size: 13.5, color: palette.ink, tabular: true),
      ),
    );
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          labelText,
          Row(
            children: [
              Expanded(child: slider),
              const SizedBox(width: 10),
              valueBox,
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        labelText,
        const SizedBox(width: 10),
        Expanded(child: slider),
        const SizedBox(width: 10),
        valueBox,
      ],
    );
  }
}
