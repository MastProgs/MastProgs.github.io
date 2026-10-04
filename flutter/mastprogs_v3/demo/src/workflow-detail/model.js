// /workflow 상세 페이지의 순수 모델. 기존 src/workflow/* (메인 요약·직접 경로용)와 분리된 추가 모듈이다.
// AI-NOTE: 브라우저 API 를 쓰지 않는다. node:test 가 직접 import 하므로 확장자를 포함한 상대 경로만 쓴다.
// 화면 상태(대화, WORK SPEC, Seed 계보, 레인, 병합 게이트, 통합, 기록)는 시나리오 하나의 steps 와 cursor 에서 파생된다.
// cursor = 적용된 단계 수(0..total). 타이머나 저장 상태가 없으므로 같은 시나리오·cursor 는 항상 같은 화면이다.
// getScenario(options) 가 직접 처리·순차·병렬 공용 엔진이다(직접 처리는 요청 → 직접 처리 → 응답 3단계). 파일 아래쪽의 기존 export(DETAIL_STEPS, deriveLane 등)는
// 기본 시나리오(병렬·Seed 보기 켬)에 묶인 호환용이다.
import {
  CLOSING_MESSAGES,
  DEFAULT_SCENARIO,
  DETAIL_LANES,
  DIRECT_CLOSING,
  DIRECT_FLOW,
  DIRECT_INTAKE,
  DIRECT_WORK,
  INTAKE_MESSAGES,
  INTEGRATION_STEPS,
  LANE_SCRIPTS,
  MERGE_ORDER,
  PARALLEL_SPEC,
  SEQUENTIAL_CLOSING,
  SEQUENTIAL_INTAKE,
  SEQUENTIAL_LANE,
  SEQUENTIAL_SPEC,
  SEQUENTIAL_TAIL,
  SEQUENTIAL_TEXT,
  TASK_PLANNING,
} from "../content/workflowDetail.js";

// AI-NOTE: 병렬 전용 전체 Task Planning 세 프레임(WORK SPEC 다음, 지시 배정·Seed·레인 기획 전).
// 제안(task-split) → 검토 승인(task-review) → 동결(task-freeze). 동결된(승인된) 계약만 레인 배정에 쓰인다.
export const TASK_STAGES = Object.freeze(["task-split", "task-review", "task-freeze"]);

export const LANE_STAGES = Object.freeze([
  { id: "plan", label: "기획" },
  { id: "plan-review", label: "기획 검수" },
  { id: "dev", label: "개발" },
  { id: "dev-review", label: "개발 검수" },
  { id: "qa", label: "QA" },
  { id: "ready", label: "완료" },
]);

const STAGE_LABEL = Object.fromEntries(LANE_STAGES.map((stage) => [stage.id, stage.label]));

// 반려·실패 시 되돌아가는 단계. QA 실패는 개발로 돌아가 개발 검수와 QA 를 다시 거친다.
export const RETURN_TARGET = Object.freeze({ "plan-review": "plan", "dev-review": "dev", qa: "dev" });

export const VERDICT_LABEL = Object.freeze({
  approved: "승인",
  rejected: "반려",
  passed: "통과",
  failed: "실패",
});

// AI-NOTE: 세션 계보(sequential-seed-workflow.md). 단계마다 세션이 정해져 있고, Seed 를 쓰면 Author/Reviewer 계열 child 는
// 역할별 Seed 에서 sibling 으로 fork 된다. 같은 단계의 재작업은 같은 child 를 resume 하며 Seed 는 다시 만들지 않는다.
// QA 와 Wiki 는 부모가 없다(구현자·Seed 문맥 상속 없음). QA 재시도는 같은 레인 QA 세션을 resume 한다(매번 새로 만들지 않음).
// 병렬 레인 Seed 는 문서상 항상 있으므로 seeded = parallel || options.seed 다. 병렬의 seed 옵션은 화면 표시만 바꾼다.
export const SESSION_FOR_STAGE = Object.freeze({
  plan: "plan-author",
  "plan-review": "plan-reviewer",
  dev: "dev-author",
  "dev-review": "dev-reviewer",
  qa: "qa",
});
export const SEED_PARENT = Object.freeze({
  "plan-author": "author-seed",
  "dev-author": "author-seed",
  "plan-reviewer": "reviewer-seed",
  "dev-reviewer": "reviewer-seed",
});
export const SEED_CHILDREN = Object.freeze(["plan-author", "dev-author", "plan-reviewer", "dev-reviewer"]);

