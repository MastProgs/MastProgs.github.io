// 05 작업 사례(React CasesSection.jsx + useCaseRail + lib/rail.js 이식).
// AI-NOTE: 레일은 가로 스크롤 + 가운데 맞춤 스냅이고, 첫·마지막 카드도 가운데에 올 수 있도록 좌우 여백을 (레일 폭 − 카드 폭)/2 로 둔다.
// 가운데에 가장 가까운 카드가 현재 카드(번호·목차 강조)다. 넓은 화면 + 동작 허용일 때만 카드가 가운데에서 떨어진 만큼 기운다(−8°×비율).
// 휠·터치 스크롤을 막거나 세로 스크롤을 가로채지 않는다. 이전/다음은 끝에서 aria-disabled(포커스 유지).
// 목차 링크는 레일 안에서만 해당 카드를 가운데로 옮기고 카드에 포커스를 준다. 키보드로 카드에 들어오면 그 카드를 가운데로 맞춘다.
// 사례 순서: 01 AgentWorkflow → 02 Hero Pixel Studio → 03 Voice to SRT → 04 KETI → 05 현장 요청 처리(id 고정).
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../core/constants.dart';
import '../../../core/js_compat.dart';
import '../../../core/public_assets.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/reveal.dart';
import '../portfolio_content.dart';
import 'case_diagram.dart';
import 'case_dialog.dart';
import 'portfolio_scope.dart';
import 'portfolio_widgets.dart';

/// 사례 id → 상세 페이지 경로. 상세 페이지가 있는 사례만 대화상자 아래에 새 탭 링크를 둔다.
const Map<String, String> caseDetailRoutes = {'case-subtitles': subtitlesRoutePath};

// ── 레일 계산(원본 lib/rail.js, 순수 함수) ─────────────────────────
class RailViewport {
  const RailViewport({required this.scrollLeft, required this.clientWidth, required this.scrollWidth});

  final double scrollLeft;
  final double clientWidth;
  final double scrollWidth;
}

class RailItem {
  const RailItem({required this.left, required this.width});

  final double left;
  final double width;
}

double _viewportCenter(RailViewport viewport) => viewport.scrollLeft + viewport.clientWidth / 2;

// 화면 가운데에 가장 가까운 카드 인덱스. 카드가 없으면 -1.
int centeredIndex(RailViewport viewport, List<RailItem> items) {
  final center = _viewportCenter(viewport);
  var best = -1;
  var bestDistance = double.infinity;
  for (final (index, item) in items.indexed) {
    final distance = (item.left + item.width / 2 - center).abs();
    if (distance < bestDistance) {
      best = index;
      bestDistance = distance;
    }
  }
  return best;
}

// 카드 중심이 화면 가운데에서 떨어진 정도(-1 왼쪽 끝 ~ 0 가운데 ~ 1 오른쪽 끝).
double tiltRatio(RailItem item, RailViewport viewport) {
  final half = viewport.clientWidth / 2;
  if (!(half > 0)) return 0;
  final ratio = ((item.left + item.width / 2 - _viewportCenter(viewport)) / half).clamp(-1.0, 1.0);
  final rounded = (ratio * 1000).roundToDouble() / 1000;
  return rounded == 0 ? 0 : rounded;
}

// 카드를 화면 가운데에 두는 scrollLeft. 스크롤 가능 범위 안으로 자른다.
double scrollLeftToCenter(RailItem item, RailViewport viewport) {
  final max = math.max(0.0, viewport.scrollWidth - viewport.clientWidth);
  return (item.left + item.width / 2 - viewport.clientWidth / 2).clamp(0.0, max);
}

// 이전/다음 버튼 대상. 범위를 벗어나면 null(버튼 비활성).
int? stepIndex(int active, int delta, int count) {
  final target = active + delta;
  return target >= 0 && target < count ? target : null;
}

class CasesSection extends StatefulWidget {
  const CasesSection({super.key, required this.site});

  final SiteContent site;

  @override
  State<CasesSection> createState() => _CasesSectionState();
}

class _CasesSectionState extends State<CasesSection> {
  final ScrollController _rail = ScrollController();
  final ValueNotifier<int> _active = ValueNotifier(0);
  late final List<FocusNode> _cardFocus = [for (final item in widget.site.cases) FocusNode(debugLabel: item.id)];
  double _cardWidth = 600;
  double _gap = 24;
  double _railWidth = 0;
  AnchorRegistry? _registry;

