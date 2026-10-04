import { ArrowsSplitIcon, CheckCircleIcon, CircleDashedIcon, CircleNotchIcon, EyeIcon, GitMergeIcon, LockIcon, LockOpenIcon, RobotIcon } from "@phosphor-icons/react";
import { DETAIL_COPY, SEED_COPY } from "../../content/workflowDetail.js";
import { LaneColumn } from "./LaneColumn.jsx";
import { SpecPanel } from "./SpecPanel.jsx";
import { TaskPlanPanel } from "./TaskPlanPanel.jsx";

const GATE_ICON = { locked: LockIcon, open: LockOpenIcon, merged: GitMergeIcon };

function gateText(gate) {
  if (gate.status === "merged") return "모든 레인 QA 통과 · 병합 완료";
  if (gate.status === "open") return "모든 레인 READY · 통합 기획 시작";
  const ready = gate.readyLanes.length ? `${gate.readyLanes.join("·")} 통과, ` : "";
  return `잠김 — ${ready}${gate.waitingFor.join("·")} QA 통과 대기`;
}

// AI-NOTE: 첫 화면에서 레인이 모두 펼쳐져 보인다(아코디언 없음). Master AI 가 WORK SPEC 을 쓰고 배정하는 순간 is-dispatched 가 붙어
// 배정선이 레인 순서대로(--lane-index 지연) 내려가며 레인이 활성화된다. 동작 줄이기에서는 즉시 바뀐다.
// 병렬(상단 탭·순차·직접 처리 탭의 병렬 라디오)과 순차(레인 1개, gate=null)가 같은 보드를 쓴다.
// frame: 방금 바뀐 노드 id 집합(frames.js). Master(master)·명세(spec)·게이트(gate)·통합 단계(integration:<id>)에
// data-frame-id 를 달고, 해당 노드에 is-frame 을 붙인다. 레인·단계 강조는 LaneColumn 이 같은 집합으로 처리한다.
const NO_FRAME = new Set();
const frameClass = (frame, id) => (frame.has(id) ? " is-frame" : "");

// taskPlan: 병렬 전체 Task Planning(제안 → 검토 → 동결). WORK SPEC 과 배정선 사이에 그린다. 순차·직접 처리는 null.
export function LaneBoard({ lanes, dispatched, gate, integration, spec, taskPlan = null, showSeed = false, frame = NO_FRAME }) {
  const GateIcon = gate ? GATE_ICON[gate.status] : CheckCircleIcon;
  const single = lanes.length === 1;
  return (
    <section className={`wfd-board${dispatched ? " is-dispatched" : ""}${single ? " is-single" : ""}`} aria-labelledby="wfd-board-title">
      <h2 id="wfd-board-title" className="sr-only">{DETAIL_COPY.boardLabel}</h2>

      <div className={`wfd-master${frameClass(frame, "master")}`} data-frame-id="master">
        <span className="wfd-master__icon" aria-hidden="true">
          <RobotIcon size={24} />
        </span>
        <div className="wfd-master__text">
          <p className="wfd-master__title">{DETAIL_COPY.dispatcherHeading}</p>
          <p className="wfd-master__line">{dispatched ? DETAIL_COPY.dispatcherDone : DETAIL_COPY.dispatcherIdle}</p>
        </div>
        <p className="wfd-master__fan">
          <ArrowsSplitIcon size={18} aria-hidden="true" />
          {lanes.map((lane) => lane.key).join(" · ")}
        </p>
      </div>

      {spec && <SpecPanel spec={spec} highlighted={frame.has("spec")} />}

      {taskPlan && <TaskPlanPanel plan={taskPlan} frame={frame} />}

      {showSeed && (
        <p className="wfd-seed-rule">
          <EyeIcon size={16} aria-hidden="true" />
          {SEED_COPY.rule}
        </p>
      )}

      <div className="wfd-fan" aria-hidden="true">
        {lanes.map((lane, index) => (
          <span key={lane.id} className="wfd-fan__drop" style={{ "--lane-index": index }} />
        ))}
      </div>

      <div className="wfd-lanes">
        {lanes.map((lane, index) => (
          <LaneColumn key={lane.id} lane={lane} index={index} showSeed={showSeed} frame={frame} />
        ))}
      </div>

      <div className="wfd-join" aria-hidden="true">
        {lanes.map((lane) => (
          <span key={lane.id} className={`wfd-join__rise${["ready", "merged", "done"].includes(lane.status) ? " is-ready" : ""}`} />
        ))}
      </div>

      <div className={`wfd-gate wfd-gate--${gate ? gate.status : "single"}${frameClass(frame, "gate")}`} data-frame-id="gate">
        {gate && (
          <p className="wfd-gate__head">
            <GateIcon size={20} weight="bold" aria-hidden="true" />
            <span className="wfd-gate__title">{DETAIL_COPY.mergeHeading}</span>
            <span className="wfd-gate__text">{gateText(gate)}</span>
          </p>
        )}
        <ol className="wfd-integration" aria-label={DETAIL_COPY.integrationHeading}>
          {integration.map((item) => {
            const Icon = item.status === "done" ? CheckCircleIcon : item.isActive ? CircleNotchIcon : CircleDashedIcon;
            return (
              <li
                key={item.id}
                data-frame-id={`integration:${item.id}`}
                className={`wfd-integration__step wfd-integration__step--${item.status}${item.isActive ? " is-active" : ""}${frameClass(frame, `integration:${item.id}`)}`}
                aria-current={item.isActive ? "step" : undefined}
              >
                <Icon size={16} weight={item.status === "done" ? "fill" : "bold"} aria-hidden="true" />
                <span className="wfd-integration__label">{item.label}</span>
                <span className="wfd-integration__text">{item.status === "done" ? item.text : item.isActive ? "진행 중" : "대기"}</span>
              </li>
            );
          })}
        </ol>
      </div>
    </section>
  );
}