const pad = (value, size = 2) => String(value).padStart(size, "0");

// 기록 예시의 시각. 날짜 없이 HH:MM:SS 만 쓴다(개인정보 검사의 날짜 패턴과 겹치지 않게).
function clockFor(step, offset) {
  const seconds = 9 * 3600 + 30 * 60 + step * 150 + offset * 20;
  return `${pad(Math.floor(seconds / 3600))}:${pad(Math.floor((seconds % 3600) / 60))}:${pad(seconds % 60)}`;
}

export function normalizeScenario(options = {}) {
  const route = options.route === "sequential" || options.route === "direct" ? options.route : "parallel";
  const pick = (key) => (options[key] === undefined ? DEFAULT_SCENARIO[key] : Boolean(options[key]));
  // 병렬은 고정 예시라 실패 옵션을 쓰지 않는다(Seed 보기만 반영). 직접 처리에는 옵션이 하나도 없다.
  const sequential = route === "sequential";
  return Object.freeze({
    route,
    seed: route === "direct" ? false : pick("seed"),
    planReject: sequential ? pick("planReject") : false,
    qaFail: sequential ? pick("qaFail") : false,
  });
}

// 순차 레인 일정. 반려·실패는 옵션마다 한 번이며 다음 회차에서 통과한다.
export function sequentialScript({ planReject, qaFail }) {
  const T = SEQUENTIAL_TEXT;
  const items = [];
  const push = (item) => items.push({ at: items.length, ...item });
  push({ stage: "plan", text: T.plan });
  if (planReject) {
    push({ stage: "plan-review", verdict: "rejected", text: T.planRejected, reason: T.planRejectReason });
    push({ stage: "plan", text: T.planRevise });
    push({ stage: "plan-review", verdict: "approved", text: T.planReApproved });
  } else {
    push({ stage: "plan-review", verdict: "approved", text: T.planApproved });
  }
  push({ stage: "dev", text: T.dev });
  push({ stage: "dev-review", verdict: "approved", text: T.devApproved });
  if (qaFail) {
    push({ stage: "qa", verdict: "failed", text: T.qaFailed, reason: T.qaFailReason, issueId: "QF-001" });
    push({ stage: "dev", text: T.devFix });
    push({ stage: "dev-review", verdict: "approved", text: T.devReApproved });
    push({ stage: "qa", verdict: "passed", text: T.qaRePassed, resolves: "QF-001" });
  } else {
    push({ stage: "qa", verdict: "passed", text: T.qaPassed });
  }
  return items;
}

// 이벤트에 seq·id·시각을 붙이고 얼린다(모든 경로 공용).
function finalizeSteps(steps) {
  let seq = 0;
  for (const step of steps) {
    step.events = step.events.map((event, offset) => {
      seq += 1;
      return Object.freeze({
        lane: null,
        stage: null,
        attempt: null,
        verdict: null,
        reason: null,
        session: null,
        parentSession: null,
        ...event,
        seq,
        id: `ev-${pad(seq, 3)}`,
        step: step.index,
        time: clockFor(step.index, offset),
      });
    });
    Object.freeze(step.events);
    Object.freeze(step);
  }
  return Object.freeze(steps);
}

// AI-NOTE: 직접 처리: 요청 → Master 직접 처리 → 응답 세 단계. 명세·배정·Seed·레인·통합이 없어 해당 단계 번호는 -1 이다.
function buildDirectSteps() {
  const steps = [];
  const pushStep = (phase, events) => steps.push({ index: steps.length, id: `detail-${steps.length + 1}`, phase, events });
  DIRECT_INTAKE.forEach((message) => pushStep("intake", [{ type: "message", ...message }]));
  pushStep("direct", [{ type: "direct", actor: "master", stage: "direct", text: DIRECT_WORK.text }]);
  DIRECT_CLOSING.forEach((message) => pushStep("closing", [{ type: "message", ...message }]));
  return { steps: finalizeSteps(steps), seeded: false, dispatchStep: -1, specStep: -1, seedStep: -1, taskSteps: null, lanes: [], tail: [], spec: null };
}

