// 01 소개(React ProfileSection.jsx + Hero.jsx ProfileTheme + ContactSlots.jsx 이식).
// AI-NOTE: 사용자 지시("이력서니까 소개 자체를 제일 위로")에 따라 페이지 첫 섹션이며, 페이지의 유일한 h1 은 이름이다.
// 섹션 번호 줄은 같은 모양을 유지한 채 제목 요소가 아닌 문단으로 둬서 첫 제목이 사람을 가리키게 한다.
// 연락처 칸은 대화상자가 아니라 이름 바로 아래에 항상 보인다(#contact). 사진은 섹션 왼쪽 기준선에 두고 이름·연락처를 바로 오른쪽 한 열로 묶는다
// (데스크톱: 사진 위 = 이름 위, 연락처 아래 = 사진 아래 / 760px 이하: 96px 사진 옆 이름(사진 아래선에 맞춤), 연락처는 아래 전체 폭).
// 대표 주제("불필요하게 반복하는 일을 검증된 자동화 AI 워크플로우로")는 사진·연락처 줄 바로 아래, 자기소개 앞에 둔다. 두 줄 사이는 실제 공백(낭독용)이다.
// 이메일·전화는 사용자가 직접 입력하고 공개를 확인한 값을 일반 텍스트로 보인다. 값이 비면 점선 칸에 "준비 중"으로 돌아간다.
// 포트폴리오 칸의 정확한 주소 하나만 새 탭 링크다(mailto/tel 없음).
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../core/js_compat.dart';
import '../../../core/public_assets.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/dashed.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/readable_text.dart';
import '../../../widgets/reveal.dart';
import '../portfolio_content.dart';
import 'portfolio_scope.dart';
import 'portfolio_widgets.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key, required this.site, required this.resume});

  final SiteContent site;
  final ResumeContent resume;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final scope = PortfolioScope.of(context);
    final about = resume.about;
    return RevealOnce(
      enabled: scope.revealEnabled,
      child: ResumeSection(
        anchorId: site.section('about'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(index: about['index']!, title: about['heading']!, heading: false),
            SizedBox(height: metrics.mobile ? 20 : 32),
            _Intro(site: site, resume: resume),
            _ProfileTheme(site: site),
            SizedBox(height: metrics.mobile ? 28 : 40),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KText(
                      about['headline']!,
                      style: textStyle(size: metrics.mobile ? 19 : 22, weight: FontWeight.w600, color: palette.ink, height: 1.4, em: -0.03),
                    ),
                    const SizedBox(height: 16),
                    for (final (i, paragraph) in resume.story.indexed) ...[
                      if (i > 0) const SizedBox(height: 12),
                      KText(paragraph, style: textStyle(size: 16.5, color: palette.ink2, height: 1.75)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _Blocks(resume: resume),
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.site, required this.resume});

  final SiteContent site;
  final ResumeContent resume;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    final scope = PortfolioScope.of(context);
    final name = Semantics(
      header: true,
      // 메인 페이지의 유일한 h1(원본 .profile__name).
      headingLevel: 1,
      child: KText(
        site.name,
        style: textStyle(size: mobile ? 28 : 34, weight: FontWeight.w700, em: -0.03, color: palette.ink, height: 1.2),
      ),
    );
    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(mobile ? 12 : 16),
      child: ColoredBox(
        color: AppPalette.white,
        child: AspectRatio(
          aspectRatio: resume.photoWidth / resume.photoHeight,
          child: Image.asset(
            publicAsset(resume.photoSrc),
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.4),
            semanticLabel: resume.photoAlt,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
    final contact = KeyedSubtree(
      key: scope.anchors.keyFor(site.section('contact')),
      child: _ContactSlots(resume: resume, inlineGrid: !mobile),
    );
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(width: 96, child: photo),
              const SizedBox(width: 16),
              Expanded(child: name),
            ],
          ),
          const SizedBox(height: 20),
          contact,
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 180,
            child: Align(alignment: Alignment.topCenter, child: photo),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [name, const SizedBox(height: 20), contact],
            ),
          ),
        ],
      ),
    );
  }
}

