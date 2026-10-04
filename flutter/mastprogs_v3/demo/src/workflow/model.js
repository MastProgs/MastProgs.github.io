import {
  BASE_OUTCOME,
  DIRECT_NODES,
  FAULT_LANE,
  GATED_PHASES,
  LANES,
  LANE_PHASES,
  MERGE_NODE,
  MODE,
  MODES,
  OUTCOME,
  OUTCOME_LABEL,
  PHASES,
  PHASE_IDS,
  PHASE_STATUS,
  REWORK_LABEL,
  RUN_STATUS,
} from "./constants.js";

// AI-NOTE: 실행 계획은 (mode, failOn) 만으로 결정되는 단계 배열이다. 화면 상태(단계 상태, 기록, 게이트)는
// 모두 plan.slice(0, cursor) 에서 다시 계산하므로 일시정지/재개/재생을 반복해도 기록이 중복될 수 없다.
// AI-NOTE: 7개 논리 단계(타일·눈금)와 실행 틱(카운터·기록)은 별개다. 실행 항목은 phaseId(7단계 중 하나) 또는
// nodeId(직접 처리 노드, 병합 게이트) 중 하나만 가진다. phaseIndex 는 눈금 위치이며 노드는 null 이다.

const PHASE_BY_ID = new Map(PHASES.map((phase, index) => [phase.id, { ...phase, order: index + 1 }]));
const NODE_BY_ID = new Map([...DIRECT_NODES, MERGE_NODE].map((node) => [node.id, node]));

export function getPhase(phaseId) {
  return PHASE_BY_ID.get(phaseId) ?? null;
}

export function getModeLabel(modeId) {
  return MODES.find((mode) => mode.id === modeId)?.label ?? modeId;
}

export function getModeHint(modeId) {
  return MODES.find((mode) => mode.id === modeId)?.hint ?? "";
}

export function isFailureAvailable(mode) {
  return mode !== MODE.DIRECT;
}

function createEntry(phaseId, { lane = null, outcome = BASE_OUTCOME[phaseId], attempt = 1, rework = false } = {}) {
  return {
    id: `${phaseId}:${lane ?? "main"}:${attempt}`,
    phaseId,
    phaseIndex: PHASE_IDS.indexOf(phaseId),
    nodeId: null,
    lane,
    outcome,
    attempt,
    rework,
  };
}

function createNodeEntry(nodeId) {
  return {
    id: `${nodeId}:main:1`,
    phaseId: null,
    phaseIndex: null,
    nodeId,
    lane: null,
    outcome: BASE_OUTCOME[nodeId],
    attempt: 1,
    rework: false,
  };
}

function single(phaseId, options) {
  return [createEntry(phaseId, options)];
}

function buildSequentialGroups(fail) {
  const groups = ["plan", "review-plan", "dev", "review-dev"].map((id) => single(id));
  if (fail) {
    groups.push(
      single("qa", { outcome: OUTCOME.DEFECT }),
      single("dev", { attempt: 2, rework: true }),
      single("review-dev", { attempt: 2, rework: true }),
      single("qa", { attempt: 2 }),
    );
  } else {
    groups.push(single("qa"));
  }
  groups.push(single("wiki"), single("integrate"));
  return groups;
}

function buildParallelGroups(fail) {
  // 각 레인은 기획→검수→개발→검수→QA 를 같은 틱에 독립적으로 진행한다.
  const groups = LANE_PHASES.map((phaseId) =>
    LANES.map((lane) =>
      createEntry(phaseId, {
        lane,
        outcome: phaseId === "qa" && fail && lane === FAULT_LANE ? OUTCOME.DEFECT : undefined,
      }),
    ),
  );
  if (fail) {
    // AI-NOTE: 복구 구간에는 결함 레인만 진행한다. 다른 레인은 추가 실행 없이 Wiki/통합 게이트에서 대기한다.
    groups.push(
      single("dev", { lane: FAULT_LANE, attempt: 2, rework: true }),
      single("review-dev", { lane: FAULT_LANE, attempt: 2, rework: true }),
      single("qa", { lane: FAULT_LANE, attempt: 2 }),
    );
  }
  groups.push([createNodeEntry(MERGE_NODE.id)], single("wiki"), single("integrate"));
  return groups;
}

export function buildPlan(mode, failOn) {
  const fail = isFailureAvailable(mode) && Boolean(failOn);
  let groups;
  if (mode === MODE.DIRECT) {
    groups = DIRECT_NODES.map((node) => [createNodeEntry(node.id)]);
  } else if (mode === MODE.PARALLEL) {
    groups = buildParallelGroups(fail);
  } else {
    groups = buildSequentialGroups(fail);
  }
  return groups.map((entries, index) => ({ id: `${mode}-${index + 1}`, index, entries }));
}

