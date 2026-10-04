// Hero Pixel Studio 라이브 미리보기(React PixelStudioPreview.jsx 이식). /sprite 에만 마운트한다.
// AI-NOTE: 왼쪽 공통 캔버스(최근접 확대, 같은 기준점·발바닥 선) + 원본 GIF/프레임, 오른쪽 조작(재생·무작위 섞기·모션·팔레트·추가 외곽선 → 2행 팔레트 세트·
// 적용 비율). 아래 작업 화면: 레이어×프레임 타임라인, 선택 레이어·어니언·기준선·중심 비교, 골격 패널. 큰 캔버스는 원본 레이어 셀을 원본 규칙으로
// 합성한 결과이고(PNG/GIF 를 대신 쓰지 않음), 모든 화면이 재생 커서 하나를 따른다. 원본 GIF 는 스스로 멈출 수 없으므로 실제로 재생 중(화면 안·탭 보임·
// 재생 켬)일 때만 쓰고, 그 외에는 재생 커서가 가리키는 같은 원본 PNG 정지 화면이다. 원본 데이터를 만들 수 없으면 원본 GIF 로 대신한다.
// 색 직접 고르기는 브라우저 기본 색 선택 창을 연다(값은 화면 상태에만, 저장 없음).
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../core/public_assets.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/dashed.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/pressable.dart';
import '../controller/pixel_studio_controller.dart';
import '../model/pixel_layers.dart';
import '../model/pixel_playback.dart';
import 'layer_timeline.dart';
import 'palette_set_row.dart';
import 'pixel_controls.dart';
import 'pixel_image_view.dart';
import 'rig_panel.dart';
import 'studio_inspector.dart';

class StudioPreview extends StatelessWidget {
  const StudioPreview({super.key, required this.controller, required this.caseButtonFocus, required this.onOpenCase});

  final PixelStudioController controller;
  final FocusNode caseButtonFocus;
  final VoidCallback onOpenCase;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final copy = controller.page.content.copy;
    final head = _Head(copy: copy, focusNode: caseButtonFocus, onOpenCase: onOpenCase);
    return Container(
      padding: metrics.mobile ? const EdgeInsets.fromLTRB(14, 18, 14, 20) : const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.line1),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final stacked = metrics.atMost(Breakpoints.desktop);
          final stages = _Stages(controller: controller);
          final controls = _Controls(controller: controller);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              head,
              const SizedBox(height: 18),
              if (stacked)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: stages),
                    const SizedBox(height: 24),
                    controls,
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    stages,
                    const SizedBox(width: 32),
                    Expanded(child: controls),
                  ],
                ),
              if (controller.ready == StudioReady.ready) _Workspace(controller: controller),
            ],
          );
        },
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.copy, required this.focusNode, required this.onOpenCase});

  final Map<String, String> copy;
  final FocusNode focusNode;
  final VoidCallback onOpenCase;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    final title = Semantics(
      header: true,
      // 원본 <h2 className="pixel-preview__title">.
      headingLevel: 2,
      child: KText(
        copy['heading']!,
        style: textStyle(size: 20, weight: FontWeight.w700, em: -0.02, color: palette.ink),
      ),
    );
    final button = Pressable(
      focusNode: focusNode,
      onPressed: onOpenCase,
      semanticLabel: copy['openCase'],
      excludeChildSemantics: true,
      builder: (context, state) => AnimatedContainer(
        duration: motionDuration(context, Motion.fast),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: state.hovered ? palette.hoverWash : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.line2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              copy['openCase']!,
              style: textStyle(size: 14, weight: FontWeight.w600, color: palette.ink),
            ),
            const SizedBox(width: 6),
            Icon(PhosphorIconsRegular.arrowsOutSimple, size: 16, color: palette.ink),
          ],
        ),
      ),
    );
    final lead = KText(copy['lead']!, style: textStyle(size: 14.5, color: palette.ink2, height: 1.6));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mobile) ...[
          title,
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerLeft, child: button),
        ] else
          Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              button,
            ],
          ),
        const SizedBox(height: 6),
        lead,
      ],
    );
  }
}

class _Stages extends StatelessWidget {
  const _Stages({required this.controller});

