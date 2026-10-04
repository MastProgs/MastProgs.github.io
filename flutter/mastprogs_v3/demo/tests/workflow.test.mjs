import assert from "node:assert/strict";
import { describe, test } from "node:test";
import { announcementFor } from "../src/workflow/announce.js";
import { MODE, OUTCOME, PHASES, PHASE_STATUS, RUN_STATUS, TARGET_PRESET } from "../src/workflow/constants.js";
import {
  buildPlan,
  canMerge,
  deriveDirectNodes,
  deriveHistory,
  deriveLaneSummaries,
  deriveMergeGate,
  derivePhaseStates,
  deriveReturnConnector,
  describePhase,
  describeRouteNode,
  describeRun,
  getIntegrationGate,
} from "../src/workflow/model.js";
import { ACTION, createInitialState, workflowReducer } from "../src/workflow/reducer.js";

const run = (state, ...types) => types.reduce((acc, type) => workflowReducer(acc, typeof type === "string" ? { type } : type), state);
const ticks = (state, count) => run(state, ...Array.from({ length: count }, () => ACTION.TICK));
const flatPhases = (plan) => plan.map((step) => step.entries.map((entry) => entry.phaseId).join("+"));
const phaseState = (state, id) => derivePhaseStates(state.mode, state.plan, state.cursor).find((phase) => phase.id === id);

describe("direct route", () => {
  test("is request -> Master AI direct handling -> response, outside the seven phases", () => {
    for (const failOn of [true, false]) {
      const plan = buildPlan(MODE.DIRECT, failOn);
      assert.equal(plan.length, 3, "three execution steps regardless of the failure toggle");
      const entries = plan.flatMap((step) => step.entries);
      assert.ok(entries.every((entry) => entry.phaseId === null), "no author/review/QA/integration phase is executed");
      assert.ok(entries.every((entry) => entry.outcome !== OUTCOME.DEFECT));
      assert.deepEqual(
        deriveHistory(plan, plan.length).map((item) => item.text),
        ["요청 — 접수", "Master AI 직접 처리 — 완료", "응답 — 전달"],
      );
    }

    const state = createInitialState({ mode: MODE.DIRECT, failOn: true });
    assert.equal(workflowReducer(state, { type: ACTION.SET_FAIL, failOn: false }), state, "toggle is a no-op in direct mode");
    assert.ok(derivePhaseStates(state.mode, state.plan, state.cursor).every((phase) => phase.status === PHASE_STATUS.SKIPPED));
    assert.equal(state.selectedPhaseId, null, "selection follows the direct node, not a phase tile");

    const midway = run(state, ACTION.NEXT, ACTION.NEXT);
    assert.equal(describeRouteNode(midway.mode, midway.plan, midway.cursor).title, "Master AI 직접 처리");
    const nodes = deriveDirectNodes(midway.mode, midway.plan, midway.cursor);
    assert.deepEqual(nodes.map((node) => node.status), [PHASE_STATUS.DONE, PHASE_STATUS.DONE, PHASE_STATUS.PENDING]);

    const done = ticks(run(state, ACTION.PLAY), 3);
    assert.equal(done.status, RUN_STATUS.DONE);
    assert.equal(deriveHistory(done.plan, done.cursor).length, 3);
    const qaLines = describePhase(phaseState(done, "qa"), { mode: done.mode, gate: getIntegrationGate(done.mode, done.plan, done.cursor) });
    assert.match(qaLines.at(-1), /거치지 않음/);
  });
});

