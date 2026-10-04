// 한 프레임을 화면 RGBA 로 만드는 순서(React src/pixel/pipeline.js 이식, 순수 함수). 화면(PixelStudioController)과 테스트가 같은 순서를 쓴다.
// AI-NOTE: 원본 레이어 합성(색 번호) → 원본 색 표 → 공통 여백 → 포인트 색 교체(기존 1행) → 추가 외곽선 → 팔레트 세트 적용(2행, 비율).
// 세트 적용이 맨 마지막이라 100% 에서는 외곽선을 포함한 모든 불투명 픽셀이 세트 색이 된다. 0% 면 기존 결과와 한 바이트도 다르지 않다.
import 'pixel_layers.dart';
import 'pixel_outline.dart';
import 'pixel_palette.dart';
import 'pixel_palette_sets.dart';

PixelImage processFrame({
  required PixelLayerModel model,
  required List<Rgb?> table,
  required int frameIndex,
  required List<bool> visibility,
  required int pad,
  Map<int, Rgb>? accentMap,
  Rgb? outlineRgb,
  PaletteSet? set,
  double ratio = 0,
  Map<int, Rgb>? nearestCache,
}) {
  final indices = compositeFrame(model, frameIndex, visibility).indices;
  final base = padPixels(indicesToRgba(indices, table), model.width, model.height, pad);
  var pixels = recolorPixels(base.data, accentMap);
  if (outlineRgb != null) pixels = addOutline(pixels, base.width, base.height, outlineRgb);
  if (set != null && ratio > 0) pixels = applyPaletteSet(pixels, set, ratio, nearestCache);
  return PixelImage(data: pixels, width: base.width, height: base.height);
}
