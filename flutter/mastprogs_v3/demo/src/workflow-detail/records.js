// 로컬 실행 기록 예시. cursor 까지 적용된 이벤트에서 파일 목록과 내용을 매번 새로 만든다(저장·디스크 쓰기 없음).
// AI-NOTE: 구성은 AgentWorkflow 문서 기준이다. 실행 폴더 ai-log/YYYYMMDD/001_HHMMSS_title 아래에
// index.md(요청·탐색), current.md(최신 상태·결정·다음), ledger.md(시간순 교환·게이트), timeline.md·decisions.md(최신순),
// events.jsonl(시간순), state.json(coordinator 직렬 checkpoint), 00-request/{work-spec.md, task-planning/(병렬: 제안·검토 라운드),
// task-contract.json·md(병렬: 승인 후 동결)}, 03-lanes/<lane>/{00-request,
// sessions,01-planning,02-development,03-qa,04-completed}, 04-integration/{planning,merge,implementation,build,qa}, 05-wiki, raw/invocations/<id>.
// 순차는 레인 폴더 없이 실행 폴더 바로 아래 01-planning 등을 쓴다. 직접 처리는 00-request/request.md 와 01-direct 만 만든다. 모든 함수는 시나리오를 받고 기본값은 병렬 기본 시나리오다.
// 기획 심사는 라운드 JSON 을 모두 남기고 승인본만 Markdown 을 만든다. QA 는 attempt-NNN/result.json·result.md,
// issue-ledger.json/md 는 model.deriveIssues 에서 파생되는 읽기 전용 원장이며 같은 지적은 한 항목으로 갱신되고 독립 QA 통과로만 해결된다.
import { DIRECT_RECORD_ROOT, DIRECT_WORK, MERGE_ORDER, RECORD_ROOT, SEQUENTIAL_RECORD_ROOT } from "../content/workflowDetail.js";
import { VERDICT_LABEL, getScenario, stageLabel } from "./model.js";

const DEFAULT = getScenario();
const pad3 = (value) => String(value).padStart(3, "0");
const json = (value) => `${JSON.stringify(value, null, 2)}\n`;

function helpers(scenario) {
  const laneDir = (laneId) => (scenario.parallel ? `03-lanes/${laneId}/` : "");
  const laneMeta = (laneId) => scenario.lanes.find((lane) => lane.id === laneId);
  return { laneDir, laneMeta, laneKey: scenario.laneKey };
}

// 원문 호출 기록을 남기는 이벤트: 반려·실패와 그 해결 시도(같은 단계의 바로 다음 회차).
function isRawEvent(event, events) {
  if (event.verdict === "rejected" || event.verdict === "failed") return true;
  if (!event.verdict) return false;
  const previous = events.filter((item) => item.lane === event.lane && item.stage === event.stage && item.seq < event.seq).at(-1);
  return Boolean(previous && (previous.verdict === "rejected" || previous.verdict === "failed"));
}

const invocationId = (event) => `${pad3(event.seq)}-${event.lane}-${event.stage}-${event.attempt}`;

function rawFiles(event, h) {
  const id = invocationId(event);
  const base = `raw/invocations/${id}`;
  const role = event.stage === "qa" ? "독립 QA" : `${stageLabel(event.stage)} 검토`;
  return [
    {
      path: `${base}/prompt.md`,
      content: `# ${role} 요청 (${h.laneKey(event.lane)} · ${event.attempt}회차)\n\n- 작업 명세: 00-request/work-spec.md\n- 검토 대상: ${event.stage === "plan-review" ? "계획 라운드 JSON" : event.stage === "dev-review" ? "실제 diff" : "실행 중인 결과물"}\n- 응답 형식: verdict(APPROVED|REJECTED|PASSED|FAILED), reasons[]\n`,
    },
    {
      path: `${base}/command.json`,
      content: json({ invocation: id, lane: event.lane, stage: event.stage, attempt: event.attempt, session: event.session, resumed: Boolean(event.resumed), stdin: "prompt.md", readOnly: true }),
    },
    { path: `${base}/stdout.txt`, content: `${JSON.stringify({ verdict: event.verdict.toUpperCase(), reasons: event.reason ? [event.reason] : [], summary: event.text })}\n` },
    { path: `${base}/stderr.txt`, content: "" },
  ];
}