describe("logical phases vs execution ticks", () => {
  test("ruler stays at seven phases while execution totals vary by route", () => {
    assert.equal(PHASES.length, 7);
    const totals = {};
    for (const mode of Object.values(MODE)) {
      for (const failOn of [false, true]) {
        const plan = buildPlan(mode, failOn);
        totals[`${mode}/${failOn}`] = plan.length;
        for (const entry of plan.flatMap((step) => step.entries)) {
          if (entry.phaseId === null) assert.equal(entry.phaseIndex, null);
          else assert.ok(entry.phaseIndex >= 0 && entry.phaseIndex < 7);
        }
      }
    }
    assert.deepEqual(totals, {
      "direct/false": 3,
      "direct/true": 3,
      "sequential/false": 7,
      "sequential/true": 10,
      "parallel/false": 8,
      "parallel/true": 11,
    });
  });
});

describe("sequential route", () => {
  test("without failure passes the seven phases in order", () => {
    const plan = buildPlan(MODE.SEQUENTIAL, false);
    assert.deepEqual(flatPhases(plan), PHASES.map((phase) => phase.id));
  });

  test("QA failure returns to developer, review and QA before Wiki", () => {
    const plan = buildPlan(MODE.SEQUENTIAL, true);
    assert.equal(plan.length, 10);
    assert.deepEqual(flatPhases(plan), [
      "plan",
      "review-plan",
      "dev",
      "review-dev",
      "qa",
      "dev",
      "review-dev",
      "qa",
      "wiki",
      "integrate",
    ]);
    const defectIndex = plan.findIndex((step) => step.entries[0].outcome === OUTCOME.DEFECT);
    const passIndex = plan.findIndex((step) => step.entries[0].phaseId === "qa" && step.entries[0].outcome === OUTCOME.PASS);
    const wikiIndex = plan.findIndex((step) => step.entries[0].phaseId === "wiki");
    assert.equal(defectIndex, 4);
    assert.ok(plan[5].entries[0].rework && plan[6].entries[0].rework);
    assert.ok(passIndex > defectIndex && wikiIndex > passIndex);
  });

  test("connector stays while the defect is unresolved and clears after QA passes", () => {
    let state = createInitialState({ mode: MODE.SEQUENTIAL, failOn: true });
    state = run(state, ...Array(5).fill(ACTION.NEXT));
    const atDefect = derivePhaseStates(state.mode, state.plan, state.cursor);
    assert.ok(deriveReturnConnector(state.mode, atDefect));
    state = run(state, ACTION.NEXT, ACTION.NEXT);
    assert.ok(deriveReturnConnector(state.mode, derivePhaseStates(state.mode, state.plan, state.cursor)), "still returned during rework");
    state = run(state, ACTION.NEXT);
    assert.equal(deriveReturnConnector(state.mode, derivePhaseStates(state.mode, state.plan, state.cursor)), null);
    assert.equal(phaseState(state, "dev").reworked, true);
  });
});

describe("identifiers", () => {
  test("repeated review phases have unique IDs and every entry/step id is unique", () => {
    const ids = PHASES.map((phase) => phase.id);
    assert.equal(new Set(ids).size, ids.length);
    const reviews = PHASES.filter((phase) => phase.label === "검수");
    assert.equal(reviews.length, 2);
    assert.notEqual(reviews[0].id, reviews[1].id);

    for (const mode of Object.values(MODE)) {
      for (const failOn of [true, false]) {
        const plan = buildPlan(mode, failOn);
        const entryIds = plan.flatMap((step) => step.entries.map((entry) => entry.id));
        assert.equal(new Set(entryIds).size, entryIds.length, `${mode}/${failOn} entry ids`);
        assert.equal(new Set(plan.map((step) => step.id)).size, plan.length, `${mode}/${failOn} step ids`);
      }
    }
  });
});