// 병렬 Task Planning 이벤트. 레인 id 는 계약 안 작업 목록(tasks)에만 있고 이벤트의 lane 은 비워 둔다(레인은 아직 배정 전).
function taskPlanningEvents(lanes) {
  const T = TASK_PLANNING.texts;
  const laneIds = lanes.map((lane) => lane.id);
  return [
    [{ type: "task", actor: "task-author", stage: "task-split", session: "task-planning-author", tasks: laneIds, text: T.split }],
    [{ type: "task", actor: "task-reviewer", stage: "task-review", session: "task-planning-reviewer", verdict: "approved", attempt: 1, text: T.review }],
    [{ type: "task", actor: "master", stage: "task-freeze", tasks: laneIds, text: T.freeze }],
  ];
}

function buildSteps(options) {
  if (options.route === "direct") return buildDirectSteps();
  const parallel = options.route === "parallel";
  const lanes = parallel ? DETAIL_LANES : [SEQUENTIAL_LANE];
  const scripts = parallel ? LANE_SCRIPTS : { [SEQUENTIAL_LANE.id]: sequentialScript(options) };
  const intake = parallel ? INTAKE_MESSAGES : SEQUENTIAL_INTAKE;
  const tail = parallel ? INTEGRATION_STEPS : SEQUENTIAL_TAIL;
  const closing = parallel ? CLOSING_MESSAGES : SEQUENTIAL_CLOSING;
  const seeded = parallel || options.seed;

  const steps = [];
  const pushStep = (phase, events) => steps.push({ index: steps.length, id: `detail-${steps.length + 1}`, phase, events });

  // Master 가 요청을 해석해 WORK SPEC 을 쓴 뒤에야 지시·배정 메시지를 보낸다.
  // 병렬은 그 사이에 전체 Task Planning(제안 → 검토 승인 → 동결)을 거친다. 순차는 하나의 의존 작업축이라 이 단계가 없다.
  let specStep = -1;
  let taskSteps = null;
  for (const message of intake) {
    if (message.decision === "dispatch") {
      specStep = steps.length;
      pushStep("spec", [{ type: "spec", actor: "master", text: parallel ? "WORK SPEC 작성: 요청 범위·완료 기준" : "WORK SPEC 작성: 범위·완료 기준·작업축 1개·소유 경로" }]);
      if (parallel) {
        const [split, review, freeze] = taskPlanningEvents(lanes).map((events) => {
          const index = steps.length;
          pushStep("task", events);
          return index;
        });
        taskSteps = { split, review, freeze };
      }
    }
    pushStep("intake", [{ type: "message", ...message }]);
  }
  const dispatchStep = steps.length - 1;

  let seedStep = -1;
  if (seeded) {
    seedStep = steps.length;
    pushStep(
      "seed",
      lanes.flatMap((lane) => [
        { type: "seed", actor: "seed", lane: lane.id, session: "author-seed", text: "Author Seed 준비(읽기 전용)" },
        { type: "seed", actor: "seed", lane: lane.id, session: "reviewer-seed", text: "Reviewer Seed 준비(읽기 전용)" },
      ]),
    );
  }

  const laneTicks = Math.max(...Object.values(scripts).flat().map((item) => item.at)) + 1;
  const attempts = {};
  for (let tick = 0; tick < laneTicks; tick += 1) {
    const events = [];
    for (const lane of lanes) {
      for (const item of scripts[lane.id].filter((entry) => entry.at === tick)) {
        const key = `${lane.id}:${item.stage}`;
        attempts[key] = (attempts[key] ?? 0) + 1;
        const session = SESSION_FOR_STAGE[item.stage];
        events.push({
          type: item.verdict ? "verdict" : "author",
          actor: item.stage.endsWith("review") ? "reviewer" : item.stage === "qa" ? "qa" : "author",
          lane: lane.id,
          stage: item.stage,
          attempt: attempts[key],
          verdict: item.verdict ?? null,
          reason: item.reason ?? null,
          issueId: item.issueId ?? null,
          resolves: item.resolves ?? null,
          ready: item.stage === "qa" && item.verdict === "passed",
          session,
          parentSession: seeded ? SEED_PARENT[session] ?? null : null,
          // 같은 단계의 두 번째 이후 실행은 같은 세션을 resume 한다(독립 QA 도 같은 레인 QA 세션을 resume).
          resumed: attempts[key] > 1,
          text: item.text,
        });
      }
    }
    pushStep("lanes", events);
  }

  tail.forEach((item) => pushStep("integration", [{ type: "integration", actor: "integration", stage: item.id, text: item.text, session: item.id === "wiki" ? "wiki" : null }]));
  closing.forEach((message) => pushStep("closing", [{ type: "message", ...message }]));

  return { steps: finalizeSteps(steps), seeded, dispatchStep, specStep, seedStep, taskSteps, lanes, tail, spec: parallel ? PARALLEL_SPEC : SEQUENTIAL_SPEC };
}

