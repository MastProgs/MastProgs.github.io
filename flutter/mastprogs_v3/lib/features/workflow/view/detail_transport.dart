// 직접 처리·순차·독립 병렬 공용 프레임 재생기(음악 재생기형, React DetailTransport.jsx 이식).
// AI-NOTE: 바깥 모양은 하나의 둥근 판이며 고정(sticky) 상태에서도 같은 모양이다(위만 둥글고 아래가 각진 막대 금지).
// 조작: 이전 프레임 · 재생/일시정지 · 다음 프레임 · 처음으로, 프레임 위치 슬라이더(0..total 정수), 현재 프레임 번호·제목,
// 속도(0.5·1·2배 — 넘김 간격만 바뀜), 현재 프레임 따라가기 스위치(기본 켬). 이전·위치 이동·다음은 리듀서에서 일시정지로 멈춘다.
// 끝에 닿으면 재생 버튼은 처음부터 다시 재생(자동 반복 없음). 경계에서는 aria-disabled 로 포커스를 남긴다. 누를 곳은 모두 44px 이상.
// 전역 단축키는 두지 않는다(입력 중 키를 가로채지 않음).
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../core/js_compat.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/hint_tooltip.dart';
import '../../../widgets/pressable.dart';
import '../controller/workflow_player_controller.dart';
import '../model/workflow_frames.dart';
import '../model/workflow_reducer.dart';

class DetailTransport extends StatelessWidget {
  const DetailTransport({super.key, required this.controller});

  final WorkflowPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    final state = controller.state;
    final scenario = controller.scenario;
    final copy = controller.content.copy;
    final total = scenario.total;
    final cursor = state.cursor;
    final running = state.status == RunStatus.running;
    final done = state.status == RunStatus.done;
    final atStart = cursor == 0 && state.status == RunStatus.idle;
    final atFirst = cursor == 0;
    final playLabel = running ? '일시정지' : (done ? '처음부터 다시 재생' : '재생');
    final title = controller.frame.title;

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TransportButton(icon: PhosphorIconsFill.skipBack, label: '이전 프레임', ariaDisabled: atFirst, onPressed: controller.prev),
        SizedBox(width: mobile ? 2 : 6),
        _TransportButton(
          icon: running ? PhosphorIconsFill.pause : PhosphorIconsFill.play,
          label: playLabel,
          primary: true,
          onPressed: running ? controller.pause : controller.play,
        ),
        SizedBox(width: mobile ? 2 : 6),
        _TransportButton(icon: PhosphorIconsFill.skipForward, label: '다음 프레임', ariaDisabled: done, onPressed: controller.next),
        SizedBox(width: mobile ? 2 : 10),
        _TransportButton(icon: PhosphorIconsRegular.arrowCounterClockwise, label: '처음으로', quiet: true, ariaDisabled: atStart, onPressed: controller.reset),
      ],
    );

    final now = Padding(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 4 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(copy['frameLabel']!, style: textStyle(size: 13, color: palette.inkSoft)),
              Text(
                '${padZero(cursor)} / ${padZero(total)}',
                style: textStyle(size: 15, weight: FontWeight.w700, color: palette.ink, tabular: true, height: 1.3),
              ),
              Text(state.status.label, style: textStyle(size: 13, color: running ? palette.orange : palette.inkSoft)),
            ],
          ),
          const SizedBox(height: 2),
          HintTooltip(
            message: title,
            waitDuration: const Duration(milliseconds: 600),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle(size: mobile ? 15 : 16, weight: FontWeight.w600, color: palette.ink),
            ),
          ),
        ],
      ),
    );

    final extra = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SpeedSelect(controller: controller, compact: mobile),
        const SizedBox(width: 6),
        _FollowButton(controller: controller, iconOnly: mobile),
      ],
    );

    final scrub = RangeInput(
      value: cursor.toDouble(),
      min: 0,
      max: total.toDouble(),
      label: copy['frameSlider'],
      valueText: '${copy['frameLabel']} $cursor / $total, $title',
      valueTextOf: (value) => '${copy['frameLabel']} ${value.round()} / $total, ${frameTitle(controller.frame.scenario, value.round())}',
      thumbColor: palette.inkMax,
      onChanged: (value) => controller.seek(value.round()),
    );

    return Semantics(
      container: true,
      label: '프레임 재생기',
      child: Container(
        padding: mobile ? const EdgeInsets.fromLTRB(10, 8, 10, 4) : const EdgeInsets.fromLTRB(18, 12, 18, 8),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(mobile ? 24 : 28),
          boxShadow: const [BoxShadow(color: AppPalette.transportShadow, blurRadius: 28, offset: Offset(0, 10))],
        ),
        child: mobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [controls, extra]),
                  const SizedBox(height: 2),
                  now,
                  const SizedBox(height: 2),
                  scrub,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      controls,
                      const SizedBox(width: 18),
                      Expanded(child: now),
                      const SizedBox(width: 18),
                      extra,
                    ],
                  ),
                  const SizedBox(height: 4),
                  scrub,
                ],
              ),
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.quiet = false,
    this.ariaDisabled = false,
  });

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
        final Color bg = primary ? (hover ? AppPalette.primaryHover : palette.orange) : (hover ? palette.line1 : Colors.transparent);
        final Color fg = primary ? palette.orangeInk : (quiet ? palette.inkSoft : palette.ink);
        return AnimatedOpacity(
          duration: motionDuration(context, Motion.fast),
          opacity: ariaDisabled ? 0.35 : 1,
          child: AnimatedScale(
            duration: motionDuration(context, Motion.fast),
            scale: state.pressed && !ariaDisabled ? 0.94 : 1,
            child: AnimatedContainer(
              duration: motionDuration(context, Motion.fast),
              width: size,
              height: size,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: primary ? 24 : 20, color: fg),
            ),
          ),
        );
      },
    );
  }
}

