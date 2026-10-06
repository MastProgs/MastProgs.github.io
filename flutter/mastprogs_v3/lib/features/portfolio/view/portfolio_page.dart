// 메인 이력서 페이지(React App.jsx 메인 + SiteHeader·StickyBar·SiteFooter 이식).
// AI-NOTE: 사용자 최신 지시에 따른 섹션 순서: 01 소개 → 02 학력·역량 → 03 핵심 구현(AgentWorkflow → Sprite 파이프라인 → Voice to SRT 요약,
// 상세는 각각 같은 탭의 /workflow·/sprite·/subtitles) → 04 회사 경력 → 05 작업 사례 → 푸터. 페이지의 유일한 h1 은 소개의 이름이다.
// 헤더·고정 바·모바일 메뉴에는 이름과 "연락"이 없다(이름·사진·항상 보이는 연락처 칸은 01 소개, 이름은 푸터).
// 고정 바는 400px 아래로 내려가면 나타나고, 숨김 상태에서는 포커스·보조기기 트리에서 빠진다(중복 내비게이션 방지).
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/route_links.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../content/content_repository.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/theme_toggle.dart';
import '../portfolio_content.dart';
import 'cases_section.dart';
import 'core_section.dart';
import 'portfolio_scope.dart';
import 'portfolio_widgets.dart';
import 'profile_section.dart';
import 'resume_sections.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key, required this.anchor, required this.anchorSerial, required this.revealEnabled});

  final String? anchor;
  final int anchorSerial;
  final bool revealEnabled;

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  late final Future<MainContent> _content = AppServices.of(context).content.main();
  final ScrollController _scroll = ScrollController();
  final AnchorRegistry _anchors = AnchorRegistry();
  final ValueNotifier<bool> _stickyVisible = ValueNotifier(false);
  double _revealAfter = 400;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(PortfolioPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.anchorSerial != oldWidget.anchorSerial && widget.anchor != null) _scheduleAnchor(widget.anchor!);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _stickyVisible.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 감시 위치(revealAfter)가 화면 위로 지나가면 고정 바를 보인다.
    _stickyVisible.value = _scroll.offset > _revealAfter;
  }

  void _scheduleAnchor(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToAnchor(id));
  }

  void _scrollToAnchor(String id) {
    if (!mounted || !_scroll.hasClients) return;
    final metrics = ScreenMetrics.of(context);
    var targetId = id;
    if (id.startsWith('case-') && _anchors.contextOf(id) == null) targetId = 'cases';
    final target = _anchors.contextOf(targetId) ?? (id.startsWith('case-') ? _anchors.contextOf('cases') : null);
    if (target == null) return;
    final box = target.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    // [id] scroll-margin-top: 고정 바 + 16px. 핵심 구현 하위 항목·연락처 칸은 80px.
    final margin = const {'workflow', 'sprite', 'subtitles', 'contact'}.contains(id) ? 80.0 : metrics.anchorMargin;
    final position = _scroll.position;
    final offset = (position.pixels + top - margin).clamp(position.minScrollExtent, position.maxScrollExtent);
    if (ReducedMotion.read(context)) {
      _scroll.jumpTo(offset);
    } else {
      _scroll.animateTo(offset, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    }
    if (id.startsWith('case-')) _anchors.revealCase?.call(id);
  }

  void _goToAnchor(String id) => AppServices.of(context).navigator.goToAnchor(id);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MainContent>(
      future: _content,
      builder: (context, snapshot) {
        final content = snapshot.data;
        if (content == null) return const SizedBox.expand();
        _revealAfter = content.site.stickyRevealAfter;
        return PortfolioScope(
          anchors: _anchors,
          onAnchor: _goToAnchor,
          revealEnabled: widget.revealEnabled,
          child: _PortfolioBody(
            content: content,
            scroll: _scroll,
            stickyVisible: _stickyVisible,
            onFirstLayout: () {
              if (widget.anchor != null) _scheduleAnchor(widget.anchor!);
            },
          ),
        );
      },
    );
  }
}

class _PortfolioBody extends StatefulWidget {
  const _PortfolioBody({required this.content, required this.scroll, required this.stickyVisible, required this.onFirstLayout});