// 이벤트 하나가 직접 만들거나 고치는 파일.
function filesForEvent(event, context, scenario, h) {
  const files = [];
  if (event.type === "message" && event.seq === 1) {
    files.push({ path: "00-request/request.md", content: `# 요청 원문\n\n${event.text}\n` });
  }
  // 범위 질문은 사람에게 묻는 Master 메시지다(Task Planning 라운드가 아니다).
  if (event.type === "message" && event.decision === "scope-question") {
    files.push({ path: "00-request/scope-question.md", content: `# 범위 확인 (Master AI → 사람)\n\n- ${event.text}\n` });
  }
  if (event.type === "spec") {
    const spec = scenario.deriveSpec(event.step + 1);
    const owns = spec.lanes.length
      ? spec.lanes.map((lane) => `- ${lane.key} ${lane.title}: ${lane.owns}`).join("\n")
      : "- 작업축별 소유 경로는 Task Planning(00-request/task-contract.json)에서 정함";
    files.push({
      path: "00-request/work-spec.md",
      content: `# WORK SPEC\n\n## 범위\n${spec.scope.map((line) => `- ${line}`).join("\n")}\n\n## 완료 기준\n${spec.criteria.map((line) => `- ${line}`).join("\n")}\n\n## 소유 경로\n${owns}\n${
        spec.axisNote ? `\n## 작업축\n- ${spec.axisNote}\n` : ""
      }`,
    });
  }
  // AI-NOTE: 병렬 전체 Task Planning 기록. 제안(proposal) → 검토 라운드(승인) → 동결 계약 순으로만 생긴다.
  // 모두 cursor 까지의 이벤트에서 다시 만들어지므로 되감으면 아직 일어나지 않은 승인·동결 파일은 없다.
  if (event.type === "task") {
    const plan = scenario.deriveTaskPlan(event.step + 1);
    const taskRows = plan.tasks.map((task) => ({
      lane: task.id,
      key: task.key,
      title: task.title,
      ownedPaths: [task.owns],
      interfaces: [task.interface],
      acceptance: [task.acceptance],
      dependsOnUnfinished: task.dependsOnUnfinished,
    }));
    if (event.stage === "task-split") {
      files.push({ path: "00-request/task-planning/proposal-001.json", content: json({ round: 1, author: "task-planning-author", source: "00-request/work-spec.md", axes: taskRows }) });
    }
    if (event.stage === "task-review") {
      files.push({
        path: "00-request/task-planning/round-001.json",
        content: json({ round: 1, reviewer: "task-planning-reviewer", proposal: "proposal-001.json", verdict: "APPROVED", checks: plan.checks, sharedOwnership: plan.sharedOwner }),
      });
    }
    if (event.stage === "task-freeze") {
      files.push({
        path: "00-request/task-contract.json",
        content: json({ frozen: true, approvedRound: plan.approvedRound, tasks: taskRows, sharedOwnership: plan.sharedOwner, mergeOrder: plan.mergeOrder }),
      });
      files.push({
        path: "00-request/task-contract.md",
        content: `# Task Contract (동결)\n\n${taskRows.map((task) => `- ${task.key} ${task.title}: ${task.ownedPaths.join(", ")} · 미완료 의존 없음`).join("\n")}\n- 공유 소유: ${plan.sharedOwner}\n\n## 병합 순서(동결)\n${plan.mergeOrder
          .map((id) => `- ${h.laneKey(id)} ${id}`)
          .join("\n")}\n`,
      });
    }
  }
  if (event.type === "message" && event.decision === "dispatch") {
    for (const lane of scenario.lanes) {
      const task = scenario.parallel ? scenario.deriveTaskPlan(event.step + 1).tasks.find((item) => item.id === lane.id) : null;
      files.push({
        path: `${h.laneDir(lane.id)}00-request/lane-context.md`,
        content: `# ${scenario.parallel ? `레인 ${lane.key}` : "작업"} · ${lane.title}\n\n- 소유 경로: ${lane.owns}\n${
          task ? `- 출처: 00-request/task-contract.json (승인 라운드 1)\n- 인터페이스: ${task.interface}\n- 수용 기준: ${task.acceptance}\n- 자기 worktree에서 진행, 다른 레인의 미완료 결과를 기다리지 않음\n` : ""
        }- 완료 조건: 개발 검수 승인 + 독립 QA 통과\n`,
      });
    }
  }
  // 직접 처리는 계획·검수·QA 기록 없이 변경 요약 하나만 남긴다.
  if (event.type === "direct") {
    files.push({ path: "01-direct/change-summary.md", content: `# 직접 처리 (Master AI)\n\n- ${event.text}\n- 변경 범위: ${DIRECT_WORK.owns}\n` });
  }
  if (event.type === "seed") {
    context.seeds[event.lane] = [...(context.seeds[event.lane] ?? []), event.session];
  }

  if (event.lane) {
    const dir = h.laneDir(event.lane);
    if (event.type === "seed") {
      files.push({ path: `${dir}sessions/lineage.json`, content: json(lineageFor(event.lane, context)) });
    }
    if (event.stage) {
      const runs = (context.runs[event.lane] ??= {});
      runs[event.session] = (runs[event.session] ?? 0) + 1;
      if (SEEDED_SESSIONS.has(event.session) && scenario.seeded) {
        files.push({ path: `${dir}sessions/lineage.json`, content: json(lineageFor(event.lane, context)) });
      }
    }
    if (event.stage === "plan-review") {
      files.push({ path: `${dir}01-planning/round-${pad3(event.attempt)}.json`, content: json({ round: event.attempt, verdict: event.verdict.toUpperCase(), reasons: event.reason ? [event.reason] : [] }) });
      if (event.verdict === "approved") {
        files.push({
          path: `${dir}01-planning/plan.md`,
          content: `# 승인된 계획 (${h.laneKey(event.lane)})\n\n- 승인 라운드: ${event.attempt}\n- 반려 라운드: ${event.attempt - 1}\n- 다음 단계: 개발\n`,
        });
      }
    }
    if (event.stage === "dev") {
      files.push({
        path: `${dir}02-development/change-summary.md`,
        content: `# 변경 요약 (${h.laneKey(event.lane)} · ${event.attempt}회차)\n\n- ${event.text}\n- 변경 범위: ${h.laneMeta(event.lane).owns}\n`,
      });
    }
    if (event.stage === "dev-review") {
      files.push({ path: `${dir}02-development/review-round-${pad3(event.attempt)}.json`, content: json({ round: event.attempt, verdict: event.verdict.toUpperCase(), reasons: event.reason ? [event.reason] : [] }) });
    }
    if (event.stage === "qa") {
      const attemptDir = `${dir}03-qa/attempt-${pad3(event.attempt)}`;
      files.push({
        path: `${attemptDir}/result.json`,
        content: json({ attempt: event.attempt, verdict: event.verdict.toUpperCase(), issues: event.issueId ? [event.issueId] : [], resolves: event.resolves ? [event.resolves] : [], session: "independent", resumed: Boolean(event.resumed) }),
      });
      files.push({
        path: `${attemptDir}/result.md`,
        content: `# QA ${event.attempt}회차 — ${VERDICT_LABEL[event.verdict]}\n\n${event.reason ? `- 결함: ${event.issueId} ${event.reason}\n` : `- ${event.text}\n`}`,
      });
      const issues = scenario.deriveIssues(event.lane, event.step + 1);
      files.push({ path: `${dir}03-qa/issue-ledger.json`, content: json({ derivedFrom: "attempt-*/result.json", issues }) });
      files.push({
        path: `${dir}03-qa/issue-ledger.md`,
        content: `# 지적 원장 (읽기 전용 파생)\n\n${
          issues.length
            ? issues.map((issue) => `- ${issue.id} · ${issue.status === "resolved" ? `해결(${issue.resolvedBy})` : "열림"} · 재현 ${issue.occurrences}회 · ${issue.text}`).join("\n")
            : "- 지적 없음"
        }\n`,
      });
    }
    if (event.ready) {
      files.push({
        path: `${dir}04-completed/manifest.json`,
        content: json({ lane: event.lane, status: "READY", planReviewRounds: context.attempts[`${event.lane}:plan-review`], devReviewRounds: context.attempts[`${event.lane}:dev-review`], qaAttempts: event.attempt }),
      });
    }
    if (event.stage && isRawEvent(event, context.events)) files.push(...rawFiles(event, h));
  }

  if (event.type === "integration") {
    // 병합 순서는 작업 계약에서 동결한 MERGE_ORDER 다. READY 도착 순서는 기록용으로만 남긴다.
    const order = [...MERGE_ORDER];
    const keys = (ids) => ids.map(h.laneKey).join(" → ");
    if (event.stage === "integration-plan") {
      files.push({ path: "04-integration/planning/plan.md", content: `# 통합 기획\n\n- 병합 순서(작업 계약 고정): ${keys(order)}\n- READY 도착 순서(참고): ${keys(context.readyOrder)}\n- 공유 경로 충돌: 없음\n` });
    }
    if (event.stage === "merge") files.push({ path: "04-integration/merge/merge.json", content: json({ order, source: "00-request/task-contract.json", readyOrder: context.readyOrder, conflicts: [] }) });
    if (event.stage === "integration-dev") files.push({ path: "04-integration/implementation/change-summary.md", content: `# 통합 구현\n\n- ${event.text}\n` });
    if (event.stage === "integration-review") files.push({ path: "04-integration/implementation/review-round-001.json", content: json({ round: 1, verdict: "APPROVED", reasons: [] }) });
    if (event.stage === "build") files.push({ path: "04-integration/build/build.json", content: json({ commands: ["npm run build", "npm test"], result: "PASSED" }) });
    if (event.stage === "integration-qa") {
      files.push({ path: "04-integration/qa/attempt-001/result.json", content: json({ attempt: 1, verdict: "PASSED", scenarios: ["목록 → 상태 변경 → 이력 확인"] }) });
      files.push({ path: "04-integration/qa/attempt-001/result.md", content: "# 통합 QA 1회차 — 통과\n\n- 목록에서 상태를 바꾸면 이력에 최신순으로 나타남\n" });
    }
    if (event.stage === "wiki") files.push({ path: "05-wiki/wiki-update.md", content: "# Wiki 갱신 (독립 Wiki Author·Reviewer)\n\n- 구조와 판단 근거 기록\n- 범위 제외 결정 기록\n" });
    if (event.stage === "final-merge") files.push({ path: "04-integration/merge/final.json", content: json({ target: "starting-branch", local: true, pushed: false }) });
  }
  return files;
}

