// /workflow 상세 페이지의 문구와 기록 예시 데이터.
// AI-NOTE: 요청·레인·대화·기록은 모두 예시 데이터(사내 요청 대시보드)다. 실제 사용자 로그를 옮기지 않고,
// 방문자 디스크 쓰기·AI 호출·외부 API·저장을 하지 않는다. 화면 문구에 데모 안내 문구나 "(설명용)" 꼬리표를 넣지 않는다
// (사용자 명시 요청). 측정 수치(속도·비용·캐시 비율)는 만들지 않는다.
// 폴더 구조는 AgentWorkflow 문서(parallel-workflow.md, agent-workflow.md)의 ai-log 구성을 따른다.

export const DETAIL_ROUTE = "/workflow";

export const DETAIL_COPY = Object.freeze({
  backLabel: "이력서로 돌아가기",
  eyebrow: "AgentWorkflow 상세",
  title: "요청 하나가 세 개의 독립 파이프라인으로 갈라졌다가 다시 합쳐지기까지",
  intro: [
    "사람은 Master AI 한 곳과만 대화합니다. Master AI는 요청을 해석해 WORK SPEC을 쓰고, Task Planning에서 서로 의존하지 않는 작업축을 제안·검토해 Task Contract로 동결한 뒤 지시합니다. 각 레인은 자기 worktree에서 기획·검수·개발·검수·QA를 따로 거칩니다.",
    "검수에서 반려되거나 QA에서 결함이 나오면 그 레인만 앞 단계로 되돌아가 고칩니다. 먼저 끝난 레인은 READY로 기다리고, 모든 레인이 QA를 통과해야 통합이 시작됩니다.",
  ],
  humanNote:
    "이 흐름에서 사람이 답한 곳은 범위와 권한이 걸린 지점입니다. 레인 안의 검수 반려·QA 실패는 AI끼리 되돌려 처리하며, 단계마다 사람이 승인하지 않습니다.",
  conversationHeading: "사람 ↔ Master AI",
  conversationEmpty: "재생하거나 다음 단계를 누르면 요청 대화가 시작됩니다.",
  dispatcherHeading: "Master AI 배정",
  dispatcherIdle: "요청 명세와 작업 분할이 확정되면 지시를 배정합니다.",
  dispatcherDone: "확정된 명세·작업 계약으로 지시를 배정했습니다.",
  boardLabel: "레인별 파이프라인",
  mergeHeading: "병합 게이트",
  integrationHeading: "통합 · Wiki",
  recordsHeading: "로컬 실행 기록 예시",
  recordsLead: "진행에 따라 실행 폴더에 쌓이는 파일입니다. 파일을 누르면 내용을 볼 수 있습니다.",
  recordsEmpty: "아직 생성된 기록이 없습니다.",
  recordsFollow: "최근 기록 따라가기",
  stepLabel: "단계",
  frameLabel: "프레임",
  frameSlider: "프레임 위치",
  speedLabel: "재생 속도",
  followLabel: "현재 프레임 따라가기",
  routeHint: "경로를 고르면 처음 프레임으로 돌아갑니다.",
  directHeading: "Master AI 직접 처리",
});

// AI-NOTE: 재생 속도는 화면 넘김 간격 배율일 뿐이다(소리·실제 시간·측정값 아님). 1배 = DETAIL_STEP_MS.
export const SPEED_OPTIONS = Object.freeze([
  { value: 0.5, label: "0.5배" },
  { value: 1, label: "1배" },
  { value: 2, label: "2배" },
]);