  final MainContent content;
  final ScrollController scroll;
  final ValueNotifier<bool> stickyVisible;
  final VoidCallback onFirstLayout;

  @override
  State<_PortfolioBody> createState() => _PortfolioBodyState();
}

class _PortfolioBodyState extends State<_PortfolioBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFirstLayout());
  }

  @override
  Widget build(BuildContext context) {
    final site = widget.content.site;
    final resume = widget.content.resume;
    return Stack(
      children: [
        Positioned.fill(
          child: Scrollbar(
            controller: widget.scroll,
            child: SingleChildScrollView(
              controller: widget.scroll,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: shellMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SiteHeader(site: site),
                      ProfileSection(site: site, resume: resume),
                      SkillsSection(site: site, resume: resume),
                      CoreSection(site: site, sprite: widget.content.sprite),
                      CareerSection(site: site, resume: resume),
                      CasesSection(site: site),
                      SiteFooter(name: site.name),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: StickyBar(site: site, visible: widget.stickyVisible),
        ),
      ],
    );
  }
}

/// 헤더: 하는 일·배경 열 + 이력 바로가기 열 + 테마 전환. 1100px 이하는 테마 전환 + 메뉴 버튼(펼치면 상위 섹션 링크 5개).
class SiteHeader extends StatefulWidget {
  const SiteHeader({super.key, required this.site});

  final SiteContent site;

  @override
  State<SiteHeader> createState() => _SiteHeaderState();
}

class _SiteHeaderState extends State<SiteHeader> {
  bool _menuOpen = false;
  final FocusNode _toggleFocus = FocusNode(debugLabel: 'menu-toggle');
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _toggleKey = GlobalKey();

  @override
  void dispose() {
    _toggleFocus.dispose();
    super.dispose();
  }

  void _setMenu(bool open) {
    if (_menuOpen == open) return;
    setState(() => _menuOpen = open);
    if (open) {
      HardwareKeyboard.instance.addHandler(_onKey);
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    } else {
      HardwareKeyboard.instance.removeHandler(_onKey);
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    }
  }

  // Esc 로 닫고 메뉴 버튼으로 포커스를 돌린다.
  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      _setMenu(false);
      _toggleFocus.requestFocus();
      return true;
    }
    return false;
  }

  // 메뉴·메뉴 버튼 밖을 누르면 닫는다.
  void _onPointer(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    bool inside(GlobalKey key) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return false;
      return (box.localToGlobal(Offset.zero) & box.size).contains(event.position);
    }

    if (!inside(_menuKey) && !inside(_toggleKey)) _setMenu(false);
  }

  @override
  void deactivate() {
    if (_menuOpen) {
      HardwareKeyboard.instance.removeHandler(_onKey);
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
      _menuOpen = false;
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final site = widget.site;
    final compact = metrics.atMost(Breakpoints.desktop);
    final scope = PortfolioScope.of(context);
    final columnStyle = textStyle(size: 15, color: palette.ink2, height: 21 / 15, em: -0.015);
    final headingStyle = textStyle(size: 15, weight: FontWeight.w600, color: palette.ink, height: 22 / 15, em: -0.015);

    Widget cell(String heading, List<Widget> items, {bool first = false}) => Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: EdgeInsets.only(left: first ? 0 : 20),
      decoration: first
          ? null
          : BoxDecoration(
              border: Border(left: BorderSide(color: palette.line)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KText(heading, style: headingStyle),
          const SizedBox(height: 4),
          ...items,
        ],
      ),
    );

    final tools = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ThemeToggle(compact: true),
        if (compact) ...[
          const SizedBox(width: 8),
          KeyedSubtree(
            key: _toggleKey,
            child: CircleIconButton(
              icon: _menuOpen ? PhosphorIconsRegular.x : PhosphorIconsRegular.list,
              iconSize: 22,
              label: _menuOpen ? '메뉴 닫기' : '메뉴 열기',
              tooltip: false,
              focusNode: _toggleFocus,
              onPressed: () => _setMenu(!_menuOpen),
            ),
          ),
        ],
      ],
    );

    return Padding(
      key: scope.anchors.keyFor('top'),
      padding: EdgeInsets.fromLTRB(metrics.pad, 24, metrics.pad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact)
            Row(children: [const Spacer(), tools])
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, column) in site.headerColumns.indexed)
                  Expanded(
                    flex: i == 0 ? 299 : 290,
                    child: cell(column.heading, [for (final item in column.items) KText(item, style: columnStyle)], first: i == 0),
                  ),
                Expanded(
                  flex: 246,
                  child: Semantics(
                    container: true,
                    label: '이력 바로가기',
                    child: cell(site.resumeNavHeading, [
                      for (final link in site.resumeLinks)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnchorTextLink(label: link.label, anchor: link.anchor, style: columnStyle, growUnderline: true),
                        ),
                    ]),
                  ),
                ),
                tools,
              ],
            ),
          if (compact && _menuOpen)
            Container(
              key: _menuKey,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: palette.line)),
              ),
              child: Semantics(
                container: true,
                label: '주요 메뉴',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final link in site.navLinks)
                      Pressable(
                        isLink: true,
                        linkUrl: anchorLink(link.anchor),
                        semanticLabel: link.label,
                        excludeChildSemantics: true,
                        radius: BorderRadius.circular(6),
                        onPressed: () {
                          _setMenu(false);
                          scope.onAnchor(link.anchor);
                        },
                        builder: (context, state) => Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.centerLeft,
                          child: KText(
                            link.label,
                            style: textStyle(size: 17, weight: FontWeight.w600, color: palette.ink),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 0),
        ],
      ),
    );
  }
}

