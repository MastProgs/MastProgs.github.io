// 팔레트 세트(AAP-64 등) 적용 도우미(순수 함수).
// AI-NOTE: 원본 Hero Pixel Studio 의 postfx/mapping.js(buildColorTable)·color.js 규칙을 옮겼다.
// - 세트 색은 입력 순서를 지킨 중복 제거(dedupeHexList), 최근접 색은 OKLab 제곱 거리(원본 DEFAULT_STYLE.method 'oklab'),
//   동률은 앞쪽(엄격 < 비교). 원본은 마스터 색마다 표를 만들지만, 여기서는 포인트 색·추가 외곽선을 바꾼 "뒤"의 실제 출력 색마다
//   최근접을 고른다(그래서 100% 에서는 외곽선까지 모든 불투명 픽셀이 세트 안 색이 된다).
// - 적용 비율(0..1): 출력 = 원래 색 + (세트 색 − 원래 색) × 비율, 채널마다 반올림. 0 은 그대로, 1 은 세트 색 그대로.
//   알파는 건드리지 않는다(투명 픽셀은 색도 그대로).

export function normalizeHex(hex) {
  const match = /^#?([0-9a-f]{6})$/i.exec(String(hex ?? "").trim());
  if (!match) throw new Error(`색은 #RRGGBB 형식이어야 합니다: ${hex}`);
  return `#${match[1].toLowerCase()}`;
}

const hexRgb = (hex) => {
  const value = parseInt(hex.slice(1), 16);
  return [(value >> 16) & 255, (value >> 8) & 255, value & 255];
};

export function dedupeHexList(hexes) {
  const seen = new Set();
  const colors = [];
  for (const hex of hexes) {
    const norm = normalizeHex(hex);
    if (seen.has(norm)) continue;
    seen.add(norm);
    colors.push(norm);
  }
  return colors;
}

// pixel-palette-sets.json → [{ id, name, colors: '#rrggbb'[], rgb: [r,g,b][], lab }]
export function buildPaletteSets(json) {
  return Object.freeze(
    json.map((set) => {
      const colors = dedupeHexList(set.colors);
      const rgb = colors.map(hexRgb);
      return Object.freeze({ id: set.id, name: set.name, colors, rgb, lab: rgb.map(rgbToOklab) });
    }),
  );
}

const srgbToLinear = (v) => {
  const f = v / 255;
  return f <= 0.04045 ? f / 12.92 : ((f + 0.055) / 1.055) ** 2.4;
};

// sRGB 8bit → OKLab(원본 color.js 와 같은 행렬).
export function rgbToOklab(rgb) {
  const r = srgbToLinear(rgb[0]);
  const g = srgbToLinear(rgb[1]);
  const b = srgbToLinear(rgb[2]);
  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return [
    0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s,
  ];
}

export function nearestSetIndex(rgb, set) {
  const lab = rgbToOklab(rgb);
  let best = 0;
  let bestDist = Infinity;
  for (let i = 0; i < set.lab.length; i += 1) {
    const q = set.lab[i];
    const d = (lab[0] - q[0]) ** 2 + (lab[1] - q[1]) ** 2 + (lab[2] - q[2]) ** 2;
    if (d < bestDist) {
      best = i;
      bestDist = d;
    }
  }
  return best;
}

export const clampRatio = (value) => {
  const n = Number(value);
  return Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : 0;
};

// 새 배열을 돌려준다. nearestCache(Map rgbKey → [r,g,b])를 주면 같은 세트 안에서 최근접 계산을 다시 쓴다.
export function applyPaletteSet(data, set, ratio, nearestCache = new Map()) {
  const t = clampRatio(ratio);
  const out = new Uint8ClampedArray(data);
  if (!set || t === 0) return out;
  for (let i = 0; i < out.length; i += 4) {
    if (out[i + 3] === 0) continue;
    const key = (out[i] << 16) | (out[i + 1] << 8) | out[i + 2];
    let target = nearestCache.get(key);
    if (!target) {
      target = set.rgb[nearestSetIndex([out[i], out[i + 1], out[i + 2]], set)];
      nearestCache.set(key, target);
    }
    if (t === 1) {
      out[i] = target[0];
      out[i + 1] = target[1];
      out[i + 2] = target[2];
    } else {
      out[i] = Math.round(out[i] + (target[0] - out[i]) * t);
      out[i + 1] = Math.round(out[i + 1] + (target[1] - out[i + 1]) * t);
      out[i + 2] = Math.round(out[i + 2] + (target[2] - out[i + 2]) * t);
    }
  }
  return out;
}

// 실제 출력의 색 점유율. 불투명 픽셀만 센다. set 을 주면 세트 안 색인지(inSet)와 세트 안 픽셀 비율을 함께 준다.
export function colorShares(data, set = null) {
  const counts = new Map();
  let total = 0;
  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] === 0) continue;
    const key = (data[i] << 16) | (data[i + 1] << 8) | data[i + 2];
    counts.set(key, (counts.get(key) ?? 0) + 1);
    total += 1;
  }
  const members = set ? new Set(set.colors) : null;
  let inSetPixels = 0;
  const entries = [...counts.entries()]
    .map(([key, count]) => {
      const hex = `#${key.toString(16).padStart(6, "0")}`;
      const inSet = members ? members.has(hex) : false;
      if (inSet) inSetPixels += count;
      return { hex, count, share: total ? count / total : 0, inSet };
    })
    .sort((a, b) => b.count - a.count || (a.hex < b.hex ? -1 : 1));
  return { total, entries, inSetShare: total ? inSetPixels / total : 0 };
}
