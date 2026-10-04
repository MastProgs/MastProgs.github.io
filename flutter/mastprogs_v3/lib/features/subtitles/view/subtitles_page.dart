// /subtitles 상세 페이지(Voice to SRT, React SubtitlesPage.jsx 이식). 라우터가 이 라이브러리를 늦게 불러온다(예시 데이터·단계 모델도 이 페이지에서만 읽음).
// AI-NOTE: 머리글은 /workflow·/sprite 와 같은 모양(이력서로 돌아가기 + 테마 전환), h1 하나, 같은 테마 상태.
// 순서: 소개(구현된 기능, 개발 진행 상태 표시 없음) → 처리 흐름(원리) → 과정 따라가기(예시) → AI 경계 → 편집기 → 구성·데이터 위치 → 쓰임.
// 원본 앱 화면 캡처는 없으므로 만들지 않는다. 도식은 아이콘 + 의미 있는 목록이다. 실제 음성 인식·네트워크·업로드·오디오·저장은 없다.
// 소개 판(밝은 판) 위의 '사례 요약 보기' 버튼은 어두운 테마에서도 stage 잉크를 쓴다(기본·가리킴·포커스 모두).
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../content/content_repository.dart';
import '../../../core/js_compat.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/page_frame.dart';
import '../../portfolio/view/case_dialog.dart';
import '../model/subtitles_content.dart';
import '../model/subtitles_model.dart';
import 'subtitle_walkthrough.dart';

class SubtitlesPage extends StatefulWidget {
  const SubtitlesPage({super.key});

  @override
  State<SubtitlesPage> createState() => _SubtitlesPageState();
}

class _SubtitlesPageState extends State<SubtitlesPage> {
  late final Future<SubtitlesPageData> _data = AppServices.of(context).content.subtitles();

  @override
  Widget build(BuildContext context) => FutureBuilder<SubtitlesPageData>(
    future: _data,
    builder: (context, snapshot) => snapshot.hasData ? SubtitlesDetailView(data: snapshot.data!) : const SizedBox.expand(),
  );
}

class SubtitlesDetailView extends StatefulWidget {
  const SubtitlesDetailView({super.key, required this.data});

  final SubtitlesPageData data;

  @override
  State<SubtitlesDetailView> createState() => _SubtitlesDetailViewState();
}

class _SubtitlesDetailViewState extends State<SubtitlesDetailView> {
  // 화면을 열 때 한 번만 만든 작은 고정 데이터(다시 그릴 때마다 새로 만들지 않음).
  late final Walkthrough _walk = buildWalkthrough(widget.data.content.fixture);
  final ScrollController _scroll = ScrollController();
  final FocusNode _caseButton = FocusNode(debugLabel: 'srt-open-case');

  @override
  void dispose() {
    _scroll.dispose();
    _caseButton.dispose();
    super.dispose();
  }

  Future<void> _openCase() async {
    await showCaseDialog(context, item: widget.data.site.caseById('case-subtitles'), detailRoute: null, returnFocus: _caseButton);
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.data.content;
    final page = content.page;
    final sections = content.sections;
    final intro = DetailIntro(
      eyebrow: page['eyebrow']!,
      title: page['title']!,
      paragraphs: content.intro,
      after: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SrtButton(
          label: page['openCase']!,
          trailingIcon: PhosphorIconsRegular.arrowsOutSimple,
          onStage: true,
          focusNode: _caseButton,
          onPressed: _openCase,
        ),
      ),
    );
    final blocks = <Widget>[
      _Section(
        title: sections['flow']!,
        child: _Flow(content: content),
      ),
      _Section(
        title: sections['walkthrough']!,
        child: SubtitleWalkthrough(content: content, walk: _walk),
      ),
      _Section(
        title: sections['boundary']!,
        child: _Boundary(content: content),
      ),
      _Section(
        title: sections['editor']!,
        child: _Grid(items: content.editor, columns3: true),
      ),
      _Section(
        title: sections['structure']!,
        child: _Structure(content: content),
      ),
      _Section(
        title: sections['uses']!,
        child: _Grid(items: content.uses, columns3: true),
      ),
    ];
    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShellWidth(child: DetailTopBar(backLabel: page['backLabel']!)),
              ShellWidth(child: intro),
              for (final block in blocks) ...[const SizedBox(height: 20), ShellWidth(child: block)],
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    return Container(
      padding: mobile ? const EdgeInsets.fromLTRB(16, 18, 16, 20) : const EdgeInsets.fromLTRB(28, 24, 28, 26),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.line1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            headingLevel: 2,
            child: KText(
              title,
              style: textStyle(size: 22, weight: FontWeight.w700, em: -0.025, color: palette.ink),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// 둥근 카드 + 위쪽 3px 강조선(CSS border-top: 3px). 강조선은 둥근 모서리를 따라 잘린다.
class _AccentBox extends StatelessWidget {
  const _AccentBox({required this.accent, required this.border, required this.padding, required this.child});

  final Color? accent;
  final Color border;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final card = Container(
      padding: padding.add(EdgeInsets.only(top: accent == null ? 0 : 2)),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: child,
    );
    if (accent == null) return card;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          card,
          Positioned(top: 0, left: 0, right: 0, height: 3, child: ColoredBox(color: accent!)),
        ],
      ),
    );
  }
}

