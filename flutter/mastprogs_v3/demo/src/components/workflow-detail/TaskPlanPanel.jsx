import { ArrowsSplitIcon, CheckCircleIcon, CircleDashedIcon, LinkBreakIcon, LockSimpleIcon, SealCheckIcon } from "@phosphor-icons/react";
import { TASK_PLANNING } from "../../content/workflowDetail.js";

const STEP_DONE = {
  split: (status) => status !== "idle",
  review: (status) => status === "approved" || status === "frozen",
  freeze: (status) => status === "frozen",
};

const STEP_ICON = { split: ArrowsSplitIcon, review: SealCheckIcon, freeze: LockSimpleIcon };

// AI-NOTE: 병렬 전용 전체 Task Planning(WORK SPEC 다음, 지시 배정·Seed·레인 기획 전). 순차·직접 처리에는 그리지 않는다.
// 위 줄: 작업축 제안 → 독립성 검토 → Task Contract 동결 세 단계(data-frame-id task:split|review|freeze, 프레임 강조 대상).
// 아래: 요청 1건이 A 화면 / B API / C 이력 작업 카드로 갈라진다(카드는 --i 지연으로 한 번만 펼쳐짐, 동작 줄이기면 즉시).
// 각 카드는 소유 경로·인터페이스·수용 기준·"미완료 레인 의존 없음"을 보이고, 검토 승인 뒤에만 검토 항목이, 동결 뒤에만 병합 순서가 나온다.
export function TaskPlanPanel({ plan, frame }) {
  const { status } = plan;
  return (
    <section className={`wfd-task is-${status}`} aria-labelledby="wfd-task-title">
      <div className="wfd-task__head">
        <h3 id="wfd-task-title" className="wfd-task__title">{TASK_PLANNING.heading}</h3>
        <span className="wfd-task__state">{TASK_PLANNING.status[status]}</span>
      </div>
      <p className="wfd-task__lead">{TASK_PLANNING.lead}</p>

      <ol className="wfd-task__steps">
        {TASK_PLANNING.steps.map((step, index) => {
          const done = STEP_DONE[step.id](status);
          const Icon = done ? STEP_ICON[step.id] : CircleDashedIcon;
          const id = `task:${step.id}`;
          return (
            <li
              key={step.id}
              data-frame-id={id}
              className={`wfd-task__step${done ? " is-done" : ""}${frame.has(id) ? " is-frame" : ""}`}
              style={{ "--i": index }}
            >
              <Icon size={18} weight={done ? "fill" : "bold"} aria-hidden="true" />
              <span className="wfd-task__step-label">{step.label}</span>
              <span className="wfd-task__step-actor">{step.actor}</span>
            </li>
          );
        })}
      </ol>

      <div className="wfd-task__split">
        <p className="wfd-task__source">
          <ArrowsSplitIcon size={16} aria-hidden="true" />
          {TASK_PLANNING.source}
        </p>
        <ul className="wfd-task__cards" aria-label="제안된 작업축">
          {plan.tasks.map((task, index) => (
            <li key={task.id} className="wfd-task__card" style={{ "--i": index }}>
              <p className="wfd-task__card-head">
                <b className="wfd-task__key">{task.key}</b>
                <span>{task.title}</span>
              </p>
              <dl className="wfd-task__facts">
                <div>
                  <dt>소유 경로</dt>
                  <dd><code>{task.owns}</code></dd>
                </div>
                <div>
                  <dt>인터페이스</dt>
                  <dd>{task.interface}</dd>
                </div>
                <div>
                  <dt>수용 기준</dt>
                  <dd>{task.acceptance}</dd>
                </div>
              </dl>
              <p className="wfd-task__nodep">
                <LinkBreakIcon size={14} aria-hidden="true" />
                {TASK_PLANNING.noDependency}
              </p>
            </li>
          ))}
        </ul>
      </div>

      {plan.checks.length > 0 && (
        <ul className="wfd-task__checks" aria-label="Task Planning Reviewer 검토 항목">
          {plan.checks.map((check, index) => (
            <li key={check} style={{ "--i": index }}>
              <CheckCircleIcon size={15} weight="fill" aria-hidden="true" />
              {check}
            </li>
          ))}
        </ul>
      )}

      {plan.mergeOrder && (
        <p className="wfd-task__contract">
          <LockSimpleIcon size={16} weight="bold" aria-hidden="true" />
          Task Contract 동결 · 병합 순서 {plan.tasks.filter((task) => plan.mergeOrder.includes(task.id)).sort((a, b) => plan.mergeOrder.indexOf(a.id) - plan.mergeOrder.indexOf(b.id)).map((task) => task.key).join(" → ")}
        </p>
      )}
    </section>
  );
}