function createScenario(options) {
  const built = buildSteps(options);
  const { steps, lanes, tail } = built;
  const parallel = options.route === "parallel";
  const total = steps.length;
  const mergeStep = steps.findIndex((step) => step.events.some((event) => event.type === "integration" && event.stage === "merge"));
  const clamp = (cursor) => Math.min(Math.max(0, Math.trunc(cursor) || 0), total);
  const eventsUpTo = (cursor) => steps.slice(0, clamp(cursor)).flatMap((step) => step.events);
  const isDispatched = (cursor) => clamp(cursor) > built.dispatchStep;
  const laneKey = (laneId) => lanes.find((lane) => lane.id === laneId)?.key ?? laneId;

  const stageEventsByLane = new Map(
    lanes.map((lane) => [lane.id, steps.flatMap((step) => step.events).filter((event) => event.lane === lane.id && event.stage)]),
  );

  function deriveConversation(cursor) {
    return eventsUpTo(cursor)
      .filter((event) => event.type === "message")
      .map((event) => ({ id: event.id, actor: event.actor, text: event.text, decision: event.decision ?? null, time: event.time }));
  }

  // WORK SPEC 카드. 작성 단계 전에는 idle, 작성 후 written, 지시 배정 후 frozen.
  // 병렬 명세는 레인을 정하지 않는다(lanes 빈 배열, splitBy: "task-planning"). 작업축별 소유 경로는 deriveTaskPlan 에 있다.
  function deriveSpec(cursor) {
    if (!built.spec) return null;
    const at = clamp(cursor);
    let status = "idle";
    if (at > built.dispatchStep) status = "frozen";
    else if (at > built.specStep) status = "written";
    return {
      status,
      ...built.spec,
      splitBy: parallel ? "task-planning" : null,
      lanes: parallel ? [] : lanes.map((lane) => ({ key: lane.key, title: lane.title, owns: lane.owns })),
    };
  }

  // 전체 Task Planning 카드(병렬만, 그 외 null). status: idle → proposed → approved → frozen.
  // 검토 승인 전에는 checks 가 비어 있고, 동결 전에는 mergeOrder 가 null 이다(되감으면 미래의 승인·동결이 남지 않음).
  function deriveTaskPlan(cursor) {
    const marks = built.taskSteps;
    if (!marks) return null;
    const at = clamp(cursor);
    let status = "idle";
    if (at > marks.freeze) status = "frozen";
    else if (at > marks.review) status = "approved";
    else if (at > marks.split) status = "proposed";
    const reviewed = status === "approved" || status === "frozen";
    return {
      status,
      tasks:
        status === "idle"
          ? []
          : lanes.map((lane) => ({ id: lane.id, key: lane.key, title: lane.title, owns: lane.owns, ...TASK_PLANNING.tasks[lane.id], dependsOnUnfinished: [] })),
      checks: reviewed ? [...TASK_PLANNING.checks] : [],
      sharedOwner: reviewed ? TASK_PLANNING.sharedOwner : null,
      approvedRound: reviewed ? 1 : null,
      mergeOrder: status === "frozen" ? [...MERGE_ORDER] : null,
    };
  }

  // 레인별 QA 지적 원장. 같은 지적 번호가 다시 실패하면 새 항목 없이 그 항목의 재현 횟수만 늘린다.
  // 해결은 독립 QA 통과(resolves)로만 바뀐다(작성자 자기 선언으로 닫지 않음).
  function deriveIssues(laneId, cursor) {
    const issues = [];
    for (const event of eventsUpTo(cursor)) {
      if (event.lane !== laneId || event.stage !== "qa") continue;
      if (event.issueId) {
        const found = issues.find((issue) => issue.id === event.issueId);
        if (found) {
          found.occurrences += 1;
          found.status = "open";
          found.text = event.reason;
          found.attempts.push(event.attempt);
        } else {
          issues.push({ id: event.issueId, status: "open", text: event.reason, occurrences: 1, attempts: [event.attempt], resolvedBy: null });
        }
      }
      if (event.resolves) {
        for (const issue of issues) {
          if (issue.id === event.resolves) {
            issue.status = "resolved";
            issue.resolvedBy = `qa:${event.attempt}`;
          }
        }
      }
    }
    return issues.map((issue) => ({ ...issue, attempts: [...issue.attempts] }));
  }

  // 레인의 세션 계보. seeded 는 실제 Seed 유무(병렬은 항상), 패널 표시 여부는 화면이 state.options.seed 로 정한다.
  function deriveLineage(laneId, seen, at) {
    const runs = (session) => seen.filter((event) => event.session === session).length;
    return {
      seeded: built.seeded,
      seedReady: built.seeded && at > built.seedStep,
      children: SEED_CHILDREN.map((id) => ({ id, parent: SEED_PARENT[id], runs: runs(id) })),
      qaRuns: runs("qa"),
    };
  }

  // 한 레인의 현재 모습. stages 의 status: pending | done | returned, isActive 는 지금 진행 중인 단계.
  function deriveLane(laneId, cursor) {
    const at = clamp(cursor);
    const meta = lanes.find((lane) => lane.id === laneId);
    const all = stageEventsByLane.get(laneId);
    const seen = all.filter((event) => event.step < at);
    const upcoming = all.find((event) => event.step >= at) ?? null;
    const dispatched = isDispatched(at);
    const seeding = built.seeded && at <= built.seedStep;
    const stages = LANE_STAGES.map((stage) => ({ ...stage, status: "pending", attempts: 0, rejections: 0, isActive: false }));
    const byId = Object.fromEntries(stages.map((stage) => [stage.id, stage]));
    const returns = [];
    let connector = null;
    let ready = false;

    for (const event of seen) {
      const stage = byId[event.stage];
      stage.attempts = event.attempt;
      if (event.type === "author") {
        stage.status = "done";
        continue;
      }
      if (event.verdict === "approved" || event.verdict === "passed") {
        stage.status = "done";
        // 같은 검수·QA 단계가 최종 승인·통과하면 그 단계의 미해결 되돌림을 모두 해결로 남긴다(각 사유·회차 보존).
        for (const item of returns) {
          if (item.from === event.stage && !item.resolvedBy) {
            item.resolvedBy = event.id;
            item.resolvedAttempt = event.attempt;
          }
        }
        if (connector && connector.from === event.stage) connector = null;
      } else {
        stage.status = "returned";
        stage.rejections += 1;
        // 같은 단계에서 다시 반려·실패하면 앞 되돌림은 "다시 반려됨"으로 남기고 새 되돌림이 이어진다.
        if (connector && connector.from === event.stage) returns.at(-1).supersededBy = event.id;
        connector = {
          from: event.stage,
          to: RETURN_TARGET[event.stage],
          reason: event.reason,
          attempt: event.attempt,
          issueId: event.issueId ?? null,
          eventId: event.id,
          // 되돌림이 막 일어난 단계(움직이는 표시는 이때 한 번만 재생).
          fresh: event.step === at - 1,
        };
        returns.push({ ...connector, verdict: event.verdict, resolvedBy: null, resolvedAttempt: null, supersededBy: null });
        // 되돌아간 뒤에는 대상 단계부터 다시 거치므로 그 사이 단계 표시도 다시 대기로 돌린다.
        const fromIndex = LANE_STAGES.findIndex((item) => item.id === event.stage);
        const toIndex = LANE_STAGES.findIndex((item) => item.id === connector.to);
        for (let index = toIndex; index < fromIndex; index += 1) stages[index].status = "pending";
      }
      if (event.ready) ready = true;
    }

    const live = dispatched && !seeding;
    if (ready) byId.ready.status = "done";
    if (live && upcoming) byId[upcoming.stage].isActive = true;

    const merged = mergeStep !== -1 && at > mergeStep;
    let status = "running";
    if (!dispatched) status = "queued";
    else if (seeding) status = "seeding";
    else if (ready && !parallel) status = "done";
    else if (merged && ready) status = "merged";
    else if (ready) status = "ready";
    else if (connector) status = "returned";

    return {
      ...meta,
      status,
      stages,
      connector,
      returns,
      issues: deriveIssues(laneId, at),
      lineage: deriveLineage(laneId, seen, at),
      readyAt: all.find((event) => event.ready)?.step ?? null,
      current: upcoming && live ? { stage: upcoming.stage, attempt: upcoming.attempt, label: STAGE_LABEL[upcoming.stage] } : null,
      lastEvent: seen.at(-1) ?? null,
      counts: {
        planReview: byId["plan-review"].attempts,
        devReview: byId["dev-review"].attempts,
        qa: byId.qa.attempts,
      },
    };
  }

  const deriveLanes = (cursor) => lanes.map((lane) => deriveLane(lane.id, cursor));

  // AI-NOTE: 병합 게이트는 병렬에만 있다. 모든 레인이 QA 를 통과(ready)해야 열리고, 먼저 끝난 레인은 READY 로 기다린다.
  function deriveMergeGate(cursor) {
    if (!parallel) return null;
    const current = deriveLanes(cursor);
    const readyLanes = current.filter((lane) => lane.status === "ready" || lane.status === "merged").map((lane) => lane.key);
    const waitingFor = current.filter((lane) => !readyLanes.includes(lane.key)).map((lane) => lane.key);
    let status = "locked";
    if (clamp(cursor) > mergeStep) status = "merged";
    else if (waitingFor.length === 0) status = "open";
    return { status, readyLanes, waitingFor };
  }

  function deriveIntegration(cursor) {
    const at = clamp(cursor);
    const done = new Set(eventsUpTo(at).filter((event) => event.type === "integration").map((event) => event.stage));
    const next = steps[at]?.events.find((event) => event.type === "integration")?.stage ?? null;
    return tail.map((item) => ({ ...item, status: done.has(item.id) ? "done" : "pending", isActive: item.id === next }));
  }

  // 직접 처리 흐름 노드(요청·직접 처리·응답). 노드 i 는 단계 i 에 대응한다. 다른 경로는 빈 배열.
  function deriveDirect(cursor) {
    if (options.route !== "direct") return [];
    const at = clamp(cursor);
    return DIRECT_FLOW.map((node, index) => ({ ...node, step: index, status: index < at ? "done" : "pending", isActive: index === at }));
  }

  function describeEvent(event) {
    if (event.type === "message") return `${event.actor === "human" ? "사람" : "Master AI"}: ${event.text}`;
    if (event.type === "spec" || event.type === "task" || event.type === "integration" || event.type === "direct") return event.text;
    if (event.type === "seed") return `${laneKey(event.lane)} ${event.text}`;
    const head = `${laneKey(event.lane)} ${STAGE_LABEL[event.stage]} ${event.attempt}회차`;
    if (event.verdict) return `${head} ${VERDICT_LABEL[event.verdict]}${event.reason ? ` — ${event.reason}` : ""}`;
    return `${head} — ${event.text}`;
  }

  // 진행 문구. 자동 재생 중에는 명세·Seed·반려·실패·READY·병합처럼 눈에 띄는 단계만 알린다.
  function stepAnnouncement(cursor, { manual = false } = {}) {
    const at = clamp(cursor);
    if (at === 0) return "";
    const events = steps[at - 1].events;
    const notable = events.filter(
      (event) => event.type === "spec" || event.type === "task" || event.type === "direct" || event.verdict === "rejected" || event.verdict === "failed" || event.ready || event.stage === "merge" || event.stage === "final-merge",
    );
    if (events[0].type === "seed") notable.push({ type: "spec", text: "레인별 Author·Reviewer Seed 준비" });
    const picked = manual ? events : notable;
    const texts = picked.map(describeEvent);
    if (at === total) texts.push("전체 진행 완료");
    if (texts.length === 0) return "";
    return `${at}단계, ${texts.join(" · ")}`;
  }

  function describeStep(cursor) {
    const at = clamp(cursor);
    if (at === 0) return "시작 전";
    const step = steps[at - 1];
    if (step.phase === "spec") return "WORK SPEC 작성";
    if (step.phase === "task") return "Task Planning";
    if (step.phase === "seed") return "Seed 준비";
    if (step.phase === "direct") return "Master AI 직접 처리";
    if (step.phase === "intake") return at - 1 === built.dispatchStep ? "지시 배정" : "요청 접수";
    if (step.phase === "lanes") return parallel ? "레인 병렬 진행" : "단계 진행";
    if (step.phase === "integration") return parallel ? "통합" : "Wiki";
    return at === total ? "완료" : "결과 보고";
  }

  return Object.freeze({
    options,
    parallel,
    seeded: built.seeded,
    lanes,
    steps,
    total,
    dispatchStep: built.dispatchStep,
    specStep: built.specStep,
    seedStep: built.seedStep,
    taskSteps: built.taskSteps,
    mergeStep,
    clamp,
    eventsUpTo,
    isDispatched,
    laneKey,
    deriveConversation,
    deriveSpec,
    deriveTaskPlan,
    deriveIssues,
    deriveLane,
    deriveLanes,
    deriveMergeGate,
    deriveIntegration,
    deriveDirect,
    describeEvent,
    stepAnnouncement,
    describeStep,
  });
}

