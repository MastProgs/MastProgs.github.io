import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { describe, test } from "node:test";
import { RUN_STATUS } from "../src/workflow/constants.js";
import {
  DETAIL_STEPS,
  DETAIL_TOTAL,
  DISPATCH_STEP,
  MERGE_STEP,
  canMergeDetail,
  deriveConversation,
  deriveIntegration,
  deriveLane,
  deriveLanes,
  deriveMergeGate,
  eventsUpTo,
  getScenario,
  isDispatched,
  stepAnnouncement,
} from "../src/workflow-detail/model.js";
import { MERGE_ORDER } from "../src/content/workflowDetail.js";
import { MODES } from "../src/workflow/constants.js";
import { DETAIL_STEP_MS, FRAME_TIER, SPEEDS, deriveFrameTargets, followScrollDelta, frameDelay, frameTitle } from "../src/workflow-detail/frames.js";
import { DETAIL_ACTION, createDetailState, detailReducer, scenarioOf } from "../src/workflow-detail/reducer.js";
import { deriveRecordChanges, deriveRecords } from "../src/workflow-detail/records.js";

const read = (relative) => readFileSync(new URL(`../${relative}`, import.meta.url), "utf8");
// 이벤트가 적용되는 cursor(그 단계 바로 다음).
const afterIn = (scenario, predicate) => scenario.steps.findIndex((step) => step.events.some(predicate)) + 1;
const after = (predicate) => afterIn(getScenario(), predicate);
const fileIn = (scenario, cursor, path) => deriveRecords(cursor, scenario).files.find((file) => file.path === path);
const fileAt = (cursor, path) => fileIn(getScenario(), cursor, path);
const run = (state, ...actions) => actions.reduce((acc, action) => detailReducer(acc, typeof action === "string" ? { type: action } : action), state);
const laneOrder = (scenario, laneId) =>
  scenario.eventsUpTo(scenario.total).filter((event) => event.lane === laneId && event.stage).map((event) => `${event.stage}:${event.attempt}${event.verdict ? `:${event.verdict}` : ""}`);

const PAR = getScenario({ route: "parallel", seed: true });
const PAR_NO_SEED = getScenario({ route: "parallel", seed: false });
const SEQ = getScenario({ route: "sequential", planReject: true, qaFail: true, seed: true });
const SEQ_PLAIN = getScenario({ route: "sequential", planReject: false, qaFail: false, seed: false });
const DIRECT = getScenario({ route: "direct" });

describe("scenario engine", () => {
  test("default exports are the parallel Seed-on scenario with fixed tick counts", () => {
    assert.equal(getScenario(), PAR);
    assert.equal(DETAIL_STEPS, PAR.steps);
    // 병렬은 WORK SPEC 다음 Task Planning 3프레임(제안·검토·동결)이 더해져 30 → 33. 순차·직접 처리는 그대로.
    assert.equal(DETAIL_TOTAL, 33);
    assert.equal(PAR_NO_SEED.total, 33, "parallel Seed option is visibility only");
    assert.equal(SEQ.total, 20);
    assert.equal(SEQ_PLAIN.total, 14);
    assert.equal(getScenario({ route: "sequential", planReject: false, qaFail: true, seed: true }).total, 18);
    assert.equal(DISPATCH_STEP, 8);
    assert.equal(MERGE_STEP, 24);
    assert.deepEqual(
      PAR.steps.map((step) => step.phase),
      [...Array(4).fill("intake"), "spec", "task", "task", "task", "intake", "seed", ...Array(13).fill("lanes"), ...Array(8).fill("integration"), "closing", "closing"],
    );
    for (const scenario of [PAR, PAR_NO_SEED, SEQ, SEQ_PLAIN]) {
      const ids = scenario.steps.flatMap((step) => step.events.map((event) => event.id));
      assert.equal(new Set(ids).size, ids.length);
      const seqs = scenario.steps.flatMap((step) => step.events.map((event) => event.seq));
      assert.deepEqual(seqs, seqs.map((_, index) => index + 1));
      assert.equal(scenario.steps[0].events[0].actor, "human", "the human talks to Master AI first");
    }
  });

  test("parallel ignores failure options: both parallel surfaces get the same fixed engine", () => {
    assert.equal(getScenario({ route: "parallel", planReject: false, qaFail: false }), PAR);
    assert.equal(scenarioOf(createDetailState({ route: "parallel" })), PAR);
    assert.equal(scenarioOf(createDetailState()), PAR);
  });

  test("human only decides scope and permission; Master writes WORK SPEC before dispatch and before any planning", () => {
    for (const scenario of [PAR, SEQ, SEQ_PLAIN]) {
      const human = scenario.deriveConversation(scenario.total).filter((message) => message.actor === "human");
      assert.deepEqual(human.map((message) => message.decision ?? null), [null, "scope", "permission"]);
      assert.ok(scenario.eventsUpTo(scenario.total).filter((event) => event.lane).every((event) => event.actor !== "human"));
      const firstPlan = scenario.steps.findIndex((step) => step.events.some((event) => event.stage === "plan"));
      assert.ok(scenario.specStep < scenario.dispatchStep && scenario.dispatchStep < firstPlan);
      assert.equal(scenario.deriveSpec(scenario.specStep).status, "idle");
      const written = scenario.deriveSpec(scenario.specStep + 1);
      assert.equal(written.status, "written");
      assert.ok(written.scope.length > 0 && written.criteria.length > 0);
      // 병렬 요청 명세는 레인을 정하지 않는다(작업축·소유 경로는 Task Planning). 순차는 하나의 작업축과 그 이유를 적는다.
      if (scenario.parallel) {
        assert.deepEqual([written.lanes, written.splitBy], [[], "task-planning"]);
      } else {
        assert.deepEqual(written.lanes.map((lane) => lane.owns), scenario.lanes.map((lane) => lane.owns));
        assert.match(written.axisNote, /작업축 1개/);
      }
      assert.equal(scenario.deriveSpec(scenario.dispatchStep + 1).status, "frozen");
      assert.ok(fileIn(scenario, scenario.specStep + 1, "00-request/work-spec.md"));
    }
  });

  test("lanes stay queued and visible until Master dispatches", () => {
    for (let cursor = 0; cursor <= DISPATCH_STEP; cursor += 1) {
      assert.equal(isDispatched(cursor), false);
      assert.deepEqual(deriveLanes(cursor).map((lane) => lane.status), ["queued", "queued", "queued"]);
    }
    assert.equal(isDispatched(DISPATCH_STEP + 1), true);
    assert.ok(deriveLanes(PAR.seedStep + 1).every((lane) => lane.status === "running" && lane.current));
  });
});