  final PixelStudioController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final copy = controller.page.content.copy;
    final sprite = controller.sprite;
    final motion = controller.motion;
    final playback = controller.playback;
    final scale = metrics.atMost(Breakpoints.compact) ? 2.0 : 3.0;
    final w = sprite.canvasWidth.toDouble();
    final h = sprite.canvasHeight.toDouble();
    final ready = controller.ready == StudioReady.ready;
    final showGif = controller.active;
    final staticFrame = (playback.frame < motion.frames.length ? motion.frames[playback.frame] : motion.frames.first).src;

    final frameChildren = <Widget>[];
    if (ready && controller.guidesOn) {
      final guides = controller.guides;
      final sole = (guides.soleRow + 1) / h * h * scale;
      final crown = guides.crownRow / h * h * scale;
      final pivot = (guides.pivotX + 0.5) / w * w * scale;
      final width = w * scale;
      frameChildren.addAll([
        Positioned(
          top: crown,
          left: width * 0.1,
          right: width * 0.1,
          child: DashedLine(color: palette.line4),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: pivot,
          child: DashedLine(color: palette.line4, vertical: true),
        ),
        Positioned(
          top: sole,
          left: width * 0.1,
          right: width * 0.1,
          height: 2,
          child: ColoredBox(color: palette.line3),
        ),
        Positioned(
          top: sole - 10,
          left: pivot - 1,
          width: 2,
          height: 12,
          child: ColoredBox(color: palette.orange.withValues(alpha: 0.7)),
        ),
      ]);
    }
    if (ready) {
      frameChildren.add(
        Positioned.fill(
          child: PixelImageView(
            controller: controller,
            kind: PixelImageKind.stage,
            frameKey: controller.frameKey(PixelImageKind.stage),
            semanticLabel: '${copy['stageLabel']}: ${motion.label}',
          ),
        ),
      );
      final bounds = celBounds(controller.model, controller.frameIndex, controller.selectedLayer);
      if (bounds != null) {
        frameChildren.add(
          Positioned(
            left: (bounds.x + sprite.pad) * scale,
            top: (bounds.y + sprite.pad) * scale,
            width: bounds.w * scale,
            height: bounds.h * scale,
            child: IgnorePointer(
              child: DashedBox(color: palette.orange, child: const SizedBox.expand()),
            ),
          ),
        );
      }
    } else {
      frameChildren.add(
        Positioned.fill(
          child: Image.asset(
            publicAsset(controller.active ? motion.gif : staticFrame),
            key: ValueKey(controller.active ? motion.gif : staticFrame),
            semanticLabel: '${copy['original']}: ${motion.label}',
            filterQuality: FilterQuality.none,
            fit: BoxFit.fill,
            gaplessPlayback: true,
          ),
        ),
      );
    }

