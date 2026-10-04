// 색 토큰(React src/styles/theme.css 이식). 메인 이력서·/workflow·/sprite·/subtitles 공용.
// AI-NOTE: 색은 이 파일 한 곳에만 둔다. 기본은 승인된 어두운 화면 값 그대로이고, 밝은 테마는 같은 이름의 토큰을 밝은 값으로 바꾼다.
// 밝은 판(stage*)과 그 위 어두운 칩·버튼(stageInk + 흰 글자)은 두 테마에서 같은 대비라 stageInk 계열은 테마와 무관하게 같다.
// 이미지에는 반전·필터를 쓰지 않는다. 테마 상태·저장은 app/theme/theme_controller.dart 가 맡는다(저장 값은 "dark" | "light" 하나뿐).
import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.bg,
    required this.ink,
    required this.inkMax,
    required this.inkHi,
    required this.ink2,
    required this.inkSoft,
    required this.inkMute,
    required this.inkDim,
    required this.ink3,
    required this.inkFaint,
    required this.line,
    required this.line1,
    required this.line2,
    required this.line3,
    required this.line4,
    required this.line5,
    required this.orange,
    required this.orangeDeep,
    required this.orangeInk,
    required this.orangeText,
    required this.orangeTint,
    required this.lime,
    required this.okLine,
    required this.fault,
    required this.faultText,
    required this.faultTextHi,
    required this.faultTint,
    required this.faultLine,
    required this.warnText,
    required this.warnLine,
    required this.warnTint,
    required this.infoText,
    required this.stage,
    required this.stageInk,
    required this.stageInk2,
    required this.stageInk3,
    required this.stageLine,
    required this.panel,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.tile,
    required this.tileLine,
    required this.ghostLine,
    required this.hoverWash,
    required this.scrim,
    required this.shadow,
    required this.stickyBg,
    required this.hero2,
    required this.paper,
  });

  final Brightness brightness;
  final Color bg;
  final Color ink;
  final Color inkMax;
  final Color inkHi;
  final Color ink2;
  final Color inkSoft;
  final Color inkMute;
  final Color inkDim;
  final Color ink3;
  final Color inkFaint;
  final Color line;
  final Color line1;
  final Color line2;
  final Color line3;
  final Color line4;
  final Color line5;
  final Color orange;
  final Color orangeDeep;
  final Color orangeInk;
  final Color orangeText;
  final Color orangeTint;
  final Color lime;
  final Color okLine;
  final Color fault;
  final Color faultText;
  final Color faultTextHi;
  final Color faultTint;
  final Color faultLine;
  final Color warnText;
  final Color warnLine;
  final Color warnTint;
  final Color infoText;
  final Color stage;
  final Color stageInk;
  final Color stageInk2;
  final Color stageInk3;
  final Color stageLine;
  final Color panel;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color tile;
  final Color tileLine;
  final Color ghostLine;
  final Color hoverWash;
  final Color scrim;
  final Color shadow;
  final Color stickyBg;
  final Color hero2;
  final Color paper;

  bool get isDark => brightness == Brightness.dark;

  // 테마와 무관한 고정 색(원본 CSS 의 리터럴 값).
  static const Color white = Color(0xFFFFFFFF);
  static const Color primaryHover = Color(0xFFFF6C35);
  static const Color darkButtonHover = Color(0xFF2A2A2A);
  static const Color segmentedBg = Color(0xFFF3F1ED);
  static const Color segmentedInk = Color(0xFF2A2926);
  static const Color segmentedChecked = Color(0xFF141414);
  static const Color msgHumanBg = Color(0xFFF7F5F1);
  static const Color decisionTagBg = Color(0xFFDFE8FF);
  static const Color decisionTagInk = Color(0xFF1E3F8A);
  static const Color chatNoteIcon = Color(0xFF3D63C9);
  static const Color coverMediaBg = Color(0xFF161A22);
  static const Color returnFlash = Color(0xCCFF2E63);
  static const Color transportShadow = Color(0x2E141414);
  static const Color pixelOnionPrev = Color(0xFFE84040);
  static const Color pixelOnionNext = Color(0xFF3878F0);

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0D0D0D),
    ink: Color(0xFFF3F2EF),
    inkMax: Color(0xFFFFFFFF),
    inkHi: Color(0xFFD6D4CF),
    ink2: Color(0xFFCBC9C4),
    inkSoft: Color(0xFFBDBAB4),
    inkMute: Color(0xFFA3A19C),
    inkDim: Color(0xFF8A8884),
    ink3: Color(0xFF8E8C88),
    inkFaint: Color(0xFF77746E),
    line: Color(0xFF2C2C2C),
    line1: Color(0xFF2A2A2A),
    line2: Color(0xFF3A3A3A),
    line3: Color(0xFF4A4A4A),
    line4: Color(0xFF555555),
    line5: Color(0xFF6B6B6B),
    orange: Color(0xFFFF5A1F),
    orangeDeep: Color(0xFFE24A12),
    orangeInk: Color(0xFF1D0A03),
    orangeText: Color(0xFFFFB08F),
    orangeTint: Color(0xFF24170F),
    lime: Color(0xFF9BE15D),
    okLine: Color(0x739BE15D),
    fault: Color(0xFFFF2E63),
    faultText: Color(0xFFFF8AA8),
    faultTextHi: Color(0xFFFFD3DE),
    faultTint: Color(0xFF2A0F17),
    faultLine: Color(0x99FF2E63),
    warnText: Color(0xFFF2C66D),
    warnLine: Color(0xFF6B5524),
    warnTint: Color(0xFF3A2F17),
    infoText: Color(0xFF7AA7FF),
    stage: Color(0xFFEBE9E4),
    stageInk: Color(0xFF161616),
    stageInk2: Color(0xFF3F3D39),
    stageInk3: Color(0xFF77746E),
    stageLine: Color(0xFFCDC9C2),
    panel: Color(0xFF141414),
    surface: Color(0xFF151515),
    surface2: Color(0xFF1D1D1D),
    surface3: Color(0xFF232323),
    tile: Color(0xFF1C1C1C),
    tileLine: Color(0xFF333333),
    ghostLine: Color(0xFFE6E4DF),
    hoverWash: Color(0x0FFFFFFF),
    scrim: Color(0xB8050505),
    shadow: Color(0x73000000),
    stickyBg: Color(0xF00D0D0D),
    hero2: Color(0xFFFBFAF8),
    paper: Color(0xFFF6F4EF),
  );

  // 밝은 테마: 같은 따뜻한 회색·주황 언어를 종이색 바탕으로 옮긴다. 본문 대비는 WCAG AA(4.5:1) 이상(원본 theme.css 값).
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF6F4EF),
    ink: Color(0xFF161513),
    inkMax: Color(0xFF0D0D0C),
    inkHi: Color(0xFF24231F),
    ink2: Color(0xFF3A3834),
    inkSoft: Color(0xFF46443F),
    inkMute: Color(0xFF55524D),
    inkDim: Color(0xFF5F5C56),
    ink3: Color(0xFF64615B),
    inkFaint: Color(0xFF75716A),
    line: Color(0xFFDCD8D0),
    line1: Color(0xFFE3DFD7),
    line2: Color(0xFFCFCAC1),
    line3: Color(0xFFBCB7AD),
    line4: Color(0xFFA8A399),
    line5: Color(0xFF8D887E),
    orange: Color(0xFFD9430C),
    orangeDeep: Color(0xFFB8380A),
    orangeInk: Color(0xFFFFF6F1),
    orangeText: Color(0xFFA3360A),
    orangeTint: Color(0xFFFDE9DF),
    lime: Color(0xFF2F7A14),
    okLine: Color(0x802F7A14),
    fault: Color(0xFFCF1046),
    faultText: Color(0xFFA80F3C),
    faultTextHi: Color(0xFF860B30),
    faultTint: Color(0xFFFDE4EA),
    faultLine: Color(0x8CCF1046),
    warnText: Color(0xFF7A5200),
    warnLine: Color(0xFFD2AD57),
    warnTint: Color(0xFFF8EDD4),
    infoText: Color(0xFF2449A8),
    stage: Color(0xFFFFFEFB),
    stageInk: Color(0xFF161616),
    stageInk2: Color(0xFF3F3D39),
    stageInk3: Color(0xFF77746E),
    stageLine: Color(0xFFD8D3CA),
    panel: Color(0xFFEEEAE3),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF5F2EC),
    surface3: Color(0xFFE5E1D9),
    tile: Color(0xFFFDFCF9),
    tileLine: Color(0xFFD6D2CA),
    ghostLine: Color(0xFF24231F),
    hoverWash: Color(0x0D14120E),
    scrim: Color(0x731E1C18),
    shadow: Color(0x29281E14),
    stickyBg: Color(0xF0F6F4EF),
    hero2: Color(0xFF141311),
    paper: Color(0xFFFBFAF7),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(covariant AppPalette? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
