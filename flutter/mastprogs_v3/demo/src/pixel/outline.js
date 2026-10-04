// 추가 외곽선 도우미(순수 함수).
// AI-NOTE: 원본이 그린 선(잉크)은 그대로 두고, 불투명 픽셀과 상하좌우로 맞닿은 투명 픽셀에만 한 칸 외곽선을 더한다
// (그래서 화면 이름이 "추가 외곽선"). 프레임 가장자리에 닿는 칼끝이 잘리지 않도록 모든 프레임을 같은 여백(pad)만큼
// 넓힌 공통 캔버스에 같은 위치로 옮긴 뒤 그린다 — 프레임마다 다시 가운데 맞추지 않으므로 기준점(pivot)이 흔들리지 않는다.

export const OUTLINE_PAD = 1;

// w×h RGBA 를 사방 pad 만큼 넓힌 새 배열로 옮긴다(위치 이동은 모든 프레임 동일).
export function padPixels(data, w, h, pad = OUTLINE_PAD) {
  const pw = w + pad * 2;
  const ph = h + pad * 2;
  const out = new Uint8ClampedArray(pw * ph * 4);
  for (let y = 0; y < h; y += 1) {
    out.set(data.subarray ? data.subarray(y * w * 4, (y + 1) * w * 4) : data.slice(y * w * 4, (y + 1) * w * 4), ((y + pad) * pw + pad) * 4);
  }
  return { data: out, width: pw, height: ph };
}

// 새 배열을 돌려준다. 원래 불투명 픽셀(알파 > 0)은 한 바이트도 바꾸지 않고, 더한 외곽선 픽셀은 알파 255.
export function addOutline(data, w, h, rgb) {
  const out = new Uint8ClampedArray(data);
  const opaque = (x, y) => x >= 0 && y >= 0 && x < w && y < h && data[(y * w + x) * 4 + 3] > 0;
  for (let y = 0; y < h; y += 1) {
    for (let x = 0; x < w; x += 1) {
      const i = (y * w + x) * 4;
      if (data[i + 3] > 0) continue;
      if (opaque(x - 1, y) || opaque(x + 1, y) || opaque(x, y - 1) || opaque(x, y + 1)) {
        out[i] = rgb[0];
        out[i + 1] = rgb[1];
        out[i + 2] = rgb[2];
        out[i + 3] = 255;
      }
    }
  }
  return out;
}

// 원본 불투명 픽셀이 공통 캔버스의 가장자리 한 줄에 닿지 않는지(외곽선이 잘리지 않는지) 확인한다.
export function fitsWithOutline(data, w, h) {
  for (let y = 0; y < h; y += 1) {
    for (let x = 0; x < w; x += 1) {
      if (data[(y * w + x) * 4 + 3] > 0 && (x === 0 || y === 0 || x === w - 1 || y === h - 1)) return false;
    }
  }
  return true;
}
