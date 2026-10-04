import { ClipboardTextIcon, LockSimpleIcon } from "@phosphor-icons/react";
import { SPEC_COPY } from "../../content/workflowDetail.js";

const STATUS_TEXT = { written: "작성됨", frozen: "동결 · 지시 배정됨" };

// AI-NOTE: Master AI 가 레인 기획보다 먼저 쓰는 WORK SPEC 카드. 작성 전에는 한 줄 안내만, 작성되면 범위·완료 기준·소유 경로가
// 나타난다(is-written 진입 전환 한 번, 동작 줄이기에서는 즉시). 지시 배정 후에는 잠금 표시가 붙는다.
// data-frame-id="spec": 명세를 쓴 프레임에서 is-frame(LaneBoard 가 highlighted 로 넘김).
// 병렬 명세는 레인을 정하지 않고 "Task Planning 에서 정함" 한 줄만 둔다(작업 분할은 TaskPlanPanel).
// 순차 명세는 하나의 의존 작업축이라 나누지 않는 이유(axisNote)를 함께 보인다.
export function SpecPanel({ spec, highlighted = false }) {
  if (spec.status === "idle") {
    return (
      <div className="wfd-spec is-idle" data-frame-id="spec">
        <p className="wfd-spec__head">
          <ClipboardTextIcon size={18} aria-hidden="true" />
          <span className="wfd-spec__title">{SPEC_COPY.heading}</span>
          <span className="wfd-spec__state">{SPEC_COPY.idle}</span>
        </p>
      </div>
    );
  }
  return (
    <div data-frame-id="spec" className={`wfd-spec is-written${spec.status === "frozen" ? " is-frozen" : ""}${highlighted ? " is-frame" : ""}`}>
      <p className="wfd-spec__head">
        {spec.status === "frozen" ? <LockSimpleIcon size={18} weight="bold" aria-hidden="true" /> : <ClipboardTextIcon size={18} aria-hidden="true" />}
        <span className="wfd-spec__title">{SPEC_COPY.heading}</span>
        <span className="wfd-spec__state">{STATUS_TEXT[spec.status]}</span>
      </p>
      <dl className="wfd-spec__grid">
        <div>
          <dt>{SPEC_COPY.scope}</dt>
          <dd>
            <ul>
              {spec.scope.map((line) => (
                <li key={line}>{line}</li>
              ))}
            </ul>
          </dd>
        </div>
        <div>
          <dt>{SPEC_COPY.criteria}</dt>
          <dd>
            <ul>
              {spec.criteria.map((line) => (
                <li key={line}>{line}</li>
              ))}
            </ul>
          </dd>
        </div>
        <div>
          <dt>{SPEC_COPY.owns}</dt>
          <dd>
            {spec.lanes.length > 0 ? (
              <ul>
                {spec.lanes.map((lane) => (
                  <li key={lane.key}>
                    <b>{lane.key}</b> {lane.title} <code>{lane.owns}</code>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="wfd-spec__defer">{SPEC_COPY.ownsByTask}</p>
            )}
          </dd>
        </div>
      </dl>
      {spec.axisNote && (
        <p className="wfd-spec__axis">
          <b>{SPEC_COPY.axis}</b> {spec.axisNote}
        </p>
      )}
    </div>
  );
}