describe("transport", () => {
  test("pause, resume, reset and replay never duplicate history", () => {
    let state = createInitialState({ mode: MODE.SEQUENTIAL, failOn: true });
    state = ticks(run(state, ACTION.PLAY), 3);
    state = run(state, ACTION.PAUSE);
    const pausedCursor = state.cursor;
    state = ticks(state, 5);
    assert.equal(state.cursor, pausedCursor, "ticks while paused are ignored");
    state = run(state, ACTION.PAUSE, ACTION.PLAY, ACTION.PLAY);
    state = ticks(state, 1);
    const history = deriveHistory(state.plan, state.cursor);
    assert.equal(history.length, 4);
    assert.equal(new Set(history.map((item) => item.id)).size, 4);

    state = run(state, ACTION.RESET);
    assert.equal(state.cursor, 0);
    assert.equal(state.status, RUN_STATUS.IDLE);
    assert.equal(deriveHistory(state.plan, state.cursor).length, 0);

    state = run(state, ACTION.REPLAY);
    assert.equal(state.status, RUN_STATUS.RUNNING);
    state = ticks(state, 25);
    const full = deriveHistory(state.plan, state.cursor);
    assert.equal(full.length, state.plan.length);
    assert.equal(new Set(full.map((item) => item.id)).size, full.length);
  });

  test("resuming unpins inspection and follows the running phase again", () => {
    let state = createInitialState({ mode: MODE.SEQUENTIAL, failOn: false });
    state = run(state, ACTION.NEXT, ACTION.NEXT, { type: ACTION.SELECT_PHASE, phaseId: "integrate" });
    assert.equal(state.selectedPhaseId, "integrate");
    state = run(state, ACTION.NEXT);
    assert.equal(state.selectedPhaseId, "integrate", "pinned selection survives manual steps");
    state = ticks(run(state, ACTION.PLAY), 1);
    assert.equal(state.selectedPhaseId, state.plan[state.cursor - 1].entries[0].phaseId);
  });

  test("selecting a tile while playing pauses without moving the cursor; follow returns to the cursor", () => {
    let state = ticks(run(createInitialState({ mode: MODE.SEQUENTIAL, failOn: true }), ACTION.PLAY), 3);
    state = workflowReducer(state, { type: ACTION.SELECT_PHASE, phaseId: "wiki" });
    assert.equal(state.status, RUN_STATUS.PAUSED);
    assert.equal(state.cursor, 3);
    assert.equal(state.selectedPhaseId, "wiki");
    assert.equal(deriveHistory(state.plan, state.cursor).length, 3);
    state = workflowReducer(state, { type: ACTION.FOLLOW_CURSOR });
    assert.equal(state.selectedPhaseId, "dev");
    assert.equal(state.pinned, false);
  });

  test("terminal state is done and does not rerun on its own", () => {
    let state = ticks(run(createInitialState({ mode: MODE.SEQUENTIAL, failOn: false }), ACTION.PLAY), 7);
    assert.equal(state.status, RUN_STATUS.DONE);
    const done = state;
    assert.equal(ticks(done, 4), done);
    assert.equal(run(done, ACTION.NEXT), done);
    assert.equal(run(done, ACTION.PAUSE), done);
    assert.equal(describeRun(done).tone, "ok");
    state = run(done, ACTION.PLAY);
    assert.equal(state.status, RUN_STATUS.RUNNING);
    assert.equal(state.cursor, 0);
  });

  test("manual next pauses and reaches done at the end", () => {
    let state = createInitialState({ mode: MODE.DIRECT });
    state = run(state, ACTION.NEXT);
    assert.equal(state.status, RUN_STATUS.PAUSED);
    state = run(state, ACTION.NEXT, ACTION.NEXT);
    assert.equal(state.status, RUN_STATUS.DONE);
  });
});