export function planHasRework(plan) {
  return plan.some((step) => step.entries.some((entry) => entry.rework));
}

function appliedEntries(plan, cursor) {
  return plan.slice(0, cursor).flatMap((step) => step.entries);
}

// 병합 게이트 상태. blocked 는 일부 레인만 QA 를 통과해 나머지 레인 복구를 기다리는 구간이다.
export function getIntegrationGate(mode, plan, cursor) {
  if (mode !== MODE.PARALLEL) return { blocked: false, waitingLanes: [], blockingLanes: [] };
  const latest = new Map();
  for (const entry of appliedEntries(plan, cursor)) {
    if (entry.phaseId === "qa") latest.set(entry.lane, entry.outcome);
  }
  const blockingLanes = LANES.filter((lane) => latest.has(lane) && latest.get(lane) !== OUTCOME.PASS);
  const blocked = blockingLanes.length > 0;
  const waitingLanes = blocked ? LANES.filter((lane) => latest.get(lane) === OUTCOME.PASS) : [];
  return { blocked, waitingLanes, blockingLanes };
}

export function canMerge(plan, cursor) {
  const latest = new Map();
  for (const entry of appliedEntries(plan, cursor)) {
    if (entry.phaseId === "qa") latest.set(entry.lane, entry.outcome);
  }
  return LANES.every((lane) => latest.get(lane) === OUTCOME.PASS);
}

export function deriveMergeGate(mode, plan, cursor) {
  if (mode !== MODE.PARALLEL) return null;
  const gate = getIntegrationGate(mode, plan, cursor);
  const merged = appliedEntries(plan, cursor).some((entry) => entry.nodeId === MERGE_NODE.id);
  const current = cursor > 0 ? plan[cursor - 1] : null;
  let status = "pending";
  if (merged) status = "done";
  else if (gate.blocked) status = "waiting";
  return {
    ...MERGE_NODE,
    status,
    isCurrent: Boolean(current?.entries.some((entry) => entry.nodeId === MERGE_NODE.id)),
    waitingLanes: gate.waitingLanes,
    blockingLanes: gate.blockingLanes,
  };
}

export function deriveDirectNodes(mode, plan, cursor) {
  if (mode !== MODE.DIRECT) return null;
  return DIRECT_NODES.map((node, index) => ({
    ...node,
    order: index + 1,
    status: index < cursor ? PHASE_STATUS.DONE : PHASE_STATUS.PENDING,
    isCurrent: index === cursor - 1,
    isNext: index === cursor,
  }));
}

function statusFromEntries(entries) {
  if (entries.length === 0) return PHASE_STATUS.PENDING;
  return entries.at(-1).outcome === OUTCOME.DEFECT ? PHASE_STATUS.FAULT : PHASE_STATUS.DONE;
}

function combineLaneStatus(lanes) {
  if (lanes.some((lane) => lane.status === PHASE_STATUS.FAULT)) return PHASE_STATUS.FAULT;
  if (lanes.every((lane) => lane.status === PHASE_STATUS.DONE)) return PHASE_STATUS.DONE;
  if (lanes.some((lane) => lane.status !== PHASE_STATUS.PENDING)) return PHASE_STATUS.PARTIAL;
  return PHASE_STATUS.PENDING;
}

const isRetry = (entry) => entry.rework || entry.attempt > 1;

// 각 단계 타일이 보여 줄 상태를 계산한다. 완료(배경에서 끝난 단계), 대기(아직 실행 전), 결함을 구분해 유지한다.
export function derivePhaseStates(mode, plan, cursor) {
  const applied = appliedEntries(plan, cursor);
  const inPlan = new Set(plan.flatMap((step) => step.entries.map((entry) => entry.phaseId)).filter(Boolean));
  const current = cursor > 0 ? plan[cursor - 1] : null;
  const currentIds = new Set(current ? current.entries.map((entry) => entry.phaseId) : []);
  const next = plan[cursor] ?? null;
  const nextIds = new Set(next ? next.entries.map((entry) => entry.phaseId) : []);
  const gate = getIntegrationGate(mode, plan, cursor);

  return PHASES.map((phase, index) => {
    const entries = applied.filter((entry) => entry.phaseId === phase.id);
    const lanes =
      mode === MODE.PARALLEL && LANE_PHASES.includes(phase.id)
        ? LANES.map((lane) => {
            const laneEntries = entries.filter((entry) => entry.lane === lane);
            return { lane, status: statusFromEntries(laneEntries), last: laneEntries.at(-1) ?? null };
          })
        : null;

    let status;
    if (!inPlan.has(phase.id)) status = PHASE_STATUS.SKIPPED;
    else if (lanes) status = combineLaneStatus(lanes);
    else if (entries.length === 0 && gate.blocked && GATED_PHASES.includes(phase.id)) status = PHASE_STATUS.GATED;
    else status = statusFromEntries(entries);

    return {
      ...phase,
      order: index + 1,
      status,
      last: entries.at(-1) ?? null,
      runs: entries.length,
      reworked: entries.some(isRetry),
      isCurrent: currentIds.has(phase.id),
      isNext: nextIds.has(phase.id),
      lanes,
    };
  });
}