const SEEDED_SESSIONS = new Set(["plan-author", "dev-author", "plan-reviewer", "dev-reviewer"]);

function lineageFor(laneId, context) {
  const runs = context.runs[laneId] ?? {};
  const child = (id, parent) => ({ id, parent, mode: runs[id] ? "fork" : "pending", resumes: Math.max(0, (runs[id] ?? 0) - 1) });
  return {
    seeds: (context.seeds[laneId] ?? []).map((id) => ({ id, readOnly: true, outputs: [] })),
    children: [child("plan-author", "author-seed"), child("dev-author", "author-seed"), child("plan-reviewer", "reviewer-seed"), child("dev-reviewer", "reviewer-seed")],
    independent: ["qa", "wiki"],
  };
}

const LANE_STATUS_TEXT = { queued: "배정 대기", seeding: "Seed 준비", running: "진행 중", returned: "되돌림", ready: "QA 통과 · 병합 대기", merged: "병합됨", done: "완료" };

function aggregateFiles(events, cursor, scenario) {
  const lanes = scenario.deriveLanes(cursor);
  const gate = scenario.deriveMergeGate(cursor);
  const integration = scenario.deriveIntegration(cursor);
  const last = events.at(-1);
  const decisions = events.filter((event) => event.type === "message" && ["route", "scope", "permission"].includes(event.decision));
  const nextLane = lanes.filter((lane) => lane.current).map((lane) => `${lane.key} ${lane.current.label} ${lane.current.attempt}회차`);
  const nextIntegration = integration.find((item) => item.isActive);
  let next = "다음 요청 대기";
  if (cursor < scenario.total) next = nextLane.length ? nextLane.join(", ") : nextIntegration ? nextIntegration.label : "Master AI 응답";
  const gateText = !gate ? `없음(${scenario.options.route === "direct" ? "직접 처리" : "순차"})` : gate.status === "locked" ? `잠김 (${gate.waitingFor.join("·") || "-"} 대기)` : gate.status === "open" ? "열림" : "병합 완료";

  return [
    {
      path: "index.md",
      content: `# ${scenario.lanes.length > 1 ? "사내 요청 대시보드" : scenario.lanes[0]?.title ?? "상태 이름 수정"}\n\n- 요청: 00-request/request.md\n${
        scenario.specStep === -1 ? "- 처리: 01-direct/change-summary.md (Master AI 직접 처리)\n" : "- 작업 명세: 00-request/work-spec.md\n"
      }${scenario.parallel ? "- 작업 분할: 00-request/task-planning/ → 00-request/task-contract.json\n" : ""}- 현재 상태: current.md\n- 교환 원장: ledger.md\n- 최신순 진행: timeline.md · decisions.md\n${scenario.parallel ? `- 레인: ${scenario.lanes.map((lane) => `03-lanes/${lane.id}`).join(", ")}\n` : ""}`,
    },
    {
      path: "current.md",
      content: `# 현재 상태\n\n- 최신: ${scenario.describeEvent(last)}\n- 결정: ${decisions.length ? decisions.at(-1).text : "없음"}\n- 레인: ${lanes.map((lane) => `${lane.key} ${LANE_STATUS_TEXT[lane.status]}`).join(" · ")}\n- 병합 게이트: ${gateText}\n- 다음: ${next}\n`,
    },
    { path: "ledger.md", content: `# 교환·게이트 원장 (시간순)\n\n${events.map((event) => `- ${event.time} ${scenario.describeEvent(event)}`).join("\n")}\n` },
    { path: "timeline.md", content: `# 타임라인 (최신순)\n\n${[...events].reverse().map((event) => `- ${event.time} ${scenario.describeEvent(event)}`).join("\n")}\n` },
    {
      path: "decisions.md",
      content: `# 결정 (최신순)\n\n${decisions.length ? [...decisions].reverse().map((event) => `- ${event.time} ${event.actor === "human" ? "사람" : "Master AI"}: ${event.text}`).join("\n") : "- 아직 없음"}\n`,
    },
    {
      path: "events.jsonl",
      content: `${events
        .map((event) =>
          JSON.stringify({ seq: event.seq, time: event.time, type: event.type, actor: event.actor, lane: event.lane, stage: event.stage, attempt: event.attempt, verdict: event.verdict, session: event.session }),
        )
        .join("\n")}\n`,
    },
    {
      path: "state.json",
      content: json({
        schemaVersion: 3,
        route: scenario.options.route,
        checkpoint: last.seq,
        // 배정 전 레인은 stage 가 없다(null). "ready" 는 실제 READY·병합·완료된 레인에만 쓴다.
        lanes: Object.fromEntries(
          lanes.map((lane) => [lane.id, { status: lane.status, stage: lane.current?.stage ?? (["ready", "merged", "done"].includes(lane.status) ? "ready" : null), ...lane.counts }]),
        ),
        mergeGate: gate ? gate.status : null,
      }),
    },
  ];
}

