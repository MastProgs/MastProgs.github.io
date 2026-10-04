// 한 프레임을 화면 RGBA 로 만드는 순서(순수 함수). 화면(usePixelPreview)과 테스트가 같은 순서를 쓴다.
// AI-NOTE: 원본 레이어 합성(색 번호) → 원본 색 표 → 공통 여백 → 포인트 색 교체(기존 1행) → 추가 외곽선 → 팔레트 세트 적용(2행, 비율).
// 세트 적용이 맨 마지막이라 100% 에서는 외곽선을 포함한 모든 불투명 픽셀이 세트 색이 된다. 0% 면 기존 결과와 한 바이트도 다르지 않다.
import { compositeFrame, indicesToRgba } from "./layers.js";
import { addOutline, padPixels } from "./outline.js";
import { recolorPixels } from "./palette.js";
import { applyPaletteSet } from "./paletteSets.js";

export function processFrame({ model, table, frameIndex, visibility, pad, accentMap = null, outlineRgb = null, set = null, ratio = 0, nearestCache }) {
  const { indices } = compositeFrame(model, frameIndex, visibility);
  const base = padPixels(indicesToRgba(indices, table), model.width, model.height, pad);
  let pixels = recolorPixels(base.data, accentMap);
  if (outlineRgb) pixels = addOutline(pixels, base.width, base.height, outlineRgb);
  if (set && ratio > 0) pixels = applyPaletteSet(pixels, set, ratio, nearestCache);
  return { data: pixels, width: base.width, height: base.height };
}
