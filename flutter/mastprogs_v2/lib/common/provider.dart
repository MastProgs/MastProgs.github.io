import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    loadTheme(); // 생성자에서 테마 로드
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    saveTheme(); // 테마 변경 시 저장
  }

  void loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTheme = prefs.getString('theme');

    if (savedTheme != null) {
      _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } else {
      // 시스템의 현재 테마 상태를 확인하여 초기화
      _themeMode =
          WidgetsBinding.instance.window.platformBrightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light;
    }
    notifyListeners(); // UI 업데이트
  }

  void saveTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('theme', _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }
}
