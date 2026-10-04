// 메인 이력서 공용 조각: 섹션 틀(.resume-section), 섹션 제목(.section-title), 블록 제목, 앵커 링크.
import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/pressable.dart';
import 'portfolio_scope.dart';

/// .resume-section: 위쪽 72px, 좌우 stage-inset, 안쪽 28/21px(모바일 24/8px), 위 가는 선.
class ResumeSection extends StatelessWidget {
  const ResumeSection({super.key, required this.anchorId, required this.child});

  final String anchorId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    return Padding(
      key: PortfolioScope.of(context).anchors.keyFor(anchorId),
      padding: EdgeInsets.fromLTRB(metrics.stageInset, 72, metrics.stageInset, 0),
      child: Container(
        padding: metrics.mobile ? const EdgeInsets.fromLTRB(8, 24, 8, 0) : const EdgeInsets.fromLTRB(21, 28, 21, 0),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.line)),
        ),
        child: child,
      ),
    );
  }
}

/// .section-title: 번호(22px, 옅은 색) + 제목(28px 굵게), 기준선 맞춤. heading=false 면 제목 요소가 아닌 문단(01 소개).
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.index, required this.title, this.heading = true});

  final String index;
  final String title;
  final bool heading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(index, style: textStyle(size: 22, color: palette.ink3, tabular: true, height: 1.5)),
        const SizedBox(width: 28),
        Flexible(
          child: KText(
            title,
            style: textStyle(size: 28, weight: FontWeight.w700, em: -0.03, color: palette.ink, height: 1.5),
          ),
        ),
      ],
    );
    // 원본 <h2 className="section-title">(01 소개만 <p>).
    return Semantics(header: heading, headingLevel: heading ? 2 : null, label: '$index $title', excludeSemantics: true, child: row);
  }
}

/// .resume-section__head: 제목과 한 줄 소개(오른쪽, 줄바꿈 허용).
class SectionHead extends StatelessWidget {
  const SectionHead({super.key, required this.title, this.lede});

  final Widget title;
  final String? lede;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 32,
      runSpacing: 8,
      children: [
        title,
        if (lede != null) KText(lede!, style: textStyle(size: 15, color: palette.ink3, em: -0.01)),
      ],
    );
  }
}

/// .profile__block-title: 15px 굵게 + 아래 가는 선.
class BlockTitle extends StatelessWidget {
  const BlockTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: Semantics(
        header: true,
        // 원본 <h3 className="profile__block-title">.
        headingLevel: 3,
        child: KText(
          text,
          style: textStyle(size: 15, weight: FontWeight.w600, em: -0.01, color: palette.ink),
        ),
      ),
    );
  }
}

/// 같은 페이지 앵커로 가는 글자 링크(헤더 이력 열의 밑줄이 자라는 효과 포함).
class AnchorTextLink extends StatelessWidget {
  const AnchorTextLink({super.key, required this.label, required this.anchor, this.style, this.hoverColor, this.growUnderline = false});

  final String label;
  final String anchor;
  final TextStyle? style;
  final Color? hoverColor;
  final bool growUnderline;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scope = PortfolioScope.of(context);
    return Pressable(
      isLink: true,
      linkUrl: Uri(fragment: anchor),
      semanticLabel: label,
      excludeChildSemantics: true,
      radius: BorderRadius.circular(4),
      onPressed: () => scope.onAnchor(anchor),
      builder: (context, state) {
        final active = state.hovered || state.focused;
        final base = style ?? textStyle(size: 15, color: palette.ink2);
        final color = active ? (hoverColor ?? palette.ink) : base.color;
        final text = KText(label, style: base.copyWith(color: color));
        if (!growUnderline) return text;
        return Stack(
          children: [
            text,
            Positioned(
              left: 0,
              bottom: 0,
              child: LayoutBuilder(
                builder: (context, _) => AnimatedContainer(
                  duration: motionDuration(context, Motion.med),
                  curve: Motion.easeOut,
                  height: 1,
                  width: active ? _textWidth(label, base) : 0,
                  color: color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _textWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}
