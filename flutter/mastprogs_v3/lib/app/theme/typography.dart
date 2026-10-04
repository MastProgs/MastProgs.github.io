// 글꼴·글자 모양 도우미.
// AI-NOTE: 글꼴은 자체 번들만 쓴다(원격 글꼴 금지). 본문은 원본 Pretendard Variable(같은 라이선스 원본 WOFF2 에서 변환한 TTF),
// 고정폭은 Roboto Mono(OFL). CSS 의 letter-spacing(em)은 글자 크기를 곱한 px 로, line-height 배수는 height 로 옮긴다.
// 가변 글꼴의 굵기는 fontWeight 와 함께 'wght' 축(fontVariations)으로도 지정해 엔진과 무관하게 같은 굵기를 쓴다.
// CSS font-variant-numeric: tabular-nums 는 tabular 옵션(FontFeature.tabularFigures)으로 옮긴다.
import 'package:flutter/widgets.dart';

abstract final class AppFonts {
  static const String sans = 'Pretendard';
  static const String mono = 'RobotoMono';
}

/// 원본 CSS 값 그대로의 글자 모양. em 은 letter-spacing 배수(예: -0.03em → -0.03).
TextStyle textStyle({
  required double size,
  FontWeight weight = FontWeight.w400,
  Color? color,
  double height = 1.5,
  double em = 0,
  bool tabular = false,
  bool mono = false,
  TextDecoration? decoration,
  Color? decorationColor,
  FontStyle? fontStyle,
}) {
  return TextStyle(
    fontFamily: mono ? AppFonts.mono : AppFonts.sans,
    // 고정폭 글꼴에 없는 한글(기록 경로 등)은 번들한 Pretendard 로 그린다(원격 대체 글꼴 요청 없음).
    fontFamilyFallback: mono ? const [AppFonts.sans] : null,
    fontSize: size,
    fontWeight: weight,
    fontVariations: mono ? null : [FontVariation.weight(weight.value.toDouble())],
    color: color,
    height: height,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: em == 0 ? null : em * size,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    decoration: decoration,
    decorationColor: decorationColor,
    fontStyle: fontStyle,
  );
}

final Map<String, String> _keepAllCache = <String, String>{};

bool _isCjk(int rune) =>
    (rune >= 0xAC00 && rune <= 0xD7A3) || // 한글 음절
    (rune >= 0x1100 && rune <= 0x11FF) || // 한글 자모
    (rune >= 0x3130 && rune <= 0x318F) || // 호환 자모
    (rune >= 0x4E00 && rune <= 0x9FFF); // 한자

bool _isSpace(int rune) => rune == 0x20 || rune == 0x0A || rune == 0x09 || rune == 0x3000;

/// CSS `word-break: keep-all` 흉내. 한글 낱말 안(공백 없이 이어진 글자 사이, 한쪽이라도 한글)에 줄바꿈 금지 문자(U+2060)를 넣어
/// 낱말 중간에서 줄이 바뀌지 않게 한다. 공백에서는 그대로 줄을 바꾼다. 화면 낭독은 원문(semanticsLabel)을 쓴다.
String keepAll(String text) {
  if (text.length < 2) return text;
  return _keepAllCache.putIfAbsent(text, () {
    final runes = text.runes.toList();
    var touched = false;
    final out = StringBuffer();
    for (var i = 0; i < runes.length; i += 1) {
      final rune = runes[i];
      out.writeCharCode(rune);
      if (i + 1 < runes.length) {
        final next = runes[i + 1];
        if (!_isSpace(rune) && !_isSpace(next) && (_isCjk(rune) || _isCjk(next))) {
          out.writeCharCode(0x2060);
          touched = true;
        }
      }
    }
    return touched ? out.toString() : text;
  });
}