// AI-NOTE: 직접 처리 경로. 요청 → Master AI 직접 처리 → 응답 세 프레임뿐이다(WORK SPEC·Seed·검수·QA 없음).
// 순차·병렬과 같은 재생기·프레임 조작을 쓴다(model.js getScenario route "direct").
export const DIRECT_INTAKE = Object.freeze([{ actor: "human", text: "요청 목록의 '처리 중' 상태 이름을 '진행 중'으로 바꿔 주세요." }]);
export const DIRECT_WORK = Object.freeze({ text: "문구 한 곳만 바뀌는 단순 요청이라 Master AI가 직접 수정하고 확인", owns: "web/src/requests/labels.js" });
export const DIRECT_CLOSING = Object.freeze([{ actor: "master", text: "상태 이름을 '진행 중'으로 바꾸고 목록 화면에서 확인했습니다." }]);
export const DIRECT_FLOW = Object.freeze([
  { id: "request", label: "요청" },
  { id: "direct", label: "Master AI 직접 처리" },
  { id: "response", label: "응답" },
]);

export const ACTOR_LABEL = Object.freeze({
  human: "사람",
  master: "Master AI",
});

// AI-NOTE: 시나리오 옵션. 순차는 세 옵션 모두, 병렬은 Seed 보기만 바뀐다(병렬은 고정된 이질 진행 예시).
// 병렬 레인 Seed 는 항상 존재하므로 병렬의 seed 옵션은 Seed 패널 표시만 바꾼다(단계·계보·기록 동일). 순차는 실제로 Seed 를 끈다.
// 직접 처리에는 기획·검수·Seed 가 없으므로 모두 비활성이다. 옵션을 바꾸면 cursor·기록이 처음으로 돌아간다.
export const SCENARIO_OPTIONS = Object.freeze([
  { id: "planReject", label: "기획 검수 실패 시나리오", routes: ["sequential"] },
  { id: "qaFail", label: "QA 실패 시나리오", routes: ["sequential"] },
  { id: "seed", label: "Seed AI 과정 보기", routes: ["sequential", "parallel"] },
]);

export const DEFAULT_SCENARIO = Object.freeze({ route: "parallel", planReject: true, qaFail: true, seed: true });

export const OPTION_HINT = Object.freeze({
  parallel: "병렬은 A·B·C가 서로 다른 속도로 진행하는 고정 예시입니다. 실패 옵션은 순차에만 적용됩니다.",
  direct: "직접 처리는 기획·검수·Seed 단계가 없어 옵션이 적용되지 않습니다.",
  parallelSeed: "병렬 레인은 원래 레인마다 Seed를 둡니다. 이 옵션은 그 세션 계보를 화면에 보여 줄지만 정합니다.",
});

export const SPEC_COPY = Object.freeze({
  heading: "WORK SPEC",
  idle: "요청을 해석해 작업 명세를 작성합니다.",
  scope: "범위",
  criteria: "완료 기준",
  owns: "소유 경로",
  ownsByTask: "작업축별 소유 경로는 다음 단계 Task Planning에서 정합니다.",
  axis: "작업축",
  dispatched: "명세를 동결하고 지시를 배정했습니다.",
});

export const SEED_COPY = Object.freeze({
  heading: "Seed 세션 계보",
  rule: "Seed는 읽기 전용입니다. 규칙·구조·관련 코드·테스트 명령만 읽고 계획·코드·판정·TODO를 만들지 않습니다.",
  authorSeed: "Author Seed",
  reviewerSeed: "Reviewer Seed",
  children: {
    "plan-author": "Planning Author",
    "dev-author": "Development Author",
    "plan-reviewer": "Planning Reviewer",
    "dev-reviewer": "Development Reviewer",
  },
  independent: "독립 QA는 레인 전용 QA 세션을 재시도마다 resume, Wiki는 별도 독립 세션(둘 다 구현자·Seed 문맥 상속 없음)",
});