describe("parallel route", () => {
  const LANE_ORDER = ["plan", "review-plan", "dev", "review-dev", "qa"];
  const isMerge = (step) => step.entries.some((entry) => entry.nodeId === "merge");

  test("each lane independently runs plan..QA, then a merge gate and shared Wiki -> integration (8 ticks)", () => {
    const plan = buildPlan(MODE.PARALLEL, false);
    assert.equal(plan.length, 8);
    LANE_ORDER.forEach((phaseId, index) => {
      const step = plan[index];
      assert.deepEqual(step.entries.map((entry) => entry.lane), ["A", "B", "C"], `tick ${index + 1} runs all three lanes`);
      assert.ok(step.entries.every((entry) => entry.phaseId === phaseId), `tick ${index + 1} is ${phaseId} in every lane`);
    });
    assert.ok(isMerge(plan[5]), "explicit merge gate after the lane QA tick");
    assert.equal(plan[5].entries[0].phaseIndex, null, "merge gate is not one of the seven phases");
    assert.deepEqual(plan.slice(6).map((step) => [step.entries.length, step.entries[0].phaseId, step.entries[0].lane]), [
      [1, "wiki", null],
      [1, "integrate", null],
    ]);
  });

  test("B repairs alone (dev -> review -> QA) while A and C wait; merge only after all lanes pass (11 ticks)", () => {
    const plan = buildPlan(MODE.PARALLEL, true);
    assert.equal(plan.length, 11);
    const defectIndex = plan.findIndex((step) => step.entries.some((entry) => entry.outcome === OUTCOME.DEFECT));
    assert.equal(defectIndex, 4, "lane QA tick");
    assert.deepEqual(
      plan[defectIndex].entries.filter((entry) => entry.outcome === OUTCOME.DEFECT).map((entry) => entry.lane),
      ["B"],
    );

    const repair = plan.slice(defectIndex + 1, defectIndex + 4);
    assert.deepEqual(repair.map((step) => step.entries.map((entry) => `${entry.lane}:${entry.phaseId}`)), [
      ["B:dev"],
      ["B:review-dev"],
      ["B:qa"],
    ]);
    const mergeIndex = plan.findIndex(isMerge);
    assert.equal(mergeIndex, defectIndex + 4);
    assert.deepEqual(plan.slice(mergeIndex + 1).map((step) => step.entries[0].phaseId), ["wiki", "integrate"]);

    for (let cursor = defectIndex + 1; cursor <= defectIndex + 3; cursor += 1) {
      assert.equal(canMerge(plan, cursor), false, `merge impossible at cursor ${cursor}`);
      const gate = deriveMergeGate(MODE.PARALLEL, plan, cursor);
      assert.equal(gate.status, "waiting");
      assert.deepEqual(gate.waitingLanes, ["A", "C"]);
      assert.deepEqual(gate.blockingLanes, ["B"]);
    }
    assert.equal(canMerge(plan, defectIndex + 4), true, "all lanes passed after B's second QA");
    assert.equal(deriveMergeGate(MODE.PARALLEL, plan, mergeIndex + 1).status, "done");

    const atDefect = derivePhaseStates(MODE.PARALLEL, plan, defectIndex + 1);
    assert.equal(atDefect.find((phase) => phase.id === "wiki").status, PHASE_STATUS.GATED);
    assert.equal(atDefect.find((phase) => phase.id === "integrate").status, PHASE_STATUS.GATED);
    assert.deepEqual(
      atDefect.find((phase) => phase.id === "qa").lanes.map((lane) => lane.status),
      [PHASE_STATUS.DONE, PHASE_STATUS.FAULT, PHASE_STATUS.DONE],
    );
    const lanes = deriveLaneSummaries(atDefect, deriveMergeGate(MODE.PARALLEL, plan, defectIndex + 1));
    assert.deepEqual(lanes.map((lane) => lane.status), [PHASE_STATUS.GATED, PHASE_STATUS.FAULT, PHASE_STATUS.GATED]);

    const afterRepair = derivePhaseStates(MODE.PARALLEL, plan, defectIndex + 4);
    assert.equal(afterRepair.find((phase) => phase.id === "wiki").status, PHASE_STATUS.PENDING);
  });

  test("history labels lanes and the merge gate", () => {
    const plan = buildPlan(MODE.PARALLEL, true);
    const texts = deriveHistory(plan, plan.length).map((item) => item.text);
    assert.ok(texts.includes("QA 1차 — A·C 통과 · B 결함 발견"));
    assert.ok(texts.includes("개발 — B 수정"));
    assert.ok(texts.includes("QA 2차 — B 통과"));
    assert.ok(texts.includes("병합 게이트 — A·B·C 병합"));
  });
});

