// 경로 판정(라우터 의존성 없이 pathname 만 본다, React App.jsx readEntryOptions 이식).
// AI-NOTE: 끝의 연속 슬래시를 지운 뒤 네 경로를 판정한다(/workflow///, /sprite/ 등). 그 밖의 경로는 404 가 아니라 메인 이력서다.
// ?state=target 은 메인 섹션 등장 애니메이션만 끄는 비교용 진입점이다. ?anchor=cases 는 메인 안의 앵커다.
// 기존 #fragment 주소도 파싱한다.
import '../core/constants.dart';

enum AppPage {
  main(mainDocumentTitle),
  workflow(workflowDocumentTitle),
  sprite(spriteDocumentTitle),
  subtitles(subtitlesDocumentTitle);

  const AppPage(this.documentTitle);

  final String documentTitle;
}

final RegExp _trailingSlashes = RegExp(r'/+$');

/// pathname → 페이지. 연속 끝 슬래시 허용, 미지 경로 = 메인.
AppPage resolvePage(String pathname) {
  final trimmed = pathname.replaceAll(_trailingSlashes, '');
  final path = trimmed.isEmpty ? '/' : trimmed;
  return switch (path) {
    workflowRoutePath => AppPage.workflow,
    spriteRoutePath => AppPage.sprite,
    subtitlesRoutePath => AppPage.subtitles,
    _ => AppPage.main,
  };
}

/// 현재 주소. uri 는 브라우저에 보인 그대로 되돌려 보고한다(정규화한 주소로 바꿔 쓰지 않음).
class AppLocation {
  AppLocation(this.uri) : page = resolvePage(uri.path);

  factory AppLocation.parse(String location) => AppLocation(Uri.tryParse(location) ?? Uri(path: '/'));

  final Uri uri;
  final AppPage page;

  String? get fragment {
    final anchor = uri.queryParameters['anchor'];
    if (anchor != null && anchor.isNotEmpty) return anchor;
    return uri.hasFragment && uri.fragment.isNotEmpty ? uri.fragment : null;
  }

  bool get isTarget => uri.queryParameters['state'] == targetStateQuery;

  AppLocation withFragment(String? fragment) {
    final query = Map<String, String>.of(uri.queryParameters)..remove('anchor');
    if (fragment != null) query['anchor'] = fragment;
    return AppLocation(Uri(path: uri.path, queryParameters: query.isEmpty ? null : query));
  }
}
