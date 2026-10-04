// Hero Pixel Studio 라이브 미리보기 문구와 팔레트 프리셋(assets/data/pixelStudio.json = React src/content/pixelStudio.js).
// AI-NOTE: 원본 용사 프레임을 다시 그리는 화면이다(새 그림·수치·내려받기 없음). 프리셋 색은 "포인트 색 무리"
// (원본의 파란 머리 계열)를 바꿀 목표 색이고, outline = 어두운 테마 자동 외곽선, outlineLight = 밝은 테마 자동 외곽선이다.
// 직접 고른 외곽선 색은 이 값으로 덮지 않는다. 값은 JSON 그대로 옮기기만 한다.
import '../../../core/json.dart';

class PixelPreset {
  const PixelPreset({required this.id, required this.label, required this.accent, required this.outline, required this.outlineLight});

  final String id;
  final String label;

  /// null 이면 원본 색 그대로('원본' 프리셋).
  final String? accent;
  final String outline;
  final String outlineLight;
}

class PixelStudioContent {
  PixelStudioContent.fromJson(Json json)
    : presets = List.unmodifiable([
        for (final preset in json.objs('PIXEL_PRESETS'))
          PixelPreset(
            id: preset.str('id'),
            label: preset.str('label'),
            accent: preset.strOrNull('accent'),
            outline: preset.str('outline'),
            outlineLight: preset.str('outlineLight'),
          ),
      ]),
      copy = json.texts('PIXEL_COPY'),
      spritePage = json.texts('SPRITE_PAGE'),
      spritePageIntro = json.obj('SPRITE_PAGE').strings('intro'),
      layerLabels = json.texts('LAYER_LABELS'),
      plantLabels = json.texts('PLANT_LABELS'),
      defaultSetId = json.str('DEFAULT_SET_ID'),
      sourceSetId = json.str('SOURCE_SET_ID'),
      defaultPaletteRatio = json.integer('DEFAULT_PALETTE_RATIO'),
      onionDefaultOpacity = json.number('ONION_DEFAULT_OPACITY');

  final List<PixelPreset> presets;
  final Map<String, String> copy;
  final Map<String, String> spritePage;
  final List<String> spritePageIntro;
  final Map<String, String> layerLabels;
  final Map<String, String> plantLabels;
  final String defaultSetId;

  /// 2행 '원본 색상' 선택지의 id(팔레트 세트 매핑을 건너뜀). 1행 '원본'(포인트 색 프리셋)과 다른 뜻이다.
  final String sourceSetId;

  /// '팔레트 적용 비율' 첫 값(0..100%, 사용자 요청으로 100).
  final int defaultPaletteRatio;

  /// 원본 편집기(app.js)의 수정 전 프레임 겹쳐 보기 불투명도와 같은 값.
  final double onionDefaultOpacity;

  List<String> get presetIds => [for (final preset in presets) preset.id];

  PixelPreset preset(String id) => presets.firstWhere((preset) => preset.id == id, orElse: () => presets.first);

  String layerLabel(String name) => layerLabels[name] ?? name;
}
