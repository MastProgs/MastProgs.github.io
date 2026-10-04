// 앱 뿌리: 테마(어두운 기본/밝은), 공용 서비스, 경로 라우터를 한곳에서 묶는다.
// AI-NOTE: 테마 상태는 ThemeController 하나뿐이고 메인·상세 페이지가 같은 상태를 쓴다. 새 탭은 저장된 같은 테마로 열린다.
// 동작 줄이기(prefers-reduced-motion)와 탭 가림(document.hidden)은 브라우저 경계(HostPlatform)에서 받아 위젯에 알린다.
import 'dart:async';

import 'package:flutter/material.dart';

import '../content/content_repository.dart';
import '../platform/host_platform.dart';
import 'app_scope.dart';
import 'router.dart';
import 'routes.dart';
import 'theme/palette.dart';
import 'theme/theme_controller.dart';
import 'theme/typography.dart';

class PortfolioApp extends StatefulWidget {
  const PortfolioApp({super.key, required this.platform, this.initialLocation, this.content});

  final HostPlatform platform;

  /// 테스트용 첫 주소. 앱 실행 때는 브라우저 주소(라우터 정보)를 쓴다.
  final String? initialLocation;
  final ContentRepository? content;

  @override
  State<PortfolioApp> createState() => _PortfolioAppState();
}

class _PortfolioAppState extends State<PortfolioApp> {
  late final ThemeController _theme = ThemeController(widget.platform);
  late final ContentRepository _content = widget.content ?? ContentRepository();
  late final ValueNotifier<bool> _reducedMotion = ValueNotifier(widget.platform.prefersReducedMotion);
  late final ValueNotifier<bool> _hidden = ValueNotifier(widget.platform.documentHidden);
  late final AppRouterDelegate _router = AppRouterDelegate(
    openTab: widget.platform.openNewTab,
    initial: widget.initialLocation == null ? null : AppLocation.parse(widget.initialLocation!),
  );
  late final PlatformRouteInformationProvider _routeProvider = PlatformRouteInformationProvider(
    initialRouteInformation: RouteInformation(uri: Uri.parse(widget.initialLocation ?? WidgetsBinding.instance.platformDispatcher.defaultRouteName)),
  );
  final List<StreamSubscription<bool>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(widget.platform.reducedMotionChanges.listen((value) => _reducedMotion.value = value))
      ..add(widget.platform.visibilityChanges.listen((value) => _hidden.value = value));
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _router.dispose();
    _routeProvider.dispose();
    _theme.dispose();
    _reducedMotion.dispose();
    _hidden.dispose();
    super.dispose();
  }

  ThemeData _themeData(AppPalette palette) => ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    fontFamily: AppFonts.sans,
    scaffoldBackgroundColor: palette.bg,
    canvasColor: palette.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: palette.orange, brightness: palette.brightness, surface: palette.surface),
    focusColor: Colors.transparent,
    hoverColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(selectionColor: palette.orange.withValues(alpha: 0.35)),
    scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStatePropertyAll(palette.line2)),
    extensions: [palette],
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _theme,
      builder: (context, _) {
        final palette = _theme.isDark ? AppPalette.dark : AppPalette.light;
        return AppServices(
          platform: widget.platform,
          theme: _theme,
          content: _content,
          navigator: _router,
          child: ReducedMotion(
            notifier: _reducedMotion,
            child: PageVisibility(
              notifier: _hidden,
              child: MaterialApp.router(
                title: AppPage.main.documentTitle,
                debugShowCheckedModeBanner: false,
                theme: _themeData(palette),
                themeAnimationDuration: Duration.zero,
                routerDelegate: _router,
                routeInformationParser: const AppRouteParser(),
                routeInformationProvider: _routeProvider,
                // 바탕 Material: 메뉴·선택 가능한 글자 같은 Material 위젯이 기대하는 조상(그림자·물결 효과는 쓰지 않음).
                builder: (context, child) => Material(
                  color: palette.bg,
                  child: DefaultTextStyle(
                    style: textStyle(size: 16, color: palette.ink),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