/// 속도 선택(0.5·1·2배). 원본 <select> 처럼 키보드(화살표·Enter)와 포인터로 고른다.
// AI-NOTE: 접근성 이름은 "재생 속도"(label) + 지금 값(value) 한 번만. PopupMenuButton 의 기본 Tooltip 이름과 안쪽 글자가
// 겹쳐 '재생 속도 재생 속도 2배 2배' 로 읽혔으므로, 바깥 노드 하나가 이름·값·열기(onTap)를 갖고 안쪽 의미는 뺀다.
// 보이는 보조 설명은 HintTooltip(접근성 이름에 붙지 않음)으로 둔다.
class _SpeedSelect extends StatefulWidget {
  const _SpeedSelect({required this.controller, required this.compact});

  final WorkflowPlayerController controller;
  final bool compact;

  @override
  State<_SpeedSelect> createState() => _SpeedSelectState();
}

class _SpeedSelectState extends State<_SpeedSelect> {
  final GlobalKey<PopupMenuButtonState<double>> _menu = GlobalKey<PopupMenuButtonState<double>>();

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final compact = widget.compact;
    final palette = context.palette;
    final options = controller.content.speedOptions;
    final current = options.firstWhere((option) => option.value == controller.state.speed, orElse: () => options[1]);
    final speedLabel = controller.content.copy['speedLabel']!;
    return Semantics(
      container: true,
      button: true,
      label: speedLabel,
      value: current.label,
      onTap: () => _menu.currentState?.showButtonMenu(),
      excludeSemantics: true,
      child: HintTooltip(
        message: speedLabel,
        waitDuration: const Duration(milliseconds: 600),
        child: Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              color: palette.surface2,
              textStyle: textStyle(size: 14, color: palette.ink),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: palette.line2),
              ),
            ),
          ),
          child: PopupMenuButton<double>(
            key: _menu,
            // 빈 문자열: Material Tooltip 을 만들지 않는다(보조 설명은 위 HintTooltip).
            tooltip: '',
            initialValue: current.value,
            onSelected: controller.setSpeed,
            position: PopupMenuPosition.under,
            itemBuilder: (context) => [
              for (final option in options)
                PopupMenuItem<double>(
                  value: option.value,
                  height: 44,
                  child: Text(
                    option.label,
                    style: textStyle(size: 14, color: palette.ink, weight: option.value == current.value ? FontWeight.w700 : FontWeight.w400),
                  ),
                ),
            ],
            child: Container(
              constraints: BoxConstraints(minWidth: compact ? 64 : 72, minHeight: 44),
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: palette.line2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(current.label, style: textStyle(size: 14, color: palette.ink)),
                  const SizedBox(width: 6),
                  Icon(PhosphorIconsBold.caretDown, size: 12, color: palette.ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.controller, required this.iconOnly});

  final WorkflowPlayerController controller;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final follow = controller.follow;
    final label = controller.content.copy['followLabel']!;
    return Pressable(
      onPressed: () => controller.setFollow(!follow),
      toggled: follow,
      semanticLabel: label,
      tooltip: label,
      excludeChildSemantics: true,
      builder: (context, state) => AnimatedContainer(
        duration: motionDuration(context, Motion.fast),
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : 14),
        decoration: BoxDecoration(
          color: state.hovered ? palette.line1 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: follow ? palette.orange : palette.line2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(follow ? PhosphorIconsBold.crosshair : PhosphorIconsRegular.crosshair, size: 18, color: follow ? palette.ink : palette.inkSoft),
            if (!iconOnly) ...[const SizedBox(width: 6), Text(label, style: textStyle(size: 13.5, color: follow ? palette.ink : palette.inkSoft))],
          ],
        ),
      ),
    );
  }
}
