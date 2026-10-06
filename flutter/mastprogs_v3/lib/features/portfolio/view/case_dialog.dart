// 사례 대화상자(React CaseDialog.jsx + Modal.jsx 이식). 메인 사례 레일, /sprite 의 '사례 자세히 보기', /subtitles 의 '사례 요약 보기'가 같이 쓴다.
// AI-NOTE: 매체는 두 종류다. 원본 이미지는 "원본 자료 · 정적 참고 이미지" 캡션으로 실제 근거를 보이고,
// 원본 화면 캡처가 없는 사례(diagram)는 처리 원리 도식으로 그리며 캡션도 도식이라고 밝힌다(원본 화면처럼 꾸미지 않음).
// 열면 닫기 버튼에 포커스, 포커스는 대화상자 안에서만 돈다(Tab), Esc·배경 누름·닫기 버튼으로 닫고, 닫으면 연 카드로 포커스가 돌아간다.
// 사례 이미지는 카드 → 대화상자로 공유 요소 전환(Hero)을 한다(원본 view-transition). 동작 줄이기면 전환 없이 바로 바뀐다.
// showDetailLink: 상세 페이지 안에서 같은 사례를 열 때는 자기 자신으로 가는 링크를 숨긴다.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/route_links.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../core/public_assets.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/k_text.dart';
import '../portfolio_content.dart';
import 'case_diagram.dart';

String caseMediaHeroTag(String caseId) => 'case-media-$caseId';

/// 사례 매체 공유 요소 전환. 날아가는 동안 중간 크기에서 내용이 넘치지 않게 잘라 그린다(원본 view-transition 은 그림을 늘려 잇는다).
class CaseMediaHero extends StatelessWidget {
  const CaseMediaHero({super.key, required this.caseId, required this.child});

  final String caseId;
  final Widget child;

  static Widget _shuttle(BuildContext flight, Animation<double> animation, HeroFlightDirection direction, BuildContext from, BuildContext to) {
    final hero = (direction == HeroFlightDirection.push ? to.widget : from.widget) as Hero;
    return ClipRect(
      child: OverflowBox(alignment: Alignment.topCenter, minHeight: 0, maxHeight: double.infinity, child: hero.child),
    );
  }

  @override
  Widget build(BuildContext context) => Hero(tag: caseMediaHeroTag(caseId), flightShuttleBuilder: _shuttle, child: child);
}

/// 사례 대화상자를 연다. 닫힐 때 완료된다. returnFocus 가 있으면 닫은 뒤 그 노드로 포커스를 돌려준다.
Future<void> showCaseDialog(BuildContext context, {required PortfolioCase item, required String? detailRoute, FocusNode? returnFocus}) async {
  final reduced = ReducedMotion.read(context);
  final palette = context.palette;
  await Navigator.of(context).push(_CaseDialogRoute(item: item, detailRoute: detailRoute, reduced: reduced, scrim: palette.scrim));
  if (returnFocus != null && returnFocus.context != null) returnFocus.requestFocus();
}

class _CaseDialogRoute extends PageRoute<void> {
  _CaseDialogRoute({required this.item, required this.detailRoute, required this.reduced, required this.scrim});

  final PortfolioCase item;
  final String? detailRoute;
  final bool reduced;
  final Color scrim;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => scrim;

  @override
  String? get barrierLabel => '사례 닫기';

  // 배경은 원본처럼 접근성 트리에 나오지 않는다(누르면 닫힘은 그대로). 대화상자를 감싸는 '사례 닫기' 버튼 노드가 생기지 않게 한다.
  @override
  bool get semanticsDismissible => false;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => reduced ? Duration.zero : const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => reduced ? Duration.zero : Motion.med;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      CaseDialogView(item: item, detailRoute: detailRoute);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (reduced) return child;
    final curved = CurvedAnimation(parent: animation, curve: Motion.easeOut);
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 12 * (1 - curved.value)),
          child: Transform.scale(scale: 0.98 + 0.02 * curved.value, child: child),
        ),
        child: child,
      ),
    );
  }
}

class CaseDialogView extends StatelessWidget {
  const CaseDialogView({super.key, required this.item, required this.detailRoute});

