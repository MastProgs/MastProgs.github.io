// 워크플로우 데모의 단계, 경로, 결과 문구와 시간 값을 한곳에 모은 상수 모듈.
// AI-NOTE: 이 모듈과 model/reducer 는 브라우저 API 를 쓰지 않는 순수 모듈이다. node:test 가 직접 import 하므로 확장자를 포함한 상대 경로만 사용한다.

export const PHASES = Object.freeze([
  {
    id: "plan",
    label: "기획",
    role: "역할 AI",
    human: true,
    humanNote: "사람 판단: 범위 판단이 필요할 때만 (필요 시)",
    summary: "요구사항과 범위를 정리해 개발·QA TODO로 나눔",
  },
  {
    id: "review-plan",
    label: "검수",
    role: "교차 검토",
    human: false,
    summary: "교차 검토: 작성 AI ↔ 다른 제공사 검토 AI",
  },
  {
    id: "dev",
    label: "개발",
    role: "작성 AI",
    human: false,
    summary: "승인된 계획만 구현",
  },
  {
    id: "review-dev",
    label: "검수",
    role: "교차 검토",
    human: false,
    summary: "교차 검토: 작성 AI ↔ 다른 제공사 검토 AI",
  },
  {
    id: "qa",
    label: "QA",
    role: "UI·API·CLI 검증",
    human: false,
    summary: "실행 중인 화면·API·CLI를 독립적으로 검증",
  },
  {
    id: "wiki",
    label: "Wiki",
    role: "기록",
    human: false,
    summary: "변경 내용과 판단 근거를 기록",
  },
  {
    id: "integrate",
    label: "통합",
    role: "병합·배포",
    human: true,
    humanNote: "사람 판단: 배포 권한이 필요할 때 (필요 시)",
    summary: "승인된 결과만 병합·배포",
  },
]);

// AI-NOTE: 직접 처리 경로의 실행 노드. 7개 단계 ID와 섞지 않으며, 작성/검수/통합 파이프라인을 거치지 않는 단순 요청을 뜻한다.
export const DIRECT_NODES = Object.freeze([
  { id: "request", label: "요청", role: "요청 접수", summary: "사용자 요청을 Master AI가 받음" },
  {
    id: "master-direct",
    label: "Master AI 직접 처리",
    role: "경로 판단 후 직접 처리",
    summary: "단순 요청이라 별도 작성·검수·QA 단계 없이 Master AI가 직접 처리",
  },
  { id: "response", label: "응답", role: "결과 전달", summary: "처리 결과를 사용자에게 바로 응답" },
]);

// 독립 병렬에서 QA 와 Wiki 사이에 놓이는 병합 게이트. 7개 단계에는 포함되지 않는 실행 노드다.
export const MERGE_NODE = Object.freeze({
  id: "merge",
  label: "병합 게이트",
  summary: "모든 레인이 QA를 통과해야 병합",
});

export const PHASE_IDS = Object.freeze(PHASES.map((phase) => phase.id));

export const MODE = Object.freeze({
  DIRECT: "direct",
  SEQUENTIAL: "sequential",
  PARALLEL: "parallel",
});

export const MODES = Object.freeze([
  { id: MODE.DIRECT, label: "직접 처리", hint: "단순 요청은 단계를 늘리지 않습니다" },
  { id: MODE.SEQUENTIAL, label: "순차", hint: "역할 AI가 단계마다 작성하고 다른 제공사 AI가 교차 검토합니다" },
  { id: MODE.PARALLEL, label: "독립 병렬", hint: "서로 의존하지 않는 작업만 병렬로 나누고, Wiki·통합에서 합칩니다" },
]);

export const LANES = Object.freeze(["A", "B", "C"]);
// 독립 병렬 시나리오에서 QA 결함이 나는 레인.
export const FAULT_LANE = "B";

// 독립 병렬에서 각 레인이 독립적으로 거치는 단계(기획→검수→개발→검수→QA).
export const LANE_PHASES = Object.freeze(["plan", "review-plan", "dev", "review-dev", "qa"]);
// 모든 레인이 QA 를 통과해야 진행되는 단계.
export const GATED_PHASES = Object.freeze(["wiki", "integrate"]);

export const OUTCOME = Object.freeze({
  DONE: "done",
  APPROVED: "approved",
  DEFECT: "defect",
  PASS: "pass",
  RECORDED: "recorded",
  MERGED: "merged",
  RECEIVED: "received",
  RESPONDED: "responded",
});

export const BASE_OUTCOME = Object.freeze({
  plan: OUTCOME.DONE,
  "review-plan": OUTCOME.APPROVED,
  dev: OUTCOME.DONE,
  "review-dev": OUTCOME.APPROVED,
  qa: OUTCOME.PASS,
  wiki: OUTCOME.RECORDED,
  integrate: OUTCOME.DONE,
  request: OUTCOME.RECEIVED,
  "master-direct": OUTCOME.DONE,
  response: OUTCOME.RESPONDED,
  merge: OUTCOME.MERGED,
});

export const OUTCOME_LABEL = Object.freeze({
  done: "완료",
  approved: "승인",
  defect: "결함 발견",
  pass: "통과",
  recorded: "기록",
  merged: "병합",
  received: "접수",
  responded: "전달",
});

export const REWORK_LABEL = Object.freeze({
  dev: "수정",
  "review-dev": "재검수",
});

export const REWORK_BADGE = "재작업 1회";
export const SKIPPED_CAPTION = "이 경로에서는 생략";

export const PHASE_STATUS = Object.freeze({
  PENDING: "pending",
  DONE: "done",
  FAULT: "fault",
  GATED: "gated",
  SKIPPED: "skipped",
  PARTIAL: "partial",
});

export const PHASE_STATUS_LABEL = Object.freeze({
  pending: "대기",
  done: "완료",
  fault: "결함 발견",
  gated: "병합 대기",
  skipped: "생략",
  partial: "진행 중",
});

export const RUN_STATUS = Object.freeze({
  IDLE: "idle",
  RUNNING: "running",
  PAUSED: "paused",
  DONE: "done",
});

export const DEFAULT_MODE = MODE.SEQUENTIAL;
export const DEFAULT_FAIL_ON = true;

// 자동 재생 시 한 단계가 머무는 시간(계약: 1100ms). 리듀서 밖의 타이머 훅에서만 사용한다.
export const STEP_INTERVAL_MS = 1100;

// 경로·실패 토글 변경 시 타임라인 영역 전환. 높이가 바뀌면 높이+페이드(LANE_RESIZE_MS), 같으면 페이드만(ROUTE_FADE_MS).
export const LANE_RESIZE_MS = 280;
export const ROUTE_FADE_MS = 150;

// ?state=target 진입 시 시각 기준 화면과 같은 상태.
export const TARGET_PRESET = Object.freeze({
  mode: MODE.SEQUENTIAL,
  failOn: true,
  cursor: 5,
  status: RUN_STATUS.PAUSED,
  selectedPhaseId: "qa",
});