// AI-NOTE: 사람 개입은 범위 판단(scope)과 권한 판단(permission) 두 번만 있다. 각 레인의 반려·실패에는 사람이 끼지 않는다.
// 병렬 흐름: 요청 → Master 해석 → WORK SPEC 작성 → Task Planning(제안 → 검토 승인 → 동결) → 지시·배정 → 레인별 Seed → 레인.
export const INTAKE_MESSAGES = Object.freeze([
  {
    actor: "human",
    text: "사내 요청 대시보드를 만들어 주세요. 요청 목록 화면, 요청 API, 상태 변경 이력이 필요합니다.",
  },
  {
    actor: "master",
    decision: "route",
    text: "세 작업은 서로 다른 경로를 소유하고 각자 검증할 수 있습니다. 독립 병렬로 진행하고, 먼저 작업 계약을 정리하겠습니다.",
  },
  {
    actor: "master",
    decision: "scope-question",
    text: "범위 확인이 필요합니다. 사내 SSO 연동도 이번 작업에 포함할까요?",
  },
  {
    actor: "human",
    decision: "scope",
    text: "SSO는 이번 범위에서 빼고, 기존 세션 확인만 사용해 주세요.",
  },
  {
    actor: "master",
    decision: "dispatch",
    text: "승인된 Task Contract로 레인 A·B·C에 지시를 배정합니다. 각 레인은 자기 worktree에서 끝까지 진행합니다.",
  },
]);

// AI-NOTE: 조립 병합 순서는 Task Contract 에서 동결한 선언 순서(A·B·C)다. READY 도착 순서(A·C·B)와 무관하다.
export const MERGE_ORDER = Object.freeze(["dashboard-ui", "request-api", "status-history"]);

// AI-NOTE: WORK SPEC 은 Master 가 요청을 해석한 "요청 명세"다(범위·완료 기준). 병렬에서는 여기서 레인을 정하지 않는다.
// 작업축·소유 경로·인터페이스·병합 순서는 다음 단계인 전체 Task Planning(Author → Reviewer → 동결)에서 정한다.
export const PARALLEL_SPEC = Object.freeze({
  scope: ["요청 목록 화면", "요청 API", "상태 변경 이력", "제외: 사내 SSO 연동(기존 세션 확인 사용)"],
  criteria: ["레인별 개발 검수 승인 + 독립 QA 통과", "모든 레인 READY 후 통합 빌드·통합 QA 통과", "원격 푸시 없이 시작 브랜치에 로컬 병합"],
});

// AI-NOTE: 전체 Task Planning(parallel-workflow.md 기준). WORK SPEC 다음, 레인 배정·레인별 Seed·레인 기획보다 먼저 한 번만 일어난다.
// 레인 안의 기획(Planning Author/Reviewer)과 다른 단계다. Task Planning Author 가 독립 작업축을 제안하고, Reviewer 가
// 독립성·소유 경로 겹침·인터페이스·QA/완료 기준을 검토해 승인한 계약만 동결된다(동결 전 레인 없음).
// 어떤 레인도 다른 레인의 미완료 결과를 기다리지 않는다. 겹치는 연결 코드는 통합 단계 소유로 명시한다.
// 축이 불확실하거나 하나의 의존 축이면 병렬로 나누지 않고 순차로 간다(순차 예시의 WORK SPEC 설명 참고).
export const TASK_PLANNING = Object.freeze({
  heading: "TASK PLANNING · 작업 분할",
  lead: "WORK SPEC 다음, 레인 배정·Seed 전에 한 번만 하는 전체 작업 분할입니다. 레인 안의 기획 단계와는 별개입니다.",
  steps: [
    { id: "split", label: "작업축 제안", actor: "Task Planning Author" },
    { id: "review", label: "독립성 검토", actor: "Task Planning Reviewer" },
    { id: "freeze", label: "Task Contract 동결", actor: "Master AI" },
  ],
  source: "요청 1건",
  noDependency: "미완료 레인 의존 없음",
  tasks: {
    "dashboard-ui": {
      interface: "계약에 고정한 요청 목록 응답 형식만 사용(목업 데이터로 개발)",
      acceptance: "목록·필터·빈 상태 브라우저 QA 통과",
    },
    "request-api": {
      interface: "요청 목록·상세·상태 변경 응답 형식 제공(계약 고정)",
      acceptance: "API 테스트 + 닫힌 요청 상태 전이 차단 QA 통과",
    },
    "status-history": {
      interface: "상태 변경 기록 함수 형식 제공(계약 고정)",
      acceptance: "최신순 조회·보존 정책·변경 주체 기록 QA 통과",
    },
  },
  checks: [
    "독립성: 세 작업 모두 다른 레인의 미완료 결과 없이 시작·완료 가능",
    "소유 경로 겹침 없음: web/src/requests · server/src/requests · server/src/history",
    "공유 연결 코드(목록 → 이력 링크)는 레인이 아닌 통합 단계 소유로 명시",
    "인터페이스: 응답 형식과 기록 함수 형식을 계약에 고정",
    "QA·완료 기준: 레인별 독립 QA, 모든 레인 READY 후 통합 QA",
  ],
  sharedOwner: "목록 → 이력 링크 연결 코드: 통합 단계",
  texts: {
    split: "Task Planning Author: 작업축 3개 제안 — A 화면 · B API · C 이력",
    review: "Task Planning Reviewer: 독립성·소유 경로·인터페이스·QA 기준 검토 승인",
    freeze: "Task Contract 동결: 소유 경로·인터페이스·QA 기준·병합 순서 A → B → C",
  },
  status: { idle: "대기", proposed: "작업축 제안됨 · 검토 대기", approved: "검토 승인 · 동결 대기", frozen: "동결 · 승인된 계약만 배정" },
});

