// 03 핵심 구현(React CoreSection.jsx + CoreItem.jsx + WorkflowSummary.jsx + SpriteBrief.jsx + SubtitlesBrief.jsx 이식).
// AI-NOTE: 사용자 최신 지시로 예전 03 AgentWorkflow·04 스프라이트를 이 묶음 하나(#core, h2)로 합쳤다. 하위 순서: AgentWorkflow → Sprite → Voice to SRT.
// 세 항목은 탭·아코디언 없이 위에서 아래로 모두 보이고, 각자 #workflow·#sprite·#subtitles 앵커와 h3 를 가진다. 하위 번호는 CORE.items 가 정한다.
// 메인에는 요약만 있고 상세는 각 요약의 새 탭 링크(/workflow·/sprite·/subtitles)가 연다.
// SpriteBrief 는 원본 GIF 세 개(걷기·달리기·공격)만 보여 준다(동작 줄이기면 같은 원본의 첫 프레임 PNG). 레이어 합성·타이머·무거운 데이터 없음.
// SubtitlesBrief 는 사례 03 의 처리 도식을 그대로 쓰고 시간·AI·사람 경계 세 줄만 덧붙인다(자막 예시·모델 데이터 없음).
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../core/constants.dart';
import '../../../core/public_assets.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/dashed.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/reveal.dart';
import '../../sprite/model/sprite_meta.dart';
import '../portfolio_content.dart';
import 'case_diagram.dart';
import 'portfolio_scope.dart';
import 'portfolio_widgets.dart';

class CoreSection extends StatelessWidget {
  const CoreSection({super.key, required this.site, required this.sprite});

  final SiteContent site;
  final SpriteMeta sprite;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final scope = PortfolioScope.of(context);
    final core = site.core;
    final items = [_WorkflowSummary(site: site), _SpriteBrief(site: site, sprite: sprite), _SubtitlesBrief(site: site)];
    return RevealOnce(
      enabled: scope.revealEnabled,
      child: ResumeSection(
        anchorId: site.section('core'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHead(
              title: SectionTitle(index: core['index']!, title: core['title']!),
              lede: core['lede'],
            ),
            const SizedBox(height: 18),
            Semantics(
              container: true,
              label: core['navLabel'],
              child: Wrap(spacing: 8, runSpacing: 8, children: [for (final item in site.coreItems) _CoreNavChip(item: item)]),
            ),
            SizedBox(height: metrics.mobile ? 36 : 36),
            for (final (i, item) in items.indexed) ...[
              if (i > 0) ...[SizedBox(height: metrics.mobile ? 36 : 48), DashedLine(color: palette.line), SizedBox(height: metrics.mobile ? 32 : 40)],
              item,
            ],
          ],
        ),
      ),
    );
  }
}

class _CoreNavChip extends StatelessWidget {
  const _CoreNavChip({required this.item});