/// 고정 바: 섹션 링크 + 테마 전환. 첫 링크가 다른 섹션 제목과 같은 왼쪽 기준선에 온다.
class StickyBar extends StatelessWidget {
  const StickyBar({super.key, required this.site, required this.visible});

  final SiteContent site;
  final ValueListenable<bool> visible;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final scope = PortfolioScope.of(context);
    final duration = motionDuration(context, Motion.med);
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, shown, _) => IgnorePointer(
        ignoring: !shown,
        child: ExcludeFocus(
          excluding: !shown,
          child: ExcludeSemantics(
            excluding: !shown,
            child: AnimatedSlide(
              duration: duration,
              curve: Motion.easeOut,
              offset: shown ? Offset.zero : const Offset(0, -1),
              child: AnimatedOpacity(
                duration: duration,
                curve: Motion.easeOut,
                opacity: shown ? 1 : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.stickyBg,
                    border: Border(bottom: BorderSide(color: palette.line)),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: shellMaxWidth),
                      child: Container(
                        height: metrics.stickyBarHeight,
                        padding: EdgeInsets.symmetric(horizontal: metrics.pad),
                        child: Row(
                          children: [
                            Expanded(
                              child: Transform.translate(
                                offset: Offset(metrics.mobile ? -10 : -14, 0),
                                child: Semantics(
                                  container: true,
                                  label: site.stickyLabel,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        for (final link in site.navLinks)
                                          Pressable(
                                            isLink: true,
                                            linkUrl: anchorLink(link.anchor),
                                            semanticLabel: link.label,
                                            excludeChildSemantics: true,
                                            radius: BorderRadius.circular(6),
                                            onPressed: () => scope.onAnchor(link.anchor),
                                            builder: (context, state) => Container(
                                              constraints: const BoxConstraints(minHeight: 44),
                                              padding: EdgeInsets.symmetric(horizontal: metrics.mobile ? 10 : 14),
                                              alignment: Alignment.center,
                                              child: Text(
                                                link.label,
                                                style: textStyle(size: 14.5, color: state.hovered ? palette.ink : palette.ink2, em: -0.01),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: metrics.mobile ? 8 : 24),
                            const ThemeToggle(compact: true),
                          ],
                        ),
                      ),
                    ),
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

/// 푸터: 이름만(사용자 요청으로 안내 문구·직함 없음).
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(metrics.stageInset, 72, metrics.stageInset, 0),
      child: Container(
        padding: const EdgeInsets.only(top: 28, bottom: 40),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.line)),
        ),
        child: Align(
          alignment: metrics.mobile ? Alignment.centerLeft : Alignment.centerRight,
          child: KText(name, style: textStyle(size: 14, color: palette.ink2)),
        ),
      ),
    );
  }
}