// 모바일 레인 그룹용: 레인별 5단계 진행 상황과 레인 전체 상태.
export function deriveLaneSummaries(phaseStates, mergeGate) {
  return LANES.map((lane) => {
    const rows = LANE_PHASES.map((phaseId) => {
      const phase = phaseStates.find((item) => item.id === phaseId);
      const laneState = phase.lanes?.find((item) => item.lane === lane) ?? { status: PHASE_STATUS.PENDING, last: null };
      return { phaseId, label: phase.label, status: laneState.status, last: laneState.last };
    });
    let status = combineLaneStatus(rows);
    if (status === PHASE_STATUS.DONE && mergeGate?.status === "waiting") status = PHASE_STATUS.GATED;
    return { lane, status, rows, reworked: rows.some((row) => row.last && isRetry(row.last)) };
  });
}

function entryTitle(entry) {
  if (entry.nodeId) return NODE_BY_ID.get(entry.nodeId).label;
  const phase = getPhase(entry.phaseId);
  return entry.phaseId === "qa" ? `${phase.label} ${entry.attempt}차` : phase.label;
}

function entryOutcome(entry) {
  if (entry.nodeId === MERGE_NODE.id) return `${LANES.join("·")} ${OUTCOME_LABEL[entry.outcome]}`;
  if (entry.rework && REWORK_LABEL[entry.phaseId]) return REWORK_LABEL[entry.phaseId];
  return OUTCOME_LABEL[entry.outcome];
}

export function stepTone(step) {
  if (step.entries.some((entry) => entry.outcome === OUTCOME.DEFECT)) return "fault";
  if (step.entries.some((entry) => entry.rework)) return "repair";
  return "ok";
}

// 실행 기록 한 줄. 예: "QA 1차 — 결함 발견", "QA 1차 — A·C 통과 · B 결함 발견".
// AI-NOTE: 사용자 명시 요청으로 "(설명용)" 꼬리표를 뺐다. 다시 붙이지 않는다.
export function describeStep(step) {
  const [first] = step.entries;
  const title = entryTitle(first);
  let body;
  if (step.entries.length === 1) {
    const lanePrefix = first.lane ? `${first.lane} ` : "";
    body = lanePrefix + entryOutcome(first);
  } else {
    const groups = new Map();
    for (const entry of step.entries) {
      const key = entryOutcome(entry);
      if (!groups.has(key)) groups.set(key, { lanes: [], entry });
      groups.get(key).lanes.push(entry.lane);
    }
    body = [...groups.entries()]
      .map(([label, group]) => `${group.lanes.join("·")} ${label}`)
      .join(" · ");
  }
  return { id: step.id, text: `${title} — ${body}`, tone: stepTone(step) };
}

export function deriveHistory(plan, cursor) {
  return plan.slice(0, cursor).map((step, index) => ({ ...describeStep(step), number: index + 1 }));
}

function shortStep(step) {
  const [first] = step.entries;
  const defects = step.entries.filter((entry) => entry.outcome === OUTCOME.DEFECT);
  if (defects.length > 0) {
    const lanes = defects.map((entry) => entry.lane).filter(Boolean);
    return `${entryTitle(first)} ${lanes.length ? `${lanes.join("·")} ` : ""}결함`;
  }
  const lanes = step.entries.length === 1 && first.lane ? `${first.lane} ` : "";
  return `${entryTitle(first)} ${lanes}${entryOutcome(first)}`;
}

// 상단 상태 표시. tone 은 색, text 는 항상 함께 표시되는 문구다.
export function describeRun(state) {
  const { plan, cursor, status } = state;
  const current = cursor > 0 ? plan[cursor - 1] : null;
  const next = plan[cursor] ?? null;
  if (status === RUN_STATUS.DONE) return { tone: "ok", text: "완료" };
  if (status === RUN_STATUS.RUNNING) {
    if (!current) return { tone: "running", text: `실행 중 · ${entryTitle(next.entries[0])} 준비` };
    return { tone: stepTone(current) === "fault" ? "fault" : "running", text: `실행 중 · ${shortStep(current)}` };
  }
  if (status === RUN_STATUS.PAUSED && current) {
    return { tone: stepTone(current) === "fault" ? "fault" : "paused", text: `일시정지 · ${shortStep(current)}` };
  }
  return { tone: "idle", text: "대기" };
}