  List<PortfolioCase> get _cases => widget.site.cases;

  @override
  void initState() {
    super.initState();
    _rail.addListener(_measure);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = PortfolioScope.of(context).anchors;
    if (registry != _registry) {
      _registry?.revealCase = null;
      _registry = registry;
      registry.revealCase = (id) {
        final index = _cases.indexWhere((item) => item.id == id);
        if (index >= 0) _scrollToIndex(index);
      };
    }
  }

  @override
  void dispose() {
    _registry?.revealCase = null;
    _rail.dispose();
    _active.dispose();
    for (final node in _cardFocus) {
      node.dispose();
    }
    super.dispose();
  }

  double get _sidePadding => (_railWidth - _cardWidth) / 2;

  RailViewport _viewport() => RailViewport(
    scrollLeft: _rail.hasClients ? _rail.offset : 0,
    clientWidth: _railWidth,
    scrollWidth: _sidePadding * 2 + _cases.length * _cardWidth + (_cases.length - 1) * _gap,
  );

  List<RailItem> _items() => [for (var i = 0; i < _cases.length; i += 1) RailItem(left: _sidePadding + i * (_cardWidth + _gap), width: _cardWidth)];

  void _measure() {
    if (_railWidth <= 0) return;
    final index = centeredIndex(_viewport(), _items());
    if (index >= 0) _active.value = index;
  }

  void _scrollToIndex(int index) {
    if (!_rail.hasClients) return;
    final target = scrollLeftToCenter(_items()[index], _viewport());
    if (ReducedMotion.read(context)) {
      _rail.jumpTo(target);
    } else {
      _rail.animateTo(target, duration: const Duration(milliseconds: 420), curve: Curves.easeInOut);
    }
  }

  void _step(int delta) {
    final target = stepIndex(_active.value, delta, _cases.length);
    if (target != null) _scrollToIndex(target);
  }

