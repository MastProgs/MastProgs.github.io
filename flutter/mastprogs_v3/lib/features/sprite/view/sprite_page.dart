// /sprite 상세 페이지(React SpritePage.jsx 이식). 라우터가 이 라이브러리를 늦게 불러온다(원본 레이어·팔레트·골격 데이터도 이 페이지에서만 읽음).
// AI-NOTE: 머리글은 /workflow 와 같은 모양(이력서로 돌아가기 + 테마 전환), h1 하나, 같은 테마 상태. "사례 자세히 보기" 는 메인 레일과 같은
// 사례 대화상자로 원본 편집기 화면 캡처를 보여 준다. 미리보기가 화면 밖이면(완전히 벗어나면) 재생 타이머가 멈추고, 조금이라도 보이면 돈다.
import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../content/content_repository.dart';
import '../../../widgets/page_frame.dart';
import '../../portfolio/view/case_dialog.dart';
import '../controller/pixel_studio_controller.dart';
import 'studio_preview.dart';

class SpritePage extends StatefulWidget {
  const SpritePage({super.key});

  @override
  State<SpritePage> createState() => _SpritePageState();
}

class _SpritePageState extends State<SpritePage> {
  late final Future<SpritePageData> _data = AppServices.of(context).content.spritePage();

  @override
  Widget build(BuildContext context) => FutureBuilder<SpritePageData>(
    future: _data,
    builder: (context, snapshot) => snapshot.hasData ? SpriteDetailView(data: snapshot.data!) : const SizedBox.expand(),
  );
}

class SpriteDetailView extends StatefulWidget {
  const SpriteDetailView({super.key, required this.data});

  final SpritePageData data;

  @override
  State<SpriteDetailView> createState() => _SpriteDetailViewState();
}

class _SpriteDetailViewState extends State<SpriteDetailView> {
  late final PixelStudioController _controller;
  late final ThemeController _theme;
  final ScrollController _scroll = ScrollController();
  final GlobalKey _previewKey = GlobalKey(debugLabel: 'pixel-preview');
  final FocusNode _caseButton = FocusNode(debugLabel: 'pixel-open-case');
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppServices.of(context);
    if (!_initialized) {
      _initialized = true;
      _theme = services.theme;
      _controller = PixelStudioController(
        page: widget.data,
        theme: _theme.theme,
        reducedMotion: ReducedMotion.read(context),
        pageHidden: PageVisibility.notifierOf(context),
      );
      _theme.addListener(_onTheme);
      services.content.studio().then(_controller.attachStudio, onError: _controller.markFallback);
      _scroll.addListener(_updateInView);
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateInView());
    }
  }

  void _onTheme() => _controller.setTheme(_theme.theme);

  // IntersectionObserver(threshold 0.2) 콜백의 entry.isIntersecting: 미리보기가 화면과 조금이라도 겹치면 참.
  void _updateInView() {
    if (!mounted) return;
    final box = _previewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final height = MediaQuery.sizeOf(context).height;
    _controller.setInView(top < height && top + box.size.height > 0);
  }

  @override
  void dispose() {
    _theme.removeListener(_onTheme);
    _controller.dispose();
    _scroll.dispose();
    _caseButton.dispose();
    super.dispose();
  }

  Future<void> _openCase() async {
    final item = widget.data.site.caseById('case-pixel');
    await showCaseDialog(context, item: item, detailRoute: null, returnFocus: _caseButton);
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.data.content.spritePage;
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateInView());
    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShellWidth(child: DetailTopBar(backLabel: copy['backLabel']!)),
              ShellWidth(
                child: DetailIntro(eyebrow: copy['eyebrow']!, title: copy['title']!, paragraphs: widget.data.content.spritePageIntro),
              ),
              const SizedBox(height: 20),
              ShellWidth(
                child: KeyedSubtree(
                  key: _previewKey,
                  child: StudioPreview(controller: _controller, caseButtonFocus: _caseButton, onOpenCase: _openCase),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
