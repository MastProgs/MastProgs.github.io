import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/provider.dart';
import 'package:provider/provider.dart';

class FontStyleNotoSans {
  static TextStyle getStyle({
    required BuildContext context,
    required double fontSize,
    Color lightColor = Colors.black,
    Color darkColor = Colors.white,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    return TextStyle(
      fontFamily: 'NotoSans',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: themeMode == ThemeMode.light ? lightColor : darkColor,
    );
  }
}

class FontStyleYouandiModernTR {
  static TextStyle getStyle({
    required BuildContext context,
    required double fontSize,
    Color lightColor = Colors.black,
    Color darkColor = Colors.white,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    return TextStyle(
      fontFamily: 'YouandiModernTR',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: themeMode == ThemeMode.light ? lightColor : darkColor,
    );
  }
}