describe("reinitialisation", () => {
  test("mode and failure toggles reset the run", () => {
    let state = ticks(run(createInitialState({ mode: MODE.SEQUENTIAL, failOn: true }), ACTION.PLAY), 4);
    const parallel = workflowReducer(state, { type: ACTION.SET_MODE, mode: MODE.PARALLEL });
    assert.equal(parallel.mode, MODE.PARALLEL);
    assert.equal(parallel.cursor, 0);
    assert.equal(parallel.status, RUN_STATUS.IDLE);
    assert.equal(parallel.plan[0].id, "parallel-1");

    assert.equal(workflowReducer(state, { type: ACTION.SET_MODE, mode: MODE.SEQUENTIAL }), state, "same mode is a no-op");
    assert.equal(workflowReducer(state, { type: ACTION.SET_MODE, mode: "unknown" }), state);

    const noFail = workflowReducer(state, { type: ACTION.SET_FAIL, failOn: false });
    assert.equal(noFail.cursor, 0);
    assert.equal(noFail.status, RUN_STATUS.IDLE);
    assert.equal(noFail.plan.length, 7);
  });
});

describe("target preset", () => {
  test("opens paused at the first QA defect with four phases complete", () => {
    const state = createInitialState(TARGET_PRESET);
    assert.equal(state.cursor, 5);
    assert.equal(state.plan.length, 10);
    assert.equal(state.status, RUN_STATUS.PAUSED);
    const phases = derivePhaseStates(state.mode, state.plan, state.cursor);
    assert.equal(phases.filter((phase) => phase.status === PHASE_STATUS.DONE).length, 4);
    assert.equal(phases.find((phase) => phase.id === "qa").status, PHASE_STATUS.FAULT);
    assert.equal(phases.find((phase) => phase.id === "wiki").status, PHASE_STATUS.PENDING);
    assert.equal(phases.find((phase) => phase.id === "integrate").status, PHASE_STATUS.PENDING);
    assert.deepEqual(describeRun(state), { tone: "fault", text: "일시정지 · QA 1차 결함" });
    assert.deepEqual(
      deriveHistory(state.plan, state.cursor).map((item) => item.text),
      ["기획 — 완료", "검수 — 승인", "개발 — 완료", "검수 — 승인", "QA 1차 — 결함 발견"],
    );
    const lines = describePhase(phases.find((phase) => phase.id === "qa"), { mode: state.mode, gate: getIntegrationGate(state.mode, state.plan, state.cursor) });
    assert.deepEqual(lines, [
      "실행 중인 화면·API·CLI를 독립적으로 검증",
      "1차 결과: 결함 발견",
      "개발로 되돌려 수정 후 검수·QA 재수행",
    ]);
  });
});

describe("announcements", () => {
  test("autoplay announces only notable steps, manual steps always", () => {
    const start = run(createInitialState({ mode: MODE.SEQUENTIAL, failOn: true }), ACTION.PLAY);
    const first = workflowReducer(start, { type: ACTION.TICK });
    assert.equal(announcementFor(start, first), "", "routine autoplay step is silent");

    const beforeDefect = ticks(start, 4);
    const defect = workflowReducer(beforeDefect, { type: ACTION.TICK });
    assert.match(announcementFor(beforeDefect, defect), /결함 발견/);

    const idle = createInitialState({ mode: MODE.SEQUENTIAL, failOn: true });
    const stepped = workflowReducer(idle, { type: ACTION.NEXT });
    assert.match(announcementFor(idle, stepped), /^1단계, 기획 — 완료/);

    const hidden = workflowReducer(start, { type: ACTION.PAUSE, reason: "hidden" });
    assert.match(announcementFor(start, hidden), /가려져/);
  });
});