  final CoreItemDef item;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scope = PortfolioScope.of(context);
    return Pressable(
      isLink: true,
      linkUrl: Uri(fragment: item.id),
      semanticLabel: '${item.index} ${item.label}',
      excludeChildSemantics: true,
      onPressed: () => scope.onAnchor(item.id),
      builder: (context, state) => AnimatedContainer(
        duration: motionDuration(context, Motion.fast),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: palette.tile,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: state.hovered ? palette.orangeText : palette.tileLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.index, style: textStyle(size: 12.5, color: palette.orangeText, tabular: true)),
            const SizedBox(width: 8),
            Text(
              item.label,
              style: textStyle(size: 14, weight: FontWeight.w600, color: palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// .core-item: 앵커 + "03.01" 번호 + h3 제목 + 한 줄 소개.
class _CoreItem extends StatelessWidget {
  const _CoreItem({required this.site, required this.id, required this.title, required this.child, this.lede});

  final SiteContent site;
  final String id;
  final String title;
  final String? lede;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final item = site.coreItems.firstWhere((entry) => entry.id == id);
    final index = Text(
      '${site.core['index']}.${item.index}',
      style: textStyle(size: 15, weight: FontWeight.w600, color: palette.orangeText, tabular: true),
    );
    final heading = Semantics(
      header: true,
      // 원본 <h3 className="core-item__title">(03.01~03.03).
      headingLevel: 3,
      child: KText(
        title,
        style: textStyle(size: metrics.mobile ? 19 : 22, weight: FontWeight.w700, em: -0.025, color: palette.ink, height: 1.3),
      ),
    );
    final ledeText = lede == null ? null : KText(lede!, style: textStyle(size: 15, color: palette.ink3, em: -0.01));
    return Column(
      key: PortfolioScope.of(context).anchors.keyFor(id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (metrics.mobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: index),
              const SizedBox(height: 6),
              heading,
              if (ledeText != null) ...[const SizedBox(height: 6), ledeText],
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  ExcludeSemantics(child: index),
                  const SizedBox(width: 16),
                  Expanded(child: heading),
                ],
              ),
              if (ledeText != null)
                Padding(
                  padding: EdgeInsets.only(left: _indexWidth(context, index) + 16, top: 6),
                  child: ledeText,
                ),
            ],
          ),
        child,
      ],
    );
  }

  double _indexWidth(BuildContext context, Text index) {
    final painter = TextPainter(
      text: TextSpan(text: index.data, style: index.style),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

class _WorkflowSummary extends StatelessWidget {
  const _WorkflowSummary({required this.site});

  final SiteContent site;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final summary = site.workflowSummary;
    final steps = site.workflowSteps;
    final navigator = AppServices.of(context).navigator;
    final stacked = metrics.atMost(Breakpoints.tablet);

    Widget step(int index, List<Widget> children) => Container(
      padding: metrics.mobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: BoxDecoration(color: palette.panel, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _gap(children, 8)),
    );
    TextStyle label() => textStyle(size: 19, weight: FontWeight.w700, em: -0.02, color: palette.ink);
    TextStyle text() => textStyle(size: 14.5, color: palette.ink2, height: 1.55);

    final cards = [
      step(0, [
        Row(
          children: [
            Icon(PhosphorIconsRegular.user, size: 22, color: palette.orange),
            const SizedBox(width: 8),
            Icon(PhosphorIconsRegular.robot, size: 22, color: palette.orange),
          ],
        ),
        KText(steps[0].label, style: label()),
        KText(steps[0].text, style: text()),
      ]),
      step(1, [
        KText(steps[1].label, style: label()),
        KText(steps[1].text, style: text()),
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              children: [
                for (final (i, key) in const ['A', 'B', 'C'].indexed) ...[
                  if (i > 0) const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(minHeight: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.tile,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.tileLine),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: palette.orange, shape: BoxShape.circle),
                          child: Text(
                            key,
                            style: textStyle(size: 12, weight: FontWeight.w700, color: palette.orangeInk, height: 1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: KText('기획 → 검수 → 개발 → 검수 → QA', style: textStyle(size: 13.5, color: palette.ink)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(PhosphorIconsRegular.arrowBendUpLeft, size: 16, color: palette.orangeText),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: KText(summary['returnNote']!, style: textStyle(size: 13.5, color: palette.orangeText, height: 1.45)),
            ),
          ],
        ),
      ]),
      step(2, [
        Icon(PhosphorIconsRegular.gitMerge, size: 22, color: palette.orange),
        KText(steps[2].label, style: label()),
        KText(steps[2].text, style: text()),
      ]),
    ];

    final Widget flow;
    if (stacked) {
      flow = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, card) in cards.indexed) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 2, height: 12, color: palette.orange),
                ),
              ),
            card,
          ],
        ],
      );
    } else {
      flow = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 10, child: cards[0]),
            _HorizontalConnector(color: palette.orange),
            Expanded(flex: 16, child: cards[1]),
            _HorizontalConnector(color: palette.orange),
            Expanded(flex: 10, child: cards[2]),
          ],
        ),
      );
    }

    final button = PillButton(
      label: summary['linkLabel']!,
      icon: PhosphorIconsRegular.arrowSquareOut,
      tone: PillTone.dark,
      expand: metrics.mobile,
      semanticLabel: '${summary['linkLabel']!} ${summary['linkHint']!}',
      linkUrl: Uri.parse(workflowRoutePath),
      onPressed: () => navigator.openNewTab(workflowRoutePath),
    );

    return _CoreItem(
      site: site,
      id: site.section('workflow'),
      title: site.stageTitle,
      child: FocusRingColor(
        color: palette.stageInk,
        child: Container(
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.fromLTRB(25, 23, 24, 30),
          decoration: BoxDecoration(color: palette.stage, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 22),
              flow,
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 24,
                  runSpacing: 14,
                  children: [
                    KText(summary['humanNote']!, style: textStyle(size: 15, color: palette.stageInk2)),
                    if (metrics.mobile) SizedBox(width: double.infinity, child: button) else button,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 단계 사이 화살표 역할의 기능 연결선(장식 아님): 12×2 주황 가로선.
class _HorizontalConnector extends StatelessWidget {
  const _HorizontalConnector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 12,
    child: Center(child: Container(height: 2, color: color)),
  );
}

List<Widget> _gap(List<Widget> children, double gap) => [
  for (final (i, child) in children.indexed) ...[if (i > 0) SizedBox(height: gap), child],
];

class _SpriteBrief extends StatelessWidget {
  const _SpriteBrief({required this.site, required this.sprite});

  final SiteContent site;
  final SpriteMeta sprite;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final reduced = ReducedMotion.of(context);
    final brief = site.spriteBrief;
    final stage = Container(
      padding: metrics.mobile ? const EdgeInsets.fromLTRB(10, 20, 10, 14) : const EdgeInsets.fromLTRB(20, 28, 20, 18),
      decoration: BoxDecoration(color: palette.stage, borderRadius: BorderRadius.circular(18)),
      child: Semantics(
        container: true,
        label: brief['previewLabel'],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, motion) in sprite.motions.indexed) ...[
              if (i > 0) SizedBox(width: metrics.mobile ? 4 : 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 168),
                      child: AspectRatio(
                        aspectRatio: sprite.width / sprite.height,
                        child: Image.asset(
                          // 동작 줄이기면 같은 원본의 첫 프레임 PNG 정지 화면(원본 GIF 는 스스로 멈출 수 없음).
                          publicAsset(reduced ? motion.frames.first.src : motion.gif),
                          key: ValueKey('${motion.id}-$reduced'),
                          semanticLabel: '${brief['previewLabel']}: ${motion.label}',
                          filterQuality: FilterQuality.none,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(color: palette.stageInk, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          motion.label,
                          style: textStyle(size: 12.5, weight: FontWeight.w600, color: AppPalette.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return _CoreItem(
      site: site,
      id: site.section('sprite'),
      title: brief['title']!,
      lede: brief['lede'],
      child: _BriefBody(
        stage: stage,
        side: _BriefSide(points: site.spritePoints, linkLabel: brief['linkLabel']!, linkHint: brief['linkHint']!, path: spriteRoutePath),
      ),
    );
  }
}

class _SubtitlesBrief extends StatelessWidget {
  const _SubtitlesBrief({required this.site});

  final SiteContent site;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final brief = site.srtBrief;
    final diagram = site.caseById('case-subtitles').diagram!;
    return _CoreItem(
      site: site,
      id: site.section('subtitles'),
      title: brief['title']!,
      lede: brief['lede'],
      child: _BriefBody(
        stage: Container(
          padding: EdgeInsets.all(metrics.mobile ? 12 : 16),
          decoration: BoxDecoration(color: palette.paper, borderRadius: BorderRadius.circular(18)),
          child: CaseDiagram(diagram: diagram, columns: metrics.mobile ? 2 : 3),
        ),
        side: _BriefSide(points: site.srtPoints, linkLabel: brief['linkLabel']!, linkHint: brief['linkHint']!, path: subtitlesRoutePath),
      ),
    );
  }
}

/// .sprite-brief__body/.srt-brief__body: 1.15fr | 1fr(960px 이하 한 열), 높이 맞춤.
class _BriefBody extends StatelessWidget {
  const _BriefBody({required this.stage, required this.side});

  final Widget stage;
  final Widget side;

  @override
  Widget build(BuildContext context) {
    final metrics = ScreenMetrics.of(context);
    final content = metrics.atMost(Breakpoints.tablet)
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [stage, const SizedBox(height: 16), side])
        : IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 115, child: stage),
                const SizedBox(width: 16),
                Expanded(flex: 100, child: side),
              ],
            ),
          );
    return Padding(padding: const EdgeInsets.only(top: 18), child: content);
  }
}

class _BriefSide extends StatelessWidget {
  const _BriefSide({required this.points, required this.linkLabel, required this.linkHint, required this.path});

  final List<LabeledPoint> points;
  final String linkLabel;
  final String linkHint;

  /// 새 탭으로 여는 상세 경로(링크 목적지와 실제 이동이 같은 값).
  final String path;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final navigator = AppServices.of(context).navigator;
    final button = PillButton(
      label: linkLabel,
      icon: PhosphorIconsRegular.arrowSquareOut,
      expand: metrics.mobile,
      semanticLabel: '$linkLabel $linkHint',
      linkUrl: Uri.parse(path),
      onPressed: () => navigator.openNewTab(path),
    );
    return Container(
      padding: metrics.mobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: BoxDecoration(color: palette.panel, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, point) in points.indexed) ...[
                if (i > 0) const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.only(bottom: i == points.length - 1 ? 0 : 12),
                  decoration: i == points.length - 1
                      ? null
                      : BoxDecoration(
                          border: Border(bottom: BorderSide(color: palette.line1)),
                        ),
                  child: metrics.mobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [_pointLabel(point.label, palette), const SizedBox(height: 4), _pointText(point.text, palette)],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 96, child: _pointLabel(point.label, palette)),
                            const SizedBox(width: 12),
                            Expanded(child: _pointText(point.text, palette)),
                          ],
                        ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          if (metrics.mobile) button else Align(alignment: Alignment.centerLeft, child: button),
        ],
      ),
    );
  }

  Widget _pointLabel(String text, AppPalette palette) => KText(
    text,
    style: textStyle(size: 14, weight: FontWeight.w700, color: palette.orangeText),
  );

  Widget _pointText(String text, AppPalette palette) => KText(text, style: textStyle(size: 14.5, color: palette.ink2, height: 1.55));
}
