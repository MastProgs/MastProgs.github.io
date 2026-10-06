// 경로 → 페이지 라우터(Flutter Router + 경로 URL 전략).
// AI-NOTE: 네 경로(/, /workflow, /sprite, /subtitles)와 끝 슬래시는 routes.dart 가 판정하고, 브라우저 주소는 보인 그대로 되돌려 보고한다
// (미지 경로도 주소를 바꾸지 않고 메인 이력서를 그린다). 페이지가 바뀌면 키가 달라져 이전 페이지의 프레임·재생 상태가 남지 않는다.
// 메인 안 앵커는 ?anchor=about 등을 앱 해시 경로 안에 넣고(브라우저 기록에 남음), 페이지가 그 위치로 스크롤한다.
// 문서 제목은 각 페이지의 Title 위젯이 정한다(상세를 떠나면 메인 제목으로 돌아온다).
// AI-NOTE: React 의 lazy 청크 대신, 무거운 데이터(레이어·팔레트 세트·골격·자막 예시)를 그 경로에 들어갔을 때만 자산에서 읽는다
// (ContentRepository). 코드 분할(deferred import)은 쓰지 않는다.
import 'package:flutter/widgets.dart';

import '../features/portfolio/view/portfolio_page.dart';
import '../features/sprite/view/sprite_page.dart';
import '../features/subtitles/view/subtitles_page.dart';
import '../features/workflow/view/workflow_page.dart';
import '../widgets/pdf_download_button.dart';
import 'app_scope.dart';
import 'routes.dart';

class AppRouteParser extends RouteInformationParser<AppLocation> {
  const AppRouteParser();

  @override
  Future<AppLocation> parseRouteInformation(RouteInformation routeInformation) async => AppLocation(routeInformation.uri);

  @override
  RouteInformation restoreRouteInformation(AppLocation configuration) => RouteInformation(uri: configuration.uri);
}

class AppRouterDelegate extends RouterDelegate<AppLocation> with ChangeNotifier implements AppNavigator {
  AppRouterDelegate({required void Function(String url) openTab, AppLocation? initial})
    : _openTab = openTab,
      _location = initial ?? AppLocation(Uri(path: '/'));

  final void Function(String url) _openTab;
  AppLocation _location;

  /// 앵커 요청 번호. 같은 앵커를 다시 눌러도 스크롤하도록 매번 늘린다.
  int _anchorSerial = 0;

  /// 페이지를 새로 만든 횟수(같은 경로로 다시 들어오면 상태를 처음부터).
  int _pageSerial = 0;

  AppLocation get location => _location;

  @override
  AppLocation get currentConfiguration => _location;

  @override
  Future<void> setNewRoutePath(AppLocation configuration) async {
    final samePage = configuration.page == _location.page && configuration.uri.path == _location.uri.path;
    if (!samePage) _pageSerial += 1;
    if (configuration.fragment != null) _anchorSerial += 1;
    _location = configuration;
    notifyListeners();
  }

  @override
  Future<bool> popRoute() async => false;

  @override
  void go(String path) {
    _pageSerial += 1;
    _location = AppLocation(Uri(path: path));
    notifyListeners();
  }

  @override
  void goToAnchor(String id) {
    _anchorSerial += 1;
    _location = _location.withFragment(id);
    notifyListeners();
  }

  @override
  void openNewTab(String url) => _openTab(url);

  @override
  Widget build(BuildContext context) {
    final location = _location;
    final key = ValueKey('${location.page.name}-$_pageSerial');
    final content = switch (location.page) {
      AppPage.main => PortfolioPage(key: key, anchor: location.fragment, anchorSerial: _anchorSerial, revealEnabled: !location.isTarget),
      AppPage.workflow => WorkflowPage(key: key),
      AppPage.sprite => SpritePage(key: key),
      AppPage.subtitles => SubtitlesPage(key: key),
    };
    final page = Title(
      title: location.page.documentTitle,
      color: const Color(0xFF0D0D0D),
      child: Stack(
        children: [
          content,
          Positioned(right: 20, bottom: 20 + MediaQuery.paddingOf(context).bottom, child: const PdfDownloadButton()),
        ],
      ),
    );
    // 대화상자·툴팁이 올라갈 Navigator. 페이지는 하나뿐이고(브라우저 기록은 라우터 주소가 맡음) 전환 없이 바로 바뀐다.
    return Navigator(
      pages: [_InstantPage(key: key, child: page)],
      onDidRemovePage: (_) {},
    );
  }
}

class _InstantPage extends Page<void> {
  const _InstantPage({required LocalKey super.key, required this.child});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => _InstantRoute(this);
}

/// 같은 키의 페이지가 새 값(예: 앵커 요청)으로 바뀌면 Navigator 가 settings 를 갱신하고 다시 그린다. 그때 최신 child 를 읽는다.
class _InstantRoute extends PageRoute<void> {
  _InstantRoute(_InstantPage page) : super(settings: page);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => (settings as _InstantPage).child;
}