const Map<String, IconData> _contactIcons = {
  'email': PhosphorIconsRegular.envelopeSimple,
  'phone': PhosphorIconsRegular.phone,
  'profile': PhosphorIconsRegular.linkSimple,
};

class _ContactSlots extends StatelessWidget {
  const _ContactSlots({required this.resume, required this.inlineGrid});

  final ResumeContent resume;
  final bool inlineGrid;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final allEmpty = resume.contactFields.every((field) => resume.contactValue(field) == null);
    final slots = [for (final field in resume.contactFields) _ContactSlot(resume: resume, field: field, stacked: inlineGrid)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: palette.line)),
          ),
          child: Semantics(
            header: true,
            headingLevel: 3,
            child: KText(
              resume.contact['heading']!,
              style: textStyle(size: 15, weight: FontWeight.w600, color: palette.ink),
            ),
          ),
        ),
        if (inlineGrid) EqualColumns(columns: 3, gap: 24, children: slots) else ...slots,
        if (allEmpty) ...[const SizedBox(height: 12), KText(resume.contact['emptyNote']!, style: textStyle(size: 13, color: palette.ink3, height: 1.6))],
      ],
    );
  }
}

class _ContactSlot extends StatelessWidget {
  const _ContactSlot({required this.resume, required this.field, required this.stacked});

  final ResumeContent resume;
  final ContactField field;

  /// true: 라벨 위·값 아래(데스크톱 3열), false: 112px 라벨 | 값(모바일).
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final value = resume.contactValue(field);
    final href = resume.contactHref(field);
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_contactIcons[field.id] ?? PhosphorIconsRegular.linkSimple, size: 18, color: palette.ink3),
        const SizedBox(width: 8),
        Flexible(
          child: KText(field.label, style: textStyle(size: 13.5, color: palette.ink3)),
        ),
      ],
    );
    final Widget valueWidget;
    if (href != null) {
      valueWidget = Align(
        alignment: Alignment.centerLeft,
        child: _PortfolioLink(url: href, text: value!),
      );
    } else if (value != null) {
      valueWidget = ReadableText(value, style: textStyle(size: 15, color: palette.ink));
    } else {
      valueWidget = DashedBox(
        color: palette.line2,
        radius: 8,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          child: KText(resume.contact['emptyValue']!, style: textStyle(size: 13.5, color: palette.ink3, height: 1.2)),
        ),
      );
    }
    final valueBox = ConstrainedBox(constraints: const BoxConstraints(minHeight: 32), child: valueWidget);
    return Container(
      padding: EdgeInsets.symmetric(vertical: stacked ? 12 : 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: stacked
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [label, const SizedBox(height: 6), valueBox])
          : Row(
              children: [
                SizedBox(width: 112, child: label),
                const SizedBox(width: 6),
                Expanded(child: valueBox),
              ],
            ),
    );
  }
}

/// 포트폴리오 주소 링크(새 탭, noopener noreferrer). 값 글자 크기는 일반 값과 같고 밑줄·포커스 링만 더한다.
class _PortfolioLink extends StatelessWidget {
  const _PortfolioLink({required this.url, required this.text});

  final String url;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final navigator = AppServices.of(context).navigator;
    return Pressable(
      isLink: true,
      linkUrl: Uri.parse(url),
      semanticLabel: text,
      excludeChildSemantics: true,
      radius: BorderRadius.circular(2),
      focusOffset: 2,
      focusColor: palette.ink,
      onPressed: () => navigator.openNewTab(url),
      builder: (context, state) => Text(
        text,
        style: textStyle(size: 15, color: palette.ink, decoration: TextDecoration.underline, decorationColor: state.hovered ? palette.ink : palette.line2),
      ),
    );
  }
}

class _ProfileTheme extends StatelessWidget {
  const _ProfileTheme({required this.site});

