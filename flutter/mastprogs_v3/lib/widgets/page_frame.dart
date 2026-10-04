// 상세 페이지 공용 틀(.wfd-shell · .wfd-top · .wfd-intro): 이력서로 돌아가기 + 테마 전환, 밝은 소개 판(h1 하나).
// AI-NOTE: /workflow·/sprite·/subtitles 가 같은 머리글 모양을 쓴다. 소개 판(stage)은 어두운 테마에서도 밝은 판이다.
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../app/app_scope.dart';
import '../app/layout.dart';
import '../app/theme/palette.dart';
import '../app/theme/typography.dart';
import 'k_text.dart';
import 'pressable.dart';
import 'theme_toggle.dart';

/// 가운데 정렬 최대 너비 1440 + 좌우 stage-inset 여백.
class ShellWidth extends StatelessWidget {
  const ShellWidth({super.key, required this.child, this.inset = true});

  final Widget child;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final metrics = ScreenMetrics.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: shellMaxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: inset ? metrics.stageInset : 0),
          child: child,
        ),
      ),
    );
  }
}

class DetailTopBar extends StatelessWidget {
  const DetailTopBar({super.key, required this.backLabel});

  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final navigator = AppServices.of(context).navigator;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Pressable(
                isLink: true,
                linkUrl: Uri.parse('/'),
                onPressed: () => navigator.go('/'),
                semanticLabel: backLabel,
                radius: BorderRadius.circular(6),
                excludeChildSemantics: true,
                builder: (context, state) => ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.arrowLeft, size: 18, color: state.hovered ? palette.ink : palette.ink2),
                        const SizedBox(width: 8),
                        Flexible(
                          child: KText(
                            backLabel,
                            style: textStyle(
                              size: 15,
                              color: state.hovered ? palette.ink : palette.ink2,
                              decoration: state.hovered ? TextDecoration.underline : null,
                              decorationColor: palette.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const ThemeToggle(compact: true),
        ],
      ),
    );
  }
}

/// .wfd-intro: 밝은 판 소개(눈썹 글 · h1 · 본문). extra 는 본문 아래(예: 상태 알약, 사례 버튼).
class DetailIntro extends StatelessWidget {
  const DetailIntro({super.key, required this.eyebrow, required this.title, required this.paragraphs, this.afterTitle, this.after});

  final String eyebrow;
  final String title;
  final List<String> paragraphs;
  final Widget? afterTitle;
  final Widget? after;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    return FocusRingColor(
      color: palette.orangeDeep,
      child: Container(
        width: double.infinity,
        padding: mobile ? const EdgeInsets.symmetric(horizontal: 16, vertical: 20) : const EdgeInsets.fromLTRB(32, 28, 32, 26),
        decoration: BoxDecoration(color: palette.stage, borderRadius: BorderRadius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KText(
              eyebrow,
              style: textStyle(size: 14, weight: FontWeight.w700, color: palette.orangeDeep),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Semantics(
                header: true,
                // 상세 페이지의 유일한 h1(원본 .wfd-intro__title).
                headingLevel: 1,
                child: KText(
                  title,
                  style: textStyle(size: mobile ? 24 : 32, weight: FontWeight.w700, color: palette.stageInk, height: 1.25, em: -0.03),
                ),
              ),
            ),
            ?afterTitle,
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, line) in paragraphs.indexed) ...[
                    if (i > 0) const SizedBox(height: 8),
                    KText(line, style: textStyle(size: 16, color: palette.stageInk2, height: 1.65)),
                  ],
                ],
              ),
            ),
            ?after,
          ],
        ),
      ),
    );
  }
}
