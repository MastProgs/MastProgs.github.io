// Hero Pixel Studio 라이브 미리보기 문구와 팔레트 프리셋.
// AI-NOTE: 원본 용사 프레임을 브라우저에서 다시 그리는 예시다(새 그림·수치·내려받기 없음). 프리셋 색은 "포인트 색 무리"
// (원본의 파란 머리 계열)를 바꿀 목표 색이고, 외곽선 색은 원본 잉크 위에 더하는 한 칸 외곽선 색이다.

// AI-NOTE: outline = 어두운 테마 자동 외곽선(기존 값 그대로, 사용자: 어두운 쪽 지금 색이 좋다),
// outlineLight = 밝은 테마 자동 외곽선(밝은 바탕에서 또렷하도록 같은 색 계열의 어두운 색). 직접 고른 외곽선 색은 이 값으로 덮지 않는다.
export const PIXEL_PRESETS = Object.freeze([
  { id: "original", label: "원본", accent: null, outline: "#fff1c9", outlineLight: "#1c1a2e" },
  { id: "crimson", label: "진홍", accent: "#c8323c", outline: "#ffe2d6", outlineLight: "#3b0f16" },
  { id: "forest", label: "숲", accent: "#3f9a4a", outline: "#f3ffd9", outlineLight: "#10291a" },
  { id: "gold", label: "황금", accent: "#d9a21b", outline: "#2a1b0a", outlineLight: "#2a1b0a" },
  { id: "violet", label: "보라", accent: "#8a4fd8", outline: "#f1e6ff", outlineLight: "#20113d" },
]);

// AI-NOTE: /sprite 상세 페이지(SpritePage) 문구. 경로 상수는 site.js 의 SPRITE_ROUTE 하나만 쓴다.
export const SPRITE_PAGE = Object.freeze({
  backLabel: "이력서로 돌아가기",
  eyebrow: "Sprite 파이프라인 상세",
  title: "원본 용사 레이어를 브라우저에서 합성하고 색·프레임·골격까지 점검하기",
  intro: [
    "직접 만든 Hero Pixel Studio 프로젝트의 레이어 셀·팔레트 세트·골격 데이터를 그대로 가져와 다시 그립니다.",
    "포인트 색과 추가 외곽선을 먼저 적용하고, 그 결과를 팔레트 세트로 옮기는 비율을 0–100%로 조절합니다. 모든 화면은 재생 커서 하나를 따르며, 프레임을 직접 고르면 재생이 멈춥니다.",
  ],
});

