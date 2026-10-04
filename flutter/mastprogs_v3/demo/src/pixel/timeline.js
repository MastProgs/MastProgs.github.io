// 프레임 커서·어니언 스킨·기준선·중심 비교 도우미(순수 함수).
// AI-NOTE: 화면의 모든 캔버스·타임라인·어니언·골격 수치는 재생 상태 하나({ motion, frame })에서 나온다.
// - 반복 여부는 원본 engine-motion/*.json 의 loop 값 그대로: 걷기·달리기 반복, 공격 한 번(끝에서 멈춤).
// - 어니언은 같은 모션 안의 실제 앞/뒤 프레임만 쓴다. 반복 모션은 처음↔끝을 잇고, 공격은 처음 앞·끝 뒤가 없다.
//   다른 모션 프레임은 절대 섞지 않는다.
// - 원본 편집기(app.js)처럼 모든 프레임을 같은 캔버스·같은 기준점(pivotX)·같은 발바닥 줄(soleRow)에 놓는다(자동 자르기·가운데 맞춤 없음).

export const MOTION_LOOP = Object.freeze({ walk: true, run: true, attack: false });
export const isLooping = (motionId) => MOTION_LOOP[motionId] ?? true;

// 이전/다음 프레임 버튼: 반복 모션은 돌아가고, 공격은 처음·끝에서 멈춘다.
export function stepFrame(length, frame, delta, loop) {
  const next = frame + delta;
  if (loop) return ((next % length) + length) % length;
  return Math.min(length - 1, Math.max(0, next));
}

// 어니언 이웃(같은 모션 안 단계 번호). 없으면 null.
export function onionNeighbors(length, frame, loop) {
  if (length < 2) return { prev: null, next: null };
  if (loop) return { prev: (frame - 1 + length) % length, next: (frame + 1) % length };
  return { prev: frame > 0 ? frame - 1 : null, next: frame < length - 1 ? frame + 1 : null };
}

// 기준선 좌표(여백 pad 를 더한 공통 캔버스 기준, 픽셀 칸 번호).
export function guideCoordinates(model, pad) {
  return { pivotX: model.pivotX + pad, soleRow: model.soleRow + pad, crownRow: model.crownRow + pad };
}

// 앞(이전)·뒤(다음) 프레임 색. Aseprite 기본처럼 이전은 붉게, 다음은 푸르게 물들인다.
export const ONION_TINT = Object.freeze({ prev: [232, 64, 64], next: [56, 120, 240] });
const TINT_MIX = 0.6;

// 불투명 픽셀의 색을 tint 쪽으로 섞고 알파를 opacity 로 낮춘 새 배열.
export function tintPixels(data, tint, opacity) {
  const out = new Uint8ClampedArray(data.length);
  const alpha = Math.round(Math.min(1, Math.max(0, opacity)) * 255);
  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] === 0) continue;
    out[i] = Math.round(data[i] + (tint[0] - data[i]) * TINT_MIX);
    out[i + 1] = Math.round(data[i + 1] + (tint[1] - data[i + 1]) * TINT_MIX);
    out[i + 2] = Math.round(data[i + 2] + (tint[2] - data[i + 2]) * TINT_MIX);
    out[i + 3] = alpha;
  }
  return out;
}

// 아래 → 위 순서로 겹친다(일반 src-over). 현재 프레임을 마지막에 주면 어니언은 항상 현재 아래에 깔린다.
export function composeOver(layers, length) {
  const out = new Uint8ClampedArray(length);
  for (const src of layers) {
    if (!src) continue;
    for (let i = 0; i < length; i += 4) {
      const sa = src[i + 3] / 255;
      if (sa === 0) continue;
      const da = out[i + 3] / 255;
      const oa = sa + da * (1 - sa);
      for (let c = 0; c < 3; c += 1) out[i + c] = Math.round((src[i + c] * sa + out[i + c] * da * (1 - sa)) / oa);
      out[i + 3] = Math.round(oa * 255);
    }
  }
  return out;
}

// 불투명 픽셀의 경계 상자(없으면 null).
export function opaqueBounds(data, w, h) {
  let minX = w;
  let minY = h;
  let maxX = -1;
  let maxY = -1;
  for (let y = 0; y < h; y += 1) {
    for (let x = 0; x < w; x += 1) {
      if (data[(y * w + x) * 4 + 3] === 0) continue;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
  }
  return maxX < 0 ? null : { x: minX, y: minY, w: maxX - minX + 1, h: maxY - minY + 1 };
}

// 비교용: 프레임마다 실루엣 상자를 잘라 가운데(pivotX)·바닥(soleRow)에 맞췄다면 어디로 갔을지.
// 원본 픽셀을 그대로 정수 칸만큼 옮기며, dx·dy 는 실제 데이터에서 계산한 이동량이다(꾸며 낸 흔들림 없음).
export function recenterByBounds(data, w, h, { pivotX, soleRow }) {
  const box = opaqueBounds(data, w, h);
  const out = new Uint8ClampedArray(data.length);
  if (!box) return { data: out, dx: 0, dy: 0, box };
  const dx = pivotX - Math.floor(box.x + (box.w - 1) / 2);
  const dy = soleRow - (box.y + box.h - 1);
  for (let y = 0; y < h; y += 1) {
    const ty = y + dy;
    if (ty < 0 || ty >= h) continue;
    for (let x = 0; x < w; x += 1) {
      const tx = x + dx;
      if (tx < 0 || tx >= w) continue;
      const s = (y * w + x) * 4;
      if (data[s + 3] === 0) continue;
      out.set(data.subarray(s, s + 4), (ty * w + tx) * 4);
    }
  }
  return { data: out, dx, dy, box };
}