const ROOT_ORDER = ["index.md", "current.md", "ledger.md", "timeline.md", "decisions.md", "events.jsonl", "state.json"];

function sortFiles(files) {
  return [...files].sort((a, b) => {
    const ra = ROOT_ORDER.indexOf(a.path);
    const rb = ROOT_ORDER.indexOf(b.path);
    if (ra !== -1 || rb !== -1) return (ra === -1 ? 99 : ra) - (rb === -1 ? 99 : rb);
    return a.path < b.path ? -1 : a.path > b.path ? 1 : 0;
  });
}

// cursor 까지의 기록. files 는 경로 순, latestPath 는 마지막 단계가 직접 만든 마지막 파일(없으면 current.md).
export function deriveRecords(cursor, scenario = DEFAULT) {
  const at = scenario.clamp(cursor);
  const events = scenario.eventsUpTo(at);
  const root = scenario.parallel ? RECORD_ROOT : scenario.options.route === "direct" ? DIRECT_RECORD_ROOT : SEQUENTIAL_RECORD_ROOT;
  if (events.length === 0) return { root, files: [], latestPath: null };

  const h = helpers(scenario);
  const context = { attempts: {}, seeds: {}, runs: {}, events, readyOrder: [] };
  const byPath = new Map();
  let latestPath = null;
  const lastStep = events.at(-1).step;
  for (const event of events) {
    if (event.lane && event.stage) context.attempts[`${event.lane}:${event.stage}`] = event.attempt;
    if (event.ready) context.readyOrder.push(event.lane);
    for (const file of filesForEvent(event, context, scenario, h)) {
      byPath.set(file.path, file);
      if (event.step === lastStep) latestPath = file.path;
    }
  }
  for (const file of aggregateFiles(events, at, scenario)) byPath.set(file.path, file);
  return { root, files: sortFiles([...byPath.values()]), latestPath: latestPath ?? "current.md" };
}

// 직전 cursor 와 비교한 파일 변화: new | updated. 화면의 "새 파일"/"갱신" 표시에 쓴다.
export function deriveRecordChanges(cursor, scenario = DEFAULT) {
  const at = scenario.clamp(cursor);
  const changes = new Map();
  if (at === 0) return changes;
  const before = new Map(deriveRecords(at - 1, scenario).files.map((file) => [file.path, file.content]));
  for (const file of deriveRecords(at, scenario).files) {
    if (!before.has(file.path)) changes.set(file.path, "new");
    else if (before.get(file.path) !== file.content) changes.set(file.path, "updated");
  }
  return changes;
}