  final SiteContent site;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final width = metrics.width;
    // desktop clamp(32px, 3.4vw, 44px) / ≤760px clamp(22px, 6.4vw, 30px).
    final size = metrics.mobile ? (width * 0.064).clamp(22.0, 30.0) : (width * 0.034).clamp(32.0, 44.0);
    final lineHeight = metrics.mobile ? 1.26 : 1.22;
    final arcStyle = textStyle(size: 14, color: palette.ink2, em: -0.01);
    return Container(
      margin: EdgeInsets.only(top: metrics.mobile ? 28 : 36),
      padding: EdgeInsets.only(top: metrics.mobile ? 20 : 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: '${site.heroArcLabel}: ${site.heroArc.join(' → ')}',
            excludeSemantics: true,
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (i, step) in site.heroArc.indexed)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i > 0) ...[Text('→', style: arcStyle.copyWith(color: palette.ink3)), const SizedBox(width: 10)],
                      KText(
                        step,
                        style: i == site.heroArc.length - 1
                            ? arcStyle.copyWith(color: palette.ink, fontWeight: FontWeight.w600, fontVariations: const [FontVariation('wght', 600)])
                            : arcStyle,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            // 원본 <h2 className="profile-theme__title">.
            headingLevel: 2,
            label: site.heroLines.join(' '),
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, line) in site.heroLines.indexed)
                  KText(
                    line,
                    style: textStyle(size: size, weight: FontWeight.w800, height: lineHeight, em: -0.04, color: i == 0 ? palette.ink2 : palette.hero2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Blocks extends StatelessWidget {
  const _Blocks({required this.resume});

  final ResumeContent resume;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final about = resume.about;
    final values = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlockTitle(about['valuesHeading']!),
        for (final (i, value) in resume.values.indexed)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.line)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  child: ExcludeSemantics(
                    child: Text(
                      padZero(i + 1),
                      style: textStyle(size: 13, weight: FontWeight.w600, color: palette.orange, height: 24 / 13, tabular: true),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KText(
                        value.title,
                        style: textStyle(size: 16, weight: FontWeight.w600, em: -0.02, color: palette.ink),
                      ),
                      const SizedBox(height: 4),
                      KText(value.body, style: textStyle(size: 14.5, color: palette.ink2, height: 1.65)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    final highlights = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlockTitle(about['highlightsHeading']!),
        for (final item in resume.highlights) _HighlightRow(item: item, stacked: metrics.mobile),
      ],
    );
    if (metrics.atMost(Breakpoints.desktop)) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [values, const SizedBox(height: 28), highlights]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: values),
        const SizedBox(width: 40),
        Expanded(child: highlights),
      ],
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.item, required this.stacked});

  final Highlight item;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scope = PortfolioScope.of(context);
    final label = KText(
      item.label,
      style: textStyle(size: 14.5, weight: FontWeight.w600, color: palette.ink, height: 1.65),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KText(item.text, style: textStyle(size: 14.5, color: palette.ink2, height: 1.65)),
        const SizedBox(height: 2),
        Transform.translate(
          offset: const Offset(0, 0),
          child: Pressable(
            isLink: true,
            linkUrl: Uri.parse(item.href),
            semanticLabel: '${item.linkLabel} 보기: ${item.label}',
            excludeChildSemantics: true,
            radius: BorderRadius.circular(6),
            onPressed: () => scope.onAnchor(item.href.substring(1)),
            builder: (context, state) {
              final color = state.hovered ? palette.orange : palette.ink;
              final reduced = ReducedMotion.of(context);
              return Container(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.linkLabel} 보기',
                      style: textStyle(size: 13.5, weight: FontWeight.w600, color: color),
                    ),
                    const SizedBox(width: 6),
                    AnimatedSlide(
                      duration: reduced ? Duration.zero : Motion.fast,
                      offset: (state.hovered || state.focused) && !reduced ? const Offset(3 / 14, 0) : Offset.zero,
                      child: Icon(PhosphorIconsRegular.arrowRight, size: 14, color: color),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: stacked
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [label, const SizedBox(height: 4), body])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 112, child: label),
                const SizedBox(width: 12),
                Expanded(child: body),
              ],
            ),
    );
  }
}
