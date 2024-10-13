import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/provider.dart';
import 'package:provider/provider.dart';

class ColorStyle {
  static Color getColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.light
        ? Colors.black
        : Colors.white;
  }
}
