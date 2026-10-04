// 앱 공용 서비스(브라우저 경계, 테마, 동작 줄이기·탭 가림 상태, 이동, 데이터 저장소)를 위젯 트리에 한 번만 내려 준다.
// AI-NOTE: 컴포넌트마다 테마·저장소를 따로 만들지 않는다. 동작 줄이기와 탭 가림은 ValueNotifier 하나씩이며,
// 필요한 위젯만 ReducedMotion.of / PageVisibility.hiddenOf 로 구독한다.
import 'package:flutter/widgets.dart';

import '../content/content_repository.dart';
import '../platform/host_platform.dart';
import 'theme/theme_controller.dart';

/// 페이지 이동 요청(같은 탭의 메인·앵커, 새 탭 상세).
abstract class AppNavigator {
  /// 같은 탭에서 경로로 이동(예: 상세 → '/').
  void go(String path);

  /// 메인 안 앵커로 이동(주소의 #fragment 도 함께 바뀐다).
  void goToAnchor(String id);

  /// 새 탭으로 연다(noopener, noreferrer).
  void openNewTab(String url);
}

class AppServices extends InheritedWidget {
  const AppServices({super.key, required this.platform, required this.theme, required this.content, required this.navigator, required super.child});

  final HostPlatform platform;
  final ThemeController theme;
  final ContentRepository content;
  final AppNavigator navigator;

  static AppServices of(BuildContext context) {
    final services = context.getInheritedWidgetOfExactType<AppServices>();
    assert(services != null, 'AppServices is missing above this widget');
    return services!;
  }

  @override
  bool updateShouldNotify(AppServices oldWidget) =>
      platform != oldWidget.platform || theme != oldWidget.theme || content != oldWidget.content || navigator != oldWidget.navigator;
}

/// prefers-reduced-motion 구독. 참이면 전환·애니메이션을 즉시 처리하고 자동 재생을 멈춘 채 시작한다.
class ReducedMotion extends InheritedNotifier<ValueNotifier<bool>> {
  const ReducedMotion({super.key, required ValueNotifier<bool> super.notifier, required super.child});

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ReducedMotion>()?.notifier?.value ?? false;

  /// 구독 없이 현재 값만 읽는다(이벤트 처리 중).
  static bool read(BuildContext context) => context.getInheritedWidgetOfExactType<ReducedMotion>()?.notifier?.value ?? false;
}

/// 문서 가림(document.hidden) 상태.
class PageVisibility extends InheritedNotifier<ValueNotifier<bool>> {
  const PageVisibility({super.key, required ValueNotifier<bool> super.notifier, required super.child});

  static ValueNotifier<bool>? notifierOf(BuildContext context) => context.getInheritedWidgetOfExactType<PageVisibility>()?.notifier;
}

/// 애니메이션 길이: 동작 줄이기면 0.
Duration motionDuration(BuildContext context, Duration duration) => ReducedMotion.of(context) ? Duration.zero : duration;