  final PortfolioCase item;
  final String? detailRoute;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final size = MediaQuery.sizeOf(context);
    final mobile = ScreenMetrics.of(context).mobile;
    void close() => Navigator.of(context).maybePop();
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (size.width - 32).clamp(0, 920).toDouble(),
                maxHeight: (size.height - 48).clamp(0, double.infinity).toDouble(),
              ),
              // 원본 role="dialog" aria-modal aria-labelledby(사례 제목). 웹 엔진은 role=dialog + aria-label(제목)로 그린다.
              child: Semantics(
                role: SemanticsRole.dialog,
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: item.title,
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.line1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: mobile ? const EdgeInsets.fromLTRB(18, 20, 18, 24) : const EdgeInsets.fromLTRB(32, 28, 32, 32),
                        child: DefaultTextStyle.merge(
                          style: TextStyle(color: palette.ink),
                          child: _CaseDetail(item: item, detailRoute: detailRoute),
                        ),
                      ),
                      Positioned(
                        top: mobile ? 12 : 20,
                        right: mobile ? 6 : 20,
                        child: CircleIconButton(
                          icon: PhosphorIconsBold.x,
                          label: '사례 닫기',
                          tooltip: false,
                          background: palette.surface2,
                          hoverBackground: palette.line1,
                          onPressed: close,
                          // 열리면 닫기 버튼이 포커스를 받는다(원본 Modal 의 closeRef.focus()).
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaseDetail extends StatelessWidget {
  const _CaseDetail({required this.item, required this.detailRoute});

  final PortfolioCase item;
  final String? detailRoute;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final navigator = AppServices.of(context).navigator;
    final factRows = <(String, Widget)>[
      ('문제', KText(item.problem, style: _factStyle(palette))),
      (
        '내 역할',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final line in item.role) _Bullet(text: line)],
        ),
      ),
      ('근거', KText(item.evidence, style: _factStyle(palette))),
      if (item.limits != null) ('한계', KText(item.limits!, style: _factStyle(palette))),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '작업 사례 ${item.index}',
                style: textStyle(size: 13, weight: FontWeight.w600, color: palette.orange),
              ),
              const SizedBox(height: 6),
              Semantics(
                header: true,
                headingLevel: 2,
                child: KText(
                  item.title,
                  style: textStyle(size: 28, weight: FontWeight.w700, color: palette.ink, em: -0.03, height: 1.3),
                ),
              ),
              const SizedBox(height: 8),
              KText(item.summary, style: textStyle(size: 16, color: palette.ink2)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Media(item: item, columns: metrics.atMost(Breakpoints.phone) ? 2 : 3),
        const SizedBox(height: 24),
        for (final (i, (label, body)) in factRows.indexed) ...[
          if (i > 0) const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.only(top: 18),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.line1)),
            ),
            child: metrics.mobile
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_FactLabel(label), const SizedBox(height: 6), body])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 96, child: _FactLabel(label)),
                      const SizedBox(width: 16),
                      Expanded(child: body),
                    ],
                  ),
          ),
        ],
        if (detailRoute != null && item.detailLabel != null) ...[
          const SizedBox(height: 22),
          PillButton(
            label: item.detailLabel!,
            icon: PhosphorIconsRegular.arrowRight,
            iconSize: 16,
            tone: PillTone.primarySmall,
            semanticLabel: item.detailLabel!,
            linkUrl: routeLink(detailRoute!),
            onPressed: () => navigator.go(detailRoute!),
          ),
        ],
      ],
    );
  }
}

TextStyle _factStyle(AppPalette palette) => textStyle(size: 15.5, color: palette.ink2, height: 1.65);

class _FactLabel extends StatelessWidget {
  const _FactLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: textStyle(size: 14, weight: FontWeight.w600, color: context.palette.ink3, height: 1.65),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = _factStyle(palette);
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -14,
            top: style.fontSize! * 0.75,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: palette.orange, shape: BoxShape.circle),
            ),
          ),
          KText(text, style: style),
        ],
      ),
    );
  }
}

class _Media extends StatelessWidget {
  const _Media({required this.item, required this.columns});

  final PortfolioCase item;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final caption = item.isDiagram ? '처리 원리 도식 · 원본 문서와 소스 기준' : '원본 자료 · 정적 참고 이미지';
    final Widget media;
    if (item.isDiagram) {
      media = CaseMediaHero(
        caseId: item.id,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: palette.paper, borderRadius: BorderRadius.circular(12)),
          child: CaseDiagram(diagram: item.diagram!, columns: columns),
        ),
      );
    } else {
      final image = item.image!;
      final picture = Image.asset(publicAsset(image.src), semanticLabel: image.alt, fit: BoxFit.contain, filterQuality: FilterQuality.medium);
      if (item.fit == 'cover') {
        media = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
            child: CaseMediaHero(
              caseId: item.id,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(aspectRatio: image.width / image.height, child: picture),
              ),
            ),
          ),
        );
      } else {
        media = CaseMediaHero(
          caseId: item.id,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: palette.paper, borderRadius: BorderRadius.circular(12)),
            child: AspectRatio(aspectRatio: image.width / image.height, child: picture),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        media,
        const SizedBox(height: 8),
        KText(caption, style: textStyle(size: 13, color: palette.ink3)),
      ],
    );
  }
}