// 순차 경로: 나눌 수 없는 한 작업축. 사람 ↔ Master 대화는 같은 구조(범위·권한 결정만)다.
export const SEQUENTIAL_INTAKE = Object.freeze([
  { actor: "human", text: "요청 상세 화면에 상태 변경 이력 탭을 추가해 주세요." },
  {
    actor: "master",
    decision: "route",
    text: "화면·API·저장이 한 변경으로 묶여 나눌 수 없습니다. 순차 경로로 진행하고, 먼저 작업 명세를 정리하겠습니다.",
  },
  { actor: "master", decision: "scope-question", text: "범위 확인이 필요합니다. 이력 내보내기(CSV)도 포함할까요?" },
  { actor: "human", decision: "scope", text: "내보내기는 빼고 조회만 해 주세요." },
  { actor: "master", decision: "dispatch", text: "WORK SPEC을 동결했습니다. 기획 Author에게 지시를 넘깁니다." },
]);

// AI-NOTE: 순차에는 병렬 전용 Task Planning 단계를 만들지 않는다. 대신 왜 나누지 않는지(하나의 의존 작업축)를 명세에 적는다.
export const SEQUENTIAL_SPEC = Object.freeze({
  scope: ["요청 상세의 이력 탭(최신순 조회)", "제외: 이력 내보내기"],
  criteria: ["기획·개발 검수 승인", "독립 QA 통과", "Wiki 기록"],
  axisNote:
    "작업축 1개: 이력 탭 화면은 새 조회 API와 저장 형식이 있어야 완성됩니다. 나누면 한 레인이 다른 레인의 미완료 결과를 기다려야 하므로 한 작업으로 묶어 순차로 진행합니다.",
});

export const SEQUENTIAL_LANE = Object.freeze({ id: "history-tab", key: "1", title: "상태 변경 이력 탭", owns: "web/src/requests/history/" });

export const SEQUENTIAL_CLOSING = Object.freeze([
  {
    actor: "master",
    decision: "permission-question",
    text: "QA와 Wiki까지 마쳤습니다. 원격 푸시와 배포는 권한이 필요합니다. 진행할까요?",
  },
  { actor: "human", decision: "permission", text: "푸시는 제가 하겠습니다. 여기서 마무리해 주세요." },
]);

