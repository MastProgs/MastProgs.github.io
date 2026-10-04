// 가리키면 뜨는 보조 설명(원본의 title 속성 자리). 보기 전용이며 접근성 트리에는 아무것도 더하지 않는다.
// AI-NOTE: Material Tooltip 은 excludeFromSemantics 여도 떠 있는 동안 말풍선 글자 노드를 OverlayPortal 로 대상 아래에 이어 붙인다
// (overlay.dart traversalParentIdentifier). 그래서 브라우저 이름이 '다음 프레임 다음 프레임' 처럼 겹쳤다.
// 같은 RawTooltip 위에 Material 기본값(어두운 테마 흰 바탕 0.9·밝은 테마 grey700 0.9, 반지름 4, 데스크톱 높이 24·글자 12·여백 8×4,
// 아래쪽 24px)을 그대로 쓰되 말풍선을 ExcludeSemantics 로 감싸 이름은 대상 위젯의 label 하나만 남긴다.
import 'package:flutter/material.dart';

class HintTooltip extends StatelessWidget {
  const HintTooltip({super.key, required this.message, required this.child, this.waitDuration = Duration.zero});

  final String message;
  final Duration waitDuration;
  final Widget child;

  static const double _verticalOffset = 24;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return child;
    final theme = Theme.of(context);
    final desktop = switch (theme.platform) {
      TargetPlatform.macOS || TargetPlatform.linux || TargetPlatform.windows => true,
      TargetPlatform.android || TargetPlatform.fuchsia || TargetPlatform.iOS => false,
    };
    final dark = theme.brightness == Brightness.dark;
    final textStyle = theme.textTheme.bodyMedium!.copyWith(color: dark ? Colors.black : Colors.white, fontSize: desktop ? 12 : 14);
    final decoration = BoxDecoration(
      color: dark ? Colors.white.withValues(alpha: 0.9) : Colors.grey[700]!.withValues(alpha: 0.9),
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    );
    return RawTooltip(
      // null: 대상 노드에 tooltip 문자열도 붙이지 않는다(이름은 대상의 label).
      semanticsTooltip: null,
      hoverDelay: waitDuration,
      positionDelegate: (context) => positionDependentBox(
        size: context.overlaySize,
        childSize: context.tooltipSize,
        target: context.target,
        verticalOffset: _verticalOffset,
        preferBelow: true,
      ),
      tooltipBuilder: (context, animation) => ExcludeSemantics(
        child: IgnorePointer(
          child: FadeTransition(
            opacity: animation,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: desktop ? 24 : 32),
              child: DefaultTextStyle(
                style: textStyle,
                child: Container(
                  decoration: decoration,
                  padding: EdgeInsets.symmetric(horizontal: desktop ? 8 : 16, vertical: 4),
                  child: Center(widthFactor: 1, heightFactor: 1, child: Text(message, style: textStyle)),
                ),
              ),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
