// 앱 진입점. 해시(#) 대신 경로 URL(/workflow 등)을 쓰고, 메인 앵커 주소(/#cases)도 첫 진입부터 그대로 읽는다.
// AI-NOTE: PathUrlStrategy(includeHash) 는 usePathUrlStrategy() 와 같은 경로 전략에 #fragment 보존만 더한 비 deprecated API 다.
// 로컬·배포 서버는 History API 경로를 index.html 로 재작성해야 직접 진입·새로 고침이 된다(없는 정적 자산은 실제 404).
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'platform/host_platform.dart';

void main() {
  setUrlStrategy(PathUrlStrategy(BrowserPlatformLocation(), true));
  runApp(PortfolioApp(platform: createHostPlatform()));
}
