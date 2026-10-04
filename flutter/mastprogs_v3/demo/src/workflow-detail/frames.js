// /workflow 재생기의 "프레임" 도우미. 순수 함수만 둔다(node:test 가 직접 import).
// AI-NOTE: 프레임 i = 단계 i-1 이 막 적용된 화면(cursor = i). 강조는 방금 바뀐 곳을 가리킨다.
// 레인의 isActive(다음에 실행될 단계)와 다르다 — 아직 실행되지 않은 이벤트를 프레임 강조로 쓰지 않는다.
// 화면 노드는 data-frame-id 로 찾는다(문구 검색 금지). id 규칙:
//   msg:<eventId> · spec · task:<split|review|freeze>(병렬 전체 Task Planning) · master(지시 배정)
//   lane:<laneId>(Seed 준비) · stage:<laneId>:<stage> · integration:<stage> · gate(조립 병합) · direct:<step>(직접 처리 흐름 노드)

// 1배 속도에서 한 프레임 머무는 시간. 한 단계에 여러 레인 변화가 겹치므로 메인보다 조금 길다.
export const DETAIL_STEP_MS = 1500;
export const SPEEDS = Object.freeze([0.5, 1, 2]);
export const DEFAULT_SPEED = 1;

export const normalizeSpeed = (value) => (SPEEDS.includes(value) ? value : DEFAULT_SPEED);
export const frameDelay = (speed) => Math.round(DETAIL_STEP_MS / normalizeSpeed(speed));

// 주 강조(스크롤 기준) 우선순위: 반려·QA 실패 → Master·WORK SPEC·Task Planning·Seed → 레인 진행 → 통합 → 대화.
export const FRAME_TIER = Object.freeze({ fault: 0, master: 1, lane: 2, integration: 3, conversation: 4 });

// task-split → task:split (TaskPlanPanel 의 같은 data-frame-id).
export const taskFrameId = (stage) => `task:${stage.replace(/^task-/, "")}`;

function targetsForEvent(event, direct) {
  if (direct) {
    const list = [{ id: `direct:${event.step}`, tier: FRAME_TIER.master }];
    if (event.type === "message") list.push({ id: `msg:${event.id}`, tier: FRAME_TIER.conversation });
    return list;
  }
  if (event.type === "message") {
    const list = [{ id: `msg:${event.id}`, tier: FRAME_TIER.conversation }];
    if (event.decision === "dispatch") list.push({ id: "master", tier: FRAME_TIER.master });
    return list;
  }
  if (event.type === "spec") return [{ id: "spec", tier: FRAME_TIER.master }];
  if (event.type === "task") return [{ id: taskFrameId(event.stage), tier: FRAME_TIER.master }];
  if (event.type === "seed") return [{ id: `lane:${event.lane}`, tier: FRAME_TIER.master }];
  if (event.type === "integration") {
    const list = [{ id: `integration:${event.stage}`, tier: FRAME_TIER.integration }];
    if (event.stage === "merge") list.push({ id: "gate", tier: FRAME_TIER.integration });
    return list;
  }
  if (event.lane && event.stage) {
    const fault = event.verdict === "rejected" || event.verdict === "failed";
    return [{ id: `stage:${event.lane}:${event.stage}`, tier: fault ? FRAME_TIER.fault : FRAME_TIER.lane }];
  }
  return [];
}

// cursor 의 프레임에서 바뀐 노드 전부와 주 강조 하나. 같은 등급이면 이벤트 순서(seq)대로라 항상 같은 결과다.
function sortedTargets(scenario, at) {
  const direct = scenario.options.route === "direct";
  const byId = new Map();
  scenario.steps[at - 1].events.forEach((event, order) => {
    for (const target of targetsForEvent(event, direct)) {
      const found = byId.get(target.id);
      if (!found || target.tier < found.tier) byId.set(target.id, { ...target, event, order: found ? found.order : order });
    }
  });
  return [...byId.values()].sort((a, b) => a.tier - b.tier || a.order - b.order);
}

export function deriveFrameTargets(scenario, cursor) {
  const at = scenario.clamp(cursor);
  if (at === 0) return { frame: 0, ids: [], primary: null };
  const sorted = sortedTargets(scenario, at);
  return { frame: at, ids: sorted.map((target) => target.id), primary: sorted[0]?.id ?? null };
}

// 재생기의 현재 프레임 제목. 주 강조와 같은 이벤트를 설명한다(병렬 반려 프레임은 다음 재기획이 아니라 그 반려).
export function frameTitle(scenario, cursor) {
  const at = scenario.clamp(cursor);
  const event = at === 0 ? null : sortedTargets(scenario, at)[0]?.event;
  return event ? scenario.describeEvent(event) : scenario.describeStep(at);
}

// 따라가기 스크롤 양(px, 음수 = 위로). 노드가 고정 재생 막대 아래 보이는 영역에 이미 다 있으면 null(움직이지 않음).
// 노드가 보이는 영역보다 크면 윗변을 막대 바로 아래에 맞춘다.
export function followScrollDelta(rect, safeTop, viewportHeight, margin = 16) {
  const top = safeTop + margin;
  const bottom = viewportHeight - margin;
  if (rect.top >= top && rect.bottom <= bottom) return null;
  if (rect.top < top || rect.bottom - rect.top > bottom - top) return Math.round(rect.top - top);
  return Math.round(rect.bottom - bottom);
}