export const PIXEL_COPY = Object.freeze({
  index: "04",
  heading: "Hero Pixel Studio 라이브 미리보기",
  lead: "원본 용사 프로젝트의 레이어 19개와 셀(걷기 8 · 달리기 8 · 공격 12)을 그대로 합성해 브라우저에서 다시 그립니다. 포인트 색·외곽선·팔레트 세트를 바꾸고, 레이어·어니언 스킨·기준점·골격 각도를 같은 프레임으로 살펴볼 수 있습니다.",
  openCase: "사례 자세히 보기",
  stageLabel: "실시간 미리보기",
  original: "원본 GIF",
  originalStatic: "원본 프레임",
  play: "재생",
  pause: "일시정지",
  shuffle: "무작위 섞기",
  motionGroup: "모션",
  paletteGroup: "팔레트",
  accentInput: "포인트 색 직접 고르기",
  outline: "추가 외곽선",
  outlineColor: "외곽선 색",
  outlineHint: "원본 선은 그대로 두고 바깥에 한 칸을 더합니다.",
  outlineAuto: "자동 색",
  outlineAutoHint: "자동 색은 화면 테마와 포인트 색에 맞춰 고릅니다(밝은 테마는 어두운 외곽선).",
  outlineManualHint: "직접 고른 외곽선 색을 유지합니다.",
  showcaseOn: "팔레트 자동 연출 중 · 직접 고르면 그대로 유지됩니다.",
  showcaseOff: "직접 고른 팔레트·외곽선을 유지합니다.",
  loading: "프레임을 읽는 중입니다. 원본 GIF를 먼저 보여 줍니다.",
  fallback: "이 브라우저에서는 프레임을 다시 그릴 수 없어 원본 GIF를 보여 줍니다.",
  pausedOffscreen: "화면 밖에서는 멈춥니다.",
  cycles: "회",
  // 2행: 팔레트 세트
  setGroup: "팔레트 세트",
  setHint: "포인트 색·외곽선을 적용한 결과의 색마다 세트에서 가장 가까운 색(OKLab)을 고릅니다.",
  ratio: "팔레트 적용 비율",
  ratioHint: "0%는 위 결과 그대로, 100%는 모든 불투명 픽셀이 세트 안 색입니다.",
  sourceSet: "원본 색상",
  sourceSetMeta: "매핑 없음",
  sourceSetHint: "팔레트 세트로 옮기지 않고 포인트 색·외곽선 결과의 색을 그대로 씁니다.",
  ratioDisabled: "원본 색상에서는 팔레트 매핑이 없어 적용 비율을 쓰지 않습니다.",
  sourceColors: "현재 프레임 출력 색",
  setColors: "세트 색",
  setUsed: "현재 프레임에 쓰인 색",
  sharesTitle: "현재 프레임 색 점유율",
  inSetShare: "세트 안 색 픽셀",
  colorsUnit: "색",
  // 작업 화면
  workspace: "레이어 · 프레임",
  prevFrame: "이전 프레임",
  nextFrame: "다음 프레임",
  frameSlider: "프레임 위치",
  timeline: "레이어 × 프레임 타임라인",
  timelineLegend: "채운 칸 = 새 셀 · 빈 테두리 = 직전 프레임과 같은 셀 · 표시 없음 = 셀 없음 · 점선 = 합성 참조",
  layerColumn: "레이어",
  showLayer: "보이기",
  hideLayer: "숨기기",
  showAll: "모든 레이어 원래대로",
  isolate: "선택 레이어만 보기",
  selectedLayer: "선택 레이어",
  noCel: "이 프레임에는 셀이 없습니다.",
  compositeRow: "합성 참조(원본 숨김)",
  onion: "어니언 스킨",
  onionOpacity: "어니언 불투명도",
  onionPrev: "이전",
  onionNext: "다음",
  onionNone: "없음",
  guides: "기준선 · 십자선",
  guideReadout: "기준점 x",
  soleRow: "발바닥 줄",
  crownRow: "정수리 줄",
  centerTitle: "기준점 정렬 비교",
  centerCommon: "공통 기준점(원본)",
  centerTrim: "프레임마다 잘라 가운데 맞춤",
  centerShift: "이동량",
  rigTitle: "골격 · 프레임 각도",
  rigCanvas: "원본 골격 좌표(1254) 위 기준 자세와 현재 프레임 각도",
  rigRest: "기준 자세",
  rigPosed: "현재 각도",
  rigBone: "뼈",
  rigParent: "부모",
  rigAngle: "월드 각",
  rigDelta: "기준 대비",
  rigMissing: "값 없음",
  rigPlant: "접지",
  rigRoot: "root",
  rigRootCells: "rootCells",
  rigHeadGrid: "headGrid",
  extraLayers: "추가 레이어(뼈에 붙음)",
});

// 원본 레이어 이름 → 한국어 이름. 뼈 이름은 원본 골격(hero-side.skeleton.json)의 ko 값, 나머지는 원본 레이어 뜻 그대로.
export const LAYER_LABELS = Object.freeze({
  fx: "효과",
  far_upper_arm: "뒤 윗팔",
  far_hand: "뒤 손",
  far_forearm: "뒤 아래팔",
  far_pauldron: "뒤 견갑",
  far_foot: "뒤 발",
  far_shin: "뒤 정강이",
  far_thigh: "뒤 허벅지",
  cape: "망토",
  near_foot: "앞 발",
  near_shin: "앞 정강이",
  near_thigh: "앞 허벅지",
  torso: "몸통",
  head: "머리",
  sword: "검",
  near_upper_arm: "앞 윗팔",
  near_pauldron: "앞 견갑",
  near_hand: "쥔 손",
  near_forearm: "앞 아래팔",
  composite: "합성 참조",
});

export const PLANT_LABELS = Object.freeze({ heel: "뒤꿈치", toe: "발끝", flat: "발바닥 전체" });
export const DEFAULT_SET_ID = "aap64";
// 2행 '원본 색상' 선택지의 id. 원본 세트 id 와 겹치지 않는다. 1행 '원본'(포인트 색 프리셋)과는 다른 뜻이다:
// 이 값은 포인트 색·외곽선 다음의 팔레트 세트 매핑 단계를 건너뛴다.
export const SOURCE_SET_ID = "source";
// '팔레트 적용 비율' 첫 값(0..100%). 사용자 요청으로 기본 100%, 0% 로 내리면 포인트 색·외곽선 결과 그대로.
export const DEFAULT_PALETTE_RATIO = 100;
// 원본 편집기(app.js)의 수정 전 프레임 겹쳐 보기 불투명도와 같은 값.
export const ONION_DEFAULT_OPACITY = 0.35;