// AI-NOTE: 순차 레인 일정은 옵션에서 만든다(model.js sequentialScript). 반려·실패는 한 번뿐이고 재시도에서 통과한다.
export const SEQUENTIAL_TEXT = Object.freeze({
  plan: "이력 탭 계획 작성",
  planRejected: "기획 검수 반려",
  planRejectReason: "이력이 비어 있을 때와 권한 없는 사용자 처리 기준이 계획에 없음",
  planRevise: "빈 이력·권한 기준을 넣어 같은 Planning Author가 계획 수정",
  planApproved: "기획 검수 승인",
  planReApproved: "수정 계획 재검수 승인",
  dev: "이력 탭과 조회 API 구현",
  devApproved: "개발 검수 승인",
  qaFailed: "QA 실패",
  qaFailReason: "이력이 오래된 순으로 표시됨(최신순이어야 함)",
  devFix: "정렬 기준을 최신순으로 수정",
  devReApproved: "수정본 재검수 승인",
  qaPassed: "브라우저 QA 통과",
  qaRePassed: "QA 재시도 통과, QF-001 해결",
});

export const SEQUENTIAL_TAIL = Object.freeze([
  { id: "wiki", label: "Wiki", text: "독립 Wiki Author·Reviewer가 변경과 판단 근거 기록" },
]);

export const CLOSING_MESSAGES = Object.freeze([
  {
    actor: "master",
    decision: "permission-question",
    text: "세 레인과 통합 QA, Wiki를 모두 마치고 시작 브랜치에 로컬 병합했습니다. 원격 푸시와 배포는 권한이 필요합니다. 진행할까요?",
  },
  {
    actor: "human",
    decision: "permission",
    text: "푸시와 배포는 제가 직접 하겠습니다. 여기서 마무리해 주세요.",
  },
]);

export const DETAIL_LANES = Object.freeze([
  { id: "dashboard-ui", key: "A", title: "요청 목록 화면", owns: "web/src/requests/" },
  { id: "request-api", key: "B", title: "요청 API", owns: "server/src/requests/" },
  { id: "status-history", key: "C", title: "상태 변경 이력", owns: "server/src/history/" },
]);