// 단계 탐색 패널의 설명 문장 목록.
export function describePhase(phaseState, { mode, gate }) {
  const lines = [phaseState.summary];
  const { status, last } = phaseState;

  if (status === PHASE_STATUS.SKIPPED) {
    lines.push(mode === MODE.DIRECT ? "직접 처리 경로에서는 이 단계를 거치지 않음 · 단순 요청은 단계를 늘리지 않습니다" : "이 경로에서는 생략");
    return lines;
  }
  if (status === PHASE_STATUS.GATED) {
    lines.push(`${gate.waitingLanes.join("·")} 병합 대기 · ${gate.blockingLanes.join("·")} 복구 전까지 병합 불가`);
    return lines;
  }
  if (status === PHASE_STATUS.PENDING) {
    lines.push("아직 실행 전 · 대기");
    if (phaseState.humanNote) lines.push(phaseState.humanNote);
    return lines;
  }

  if (phaseState.lanes) {
    const faultLanes = phaseState.lanes.filter((lane) => lane.status === PHASE_STATUS.FAULT).map((lane) => lane.lane);
    const laneText = phaseState.lanes
      .map((lane) => `${lane.lane} ${lane.last ? entryOutcome(lane.last) : "대기"}`)
      .join(" · ");
    lines.push(`레인 결과: ${laneText}`);
    if (faultLanes.length > 0) {
      lines.push(`${faultLanes.join("·")}만 개발로 되돌려 수정 후 검수·QA 재수행`);
    } else if (phaseState.reworked) {
      lines.push(`${FAULT_LANE} 결함 수정 반영`);
    }
    if (gate.blocked && phaseState.id === "qa") {
      lines.push(`${gate.waitingLanes.join("·")}는 ${gate.blockingLanes.join("·")} 복구까지 병합 대기`);
    }
    return lines;
  }

  if (status === PHASE_STATUS.FAULT) {
    lines.push(`${last.attempt}차 결과: 결함 발견`);
    lines.push("개발로 되돌려 수정 후 검수·QA 재수행");
    return lines;
  }
  if (phaseState.id === "qa" && last.attempt > 1) {
    lines.push(`${last.attempt}차 결과: 통과 · 수정 후 재검증`);
  } else if (phaseState.reworked) {
    lines.push(`결함 수정 반영 · ${entryOutcome(last)}`);
  } else {
    lines.push(`결과: ${entryOutcome(last)}`);
  }
  if (phaseState.humanNote) lines.push(phaseState.humanNote);
  return lines;
}

// 7단계에 속하지 않는 실행 노드(직접 처리 노드, 병합 게이트)의 상세 패널 내용.
export function describeRouteNode(mode, plan, cursor) {
  if (mode === MODE.DIRECT) {
    const nodes = deriveDirectNodes(mode, plan, cursor);
    const node = nodes.find((item) => item.isCurrent) ?? nodes.find((item) => item.isNext) ?? nodes[0];
    return {
      title: node.label,
      lines: [
        node.summary,
        node.status === PHASE_STATUS.DONE ? `결과: ${entryOutcome(plan[node.order - 1].entries[0])}` : "아직 실행 전 · 대기",
        getModeHint(MODE.DIRECT),
      ],
    };
  }
  const gate = deriveMergeGate(mode, plan, cursor);
  if (!gate) return null;
  const statusLine = {
    done: `결과: ${LANES.join("·")} 병합`,
    waiting: `${gate.waitingLanes.join("·")} 병합 대기 · ${gate.blockingLanes.join("·")} 복구 중`,
    pending: "아직 실행 전 · 대기",
  }[gate.status];
  return { title: gate.label, lines: [gate.summary, statusLine] };
}

// 결함 반환 연결선 표시 여부와 문구.
export function deriveReturnConnector(mode, phaseStates) {
  const qa = phaseStates.find((phase) => phase.id === "qa");
  if (!qa || qa.status !== PHASE_STATUS.FAULT) return null;
  const lanes = qa.lanes ? qa.lanes.filter((lane) => lane.status === PHASE_STATUS.FAULT).map((lane) => lane.lane) : [];
  const prefix = mode === MODE.PARALLEL && lanes.length ? `${lanes.join("·")} ` : "";
  return { from: "qa", to: "dev", text: `${prefix}결함 반환 → 개발 · 검수 · QA 재수행` };
}
