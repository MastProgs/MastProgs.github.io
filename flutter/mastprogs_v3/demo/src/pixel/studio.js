// /sprite 작업 화면의 색 설정·재생 한 칸 전환(순수 함수, node:test 가 직접 import).
// AI-NOTE: usePixelPreview 가 이 모듈만으로 색 설정 상태를 바꾼다. 여기 있는 어떤 전환도 재생(playing)을 건드리지 않는다:
// 사용자 지시로 팔레트·외곽선·세트·비율을 바꿔도 재생은 계속되고, 멈추는 것은 프레임 직접 선택과 재생 버튼뿐이다.
import { DEFAULT_PALETTE_RATIO, DEFAULT_SET_ID, PIXEL_PRESETS, SOURCE_SET_ID } from "../content/pixelStudio.js";
import { hexToRgb } from "./palette.js";
import { cyclesFor } from "./playback.js";

// ── 외곽선 색 ─────────────────────────────────────────────
// mode "auto": 테마·프리셋에서 고른다(어두운 테마 = 기존 outline, 밝은 테마 = outlineLight 어두운 색).
// mode "manual": 사용자가 고른 색을 그대로 쓴다. 프리셋을 바꾸거나 테마를 바꿔도 덮지 않는다.
export const OUTLINE_MODES = Object.freeze(["auto", "manual"]);

export function autoOutlineColor(presetId, theme) {
  const preset = PIXEL_PRESETS.find((item) => item.id === presetId) ?? PIXEL_PRESETS[0];
  return theme === "light" ? preset.outlineLight : preset.outline;
}

// 캔버스·색 입력·캐시 키가 모두 이 값 하나를 쓴다(표시된 색과 그려진 색이 어긋나지 않게).
export function effectiveOutlineColor(style, theme) {
  if (style.outlineMode === "manual" && hexToRgb(style.outlineManual)) return style.outlineManual.toLowerCase();
  return autoOutlineColor(style.presetId, theme);
}

// ── 팔레트 세트 ───────────────────────────────────────────
// '원본 색상'(SOURCE_SET_ID)은 매핑 단계를 건너뛴다(set = null). 알 수 없는 id 만 첫 세트로 돌아가며,
// 원본 색상을 고른 상태를 AAP-64 로 바꾸지 않는다.
export function resolvePaletteSet(sets, setId) {
  if (setId === SOURCE_SET_ID) return { mode: "source", set: null };
  return { mode: "set", set: sets.find((item) => item.id === setId) ?? sets[0] };
}

export const isKnownSetId = (sets, id) => id === SOURCE_SET_ID || sets.some((item) => item.id === id);

// ── 색 설정 상태 ──────────────────────────────────────────
export const INITIAL_STYLE = Object.freeze({
  presetId: "original",
  customAccent: null,
  outlineOn: false,
  outlineMode: "auto",
  outlineManual: null,
  setId: DEFAULT_SET_ID,
  ratio: DEFAULT_PALETTE_RATIO,
  // 사람이 색을 직접 고르면 참. 자동 연출(showcase)은 이 값이 거짓일 때만 돈다.
  touched: false,
});

const clampRatio100 = (value) => {
  const n = Math.round(Number(value));
  return Number.isFinite(n) ? Math.min(100, Math.max(0, n)) : null;
};

// action.type: preset | accent | toggleOutline | outlineColor | outlineAuto | set | ratio | showcase
// 유효하지 않은 입력이면 같은 객체를 그대로 돌려준다(리렌더 없음). playing 같은 재생 필드는 결과에 절대 넣지 않는다.
export function styleReducer(state, action) {
  switch (action.type) {
    case "preset":
      if (!PIXEL_PRESETS.some((item) => item.id === action.id)) return state;
      // 외곽선이 자동이면 effectiveOutlineColor 가 새 프리셋 색을 고른다. 직접 고른 색은 그대로 둔다.
      return { ...state, presetId: action.id, touched: true };
    case "accent":
      if (!hexToRgb(action.hex)) return state;
      return { ...state, customAccent: action.hex, presetId: "custom", touched: true };
    case "toggleOutline":
      return { ...state, outlineOn: !state.outlineOn, touched: true };
    case "outlineColor":
      if (!hexToRgb(action.hex)) return state;
      return { ...state, outlineMode: "manual", outlineManual: action.hex.toLowerCase(), outlineOn: true, touched: true };
    case "outlineAuto":
      // 마지막으로 고른 색은 남겨 둔다(다시 직접 고르면 그 색에서 시작).
      return state.outlineMode === "auto" ? state : { ...state, outlineMode: "auto", touched: true };
    case "set":
      if (!isKnownSetId(action.sets, action.id)) return state;
      return { ...state, setId: action.id, touched: true };
    case "ratio": {
      const ratio = clampRatio100(action.value);
      if (ratio === null) return state;
      return { ...state, ratio, touched: true };
    }
    case "showcase":
      // 자동 연출: 손대기 전까지만 프리셋·외곽선 켬/끔을 돌린다. 외곽선 색은 자동 모드라 따로 정하지 않는다.
      if (state.touched) return state;
      return { ...state, presetId: action.presetId, outlineOn: action.outline };
    default:
      return state;
  }
}

// ── 재생 한 칸 ────────────────────────────────────────────
// 이 칸에서 다음 모션을 꺼내야 하는지(마지막 사이클의 마지막 프레임 다음). 꺼냄(주머니 변경)은 이 판단 뒤 상태 갱신 함수 "밖"에서
// 한 번만 한다. StrictMode 는 상태 갱신 함수를 두 번 부르므로 그 안에서 주머니를 꺼내면 모션을 건너뛴다.
export function needsNextMotion(state, motionsById, hold = false) {
  const motion = motionsById[state.motion];
  if (state.frame + 1 < motion.frames.length) return false;
  return !hold && state.loop + 1 >= cyclesFor(state.motion);
}

// 순수 전환: nextMotion 은 needsNextMotion 이 참일 때 미리 꺼내 둔 값이다.
export function advancePlayback(state, motionsById, { nextMotion = null, hold = false } = {}) {
  const motion = motionsById[state.motion];
  const frame = state.frame + 1;
  if (frame < motion.frames.length) return { ...state, frame };
  const loop = state.loop + 1;
  if (hold || loop < cyclesFor(state.motion)) return { ...state, frame: 0, loop: hold ? 0 : loop };
  if (!nextMotion) return { ...state, frame: 0, loop: 0 };
  return { motion: nextMotion, frame: 0, loop: 0, turn: state.turn + 1 };
}

// 타이머 한 번의 처리: 최신 커밋 상태(latest)가 타이머를 건 때의 상태(snapshot)와 다르면 아무것도 꺼내지 않는다(오래된 타이머).
// 같으면 필요할 때만 주머니에서 한 번 꺼내고, 상태 갱신 함수는 snapshot 과 같을 때만 전환하는 순수 함수다.
export function planTick({ snapshot, latest, motionsById, hold, draw }) {
  if (latest !== snapshot) return null;
  const nextMotion = needsNextMotion(snapshot, motionsById, hold) ? draw() : null;
  return (state) => (state === snapshot ? advancePlayback(state, motionsById, { nextMotion, hold }) : state);
}