int _columns(BuildContext context, {required int wide}) {
  final metrics = ScreenMetrics.of(context);
  if (metrics.mobile) return 1;
  if (metrics.atMost(Breakpoints.desktop)) return 2;
  return wide;
}

class _Flow extends StatelessWidget {
  const _Flow({required this.content});

  final SubtitlesContent content;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return EqualColumns(
      columns: _columns(context, wide: 4),
      gap: 10,
      children: [
        for (final (index, step) in content.pipeline.indexed)
          _AccentBox(
            accent: step.where == '외부 CLI' ? palette.infoText : (step.where == '사람' ? palette.orange : palette.line4),
            border: palette.line2,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      padZero(index + 1),
                      style: textStyle(size: 12, weight: FontWeight.w700, color: palette.ink3, tabular: true),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KText(
                        step.label,
                        style: textStyle(size: 16, weight: FontWeight.w700, color: palette.ink),
                      ),
                    ),
                    KText(step.where, style: textStyle(size: 12, color: palette.ink3)),
                  ],
                ),
                const SizedBox(height: 8),
                KText(step.text, style: textStyle(size: 14, color: palette.ink2, height: 1.6)),
              ],
            ),
          ),
      ],
    );
  }
}

class _BoundaryColumn extends StatelessWidget {
  const _BoundaryColumn({required this.list, this.icon, this.emphasis = false, this.external = false});

  final TitledList list;
  final IconData? icon;
  final bool emphasis;
  final bool external;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _AccentBox(
      accent: external ? palette.infoText : null,
      border: emphasis ? palette.line3 : palette.line2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            // 원본 <h3 className="srt-boundary__title">.
            headingLevel: 3,
            child: Row(
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: palette.ink), const SizedBox(width: 8)],
                Expanded(
                  child: KText(
                    list.title,
                    style: textStyle(size: 16, weight: FontWeight.w700, color: palette.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final item in list.items)
            Padding(
              padding: const EdgeInsets.only(left: 18, bottom: 6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -12,
                    top: 14.5 * 0.7,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(color: palette.ink2, shape: BoxShape.circle),
                    ),
                  ),
                  KText(item, style: textStyle(size: 14.5, color: palette.ink2, height: 1.55)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Boundary extends StatelessWidget {
  const _Boundary({required this.content});

  final SubtitlesContent content;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EqualColumns(
          columns: mobile ? 1 : 2,
          gap: 12,
          children: [
            _BoundaryColumn(list: content.does),
            _BoundaryColumn(list: content.doesNot, emphasis: true),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            KText(content.proposalNote, style: textStyle(size: 13.5, color: palette.ink3)),
            for (final field in content.proposalFieldsShown)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: palette.surface3, borderRadius: BorderRadius.circular(6)),
                child: Text(field, style: textStyle(size: 13, mono: true, color: palette.ink)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.items, required this.columns3});

  final List<LabeledText> items;
  final bool columns3;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return EqualColumns(
      columns: _columns(context, wide: 3),
      gap: 10,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.line2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KText(
                  item.label,
                  style: textStyle(size: 16, weight: FontWeight.w700, color: palette.ink),
                ),
                const SizedBox(height: 6),
                KText(item.text, style: textStyle(size: 14, color: palette.ink2, height: 1.6)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Structure extends StatelessWidget {
  const _Structure({required this.content});

  final SubtitlesContent content;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EqualColumns(
          columns: _columns(context, wide: 4),
          gap: 10,
          children: [
            for (final part in content.structureParts)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.line2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(PhosphorIconsRegular.cpu, size: 18, color: palette.ink),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          KText(
                            part.label,
                            style: textStyle(size: 16, weight: FontWeight.w700, color: palette.ink),
                          ),
                          const SizedBox(height: 2),
                          KText(part.text, style: textStyle(size: 13.5, color: palette.ink2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        EqualColumns(
          columns: mobile ? 1 : 2,
          gap: 12,
          children: [
            _BoundaryColumn(list: content.structureLocal, icon: PhosphorIconsRegular.lock),
            _BoundaryColumn(list: content.structureExternal, icon: PhosphorIconsRegular.cloud, external: true),
          ],
        ),
      ],
    );
  }
}
