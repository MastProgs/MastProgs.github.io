// 테마 전환 버튼(메인 헤더·모바일 헤더·고정 바·상세 페이지 상단 공용). 현재 테마 이름을 보이고, 누르면 반대 테마로 바뀐다.
// compact: 520px 이하에서 글자를 숨기고 아이콘만(접근 이름은 유지, 44px).
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../app/app_scope.dart';
import '../app/layout.dart';
import '../app/theme/palette.dart';
import '../app/theme/typography.dart';
import 'pressable.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = AppServices.of(context).theme;
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        final palette = context.palette;
        final copy = theme.copy;
        final iconOnly = compact && ScreenMetrics.of(context).atMost(Breakpoints.compact);
        final reduced = ReducedMotion.of(context);
        return Pressable(
          onPressed: theme.toggle,
          semanticLabel: copy.switchTo,
          tooltip: copy.switchTo,
          excludeChildSemantics: true,
          builder: (context, state) => AnimatedContainer(
            duration: motionDuration(context, Motion.fast),
            height: 44,
            constraints: const BoxConstraints(minWidth: 44),
            padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : 14),
            decoration: BoxDecoration(
              color: state.hovered ? palette.hoverWash : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: state.hovered ? palette.line4 : palette.line2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedRotation(
                  duration: reduced ? Duration.zero : Motion.med,
                  curve: Motion.easeOut,
                  turns: state.hovered && !reduced ? -18 / 360 : 0,
                  child: Icon(theme.isDark ? PhosphorIconsBold.moon : PhosphorIconsBold.sun, size: 18, color: palette.ink),
                ),
                if (!iconOnly) ...[
                  const SizedBox(width: 8),
                  Text(
                    copy.label,
                    style: textStyle(size: 14, weight: FontWeight.w600, color: palette.ink, height: 1.2),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
