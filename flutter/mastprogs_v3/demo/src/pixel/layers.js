// 원본 v8 레이어·셀 데이터 도우미(순수 함수, node:test 가 직접 import).
// AI-NOTE: 원본 Hero Pixel Studio(studio-src/style.js)의 unpack·sourceFrame 과 같은 규칙이다.
// - 셀 data 는 base64 RLE: 3바이트마다 [개수 uint16 LE, 마스터 색 번호 1바이트]. 펼친 길이가 w×h 와 다르면 오류.
// - 합성: 레이어 0번(맨 아래)부터 차례로, 'composite'(원본이 저장해 둔 합성 참조, 숨김)와 숨긴 레이어는 건너뛰고,
//   색 번호가 0 이 아닌 픽셀은 덮어쓴다(마지막 불투명이 이김). 0 은 투명.
// - 색: 마스터 번호 i 의 색 = PALETTE_DEFS[i - 1](pixel-source-colors.json). 0 번은 투명이라 색이 없다.
// 위치는 다시 계산하지 않는다. 모든 프레임은 원본의 같은 84×89 캔버스·같은 기준점(pivotX·soleRow)에 있다.

export const COMPOSITE_LAYER = "composite";

const MOTION_OF_KEY = /^([a-z]+)-(\d+)$/;

function base64ToBytes(text) {
  if (typeof atob === "function") return Uint8Array.from(atob(text), (c) => c.charCodeAt(0));
  return Uint8Array.from(globalThis.Buffer.from(text, "base64"));
}

// 셀 하나를 w×h 색 번호 배열로 펼친다(원본 unpack 의 RLE 부분).
export function decodeCel(cel) {
  const bytes = base64ToBytes(cel.data);
  if (bytes.length % 3 !== 0) throw new Error("RLE 길이가 3의 배수가 아닙니다");
  const raw = new Uint8Array(cel.w * cel.h);
  let pos = 0;
  for (let i = 0; i < bytes.length; i += 3) {
    const n = bytes[i] | (bytes[i + 1] << 8);
    if (pos + n > raw.length) throw new Error("셀 픽셀 수가 크기보다 많습니다");
    raw.fill(bytes[i + 2], pos, pos + n);
    pos += n;
  }
  if (pos !== raw.length) throw new Error("셀 픽셀 수가 크기와 다릅니다");
  return raw;
}

// 원본 PALETTE_DEFS([[이름, "rrggbb"], ...]) → 색 표. table[0] = null(투명), table[i] = defs[i - 1] 의 RGB.
export function sourceColorTable(defs) {
  return [null, ...defs.map(([, hex]) => {
    const value = parseInt(hex, 16);
    return [(value >> 16) & 255, (value >> 8) & 255, value & 255];
  })];
}

// JSON → 화면이 쓰는 모델. 셀 펼침 결과는 모델 안에 한 번만 보관한다(데이터 크기로 상한이 정해짐).
export function buildLayerModel(json) {
  const layers = json.layers.map((layer, index) => ({
    index,
    name: layer.name,
    visible: Boolean(layer.visible),
    isComposite: layer.name === COMPOSITE_LAYER,
  }));
  const compositeIndex = layers.findIndex((layer) => layer.isComposite);
  const frames = json.frames.map((frame, index) => {
    const match = MOTION_OF_KEY.exec(frame.key);
    if (!match) throw new Error(`프레임 이름 형식이 다릅니다: ${frame.key}`);
    if (frame.cels.length !== layers.length) throw new Error(`셀 수가 레이어 수와 다릅니다: ${frame.key}`);
    return { index, key: frame.key, motion: match[1], step: Number(match[2]), ms: frame.ms, advance: frame.advance, cels: frame.cels };
  });
  const motions = {};
  for (const frame of frames) (motions[frame.motion] ??= []).push(frame.index);
  const decoded = new Map();
  return Object.freeze({
    res: json.res,
    width: json.width,
    height: json.height,
    pivotX: json.pivotX,
    soleRow: json.soleRow,
    crownRow: json.crownRow,
    layers,
    compositeIndex,
    frames,
    motions,
    // 레이어 표시 기본값(원본 파일 그대로: composite 만 숨김).
    defaultVisibility: Object.freeze(layers.map((layer) => layer.visible)),
    celRaw(frameIndex, layerIndex) {
      const cel = frames[frameIndex].cels[layerIndex];
      if (!cel) return null;
      let raw = decoded.get(cel);
      if (!raw) {
        raw = decodeCel(cel);
        decoded.set(cel, raw);
      }
      return raw;
    },
  });
}