describe("parallel Task Planning (global task split before dispatch)", () => {
  const { split, review, freeze } = PAR.taskSteps;

  test("order: WORK SPEC → proposal → review → frozen contract → dispatch → Seed → lane planning", () => {
    const firstPlan = PAR.steps.findIndex((step) => step.events.some((event) => event.stage === "plan"));
    const order = [PAR.specStep, split, review, freeze, PAR.dispatchStep, PAR.seedStep, firstPlan];
    assert.deepEqual(order, [...order].sort((a, b) => a - b));
    assert.equal(new Set(order).size, order.length);
    assert.deepEqual(
      [split, review, freeze].map((index) => PAR.steps[index].events.map((event) => [event.type, event.stage, event.actor])),
      [[["task", "task-split", "task-author"]], [["task", "task-review", "task-reviewer"]], [["task", "task-freeze", "master"]]],
    );
    assert.equal(PAR.steps[review].events[0].verdict, "approved");
    // 전체 Task Planning 은 레인 이벤트가 아니다(레인 기획과 섞이지 않음).
    assert.ok([split, review, freeze].every((index) => PAR.steps[index].events.every((event) => event.lane === null)));
    for (let cursor = 0; cursor <= freeze + 1; cursor += 1) assert.equal(PAR.isDispatched(cursor), false, `cursor ${cursor}`);
  });

  test("states: proposed cards first, review checks only after approval, merge order only after freeze", () => {
    assert.deepEqual(PAR.deriveTaskPlan(split).tasks, []);
    assert.equal(PAR.deriveTaskPlan(split).status, "idle");
    const proposed = PAR.deriveTaskPlan(split + 1);
    assert.equal(proposed.status, "proposed");
    assert.deepEqual(proposed.tasks.map((task) => [task.key, task.owns]), PAR.lanes.map((lane) => [lane.key, lane.owns]));
    assert.ok(proposed.tasks.every((task) => task.interface && task.acceptance && task.dependsOnUnfinished.length === 0));
    assert.deepEqual([proposed.checks, proposed.mergeOrder, proposed.approvedRound], [[], null, null]);
    const approved = PAR.deriveTaskPlan(review + 1);
    assert.equal(approved.status, "approved");
    assert.ok(approved.checks.some((check) => /독립성/.test(check)) && approved.checks.some((check) => /통합 단계 소유/.test(check)));
    assert.equal(approved.mergeOrder, null, "not frozen yet");
    const frozen = PAR.deriveTaskPlan(freeze + 1);
    assert.deepEqual([frozen.status, frozen.approvedRound, frozen.mergeOrder], ["frozen", 1, [...MERGE_ORDER]]);
  });

  test("records: only the approved contract exists after review; rewinding removes future approval and contract files", () => {
    const has = (cursor, path) => Boolean(fileAt(cursor, path));
    assert.ok(has(split + 1, "00-request/task-planning/proposal-001.json"));
    assert.ok(!has(split + 1, "00-request/task-planning/round-001.json"));
    assert.ok(!has(split + 1, "00-request/task-contract.json"));
    assert.equal(JSON.parse(fileAt(review + 1, "00-request/task-planning/round-001.json").content).verdict, "APPROVED");
    assert.ok(!has(review + 1, "00-request/task-contract.json"));
    const contract = JSON.parse(fileAt(freeze + 1, "00-request/task-contract.json").content);
    assert.deepEqual([contract.frozen, contract.approvedRound, contract.mergeOrder], [true, 1, [...MERGE_ORDER]]);
    assert.ok(contract.tasks.every((task) => task.ownedPaths.length === 1 && task.dependsOnUnfinished.length === 0));
    assert.ok(!has(freeze + 1, "03-lanes/dashboard-ui/00-request/lane-context.md"), "no lane context before dispatch");
    assert.match(fileAt(PAR.dispatchStep + 1, "03-lanes/request-api/00-request/lane-context.md").content, /task-contract\.json[\s\S]*인터페이스[\s\S]*수용 기준/);
    // 끝까지 갔다가 제안 직후로 되감으면 승인·동결 기록과 레인 기록이 모두 사라진다.
    const state = run(createDetailState(), { type: DETAIL_ACTION.SEEK, cursor: PAR.total }, { type: DETAIL_ACTION.SEEK, cursor: split + 1 });
    const paths = deriveRecords(state.cursor, PAR).files.map((file) => file.path);
    assert.ok(paths.includes("00-request/task-planning/proposal-001.json"));
    assert.ok(!paths.some((path) => /round-001|task-contract|03-lanes\//.test(path)), JSON.stringify(paths));
    assert.equal(PAR.deriveTaskPlan(state.cursor).status, "proposed");
  });

  test("frames: each Task Planning frame targets its own step; title names it; panel exposes the same ids", () => {
    for (const [index, id] of [[split, "task:split"], [review, "task:review"], [freeze, "task:freeze"]]) {
      assert.deepEqual(deriveFrameTargets(PAR, index + 1), { frame: index + 1, ids: [id], primary: id });
      assert.equal(frameTitle(PAR, index + 1), PAR.steps[index].events[0].text);
      assert.equal(PAR.describeStep(index + 1), "Task Planning");
    }
    assert.match(stepAnnouncement(review + 1), /Task Planning Reviewer/);
    const panel = read("src/components/workflow-detail/TaskPlanPanel.jsx");
    assert.match(panel, /const id = `task:\$\{step\.id\}`/);
    assert.match(panel, /data-frame-id=\{id\}/);
    const board = read("src/components/workflow-detail/LaneBoard.jsx");
    const at = (token) => board.indexOf(token);
    assert.ok(at("<SpecPanel") < at("<TaskPlanPanel") && at("<TaskPlanPanel") < at('className="wfd-fan"'), "Task Planning sits between WORK SPEC and dispatch fan-out");
  });

  test("sequential and direct have no engine Task Planning; sequential explains its single dependent axis", () => {
    for (const scenario of [SEQ, SEQ_PLAIN, DIRECT]) {
      assert.equal(scenario.taskSteps, null);
      assert.equal(scenario.deriveTaskPlan(scenario.total), null);
      assert.ok(!scenario.eventsUpTo(scenario.total).some((event) => event.type === "task"));
      assert.ok(!deriveRecords(scenario.total, scenario).files.some((file) => /task-planning|task-contract/.test(file.path)));
    }
    assert.match(fileIn(SEQ, SEQ.specStep + 1, "00-request/work-spec.md").content, /## 작업축\n- 작업축 1개/);
  });
});

describe("parallel heterogeneous example", () => {
  test("A READY first, C second, B last; READY lanes wait and never re-run", () => {
    const readyAt = Object.fromEntries(deriveLanes(DETAIL_TOTAL).map((lane) => [lane.key, lane.readyAt]));
    assert.ok(readyAt.A < readyAt.C && readyAt.C < readyAt.B, JSON.stringify(readyAt));
    for (const lane of PAR.lanes) {
      const events = PAR.eventsUpTo(PAR.total).filter((event) => event.lane === lane.id && event.stage);
      assert.ok(events.every((event) => event.step <= readyAt[lane.key]), `${lane.key} has no events after READY`);
    }
    for (let cursor = readyAt.A + 1; cursor <= readyAt.B; cursor += 1) assert.equal(deriveLane("dashboard-ui", cursor).status, "ready");
    assert.equal(deriveMergeGate(readyAt.B).status, "locked");
    assert.deepEqual(deriveMergeGate(readyAt.B).readyLanes, ["A", "C"]);
    assert.deepEqual(deriveMergeGate(readyAt.B).waitingFor, ["B"]);
  });

  test("A passes everything first time; C is rejected twice in planning and once in development", () => {
    assert.deepEqual(laneOrder(PAR, "dashboard-ui"), ["plan:1", "plan-review:1:approved", "dev:1", "dev-review:1:approved", "qa:1:passed"]);
    assert.deepEqual(laneOrder(PAR, "status-history"), [
      "plan:1",
      "plan-review:1:rejected",
      "plan:2",
      "plan-review:2:rejected",
      "plan:3",
      "plan-review:3:approved",
      "dev:1",
      "dev-review:1:rejected",
      "dev:2",
      "dev-review:2:approved",
      "qa:1:passed",
    ]);
    const rejectAt = after((event) => event.lane === "status-history" && event.verdict === "rejected");
    const rejected = deriveLane("status-history", rejectAt);
    assert.deepEqual([rejected.connector.from, rejected.connector.to], ["plan-review", "plan"]);
    assert.equal(rejected.connector.fresh, true);
    assert.equal(deriveLane("status-history", rejectAt + 1).connector.fresh, false);
    const end = deriveLane("status-history", DETAIL_TOTAL);
    assert.equal(end.returns.length, 3);
    assert.deepEqual(end.returns.map((item) => [item.from, item.attempt, Boolean(item.supersededBy), Boolean(item.resolvedBy), item.resolvedAttempt]), [
      ["plan-review", 1, true, true, 3],
      ["plan-review", 2, false, true, 3],
      ["dev-review", 1, false, true, 2],
    ]);
    assert.ok(end.returns.every((item) => item.reason));
    const endB = deriveLane("request-api", DETAIL_TOTAL);
    assert.deepEqual(endB.returns.map((item) => [item.from, item.attempt, Boolean(item.resolvedBy), item.resolvedAttempt]), [
      ["qa", 1, true, 3],
      ["qa", 2, true, 3],
    ]);
    assert.match(read("src/components/workflow-detail/LaneColumn.jsx"), /resolvedAttempt\}회차/);
    assert.doesNotMatch(read("src/components/workflow-detail/LaneColumn.jsx"), /다음 회차에서 해결/);
    assert.deepEqual([end.counts.planReview, end.counts.devReview, end.counts.qa], [3, 2, 1]);
  });

  test("B repeats the same real defect: one ledger issue updated, resolved only by independent QA", () => {
    assert.deepEqual(laneOrder(PAR, "request-api").filter((item) => item.startsWith("qa")), ["qa:1:failed", "qa:2:failed", "qa:3:passed"]);
    const secondFail = after((event) => event.lane === "request-api" && event.stage === "qa" && event.attempt === 2);
    const issues = PAR.deriveIssues("request-api", secondFail);
    assert.equal(issues.length, 1, "same QF id does not duplicate");
    assert.deepEqual([issues[0].id, issues[0].status, issues[0].occurrences], ["QF-001", "open", 2]);
    const ledger = JSON.parse(fileAt(secondFail, "03-lanes/request-api/03-qa/issue-ledger.json").content);
    assert.equal(ledger.issues.length, 1);
    // 수정·재검수(작성자·검토자)는 원장을 닫지 않는다.
    const reviewAfter = after((event) => event.lane === "request-api" && event.stage === "dev-review" && event.attempt === 3);
    assert.equal(PAR.deriveIssues("request-api", reviewAfter)[0].status, "open");
    const end = PAR.deriveIssues("request-api", DETAIL_TOTAL);
    assert.deepEqual([end.length, end[0].status, end[0].resolvedBy], [1, "resolved", "qa:3"]);
    assert.match(fileAt(DETAIL_TOTAL, "03-lanes/request-api/03-qa/issue-ledger.md").content, /재현 2회/);
    const failed = deriveLane("request-api", secondFail);
    assert.deepEqual([failed.connector.from, failed.connector.to, failed.connector.issueId], ["qa", "dev", "QF-001"]);
  });

  test("lanes sit at different stages at the same time", () => {
    const tickCursor = PAR.seedStep + 1 + 2; // 레인 틱 2 이후
    const stages = deriveLanes(tickCursor).map((lane) => lane.current?.stage ?? lane.status);
    assert.equal(new Set(stages).size, 3, JSON.stringify(stages));
  });

  test("integration order after all READY, never before; final local merge without push", () => {
    for (let cursor = 0; cursor <= DETAIL_TOTAL; cursor += 1) {
      const allReady = deriveLanes(cursor).every((lane) => lane.status === "ready" || lane.status === "merged");
      assert.equal(canMergeDetail(cursor), allReady, `cursor ${cursor}`);
      if (!allReady) assert.ok(deriveIntegration(cursor).every((item) => item.status === "pending"), `cursor ${cursor}`);
    }
    const integration = PAR.steps.filter((step) => step.phase === "integration").map((step) => step.events[0].stage);
    assert.deepEqual(integration, ["integration-plan", "merge", "integration-dev", "integration-review", "build", "integration-qa", "wiki", "final-merge"]);
    assert.equal(deriveMergeGate(MERGE_STEP).status, "open");
    assert.equal(deriveMergeGate(MERGE_STEP + 1).status, "merged");
    // READY 도착은 A·C·B 지만 병합은 작업 계약에 동결된 A·B·C 순서를 따른다.
    const merge = JSON.parse(fileAt(DETAIL_TOTAL, "04-integration/merge/merge.json").content);
    assert.deepEqual(merge.readyOrder, ["dashboard-ui", "status-history", "request-api"]);
    assert.deepEqual(merge.order, [...MERGE_ORDER]);
    assert.deepEqual(MERGE_ORDER, ["dashboard-ui", "request-api", "status-history"]);
    // 병합 순서는 Task Planning 에서 승인·동결한 Task Contract 에 있다(요청 명세 WORK SPEC 이 아님).
    assert.deepEqual(PAR.deriveTaskPlan(PAR.total).mergeOrder, MERGE_ORDER);
    assert.match(fileAt(DETAIL_TOTAL, "00-request/task-contract.md").content, /병합 순서\(동결\)\n- A dashboard-ui\n- B request-api\n- C status-history/);
    assert.equal(merge.source, "00-request/task-contract.json");
    assert.match(fileAt(DETAIL_TOTAL, "04-integration/planning/plan.md").content, /작업 계약 고정\): A → B → C/);
    assert.doesNotMatch(read("src/content/workflowDetail.js") + read("src/workflow-detail/records.js"), /READY 순|A·C·B 레인/);
    assert.ok(deriveLanes(MERGE_STEP).every((lane) => lane.status === "ready"), "every lane READY before assembly");
    assert.deepEqual(JSON.parse(fileAt(DETAIL_TOTAL, "04-integration/merge/final.json").content), { target: "starting-branch", local: true, pushed: false });
    assert.deepEqual(deriveLanes(DETAIL_TOTAL).map((lane) => lane.status), ["merged", "merged", "merged"]);
  });
});

describe("sequential planning-review failure option", () => {
  test("ON: plan → rejection → visible return to planning → re-review approved → only then development", () => {
    const order = laneOrder(SEQ, "history-tab");
    assert.deepEqual(order.slice(0, 5), ["plan:1", "plan-review:1:rejected", "plan:2", "plan-review:2:approved", "dev:1"]);
    const rejectAt = afterIn(SEQ, (event) => event.verdict === "rejected");
    const lane = SEQ.deriveLane("history-tab", rejectAt);
    assert.equal(lane.status, "returned");
    assert.deepEqual([lane.connector.from, lane.connector.to, lane.connector.fresh], ["plan-review", "plan", true]);
    assert.equal(lane.current.stage, "plan");
    assert.equal(lane.current.attempt, 2);
    assert.equal(lane.stages.find((stage) => stage.id === "dev").status, "pending");
    const approveAt = afterIn(SEQ, (event) => event.stage === "plan-review" && event.verdict === "approved");
    const devAt = afterIn(SEQ, (event) => event.stage === "dev");
    assert.ok(devAt > approveAt, "no development before approval");
    const approved = SEQ.deriveLane("history-tab", approveAt);
    assert.equal(approved.connector, null);
    assert.equal(approved.counts.planReview, 2);
    assert.ok(approved.returns[0].resolvedBy, "rejection history retained");
    assert.match(fileIn(SEQ, SEQ.total, "01-planning/round-001.json").content, /"REJECTED"/);
    assert.equal(fileIn(SEQ, rejectAt, "01-planning/plan.md"), undefined);
  });

  test("OFF: no planning rejection; QA option stays independent", () => {
    const noPlan = getScenario({ route: "sequential", planReject: false, qaFail: true, seed: false });
    assert.ok(!noPlan.eventsUpTo(noPlan.total).some((event) => event.stage === "plan-review" && event.verdict === "rejected"));
    assert.ok(noPlan.eventsUpTo(noPlan.total).some((event) => event.stage === "qa" && event.verdict === "failed"));
    const noQa = getScenario({ route: "sequential", planReject: true, qaFail: false, seed: false });
    assert.ok(noQa.eventsUpTo(noQa.total).some((event) => event.verdict === "rejected"));
    assert.ok(!noQa.eventsUpTo(noQa.total).some((event) => event.verdict === "failed"));
    assert.ok(!SEQ_PLAIN.eventsUpTo(SEQ_PLAIN.total).some((event) => event.verdict === "rejected" || event.verdict === "failed"));
  });

  test("sequential QA failure returns to development and the ledger resolves after re-QA", () => {
    const failAt = afterIn(SEQ, (event) => event.verdict === "failed");
    assert.deepEqual([SEQ.deriveLane("history-tab", failAt).connector.from, SEQ.deriveLane("history-tab", failAt).connector.to], ["qa", "dev"]);
    assert.equal(SEQ.deriveIssues("history-tab", SEQ.total)[0].status, "resolved");
    assert.equal(SEQ.deriveMergeGate(SEQ.total), null, "sequential has no merge gate");
    assert.equal(SEQ.deriveLane("history-tab", SEQ.total).status, "done");
    assert.deepEqual(SEQ.deriveIntegration(SEQ.total).map((item) => item.id), ["wiki"]);
  });

  test("toggling options resets cursor, selection and records", () => {
    let state = createDetailState({ route: "sequential" });
    assert.deepEqual(state.options, { route: "sequential", seed: true, planReject: true, qaFail: true });
    state = run(state, DETAIL_ACTION.PLAY, DETAIL_ACTION.TICK, DETAIL_ACTION.TICK, { type: DETAIL_ACTION.SELECT_FILE, path: "current.md" });
    state = run(state, { type: DETAIL_ACTION.SET_OPTION, key: "planReject", value: false });
    assert.deepEqual([state.cursor, state.status, state.selectedPath, state.lastAction], [0, RUN_STATUS.IDLE, null, "options"]);
    assert.equal(state.options.planReject, false);
    assert.equal(scenarioOf(state).total, 18);
    assert.equal(run(state, { type: DETAIL_ACTION.SET_OPTION, key: "planReject", value: false }), state, "same value is a no-op");
    let par = createDetailState({ route: "parallel" });
    assert.equal(run(par, { type: DETAIL_ACTION.SET_OPTION, key: "qaFail", value: true }), par, "failure options do not apply to parallel");
    par = run(par, { type: DETAIL_ACTION.SET_OPTION, key: "seed", value: false });
    assert.equal(scenarioOf(par), PAR_NO_SEED);
  });
});

describe("Seed lineage", () => {
  test("sequential OFF: no Seed events, sessions have no Seed parent", () => {
    const events = SEQ_PLAIN.eventsUpTo(SEQ_PLAIN.total);
    assert.equal(SEQ_PLAIN.seeded, false);
    assert.ok(!events.some((event) => event.type === "seed"));
    assert.ok(events.filter((event) => event.stage).every((event) => event.parentSession === null));
    assert.equal(SEQ_PLAIN.seedStep, -1);
    assert.ok(!deriveRecords(SEQ_PLAIN.total, SEQ_PLAIN).files.some((file) => file.path.includes("sessions/")));
  });

  test("parallel Seed option only hides panels: same steps, parents and records", () => {
    assert.deepEqual([PAR.seeded, PAR_NO_SEED.seeded], [true, true]);
    assert.deepEqual([PAR.options.seed, PAR_NO_SEED.options.seed], [true, false]);
    assert.deepEqual(PAR_NO_SEED.steps, PAR.steps);
    assert.equal(PAR_NO_SEED.seedStep, PAR.seedStep);
    for (let cursor = 0; cursor <= PAR.total; cursor += 1) {
      assert.deepEqual(deriveRecords(cursor, PAR_NO_SEED), deriveRecords(cursor, PAR), `cursor ${cursor}`);
      assert.deepEqual(PAR_NO_SEED.deriveLanes(cursor), PAR.deriveLanes(cursor), `cursor ${cursor}`);
    }
  });

  test("ON: per-lane Author/Reviewer Seeds before planning, sibling children, rework resumes the same child", () => {
    for (const scenario of [PAR, SEQ]) {
      const seedEvents = scenario.steps[scenario.seedStep].events;
      assert.ok(scenario.seedStep > scenario.dispatchStep);
      for (const lane of scenario.lanes) {
        assert.deepEqual(seedEvents.filter((event) => event.lane === lane.id).map((event) => event.session), ["author-seed", "reviewer-seed"]);
      }
      const firstPlan = scenario.steps.findIndex((step) => step.events.some((event) => event.stage === "plan"));
      assert.ok(scenario.seedStep < firstPlan, "Seeds exist before lane planning");
      const events = scenario.eventsUpTo(scenario.total);
      assert.equal(events.filter((event) => event.type === "seed").length, scenario.lanes.length * 2, "Seed is never rerun");
      const parent = Object.fromEntries(events.filter((event) => event.stage).map((event) => [event.session, event.parentSession]));
      assert.equal(parent["plan-author"], "author-seed");
      assert.equal(parent["dev-author"], "author-seed");
      assert.equal(parent["plan-reviewer"], "reviewer-seed");
      assert.equal(parent["dev-reviewer"], "reviewer-seed");
      assert.equal(parent.qa, null, "QA does not inherit implementer or Seed sessions");
      const wiki = events.find((event) => event.stage === "wiki");
      assert.deepEqual([wiki.session, wiki.parentSession], ["wiki", null]);
      const laneEvents = events.filter((item) => item.type === "author" || item.type === "verdict");
      for (const event of laneEvents) assert.equal(event.resumed, event.attempt > 1);
      // 독립 QA 는 부모 없이 레인 전용 QA 세션 하나를 재시도마다 resume 한다.
      for (const event of events.filter((item) => item.stage === "qa")) assert.deepEqual([event.session, event.parentSession, event.resumed], ["qa", null, event.attempt > 1]);
    }
    const lineage = deriveLane("status-history", DETAIL_TOTAL).lineage;
    assert.equal(lineage.seedReady, true);
    assert.deepEqual(Object.fromEntries(lineage.children.map((child) => [child.id, child.runs])), { "plan-author": 3, "dev-author": 2, "plan-reviewer": 3, "dev-reviewer": 2 });
    assert.equal(deriveLane("status-history", PAR.seedStep).status, "seeding");
    const file = JSON.parse(fileAt(DETAIL_TOTAL, "03-lanes/status-history/sessions/lineage.json").content);
    assert.deepEqual(file.seeds.map((seed) => seed.id), ["author-seed", "reviewer-seed"]);
    assert.ok(file.seeds.every((seed) => seed.readOnly && seed.outputs.length === 0));
    assert.deepEqual(file.independent, ["qa", "wiki"]);
    assert.equal(file.children.find((child) => child.id === "plan-author").resumes, 2);
    const qa2 = JSON.parse(fileAt(DETAIL_TOTAL, "03-lanes/request-api/03-qa/attempt-002/result.json").content);
    assert.deepEqual([qa2.session, qa2.resumed], ["independent", true]);
    assert.doesNotMatch(read("src/content/workflowDetail.js") + read("src/components/workflow-detail/SeedLineage.jsx"), /각각 새 세션|QA · Wiki는 새 세션/);
  });

  test("no invented speed, cache or cost metrics", () => {
    const text = read("src/content/workflowDetail.js") + read("src/components/workflow-detail/SeedLineage.jsx");
    assert.doesNotMatch(text, /캐시 히트|\d+\s*%|절감|토큰/);
  });
});

describe("local records", () => {
  test("records are derived from the same events at every cursor in every scenario", () => {
    for (const scenario of [PAR, SEQ, SEQ_PLAIN, DIRECT]) {
      assert.deepEqual(deriveRecords(0, scenario).files, []);
      for (let cursor = 1; cursor <= scenario.total; cursor += 1) {
        const events = scenario.eventsUpTo(cursor);
        const lines = fileIn(scenario, cursor, "events.jsonl").content.trim().split("\n").map((line) => JSON.parse(line));
        assert.deepEqual(lines.map((line) => line.seq), events.map((event) => event.seq));
        const timeline = fileIn(scenario, cursor, "timeline.md").content.split("\n").filter((line) => line.startsWith("- "));
        assert.ok(timeline[0].includes(events.at(-1).time), "timeline.md is latest first");
        assert.equal(timeline.length, events.length);
        assert.equal(JSON.parse(fileIn(scenario, cursor, "state.json").content).checkpoint, events.at(-1).seq);
        const paths = deriveRecords(cursor, scenario).files.map((file) => file.path);
        assert.equal(new Set(paths).size, paths.length);
        assert.ok(paths.includes(deriveRecords(cursor, scenario).latestPath));
      }
    }
  });

  test("state.json lane stage is null before dispatch and ready only for finished lanes", () => {
    const lanesAt = (cursor) => Object.values(JSON.parse(fileAt(cursor, "state.json").content).lanes);
    for (const lane of lanesAt(1)) assert.deepEqual([lane.status, lane.stage], ["queued", null]);
    for (const lane of lanesAt(DETAIL_TOTAL)) assert.deepEqual([lane.status, lane.stage], ["merged", "ready"]);
    for (let cursor = 1; cursor <= DETAIL_TOTAL; cursor += 1) {
      for (const lane of lanesAt(cursor)) {
        if (lane.status === "queued") assert.equal(lane.stage, null);
        if (lane.stage === "ready") assert.ok(["ready", "merged"].includes(lane.status));
      }
    }
  });

  test("raw invocations keep prompt, command, stdout and stderr for every return and its retry", () => {
    const paths = deriveRecords(DETAIL_TOTAL).files.map((file) => file.path).filter((path) => path.startsWith("raw/invocations/"));
    const invocations = new Set(paths.map((path) => path.split("/")[2]));
    // C: 기획 반려 2 + 재검수 2(반려·승인), 개발 반려 1 + 재검수 1, B: QA 실패 2 + 재시도 2(실패·통과) → 중복 제외 8.
    assert.equal(invocations.size, 8);
    for (const id of invocations) {
      for (const name of ["prompt.md", "command.json", "stdout.txt", "stderr.txt"]) assert.ok(paths.includes(`raw/invocations/${id}/${name}`));
    }
  });

  test("changes mark new and updated files relative to the previous cursor", () => {
    assert.equal(deriveRecordChanges(1).get("00-request/request.md"), "new");
    const rejectC = after((event) => event.lane === "status-history" && event.verdict === "rejected");
    assert.equal(deriveRecordChanges(rejectC).get("03-lanes/status-history/01-planning/round-001.json"), "new");
    assert.equal(deriveRecordChanges(rejectC).get("current.md"), "updated");
  });
});

describe("detail playback", () => {
  test("play, pause, next, reset are deterministic and reset clears records and selection", () => {
    let state = createDetailState();
    state = run(state, DETAIL_ACTION.PLAY, DETAIL_ACTION.TICK, DETAIL_ACTION.TICK, DETAIL_ACTION.PAUSE);
    assert.equal(state.cursor, 2);
    assert.equal(run(state, DETAIL_ACTION.TICK).cursor, 2, "ticks while paused are ignored");
    state = run(state, DETAIL_ACTION.NEXT, { type: DETAIL_ACTION.SELECT_FILE, path: "current.md" });
    assert.deepEqual([state.status, state.cursor, state.selectedPath], [RUN_STATUS.PAUSED, 3, "current.md"]);
    state = run(state, DETAIL_ACTION.RESET);
    assert.deepEqual([state.cursor, state.status, state.selectedPath], [0, RUN_STATUS.IDLE, null]);
    assert.equal(deriveRecords(state.cursor).files.length, 0);
    assert.equal(deriveConversation(state.cursor).length, 0);
  });

  test("ends in done without rerunning; play from done restarts the same scenario", () => {
    for (const route of ["parallel", "sequential"]) {
      const start = createDetailState({ route });
      const total = scenarioOf(start).total;
      let state = run(start, DETAIL_ACTION.PLAY, ...Array(total + 5).fill(DETAIL_ACTION.TICK));
      assert.deepEqual([state.status, state.cursor], [RUN_STATUS.DONE, total]);
      assert.equal(run(state, DETAIL_ACTION.TICK), state);
      assert.equal(run(state, DETAIL_ACTION.NEXT), state);
      state = run(state, DETAIL_ACTION.PLAY);
      assert.deepEqual([state.cursor, state.status, state.options.route], [0, RUN_STATUS.RUNNING, route]);
      assert.equal(run(state, { type: DETAIL_ACTION.PAUSE, reason: "hidden" }).lastAction, "hidden");
    }
  });

  test("autoplay announces only notable steps", () => {
    const rejectC = after((event) => event.lane === "status-history" && event.verdict === "rejected");
    assert.match(stepAnnouncement(rejectC), /반려/);
    assert.equal(stepAnnouncement(2), "");
    assert.match(stepAnnouncement(2, { manual: true }), /Master AI/);
    assert.match(stepAnnouncement(PAR.specStep + 1), /WORK SPEC/);
  });
});

describe("routing and composition", () => {
  test("App serves /workflow without a router and the summary opens it in a new tab", () => {
    assert.match(read("src/App.jsx"), /window\.location\.pathname/);
    assert.match(read("src/App.jsx"), /<WorkflowDetailPage \/>/);
    assert.match(read("src/components/workflow/WorkflowSummary.jsx"), /href=\{DETAIL_ROUTE\} target="_blank" rel="noopener noreferrer"/);
    const pkg = JSON.parse(read("package.json"));
    assert.ok(!Object.keys(pkg.dependencies).some((name) => /router/i.test(name)));
  });

  test("the page has exactly one route selector and one player for all three routes; no top tabs or WorkflowStage", () => {
    const page = read("src/components/workflow-detail/WorkflowDetailPage.jsx");
    const code = page.replace(/^\s*\/\/.*$/gm, "");
    assert.equal(code.match(/<WorkflowPlayer\b/g)?.length, 1);
    assert.match(code, /<WorkflowPlayer route="parallel" selectable \/>/);
    assert.doesNotMatch(code, /WorkflowStage|wfd-routes|aria-pressed|ModeSwitch/);
    const player = read("src/components/workflow-detail/WorkflowPlayer.jsx").replace(/^\s*\/\/.*$/gm, "");
    assert.equal(player.match(/<ModeSwitch\b/g)?.length, 1, "one selector");
    assert.equal(player.match(/<DetailTransport\b/g)?.length, 1, "one transport shared by every route");
    assert.match(player, /selectable && \(/);
    assert.match(player, /<LaneBoard /);
    assert.match(player, /<DirectPanel /);
    assert.doesNotMatch(player, /PhaseTimeline|buildPlan|WorkflowStage/);
    // ModeSwitch 순서가 요청 순서(직접 처리 / 순차 / 독립 병렬)이고 기본 선택은 독립 병렬이다.
    assert.deepEqual(MODES.map((mode) => mode.label), ["직접 처리", "순차", "독립 병렬"]);
    assert.equal(createDetailState({ route: "parallel" }).options.route, "parallel");
    // 옛 WorkflowStage 는 호환용으로 남아 있고(마운트 안 함) 경로 선택 없이 플레이어를 쓴다.
    const stage = read("src/components/workflow/WorkflowStage.jsx");
    assert.match(stage, /<WorkflowPlayer key=\{mode\} route=\{mode\} \/>/);
  });

  test("transport: prev / play / next / reset, integer frame slider, speed and follow; rounded at rest and sticky", () => {
    const transport = read("src/components/workflow-detail/DetailTransport.jsx").replace(/^\s*\/\/.*$/gm, "");
    for (const label of ["이전 프레임", "다음 프레임", "처음으로"]) assert.match(transport, new RegExp(`aria-label="${label}"`));
    assert.match(transport, /type="range"[\s\S]*min=\{0\}[\s\S]*max=\{total\}[\s\S]*step=\{1\}/);
    assert.match(transport, /aria-valuetext=/);
    assert.match(transport, /aria-disabled=\{atFirst\}/);
    assert.match(transport, /aria-disabled=\{done\}/);
    assert.doesNotMatch(transport, /\sdisabled[=\s>]/, "boundary buttons keep focus (aria-disabled only)");
    assert.doesNotMatch(transport + read("src/components/workflow-detail/WorkflowPlayer.jsx"), /addEventListener\("keydown"/, "no global shortcuts");
    const css = read("src/styles/workflow-detail.css");
    const bar = css.match(/\.wfd-run__bar \{[^}]*\}/)[0];
    assert.doesNotMatch(bar, /border-radius|background/, "sticky wrapper adds no square-bottom bar");
    assert.match(css.match(/\.wfd-transport \{[^}]*\}/)[0], /border-radius: 28px/);
    assert.match(css, /\.wfd-transport__btn \{[^}]*width: 44px;[^}]*height: 44px;/);
    assert.match(css, /\.wfd-transport__scrub \{[^}]*height: 44px;/);
  });

  test("detail board keeps lanes expanded, not in an accordion; return marker animation is once and has a reduced-motion static state", () => {
    const board = read("src/components/workflow-detail/LaneBoard.jsx");
    const lane = read("src/components/workflow-detail/LaneColumn.jsx");
    assert.doesNotMatch(board + lane, /<details/);
    assert.equal(deriveLanes(0).length, 3);
    const css = read("src/styles/workflow-detail.css");
    assert.match(css, /\.wfd-return-track\.is-fresh \.wfd-return-track__marker \{\s*animation: wfd-return-run [^;]*both;/);
    assert.doesNotMatch(css, /wfd-return-run[^;]*infinite/);
    const ruleAt = css.indexOf(".wfd-return-track.is-fresh");
    const mediaAt = css.lastIndexOf("prefers-reduced-motion: no-preference", ruleAt);
    assert.ok(mediaAt !== -1 && !css.slice(mediaAt, ruleAt).includes("\n}"), "return animation only when motion is allowed");
  });
});

describe("direct route in the shared player", () => {
  test("three frames: request → Master direct processing → response; no plan, Seed, review or QA", () => {
    assert.equal(DIRECT.total, 3);
    assert.deepEqual(DIRECT.steps.map((step) => step.phase), ["intake", "direct", "closing"]);
    const events = DIRECT.eventsUpTo(DIRECT.total);
    assert.deepEqual(events.map((event) => [event.type, event.actor]), [
      ["message", "human"],
      ["direct", "master"],
      ["message", "master"],
    ]);
    assert.ok(!events.some((event) => ["spec", "seed", "integration"].includes(event.type) || event.lane || event.verdict));
    assert.deepEqual([DIRECT.specStep, DIRECT.seedStep, DIRECT.lanes.length], [-1, -1, 0]);
    assert.equal(DIRECT.deriveSpec(DIRECT.total), null);
    assert.equal(DIRECT.deriveMergeGate(DIRECT.total), null);
    assert.deepEqual(DIRECT.deriveIntegration(DIRECT.total), []);
    assert.deepEqual(DIRECT.deriveDirect(2).map((node) => [node.id, node.status, node.isActive]), [
      ["request", "done", false],
      ["direct", "done", false],
      ["response", "pending", true],
    ]);
    assert.deepEqual(DIRECT.steps.map((_, index) => DIRECT.describeStep(index + 1)), ["요청 접수", "Master AI 직접 처리", "완료"]);
    const paths = deriveRecords(DIRECT.total, DIRECT).files.map((file) => file.path);
    assert.ok(paths.includes("01-direct/change-summary.md"));
    assert.ok(!paths.some((path) => /work-spec|planning|03-qa|sessions|raw\//.test(path)), JSON.stringify(paths));
  });

  test("no option applies to direct: normalized off and toggles are no-ops", () => {
    assert.deepEqual(DIRECT.options, { route: "direct", seed: false, planReject: false, qaFail: false });
    assert.equal(getScenario({ route: "direct", seed: true, planReject: true, qaFail: true }), DIRECT);
    const state = createDetailState({ route: "direct" });
    for (const key of ["seed", "planReject", "qaFail"]) assert.equal(run(state, { type: DETAIL_ACTION.SET_OPTION, key, value: true }), state, key);
    // 화면에는 쓸 수 없는 스위치를 그리지 않고 이유 한 줄만 보인다.
    assert.match(read("src/components/workflow-detail/ScenarioOptions.jsx"), /if \(route === "direct"\) \{\s*return \(\s*<div className="wfd-options">\s*<p className="wfd-options__hint">\{hint\}<\/p>/);
  });
});

describe("frame controls (all three routes)", () => {
  for (const route of ["direct", "sequential", "parallel"]) {
    test(`${route}: prev/seek pause, boundaries are exact, replay runs once`, () => {
      let state = createDetailState({ route });
      const { total } = scenarioOf(state);
      assert.equal(run(state, DETAIL_ACTION.PREV), state, "previous is unavailable at frame 0");
      state = run(state, DETAIL_ACTION.PLAY, DETAIL_ACTION.TICK, DETAIL_ACTION.TICK);
      assert.deepEqual([state.cursor, state.status], [2, RUN_STATUS.RUNNING]);
      state = run(state, DETAIL_ACTION.PREV);
      assert.deepEqual([state.cursor, state.status, state.lastAction], [1, RUN_STATUS.PAUSED, "prev"]);
      state = run(state, DETAIL_ACTION.PLAY, { type: DETAIL_ACTION.SEEK, cursor: 2 });
      assert.deepEqual([state.cursor, state.status, state.lastAction], [2, RUN_STATUS.PAUSED, "seek"], "seek pauses playback");
      state = run(state, { type: DETAIL_ACTION.SEEK, cursor: total + 9 });
      assert.deepEqual([state.cursor, state.status], [total, RUN_STATUS.DONE], "seeking to the exact end is done");
      assert.equal(run(state, DETAIL_ACTION.NEXT), state, "next is unavailable at the end");
      state = run(state, DETAIL_ACTION.PREV);
      assert.deepEqual([state.cursor, state.status], [total - 1, RUN_STATUS.PAUSED], "completed runs can step back");
      state = run(state, DETAIL_ACTION.NEXT);
      assert.deepEqual([state.cursor, state.status], [total, RUN_STATUS.DONE]);
      state = run(state, { type: DETAIL_ACTION.SEEK, cursor: 1.7 });
      assert.deepEqual([state.cursor, state.status], [1, RUN_STATUS.PAUSED], "integer frames, earlier seek is paused");
      assert.equal(run(state, { type: DETAIL_ACTION.SEEK, cursor: "x" }), state);
      state = run(state, { type: DETAIL_ACTION.SEEK, cursor: 0 });
      assert.deepEqual([state.cursor, state.status], [0, RUN_STATUS.IDLE]);
      state = run(state, { type: DETAIL_ACTION.SEEK, cursor: total }, DETAIL_ACTION.PLAY);
      assert.deepEqual([state.cursor, state.status], [0, RUN_STATUS.RUNNING], "replay restarts from frame 0");
      state = run(state, ...Array(total + 4).fill(DETAIL_ACTION.TICK));
      assert.deepEqual([state.cursor, state.status], [total, RUN_STATUS.DONE], "no auto loop");
    });
  }

  test("route and option changes reset progress and stop playback; speed is kept", () => {
    let state = run(createDetailState(), { type: DETAIL_ACTION.SET_SPEED, speed: 2 }, DETAIL_ACTION.PLAY, DETAIL_ACTION.TICK, DETAIL_ACTION.TICK);
    state = run(state, { type: DETAIL_ACTION.SET_ROUTE, route: "sequential" });
    assert.deepEqual([state.cursor, state.status, state.lastAction, state.speed], [0, RUN_STATUS.IDLE, "route", 2]);
    assert.deepEqual(state.options, { route: "sequential", seed: true, planReject: true, qaFail: true }, "sequential failure options default ON");
    assert.equal(run(state, { type: DETAIL_ACTION.SET_ROUTE, route: "sequential" }), state);
    state = run(state, DETAIL_ACTION.PLAY, DETAIL_ACTION.TICK, { type: DETAIL_ACTION.SET_OPTION, key: "qaFail", value: false });
    assert.deepEqual([state.cursor, state.status, state.speed], [0, RUN_STATUS.IDLE, 2]);
    state = run(state, DETAIL_ACTION.NEXT, { type: DETAIL_ACTION.SET_ROUTE, route: "direct" });
    assert.deepEqual([scenarioOf(state).total, state.cursor, state.status], [3, 0, RUN_STATUS.IDLE]);
    state = run(state, { type: DETAIL_ACTION.SET_ROUTE, route: "parallel" });
    assert.equal(scenarioOf(state), PAR);
    assert.equal(run(state, { type: DETAIL_ACTION.SET_SPEED, speed: 3 }), state, "unknown speeds are ignored");
    assert.equal(run(state, DETAIL_ACTION.RESET).speed, 2);
  });

  test("timers use the selected speed and are cleaned up", () => {
    assert.deepEqual(SPEEDS, [0.5, 1, 2]);
    assert.deepEqual(SPEEDS.map(frameDelay), [DETAIL_STEP_MS * 2, DETAIL_STEP_MS, DETAIL_STEP_MS / 2]);
    const hook = read("src/hooks/useDetailPlayer.js");
    assert.match(hook, /window\.setTimeout\([^;]*frameDelay\(state\.speed\)\)/);
    assert.match(hook, /return \(\) => window\.clearTimeout\(timer\)/);
    assert.match(hook, /\[state\.status, state\.cursor, state\.speed, route, dispatch\]/);
    assert.match(hook, /visibilitychange/);
    assert.doesNotMatch(hook, /setInterval/);
  });

  test("rewinding recomputes everything from the cursor: resolved QA reopens, future files vanish, forward again does not duplicate", () => {
    const failAt = afterIn(SEQ, (event) => event.verdict === "failed");
    let state = run(createDetailState({ route: "sequential" }), { type: DETAIL_ACTION.SEEK, cursor: SEQ.total });
    assert.equal(SEQ.deriveIssues("history-tab", state.cursor)[0].status, "resolved");
    assert.ok(fileIn(SEQ, state.cursor, "03-qa/attempt-002/result.json"));
    state = run(state, { type: DETAIL_ACTION.SEEK, cursor: failAt });
    assert.deepEqual(SEQ.deriveIssues("history-tab", state.cursor).map((issue) => [issue.id, issue.status, issue.occurrences]), [["QF-001", "open", 1]]);
    assert.equal(fileIn(SEQ, state.cursor, "03-qa/attempt-002/result.json"), undefined);
    assert.equal(fileIn(SEQ, state.cursor, "05-wiki/wiki-update.md"), undefined);
    assert.equal(JSON.parse(fileIn(SEQ, state.cursor, "03-qa/issue-ledger.json").content).issues[0].status, "open");
    assert.equal(fileIn(SEQ, state.cursor, "events.jsonl").content.trim().split("\n").length, SEQ.eventsUpTo(failAt).length);
    assert.equal(SEQ.deriveLane("history-tab", state.cursor).connector.from, "qa");
    state = run(state, ...Array(SEQ.total).fill(DETAIL_ACTION.NEXT));
    assert.deepEqual(deriveRecords(state.cursor, SEQ), deriveRecords(SEQ.total, SEQ));
    assert.equal(SEQ.deriveIssues("history-tab", state.cursor).length, 1);

    // 병렬 B: 3회차 QA 직전으로 되감으면 원장은 열림·재현 2회, 3회차 결과·병합 기록·Seed 이후 재개 횟수도 그 시점 값이다.
    const qa3 = afterIn(PAR, (event) => event.lane === "request-api" && event.stage === "qa" && event.attempt === 3);
    let par = run(createDetailState(), { type: DETAIL_ACTION.SEEK, cursor: PAR.total }, { type: DETAIL_ACTION.SEEK, cursor: qa3 - 1 });
    assert.deepEqual(PAR.deriveIssues("request-api", par.cursor).map((issue) => [issue.status, issue.occurrences]), [["open", 2]]);
    assert.equal(fileIn(PAR, par.cursor, "03-lanes/request-api/03-qa/attempt-003/result.json"), undefined);
    assert.equal(fileIn(PAR, par.cursor, "04-integration/merge/merge.json"), undefined);
    assert.equal(PAR.deriveLane("request-api", par.cursor).status, "returned", "still waiting for the third QA, not READY");
    assert.equal(PAR.deriveMergeGate(par.cursor).status, "locked");
    assert.deepEqual(PAR.deriveLanes(par.cursor), PAR.deriveLanes(qa3 - 1));
    par = run(par, DETAIL_ACTION.NEXT);
    assert.deepEqual(PAR.deriveIssues("request-api", par.cursor).map((issue) => [issue.status, issue.occurrences]), [["resolved", 2]]);
  });
});

describe("frame targets and follow", () => {
  test("frame 0 has no target; every frame points at what just changed, deterministically", () => {
    assert.deepEqual(deriveFrameTargets(PAR, 0), { frame: 0, ids: [], primary: null });
    for (const scenario of [PAR, SEQ, DIRECT]) {
      for (let cursor = 1; cursor <= scenario.total; cursor += 1) {
        const targets = deriveFrameTargets(scenario, cursor);
        assert.ok(targets.ids.length > 0, `${scenario.options.route} ${cursor}`);
        assert.equal(targets.primary, targets.ids[0]);
        assert.deepEqual(deriveFrameTargets(scenario, cursor), targets);
        for (const event of scenario.steps[cursor - 1].events.filter((item) => item.lane && item.stage)) {
          assert.ok(targets.ids.includes(`stage:${event.lane}:${event.stage}`));
        }
      }
    }
    assert.deepEqual(DIRECT.steps.map((_, index) => deriveFrameTargets(DIRECT, index + 1).primary), ["direct:0", "direct:1", "direct:2"]);
  });

  test("parallel frames highlight every changed lane; rejection/QA fault outranks Master, lane progress and integration", () => {
    assert.deepEqual(Object.values(FRAME_TIER), [0, 1, 2, 3, 4]);
    const tick0 = deriveFrameTargets(PAR, PAR.seedStep + 2);
    assert.deepEqual(tick0.ids, ["stage:dashboard-ui:plan", "stage:status-history:plan"]);
    const tick1Cursor = PAR.seedStep + 3;
    const tick1 = deriveFrameTargets(PAR, tick1Cursor);
    assert.deepEqual([...tick1.ids].sort(), ["stage:dashboard-ui:plan-review", "stage:request-api:plan", "stage:status-history:plan-review"]);
    assert.equal(tick1.primary, "stage:status-history:plan-review", "rejection is the anchor");
    // 레인 C 의 다음 작업(기획 2회차)은 is-active 이지만, 프레임 강조는 방금 일어난 기획 검수 반려를 가리킨다.
    assert.equal(PAR.deriveLane("status-history", tick1Cursor).current.stage, "plan");
    assert.ok(!tick1.ids.includes("stage:status-history:plan"));
    const qaFail = deriveFrameTargets(PAR, afterIn(PAR, (event) => event.lane === "request-api" && event.verdict === "failed"));
    assert.equal(qaFail.primary, "stage:request-api:qa");
    assert.ok(qaFail.ids.length > 1, "other lanes changing in the same frame are highlighted too");
    assert.deepEqual(deriveFrameTargets(PAR, PAR.specStep + 1).ids, ["spec"]);
    assert.equal(deriveFrameTargets(PAR, PAR.dispatchStep + 1).primary, "master");
    assert.deepEqual(deriveFrameTargets(PAR, PAR.seedStep + 1).ids, PAR.lanes.map((lane) => `lane:${lane.id}`));
    assert.deepEqual(deriveFrameTargets(PAR, PAR.mergeStep + 1).ids, ["integration:merge", "gate"]);
    const lane = read("src/components/workflow-detail/LaneColumn.jsx");
    assert.match(lane, /data-frame-id=\{`stage:\$\{lane\.id\}:\$\{stage\.id\}`\}/);
    assert.match(read("src/components/workflow-detail/LaneBoard.jsx"), /data-frame-id=\{`integration:\$\{item\.id\}`\}/);
    assert.match(read("src/components/workflow-detail/ConversationPanel.jsx"), /data-frame-id=\{`msg:\$\{message\.id\}`\}/);
  });

  test("frame title names the primary event, not a generic phase", () => {
    assert.equal(frameTitle(PAR, 0), "시작 전");
    const rejectCursor = PAR.seedStep + 3;
    const rejection = PAR.steps[rejectCursor - 1].events.find((event) => event.lane === "status-history" && event.verdict === "rejected");
    assert.equal(frameTitle(PAR, rejectCursor), PAR.describeEvent(rejection));
    for (const scenario of [PAR, SEQ]) {
      const lanes = [];
      for (let cursor = 1; cursor <= scenario.total; cursor += 1) if (scenario.steps[cursor - 1].phase === "lanes") lanes.push(frameTitle(scenario, cursor));
      assert.ok(!lanes.some((title) => title === "레인 병렬 진행" || title === "단계 진행"), scenario.options.route);
      assert.ok(new Set(lanes).size > lanes.length / 2, "lane frames get distinct titles");
    }
    const direct = DIRECT.steps.map((_, index) => frameTitle(DIRECT, index + 1));
    assert.equal(direct.length, 3);
    for (const title of direct) assert.ok(title.trim().length > 0);
    assert.match(read("src/components/workflow-detail/DetailTransport.jsx"), /const title = frameTitle\(scenario, cursor\)/);
  });

  test("follow only scrolls when hidden under the sticky player or below the fold, without stealing focus", () => {
    assert.equal(followScrollDelta({ top: 300, bottom: 400 }, 150, 800), null);
    assert.equal(followScrollDelta({ top: 100, bottom: 200 }, 150, 800), -66);
    assert.equal(followScrollDelta({ top: 900, bottom: 1000 }, 150, 800), 216);
    assert.equal(followScrollDelta({ top: 900, bottom: 2000 }, 150, 800), 734, "tall nodes align their top under the player");
    const hook = read("src/hooks/useFrameFollow.js");
    assert.match(hook, /FRAME_ACTIONS = new Set\(\["tick", "next", "prev", "seek"\]\)/, "no scroll on first render, reset, route or option change");
    assert.match(hook, /import \{ prefersReducedMotion \} from "\.\.\/lib\/motion\.js"/);
    assert.match(hook, /reduced \? "auto" : "smooth"/);
    // 끔→켬은 휠·터치 멈춤을 풀고 lastAction 과 무관하게(일시정지 중에도) 현재 주 강조로 옮긴다. 처음 렌더는 재활성이 아니다.
    assert.match(hook, /const wasEnabled = useRef\(enabled\)/);
    assert.match(hook, /const reenabled = enabled && !wasEnabled\.current;\s*wasEnabled\.current = enabled;\s*if \(reenabled\) suspended\.current = false;/);
    assert.match(hook, /if \(!reenabled && !FRAME_ACTIONS\.has\(lastAction\)\) return;/);
    assert.match(hook, /if \(!reenabled && lastAction === "tick" && suspended\.current\) return;/);
    assert.match(hook, /"wheel"/);
    assert.match(hook, /"touchmove"/);
    assert.doesNotMatch(hook, /\.focus\(|scrollIntoView|querySelectorAll\([^)]*:contains/);
    assert.match(read("src/components/workflow-detail/WorkflowPlayer.jsx"), /const \[follow, setFollow\] = useState\(true\)/, "follow defaults ON");
  });
});