const scenarioCache = new Map();

// 같은 옵션이면 같은 시나리오 객체를 돌려준다(병렬 상단 탭과 순차·직접 처리 탭의 병렬 라디오가 같은 엔진을 쓴다).
export function getScenario(options = {}) {
  const normalized = normalizeScenario(options);
  const key = `${normalized.route}|${normalized.seed}|${normalized.planReject}|${normalized.qaFail}`;
  if (!scenarioCache.has(key)) scenarioCache.set(key, createScenario(normalized));
  return scenarioCache.get(key);
}

export function stageLabel(stageId) {
  return STAGE_LABEL[stageId] ?? stageId;
}

// ---- 기존 호출부 호환 export: 기본 시나리오(병렬·Seed 보기 켬) ----
const DEFAULT = getScenario(DEFAULT_SCENARIO);

export const DETAIL_STEPS = DEFAULT.steps;
export const DETAIL_TOTAL = DEFAULT.total;
// 이 단계가 적용되면(cursor > DISPATCH_STEP) 레인이 배정된다.
export const DISPATCH_STEP = DEFAULT.dispatchStep;
export const MERGE_STEP = DEFAULT.mergeStep;
export const clampCursor = DEFAULT.clamp;
export const eventsUpTo = DEFAULT.eventsUpTo;
export const isDispatched = DEFAULT.isDispatched;
export const deriveConversation = DEFAULT.deriveConversation;
export const deriveLane = DEFAULT.deriveLane;
export const deriveLanes = DEFAULT.deriveLanes;
export const deriveMergeGate = DEFAULT.deriveMergeGate;
export const deriveIntegration = DEFAULT.deriveIntegration;
export const describeEvent = DEFAULT.describeEvent;
export const stepAnnouncement = DEFAULT.stepAnnouncement;
export const describeDetailStep = DEFAULT.describeStep;

export function canMergeDetail(cursor, scenario = DEFAULT) {
  const gate = scenario.deriveMergeGate(cursor);
  return Boolean(gate) && gate.waitingFor.length === 0;
}
