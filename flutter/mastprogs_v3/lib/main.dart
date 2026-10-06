// 앱 진입점. GitHub Pages가 제공하는 루트 문서 하나에서 해시 경로를 읽는다.
// AI-NOTE: GitHub Pages는 /workflow 등의 요청을 index.html로 재작성하지 않는다. HashUrlStrategy는
// /#/workflow처럼 루트만 요청하므로 상세 화면의 직접 진입·새로고침도 동작한다.
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'platform/host_platform.dart';

void main() {
  setUrlStrategy(const HashUrlStrategy());
  runApp(PortfolioApp(platform: createHostPlatform()));
}
