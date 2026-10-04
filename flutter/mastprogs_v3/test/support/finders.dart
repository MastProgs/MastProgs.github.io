// 글자 찾기 도우미. 화면 글자에는 한국어 낱말 줄바꿈 방지 문자(U+2060)가 들어 있으므로 비교 전에 지운다.
// AI-NOTE: 입력된 연락처는 복사 가능한 SelectableText로 표시된다. 일반 Text만 찾으면 실제 표시된 연락처를 누락하므로 두 종류의 최상위 글 위젯을 검사한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String plain(String text) => text.replaceAll('⁠', '');

String? _textOf(Widget widget) {
  if (widget is Text) return widget.data ?? widget.textSpan?.toPlainText();
  if (widget is RichText) return widget.text.toPlainText();
  if (widget is SelectableText) return widget.data ?? widget.textSpan?.toPlainText();
  return null;
}

/// 정확히 같은 글자(줄바꿈 방지 문자 제외).
Finder findText(String text) => find.byWidgetPredicate((widget) {
  final value = _textOf(widget);
  return (widget is Text || widget is SelectableText) && value != null && plain(value) == text;
}, description: 'text "$text"');

/// 글자 포함(문자열 또는 정규식).
Finder findTextContaining(Pattern pattern) => find.byWidgetPredicate((widget) {
  final value = _textOf(widget);
  return (widget is Text || widget is SelectableText) && value != null && plain(value).contains(pattern);
}, description: 'text containing "$pattern"');