  void _jumpTo(int index) {
    final scope = PortfolioScope.read(context);
    final railContext = scope.anchors.contextOf('cases-rail');
    if (railContext != null) Scrollable.ensureVisible(railContext, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
    _scrollToIndex(index);
    _cardFocus[index].requestFocus();
  }

  Future<void> _open(PortfolioCase item, int index) async {
    _cardFocus[index].requestFocus();
    await showCaseDialog(context, item: item, detailRoute: caseDetailRoutes[item.id], returnFocus: _cardFocus[index]);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final scope = PortfolioScope.of(context);
    final rail = widget.site.casesRail;
    final narrowHead = metrics.atMost(Breakpoints.desktop);
    final viewWidth = metrics.width;
    _cardWidth = metrics.mobile ? viewWidth * 0.84 : math.min(600, viewWidth * 0.84);
    _gap = metrics.mobile ? 12 : 24;

    final title = SectionTitle(index: rail['index']!, title: rail['heading']!);
    final index = ValueListenableBuilder<int>(
      valueListenable: _active,
      builder: (context, active, _) => Semantics(
        container: true,
        label: rail['indexLabel'],
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, item) in _cases.indexed)
                Container(
                  decoration: i == 0
                      ? null
                      : BoxDecoration(
                          border: Border(left: BorderSide(color: palette.tileLine)),
                        ),
                  child: Pressable(
                    isLink: true,
                    linkUrl: Uri(fragment: item.id),
                    selected: i == active,
                    semanticLabel: '${item.index} ${item.title}',
                    excludeChildSemantics: true,
                    radius: BorderRadius.circular(6),
                    onPressed: () => _jumpTo(i),
                    builder: (context, state) {
                      final on = state.hovered || i == active;
                      final horizontal = narrowHead ? 20.0 : 40.0;
                      return Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: EdgeInsets.only(left: narrowHead && i == 0 ? 0 : horizontal, right: !narrowHead && i == _cases.length - 1 ? 0 : horizontal),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.index, style: textStyle(size: 14, color: i == active ? palette.orange : palette.ink3, tabular: true, em: -0.01)),
                            const SizedBox(width: 14),
                            Text(item.title, style: textStyle(size: 14, color: on ? palette.ink : palette.inkSoft, em: -0.01)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final head = Container(
      margin: EdgeInsets.symmetric(horizontal: metrics.stageInset),
      constraints: const BoxConstraints(minHeight: 78),
      padding: narrowHead ? const EdgeInsets.fromLTRB(8, 20, 8, 0) : const EdgeInsets.symmetric(horizontal: 21),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: narrowHead
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 16), index])
          // flex-wrap + space-between: 목차가 제목 옆에 들어가지 않으면 다음 줄로 내려가고, 목차 자체는 자기 폭 안에서 가로 스크롤한다.
          : LayoutBuilder(
              builder: (context, constraints) => ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 77),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    title,
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                      child: index,
                    ),
                  ],
                ),
              ),
            ),
    );

    final controls = Padding(
      padding: EdgeInsets.fromLTRB(metrics.stageInset + (metrics.mobile ? 8 : 21), 8, metrics.stageInset + (metrics.mobile ? 8 : 21), 0),
      child: ValueListenableBuilder<int>(
        valueListenable: _active,
        builder: (context, active, _) {
          final prevDisabled = stepIndex(active, -1, _cases.length) == null;
          final nextDisabled = stepIndex(active, 1, _cases.length) == null;
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ExcludeSemantics(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: padZero(active + 1),
                        style: textStyle(size: 14, weight: FontWeight.w600, color: palette.ink, tabular: true),
                      ),
                      TextSpan(
                        text: ' / ${padZero(_cases.length)}',
                        style: textStyle(size: 14, color: palette.ink3, tabular: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              CircleIconButton(icon: PhosphorIconsRegular.caretLeft, label: rail['prev']!, ariaDisabled: prevDisabled, onPressed: () => _step(-1)),
              const SizedBox(width: 8),
              CircleIconButton(icon: PhosphorIconsRegular.caretRight, label: rail['next']!, ariaDisabled: nextDisabled, onPressed: () => _step(1)),
            ],
          );
        },
      ),
    );

    final list = LayoutBuilder(
      builder: (context, constraints) {
        _railWidth = constraints.maxWidth;
        // 좌우 여백 max(stage-inset, (레일 폭 − 카드 폭)/2): 첫·마지막 카드도 가운데에 온다.
        final side = math.max(metrics.stageInset, (_railWidth - _cardWidth) / 2);
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
        return Semantics(
          container: true,
          label: rail['railLabel'],
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {...PointerDeviceKind.values}, scrollbars: true),
            child: Scrollbar(
              controller: _rail,
              child: SingleChildScrollView(
                key: scope.anchors.keyFor('cases-rail'),
                controller: _rail,
                scrollDirection: Axis.horizontal,
                physics: _CenterSnapPhysics(extent: _cardWidth + _gap, count: _cases.length),
                padding: EdgeInsets.fromLTRB(side, 12, side, metrics.mobile ? 12 : 20),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, item) in _cases.indexed) ...[
                        if (i > 0) SizedBox(width: _gap),
                        StaggerReveal(
                          index: i,
                          delay: const Duration(milliseconds: 80),
                          style: StaggerStyle.tilt,
                          child: SizedBox(
                            key: scope.anchors.keyFor(item.id),
                            width: _cardWidth,
                            child: _CaseCard(
                              item: item,
                              index: i,
                              moreLabel: rail['more']!,
                              active: _active,
                              rail: _rail,
                              focusNode: _cardFocus[i],
                              tiltFor: () => tiltRatio(_items()[i], _viewport()),
                              onOpen: () => _open(item, i),
                              onKeyboardFocus: () {
                                if (i != _active.value) _scrollToIndex(i);
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return RevealOnce(
      enabled: scope.revealEnabled,
      animateSelf: false,
      child: Padding(
        key: scope.anchors.keyFor(widget.site.section('cases')),
        padding: const EdgeInsets.only(top: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [head, controls, const SizedBox(height: 12), list]),
      ),
    );
  }
}

/// 카드 중심이 뷰포트 가운데에 오도록 스냅하는 물리(원본 scroll-snap-type: x mandatory, align center).
class _CenterSnapPhysics extends ScrollPhysics {
  const _CenterSnapPhysics({required this.extent, required this.count, super.parent});

  final double extent;
  final int count;

  @override
  _CenterSnapPhysics applyTo(ScrollPhysics? ancestor) => _CenterSnapPhysics(extent: extent, count: count, parent: buildParent(ancestor));

  double _target(ScrollMetrics position, double velocity, Tolerance tolerance) {
    var page = position.pixels / extent;
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    final index = page.round().clamp(0, count - 1);
    return (index * extent).clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) || (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final target = _target(position, velocity, tolerance);
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tolerance);
  }

  @override
  bool get allowImplicitScrolling => false;
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.item,
    required this.index,
    required this.moreLabel,
    required this.active,
    required this.rail,
    required this.focusNode,
    required this.tiltFor,
    required this.onOpen,
    required this.onKeyboardFocus,
  });

  final PortfolioCase item;
  final int index;
  final String moreLabel;
  final ValueListenable<int> active;
  final ScrollController rail;
  final FocusNode focusNode;
  final double Function() tiltFor;
  final VoidCallback onOpen;
  final VoidCallback onKeyboardFocus;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final reduced = ReducedMotion.of(context);
    final tilting = !metrics.mobile && !reduced;
    return Pressable(
      focusNode: focusNode,
      radius: BorderRadius.circular(18),
      semanticLabel: '${item.index} ${item.title}. ${item.summary}',
      excludeChildSemantics: true,
      onPressed: onOpen,
      onFocusChange: (focused) {
        if (focused && FocusManager.instance.highlightMode == FocusHighlightMode.traditional) onKeyboardFocus();
      },
      builder: (context, state) {
        final lifted = state.hovered || state.focused;
        return AnimatedBuilder(
          animation: Listenable.merge([active, rail]),
          builder: (context, child) {
            final isActive = active.value == index;
            final tilt = tilting && !lifted ? tiltFor() : 0.0;
            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 1 / 1600)
              ..rotateY(-tilt * 8 * math.pi / 180);
            if (lifted && !reduced) matrix.translateByDouble(0, -6, 0, 1);
            return Transform(
              alignment: Alignment.center,
              transform: matrix,
              child: AnimatedOpacity(
                duration: motionDuration(context, Motion.med),
                opacity: isActive || lifted ? 1 : 0.74,
                child: AnimatedContainer(
                  duration: motionDuration(context, Motion.med),
                  curve: Motion.easeOut,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: lifted ? palette.line3 : (isActive ? palette.line2 : palette.line1)),
                    boxShadow: lifted ? [BoxShadow(color: palette.shadow, blurRadius: 40, offset: const Offset(0, 18))] : const [],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: metrics.mobile ? 190 : 264,
                child: _CardMedia(item: item, zoom: lifted && !reduced),
              ),
              Expanded(
                child: _CardBody(item: item, moreLabel: moreLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardMedia extends StatelessWidget {
  const _CardMedia({required this.item, required this.zoom});

  final PortfolioCase item;
  final bool zoom;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (item.isDiagram) {
      return Container(
        color: palette.paper,
        padding: const EdgeInsets.all(22),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: CaseMediaHero(
            caseId: item.id,
            child: CaseDiagram(diagram: item.diagram!, compact: true),
          ),
        ),
      );
    }
    final image = item.image!;
    final cover = item.fit == 'cover';
    final picture = AnimatedScale(
      duration: motionDuration(context, Motion.slow),
      curve: Motion.easeOut,
      scale: zoom ? 1.03 : 1,
      child: Image.asset(
        publicAsset(image.src),
        fit: cover ? BoxFit.cover : BoxFit.contain,
        alignment: cover ? Alignment.topCenter : Alignment.center,
        semanticLabel: image.alt,
        filterQuality: FilterQuality.medium,
        width: double.infinity,
        height: double.infinity,
      ),
    );
    return Container(
      color: cover ? AppPalette.coverMediaBg : palette.paper,
      padding: cover ? EdgeInsets.zero : const EdgeInsets.all(24),
      child: ClipRect(
        child: CaseMediaHero(caseId: item.id, child: picture),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.item, required this.moreLabel});

  final PortfolioCase item;
  final String moreLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.index,
            style: textStyle(size: 13, weight: FontWeight.w600, color: palette.orange, tabular: true),
          ),
          const SizedBox(height: 8),
          KText(
            item.title,
            style: textStyle(size: 22, weight: FontWeight.w700, em: -0.03, color: palette.ink),
          ),
          const SizedBox(height: 8),
          KText(item.summary, style: textStyle(size: 15, color: palette.ink2, height: 1.55)),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final tag in item.tags) TagChip(tag)]),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                moreLabel,
                style: textStyle(size: 14, weight: FontWeight.w600, color: palette.ink),
              ),
              const SizedBox(width: 6),
              Icon(PhosphorIconsRegular.arrowsOutSimple, size: 16, color: palette.ink),
            ],
          ),
        ],
      ),
    );
  }
}