// AI-NOTE: 레인별 일정은 서로 독립이다(at = 배정·Seed 이후 레인 틱). 사이가 비어 있으면 그 레인은 다음 단계를 진행 중이다.
// A 가장 빠름: 한 번에 통과해 틱 4 에 READY 후 대기. C 기획 검수 2회·개발 검수 1회 반려 뒤 틱 10 에 READY(두 번째).
// B 가장 느림: 같은 결함 QF-001 이 QA 에서 두 번 재현되고 세 번째 QA 에서 해결, 틱 12 에 READY(마지막).
// READY 레인은 다시 실행하지 않는다. 모든 반복은 유한하다. 일정을 바꾸면 tests/workflow-detail.test.mjs 도 함께 고친다.
export const LANE_SCRIPTS = Object.freeze({
  "dashboard-ui": [
    { at: 0, stage: "plan", text: "목록·필터·빈 상태 화면 계획 작성" },
    { at: 1, stage: "plan-review", verdict: "approved", text: "기획 검수 승인" },
    { at: 2, stage: "dev", text: "목록·필터 화면 구현" },
    { at: 3, stage: "dev-review", verdict: "approved", text: "개발 검수 승인" },
    { at: 4, stage: "qa", verdict: "passed", text: "브라우저 QA 통과: 목록·필터·빈 상태" },
  ],
  "request-api": [
    { at: 1, stage: "plan", text: "목록·상세·상태 변경 API 계획 작성" },
    { at: 2, stage: "plan-review", verdict: "approved", text: "기획 검수 승인" },
    { at: 4, stage: "dev", text: "API와 테스트 구현" },
    { at: 5, stage: "dev-review", verdict: "approved", text: "개발 검수 승인" },
    {
      at: 6,
      stage: "qa",
      verdict: "failed",
      text: "QA 실패",
      reason: "상태 변경 API가 이미 닫힌 요청도 다시 열어 버림",
      // QA 지적 번호는 레인별 issue-ledger 안에서 매긴다(QF-001 은 레인 B 범위).
      issueId: "QF-001",
    },
    { at: 7, stage: "dev", text: "닫힌 요청의 상태 전이 차단" },
    { at: 8, stage: "dev-review", verdict: "approved", text: "수정본 재검수 승인" },
    {
      at: 9,
      stage: "qa",
      verdict: "failed",
      text: "QA 재시도 실패(같은 결함 재현)",
      reason: "일괄 변경 경로에서는 닫힌 요청이 여전히 다시 열림",
      issueId: "QF-001",
    },
    { at: 10, stage: "dev", text: "일괄 변경 경로에도 같은 전이 규칙 적용" },
    { at: 11, stage: "dev-review", verdict: "approved", text: "수정본 재검수 승인" },
    { at: 12, stage: "qa", verdict: "passed", text: "QA 3회차 통과, QF-001 해결", resolves: "QF-001" },
  ],
  "status-history": [
    { at: 0, stage: "plan", text: "상태 변경 이력 계획 작성" },
    { at: 1, stage: "plan-review", verdict: "rejected", text: "기획 검수 반려", reason: "이력 보존 기간과 삭제 정책이 계획에 없음" },
    { at: 2, stage: "plan", text: "보존 기간·삭제 정책을 넣어 계획 수정" },
    { at: 3, stage: "plan-review", verdict: "rejected", text: "기획 검수 재반려", reason: "변경 주체(누가 바꿨는지) 기록 기준이 빠짐" },
    { at: 4, stage: "plan", text: "변경 주체 기록 기준 추가" },
    { at: 5, stage: "plan-review", verdict: "approved", text: "3회차 계획 승인" },
    { at: 6, stage: "dev", text: "이력 저장·조회 구현" },
    { at: 7, stage: "dev-review", verdict: "rejected", text: "개발 검수 반려", reason: "이력 조회가 최신순이 아니고 페이지 경계 테스트가 없음" },
    { at: 8, stage: "dev", text: "최신순 정렬과 경계 테스트 보강" },
    { at: 9, stage: "dev-review", verdict: "approved", text: "수정본 재검수 승인" },
    { at: 10, stage: "qa", verdict: "passed", text: "API·화면 QA 통과" },
  ],
});

// 되돌림 대상 단계 표기(되돌림은 기획·개발로만 간다).
export const RETURN_TARGET_LABEL = Object.freeze({
  plan: "기획으로",
  dev: "개발로",
});

// 모든 레인 READY 이후 순서(parallel-workflow.md): 작업 통합 기획 → 조립 병합 → 통합 구현·검수 → 빌드 → 통합 QA → Wiki → 시작 브랜치 로컬 병합.
export const INTEGRATION_STEPS = Object.freeze([
  { id: "integration-plan", label: "통합 기획", text: "작업 계약의 고정 병합 순서와 공유 경로 확인" },
  { id: "merge", label: "조립 병합", text: "작업 계약의 고정 병합 순서대로 A·B·C 레인 커밋 조립" },
  { id: "integration-dev", label: "통합 구현", text: "레인 사이 연결 코드(목록 → 이력 링크) 작성" },
  { id: "integration-review", label: "통합 검수", text: "통합 변경 검수 승인" },
  { id: "build", label: "빌드", text: "필수 빌드·테스트 통과" },
  { id: "integration-qa", label: "통합 QA", text: "레인을 넘나드는 시나리오 통합 QA 통과" },
  { id: "wiki", label: "Wiki", text: "변경 내용과 판단 근거를 Wiki에 기록" },
  { id: "final-merge", label: "최종 병합", text: "시작 브랜치에 로컬 병합(푸시 없음)" },
]);

export const RECORD_ROOT = "ai-log/20260915/001_093000_사내-요청-대시보드";
export const SEQUENTIAL_RECORD_ROOT = "ai-log/20260915/002_141500_상태-이력-탭";
export const DIRECT_RECORD_ROOT = "ai-log/20260915/003_160000_상태-이름-수정";
