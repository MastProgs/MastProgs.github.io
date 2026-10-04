{{flutter_js}}
{{flutter_build_config}}

// 표준 Flutter 로더 설정만 둔다(앱 로직·JS 런타임 없음).
// 누락 글리프 대체 글꼴 주소를 같은 출처 /fonts/ 로 바꿔 fonts.gstatic.com 요청을 막는다.
// 화면 글자는 번들한 Pretendard·Roboto Mono 로 모두 덮이며, CanvasKit 기본 글꼴(Roboto)도 번들 글꼴로 등록되어 있다(pubspec).
// CanvasKit 은 flutter build web --no-web-resources-cdn 으로 build/web/canvaskit/ 에서 읽는다.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: '/fonts/',
  },
});