    final stage = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: w * scale,
          height: h * scale,
          child: CheckerBackground(
            cell: 24,
            radius: 14,
            child: Stack(clipBehavior: Clip.hardEdge, children: frameChildren),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: w * scale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 좁은 무대(390)에서도 넘치지 않게 이름 쪽이 줄어든다(넓은 화면은 그대로).
              Flexible(
                child: Text(
                  motion.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: textStyle(size: 13, weight: FontWeight.w700, color: palette.ink),
                ),
              ),
              Text(
                '${(playback.loop + 1).clamp(1, cyclesFor(motion.id))}/${cyclesFor(motion.id)}${copy['cycles']} · ${playback.frame + 1}/${motion.frames.length}',
                style: textStyle(size: 13, color: palette.ink3, tabular: true),
              ),
            ],
          ),
        ),
        if (!controller.inView && controller.playing) ScreenReaderOnly(copy['pausedOffscreen']!),
        if (controller.ready == StudioReady.fallback)
          SizedBox(
            width: w * scale,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: KText(copy['fallback']!, style: textStyle(size: 12.5, color: palette.ink3, height: 1.5)),
            ),
          ),
      ],
    );

    final original = ready
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 89,
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.line1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  publicAsset(showGif ? motion.gif : staticFrame),
                  key: ValueKey(showGif ? motion.gif : staticFrame),
                  semanticLabel: '${showGif ? copy['original'] : copy['originalStatic']}: ${motion.label}',
                  filterQuality: FilterQuality.none,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
              const SizedBox(height: 4),
              Text(showGif ? copy['original']! : copy['originalStatic']!, style: textStyle(size: 12, color: palette.ink3)),
            ],
          )
        : null;

    final wrap = metrics.atMost(Breakpoints.compact);
    if (original == null) return stage;
    return wrap
        ? Wrap(spacing: 14, runSpacing: 14, crossAxisAlignment: WrapCrossAlignment.end, children: [stage, original])
        : Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [stage, const SizedBox(width: 14), original]);
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller});

  final PixelStudioController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final copy = controller.page.content.copy;
    final style = controller.style;
    final platform = AppServices.of(context).platform;
    final group = <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PixelButton(
            primary: true,
            icon: controller.playing ? PhosphorIconsFill.pause : PhosphorIconsFill.play,
            semanticLabel: controller.playing ? copy['pause'] : copy['play'],
            tooltip: controller.playing ? copy['pause'] : copy['play'],
            onPressed: controller.togglePlay,
          ),
          PixelButton(icon: PhosphorIconsRegular.shuffle, label: copy['shuffle'], pressed: controller.shuffleOn, onPressed: controller.toggleShuffle),
        ],
      ),
      _Group(
        label: copy['motionGroup']!,
        child: Align(
          alignment: Alignment.centerLeft,
          child: PixelSegment(
            items: [for (final motion in controller.sprite.motions) (motion.id, motion.label)],
            current: controller.motion.id,
            onSelect: controller.selectMotion,
          ),
        ),
      ),
      _Group(
        label: copy['paletteGroup']!,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final preset in controller.page.content.presets)
              PixelSwatch(
                label: preset.label,
                leading: PresetChip(color: preset.accent == null ? null : hexColor(preset.accent!)),
                current: style.presetId == preset.id,
                pressed: style.presetId == preset.id,
                onPressed: () => controller.selectPreset(preset.id),
              ),
            PixelSwatch(
              label: copy['accentInput']!,
              leading: ColorWell(color: hexColor(style.customAccent ?? '#3a7bd5')),
              current: style.presetId == 'custom',
              onPressed: () => platform.pickColor(initial: style.customAccent ?? '#3a7bd5', onInput: controller.setAccent),
            ),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ToggleSwitch(value: style.outlineOn, label: copy['outline']!, onChanged: (_) => controller.toggleOutline()),
              // 색 입력은 실제로 그리는 외곽선 색(effectiveOutlineColor)을 보여 준다. 직접 고르면 manual, '자동 색' 으로 되돌린다.
              PixelSwatch(
                label: copy['outlineColor']!,
                leading: ColorWell(color: hexColor(controller.outlineColor)),
                current: style.outlineMode == 'manual',
                onPressed: () => platform.pickColor(initial: controller.outlineColor, onInput: controller.setOutlineColor),
              ),
              PixelButton(
                label: copy['outlineAuto'],
                pressed: style.outlineMode == 'auto',
                current: style.outlineMode == 'auto',
                onPressed: controller.setOutlineAuto,
              ),
            ],
          ),
          const SizedBox(height: 6),
          KText('${copy['outlineHint']} ${style.outlineMode == 'auto' ? copy['outlineAutoHint'] : copy['outlineManualHint']}', style: pixelHintStyle(palette)),
        ],
      ),
      if (controller.studio != null) PaletteSetRow(controller: controller),
      KText(controller.showcase ? copy['showcaseOn']! : copy['showcaseOff']!, style: pixelHintStyle(palette)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in group.indexed) ...[if (i > 0) const SizedBox(height: 14), child],
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: Text(label, style: pixelLabelStyle(context.palette))),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );
}

class _Workspace extends StatelessWidget {
  const _Workspace({required this.controller});

  final PixelStudioController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final stacked = ScreenMetrics.of(context).atMost(Breakpoints.desktop);
    final timeline = LayerTimeline(controller: controller);
    final inspector = StudioInspector(controller: controller);
    final rig = RigPanel(controller: controller);
    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.line1)),
      ),
      child: Semantics(
        container: true,
        label: controller.page.content.copy['workspace'],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stacked)
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [timeline, const SizedBox(height: 20), inspector])
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 13, child: timeline),
                  const SizedBox(width: 24),
                  Expanded(flex: 10, child: inspector),
                ],
              ),
            const SizedBox(height: 20),
            rig,
          ],
        ),
      ),
    );
  }
}
