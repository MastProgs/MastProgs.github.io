// 픽셀 팔레트 도우미(순수 함수, node:test 가 직접 import).
// AI-NOTE: 원본 프레임의 실제 색 목록(이산 팔레트)을 읽고, 포인트 색 무리(파란 머리 계열)만 목표 색으로 바꾼 대응표를 만든 뒤
// 픽셀마다 정확히 같은 RGB 를 표에서 찾아 바꾼다. CSS hue-rotate/filter 같은 연속 필터가 아니라 팔레트 항목 단위 교체다.
// 알파는 절대 바꾸지 않는다(원본의 0/255 그대로). 투명 픽셀(알파 0)은 색도 건드리지 않는다.

export const rgbKey = (r, g, b) => (r << 16) | (g << 8) | b;

export function hexToRgb(hex) {
  const match = /^#?([0-9a-f]{6})$/i.exec(String(hex ?? "").trim());
  if (!match) return null;
  const value = parseInt(match[1], 16);
  return [(value >> 16) & 255, (value >> 8) & 255, value & 255];
}

export const rgbToHex = ([r, g, b]) => `#${[r, g, b].map((value) => value.toString(16).padStart(2, "0")).join("")}`;

export function rgbToHsl([r, g, b]) {
  const rn = r / 255;
  const gn = g / 255;
  const bn = b / 255;
  const max = Math.max(rn, gn, bn);
  const min = Math.min(rn, gn, bn);
  const l = (max + min) / 2;
  if (max === min) return [0, 0, l];
  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  let h;
  if (max === rn) h = (gn - bn) / d + (gn < bn ? 6 : 0);
  else if (max === gn) h = (bn - rn) / d + 2;
  else h = (rn - gn) / d + 4;
  return [h * 60, s, l];
}

export function hslToRgb([h, s, l]) {
  if (s === 0) {
    const v = Math.round(l * 255);
    return [v, v, v];
  }
  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;
  const hue = (t) => {
    let x = t;
    if (x < 0) x += 1;
    if (x > 1) x -= 1;
    if (x < 1 / 6) return p + (q - p) * 6 * x;
    if (x < 1 / 2) return q;
    if (x < 2 / 3) return p + (q - p) * (2 / 3 - x) * 6;
    return p;
  };
  const hn = (((h % 360) + 360) % 360) / 360;
  return [hue(hn + 1 / 3), hue(hn), hue(hn - 1 / 3)].map((value) => Math.round(value * 255));
}

const clamp01 = (value) => Math.min(1, Math.max(0, value));
const hueDistance = (a, b) => {
  const d = Math.abs(a - b) % 360;
  return d > 180 ? 360 - d : d;
};

// 불투명 픽셀의 고유 색과 개수. 여러 프레임을 넘기면 합친다(모든 프레임에 같은 대응표를 쓰기 위해).
export function extractPalette(pixelArrays) {
  const counts = new Map();
  for (const data of pixelArrays) {
    for (let i = 0; i < data.length; i += 4) {
      if (data[i + 3] === 0) continue;
      const key = rgbKey(data[i], data[i + 1], data[i + 2]);
      counts.set(key, (counts.get(key) ?? 0) + 1);
    }
  }
  return [...counts.entries()]
    .map(([key, count]) => ({ key, rgb: [(key >> 16) & 255, (key >> 8) & 255, key & 255], count }))
    .sort((a, b) => b.count - a.count || a.key - b.key);
}

const ACCENT_MIN_SAT = 0.18;
const ACCENT_HUE_RANGE = 40;
const BLUE_RANGE = [170, 270];

// 포인트 색 무리의 기준 색상(hue). 파란 계열(원본 용사의 머리)을 먼저 찾고, 없으면 가장 많이 쓰인 채도 높은 색을 쓴다.
export function detectAccentHue(palette) {
  const saturated = palette
    .map((entry) => ({ ...entry, hsl: rgbToHsl(entry.rgb) }))
    .filter(({ hsl: [, s, l] }) => s >= 0.25 && l >= 0.15 && l <= 0.85);
  const blue = saturated.filter(({ hsl: [h] }) => h >= BLUE_RANGE[0] && h <= BLUE_RANGE[1]);
  const pool = blue.length ? blue : saturated;
  if (!pool.length) return null;
  const best = [...pool].sort((a, b) => b.count - a.count || a.key - b.key)[0];
  return best.hsl[0];
}

export function accentGroup(palette, accentHue) {
  if (accentHue === null || accentHue === undefined) return [];
  return palette.filter((entry) => {
    const [h, s] = rgbToHsl(entry.rgb);
    return s >= ACCENT_MIN_SAT && hueDistance(h, accentHue) <= ACCENT_HUE_RANGE;
  });
}

// 대응표(Map key → [r,g,b]). target 이 없으면 원본 그대로(빈 표). 무리 안 색의 명암 순서는 유지한다(음영 단계 보존).
export function buildPaletteMap(palette, target) {
  const map = new Map();
  const targetRgb = typeof target === "string" ? hexToRgb(target) : target;
  if (!targetRgb) return map;
  const accentHue = detectAccentHue(palette);
  const group = accentGroup(palette, accentHue);
  if (!group.length) return map;
  const [th, ts, tl] = rgbToHsl(targetRgb);
  const weight = group.reduce((sum, entry) => sum + entry.count, 0);
  const refS = group.reduce((sum, entry) => sum + rgbToHsl(entry.rgb)[1] * entry.count, 0) / weight;
  const refL = group.reduce((sum, entry) => sum + rgbToHsl(entry.rgb)[2] * entry.count, 0) / weight;
  for (const entry of group) {
    const [, s, l] = rgbToHsl(entry.rgb);
    const next = hslToRgb([th, clamp01(refS > 0 ? (s * ts) / refS : ts), clamp01(l + (tl - refL) * 0.6)]);
    map.set(entry.key, next);
  }
  return map;
}

// 새 배열에 색만 바꿔 쓴다(입력은 그대로). 알파·투명 픽셀은 손대지 않는다.
export function recolorPixels(data, map) {
  const out = new Uint8ClampedArray(data);
  if (!map || map.size === 0) return out;
  for (let i = 0; i < out.length; i += 4) {
    if (out[i + 3] === 0) continue;
    const next = map.get(rgbKey(out[i], out[i + 1], out[i + 2]));
    if (!next) continue;
    out[i] = next[0];
    out[i + 1] = next[1];
    out[i + 2] = next[2];
  }
  return out;
}

// 캐시 키에 쓰는 정규화된 설정 문자열.
export const paletteKey = (target) => (target ? rgbToHex(typeof target === "string" ? hexToRgb(target) ?? [0, 0, 0] : target) : "original");
