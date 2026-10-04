// 화면 테마(어두운/밝은) 상태. 앱 전체에 하나만 있다(메인과 상세 페이지가 같은 상태를 쓴다).
// AI-NOTE: 저장 값은 "dark" | "light" 둘뿐이고(키 mastprogs-theme), 허용 목록 밖의 값·읽기 실패는 기본 dark 다.
// 다른 탭에서 바꾸면 storage 이벤트로 이 탭도 따라간다(허용 값만 반영). 다른 상태(연락처·진행·방문 정보)는 저장하지 않는다.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../platform/host_platform.dart';

const List<String> themes = ['dark', 'light'];
const String defaultTheme = 'dark';

bool isTheme(Object? value) => themes.contains(value);

String normalizeTheme(Object? value) => isTheme(value) ? value! as String : defaultTheme;

String toggledTheme(Object? value) => normalizeTheme(value) == 'dark' ? 'light' : 'dark';

class ThemeCopy {
  const ThemeCopy({required this.label, required this.switchTo});

  final String label;
  final String switchTo;
}

const Map<String, ThemeCopy> themeCopy = {
  'dark': ThemeCopy(label: '어두운 테마', switchTo: '밝은 테마로 전환'),
  'light': ThemeCopy(label: '밝은 테마', switchTo: '어두운 테마로 전환'),
};

class ThemeController extends ChangeNotifier {
  ThemeController(this._platform) : _theme = normalizeTheme(_platform.readTheme()) {
    _subscription = _platform.themeChanges.listen((value) => _apply(normalizeTheme(value)));
  }

  final HostPlatform _platform;
  late final StreamSubscription<String?> _subscription;
  String _theme;

  String get theme => _theme;
  bool get isDark => _theme == 'dark';
  ThemeCopy get copy => themeCopy[_theme]!;

  void _apply(String next) {
    if (next == _theme) return;
    _theme = next;
    notifyListeners();
  }

  void setTheme(Object? value) {
    final next = normalizeTheme(value);
    _platform.writeTheme(next);
    _apply(next);
  }

  void toggle() => setTheme(toggledTheme(_theme));

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
