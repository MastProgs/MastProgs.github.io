// 브라우저와 맞닿는 최소 경계(테마 저장, 탭 가림, 동작 줄이기 설정, 새 탭 열기, 기본 색 선택 창).
// AI-NOTE: 앱 로직·모델은 브라우저 API 를 직접 부르지 않고 이 인터페이스만 쓴다. 웹 구현은 dart:js_interop + package:web(platform_web.dart),
// 테스트·VM 은 메모리 구현(MemoryHostPlatform)이다. React 설정과 같이 저장하는 값은 테마("dark" | "light") 하나뿐이다.
// 경로 판정·문서 제목은 Flutter 라우터(usePathUrlStrategy)와 Title 위젯이 맡으므로 여기에 두지 않는다.
import 'dart:async';

import 'platform_stub.dart' if (dart.library.js_interop) 'platform_web.dart' as impl;

abstract class HostPlatform {
  /// 저장된 테마 값 원문(없거나 읽기 실패면 null). 허용 값 판정은 ThemeController 가 한다.
  String? readTheme();

  /// 테마 값을 저장한다. 실패해도 예외를 던지지 않고 false.
  bool writeTheme(String value);

  /// 다른 탭에서 같은 키가 바뀌면 새 값(원문)을 알린다.
  Stream<String?> get themeChanges;

  /// 문서가 가려졌는지(document.hidden).
  bool get documentHidden;

  /// 가림 상태가 바뀔 때마다 hidden 값을 알린다.
  Stream<bool> get visibilityChanges;

  /// prefers-reduced-motion: reduce.
  bool get prefersReducedMotion;

  Stream<bool> get reducedMotionChanges;

  /// 같은 출처 경로나 허용된 외부 주소를 새 탭으로 연다(noopener, noreferrer).
  void openNewTab(String url);

  /// 브라우저 기본 색 선택 창을 연다. 고르는 동안 onInput 이 값을 보낸다(형식 '#rrggbb'). 창을 쓸 수 없으면 false.
  bool pickColor({required String initial, required void Function(String hex) onInput});

  void dispose() {}
}

HostPlatform createHostPlatform() => impl.createPlatform();

/// 테스트·VM 용 메모리 구현. 호출 기록을 남겨 위젯 테스트가 새 탭·색 선택 요청을 확인할 수 있다.
class MemoryHostPlatform implements HostPlatform {
  MemoryHostPlatform({String? storedTheme, bool hidden = false, bool reducedMotion = false, this.storageThrows = false})
    : _theme = storedTheme,
      _hidden = hidden,
      _reduced = reducedMotion;

  String? _theme;
  bool _hidden;
  bool _reduced;
  final bool storageThrows;
  final List<String> openedTabs = [];
  final List<String> colorRequests = [];
  void Function(String hex)? lastColorInput;
  final StreamController<String?> _themeController = StreamController<String?>.broadcast();
  final StreamController<bool> _visibilityController = StreamController<bool>.broadcast();
  final StreamController<bool> _motionController = StreamController<bool>.broadcast();

  String? get storedTheme => _theme;

  @override
  String? readTheme() => storageThrows ? null : _theme;

  @override
  bool writeTheme(String value) {
    if (storageThrows) return false;
    _theme = value;
    return true;
  }

  @override
  Stream<String?> get themeChanges => _themeController.stream;

  /// 다른 탭에서 값이 바뀐 것처럼 흉내 낸다.
  void simulateStorage(String? value) {
    _theme = value;
    _themeController.add(value);
  }

  @override
  bool get documentHidden => _hidden;

  @override
  Stream<bool> get visibilityChanges => _visibilityController.stream;

  void setHidden(bool hidden) {
    _hidden = hidden;
    _visibilityController.add(hidden);
  }

  @override
  bool get prefersReducedMotion => _reduced;

  @override
  Stream<bool> get reducedMotionChanges => _motionController.stream;

  void setReducedMotion(bool value) {
    _reduced = value;
    _motionController.add(value);
  }

  @override
  void openNewTab(String url) => openedTabs.add(url);

  @override
  bool pickColor({required String initial, required void Function(String hex) onInput}) {
    colorRequests.add(initial);
    lastColorInput = onInput;
    return true;
  }

  @override
  void dispose() {
    _themeController.close();
    _visibilityController.close();
    _motionController.close();
  }
}