export const frameIndexOf = (model, motionId, step) => model.motions[motionId]?.[step];

// 원본 sourceFrame 합성. visibility 는 레이어 수 길이의 참/거짓 배열(없으면 원본 표시값).
// 반환: { indices: 색 번호(w×h), owner: 픽셀을 마지막으로 칠한 레이어 번호(-1 = 빈칸) }
export function compositeFrame(model, frameIndex, visibility = model.defaultVisibility) {
  const { width, height } = model;
  const indices = new Uint8Array(width * height);
  const owner = new Int16Array(width * height).fill(-1);
  const frame = model.frames[frameIndex];
  for (let li = 0; li < model.layers.length; li += 1) {
    if (model.layers[li].isComposite || !visibility[li]) continue;
    const cel = frame.cels[li];
    if (!cel) continue;
    const raw = model.celRaw(frameIndex, li);
    for (let y = 0; y < cel.h; y += 1) {
      for (let x = 0; x < cel.w; x += 1) {
        const value = raw[y * cel.w + x];
        if (!value) continue;
        const p = (cel.y + y) * width + cel.x + x;
        indices[p] = value;
        owner[p] = li;
      }
    }
  }
  return { indices, owner };
}

// 원본이 저장해 둔 합성 참조 셀(숨김 레이어)을 캔버스 크기로 펼친다. 다시 합성한 결과와 같은지 검사할 때 쓴다.
export function compositeReference(model, frameIndex) {
  const out = new Uint8Array(model.width * model.height);
  const cel = model.frames[frameIndex].cels[model.compositeIndex];
  if (!cel) return out;
  const raw = model.celRaw(frameIndex, model.compositeIndex);
  for (let y = 0; y < cel.h; y += 1) out.set(raw.subarray(y * cel.w, (y + 1) * cel.w), (cel.y + y) * model.width + cel.x);
  return out;
}

// 색 번호 → RGBA(알파 0/255 만). 원본 mapping.indexToRGBA 와 같은 규칙.
export function indicesToRgba(indices, table) {
  const out = new Uint8ClampedArray(indices.length * 4);
  for (let i = 0; i < indices.length; i += 1) {
    const idx = indices[i];
    if (!idx) continue;
    const rgb = table[idx];
    if (!rgb) throw new Error(`색 표에 없는 번호입니다: ${idx}`);
    out[i * 4] = rgb[0];
    out[i * 4 + 1] = rgb[1];
    out[i * 4 + 2] = rgb[2];
    out[i * 4 + 3] = 255;
  }
  return out;
}

// 표시 상태 도우미. 모두 새 배열을 돌려준다(원본 기본값은 바꾸지 않음).
export const toggleLayer = (visibility, index) => visibility.map((on, i) => (i === index ? !on : on));
export const isolateLayer = (model, index) => model.layers.map((layer, i) => !layer.isComposite && i === index);
export const visibilityKey = (visibility) => visibility.map((on) => (on ? 1 : 0)).join("");

// 타임라인 칸 상태: 셀이 없음 / 직전 프레임과 같은 셀(위치·픽셀 동일) / 새 셀.
export function celState(model, frameIndex, layerIndex, previousFrameIndex) {
  const cel = model.frames[frameIndex].cels[layerIndex];
  if (!cel) return "empty";
  if (previousFrameIndex === null || previousFrameIndex === undefined) return "key";
  const prev = model.frames[previousFrameIndex].cels[layerIndex];
  if (prev && prev.data === cel.data && prev.x === cel.x && prev.y === cel.y) return "same";
  return "key";
}

export function celBounds(model, frameIndex, layerIndex) {
  const cel = model.frames[frameIndex].cels[layerIndex];
  return cel ? { x: cel.x, y: cel.y, w: cel.w, h: cel.h } : null;
}
