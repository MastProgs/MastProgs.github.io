// 경로 선택(직접 처리 / 순차 / 독립 병렬, React ModeSwitch.jsx)과 시나리오 옵션 스위치(ScenarioOptions.jsx).
// AI-NOTE: 라디오 그룹 규칙: 선택된 항목만 Tab 으로 들어가고, 화살표/Home/End 로 이동과 동시에 선택한다. 선택 표시는 하나의 표시기가
// 미끄러진다(280ms, 동작 줄이기면 즉시). 페이지에 경로 선택은 하나뿐이다.
// 옵션: 경로에 해당하지 않는 옵션은 비활성이며 이유를 한 줄로 보인다. 직접 처리는 스위치 없이 이유 한 줄만(쓸 수 없는 옵션을 늘어놓지 않음).
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/pressable.dart';
import '../model/workflow_content.dart';
import '../model/workflow_scenario.dart';

class RouteMode {
  const RouteMode(this.id, this.label, this.hint);

  final String id;
  final String label;
  final String hint;
}

// 원본 src/workflow/constants.js MODES(라벨·설명 그대로, test 에서 constants.json 과 비교).
const List<RouteMode> routeModes = [
  RouteMode('direct', '직접 처리', '단순 요청은 단계를 늘리지 않습니다'),
  RouteMode('sequential', '순차', '역할 AI가 단계마다 작성하고 다른 제공사 AI가 교차 검토합니다'),
  RouteMode('parallel', '독립 병렬', '서로 의존하지 않는 작업만 병렬로 나누고, Wiki·통합에서 합칩니다'),
];

/// 탭/라디오 그룹의 화살표 키 이동 규칙(원본 lib/roving.js). 처리하지 않는 키는 null.
int? nextRovingIndex(LogicalKeyboardKey key, int index, int count, {bool both = false}) {
  if (count <= 0) return null;
  final prev = both ? [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowUp] : [LogicalKeyboardKey.arrowLeft];
  final next = both ? [LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.arrowDown] : [LogicalKeyboardKey.arrowRight];
  if (prev.contains(key)) return (index - 1 + count) % count;
  if (next.contains(key)) return (index + 1) % count;
  if (key == LogicalKeyboardKey.home) return 0;
  if (key == LogicalKeyboardKey.end) return count - 1;
  return null;
}

class RouteSwitch extends StatefulWidget {
  const RouteSwitch({super.key, required this.value, required this.onChanged, this.fullWidth = false});

  final String value;
  final ValueChanged<String> onChanged;
  final bool fullWidth;

  @override
  State<RouteSwitch> createState() => _RouteSwitchState();
}

class _RouteSwitchState extends State<RouteSwitch> {
  late final List<FocusNode> _nodes = [for (final mode in routeModes) FocusNode(debugLabel: 'route-${mode.id}')];

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final target = nextRovingIndex(event.logicalKey, index, routeModes.length, both: true);
    if (target == null) return KeyEventResult.ignored;
    widget.onChanged(routeModes[target].id);
    _nodes[target].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final checked = routeModes.indexWhere((mode) => mode.id == widget.value);
    final duration = motionDuration(context, const Duration(milliseconds: 280));
    final itemHeight = 44.0;
    // 원본 role="radiogroup" aria-label="실행 경로" + 각 항목 role="radio" aria-checked(방향키 로빙은 그대로).
    return Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      label: '실행 경로',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppPalette.segmentedBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.palette.stageLine),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final full = widget.fullWidth;
            final itemWidth = full ? (constraints.maxWidth / routeModes.length) : 95.0;
            return SizedBox(
              width: full ? constraints.maxWidth : null,
              height: itemHeight,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: duration,
                    curve: Motion.easeOut,
                    left: itemWidth * checked,
                    top: 0,
                    width: itemWidth,
                    height: itemHeight,
                    child: Container(
                      decoration: BoxDecoration(color: AppPalette.segmentedChecked, borderRadius: BorderRadius.circular(7)),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, mode) in routeModes.indexed)
                        Focus(
                          canRequestFocus: false,
                          skipTraversal: true,
                          onKeyEvent: (_, event) => _onKey(i, event),
                          child: SizedBox(
                            width: itemWidth,
                            height: itemHeight,
                            child: ExcludeFocusTraversal(
                              excluding: i != checked,
                              child: Pressable(
                                focusNode: _nodes[i],
                                radio: true,
                                checked: i == checked,
                                semanticLabel: mode.label,
                                tooltip: mode.hint,
                                excludeChildSemantics: true,
                                radius: BorderRadius.circular(7),
                                onPressed: () => widget.onChanged(mode.id),
                                builder: (context, state) => AnimatedContainer(
                                  duration: motionDuration(context, Motion.fast),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: i != checked && state.hovered ? const Color(0x0D000000) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: AnimatedDefaultTextStyle(
                                    duration: duration,
                                    style: textStyle(
                                      size: 15,
                                      em: -0.02,
                                      weight: i == checked ? FontWeight.w600 : FontWeight.w400,
                                      color: i == checked ? AppPalette.white : AppPalette.segmentedInk,
                                    ),
                                    child: Text(mode.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ScenarioOptionsView extends StatelessWidget {
  const ScenarioOptionsView({super.key, required this.content, required this.options, required this.onChanged});

  final WorkflowContent content;
  final ScenarioOptions options;
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final route = options.route;
    final hintStyle = textStyle(size: 13, color: palette.stageInk2, height: 1.5);
    final hint = route == 'direct' ? content.optionHint['direct'] : (route == 'parallel' ? content.optionHint['parallel'] : null);
    if (route == 'direct') {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: KText(hint!, style: hintStyle),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        container: true,
        label: '시나리오 옵션',
        hint: hint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 20,
              runSpacing: 4,
              children: [
                for (final option in content.scenarioOptions)
                  ToggleSwitch(
                    large: true,
                    value: option.routes.contains(route) && options.flag(option.id),
                    enabled: option.routes.contains(route),
                    label: option.label,
                    labelStyle: textStyle(size: 14, weight: FontWeight.w600, color: palette.stageInk),
                    onChanged: (value) => onChanged(option.id, value),
                  ),
              ],
            ),
            if (hint != null) ...[const SizedBox(height: 4), KText(hint, style: hintStyle)],
            if (route == 'parallel' && options.seed) ...[const SizedBox(height: 4), KText(content.optionHint['parallelSeed']!, style: hintStyle)],
          ],
        ),
      ),
    );
  }
}

/// 경로 선택 줄: 선택기 + "경로를 고르면 처음 프레임으로 돌아갑니다."
class RouteRow extends StatelessWidget {
  const RouteRow({super.key, required this.value, required this.hint, required this.onChanged});

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final phone = ScreenMetrics.of(context).atMost(Breakpoints.phone);
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (phone) RouteSwitch(value: value, onChanged: onChanged, fullWidth: true) else RouteSwitch(value: value, onChanged: onChanged),
        KText(hint, style: textStyle(size: 13.5, color: palette.stageInk3)),
      ],
    );
  }
}
