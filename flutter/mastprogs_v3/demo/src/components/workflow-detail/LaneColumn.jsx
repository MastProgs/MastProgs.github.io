import {
  ArrowBendUpLeftIcon,
  ArrowLeftIcon,
  BugIcon,
  CheckCircleIcon,
  CircleDashedIcon,
  CircleNotchIcon,
  EyeIcon,
  GitMergeIcon,
  HourglassIcon,
  WarningIcon,
  XCircleIcon,
} from "@phosphor-icons/react";
import { LANE_STAGES, VERDICT_LABEL, stageLabel } from "../../workflow-detail/model.js";
import { RETURN_TARGET_LABEL } from "../../content/workflowDetail.js";
import { SeedLineage } from "./SeedLineage.jsx";

export const LANE_STATUS_TEXT = {
  queued: "배정 대기",
  seeding: "Seed 준비 중",
  running: "진행 중",
  returned: "되돌림 수정 중",
  ready: "READY · 다른 레인 대기",
  merged: "병합됨",
  done: "QA 통과 · 완료",
};

const LANE_STATUS_ICON = {
  queued: CircleDashedIcon,
  seeding: EyeIcon,
  running: CircleNotchIcon,
  returned: WarningIcon,
  ready: HourglassIcon,
  merged: GitMergeIcon,
  done: CheckCircleIcon,
};

// AI-NOTE: 되돌림 이동 표시. 오른쪽(반려·실패 단계)에서 왼쪽(되돌아갈 단계)으로 표식이 한 번 미끄러져 간다.
// key 가 반려 이벤트 id 라 새 반려마다 한 번만 다시 재생되고, 무한 반복하지 않는다. 동작 줄이기에서는 표식이 도착 위치에 정지해 있다.
function ReturnTrack({ connector }) {
  return (
    <span className={`wfd-return-track${connector.fresh ? " is-fresh" : ""}`} aria-hidden="true">
      <span className="wfd-return-track__end">{stageLabel(connector.to)}</span>
      <span className="wfd-return-track__rail">
        <span className="wfd-return-track__marker">
          <ArrowLeftIcon size={14} weight="bold" />
        </span>
      </span>
      <span className="wfd-return-track__end is-from">{stageLabel(connector.from)}</span>
    </span>
  );
}

const isVerdictStage = (id) => id === "plan-review" || id === "dev-review" || id === "qa";

function stageText(stage, current) {
  const qa = stage.id === "qa";
  if (stage.status === "returned") {
    if (stage.isActive) return qa ? `재시도 중 · ${current.attempt}회차` : `재검수 중 · ${current.attempt}회차`;
    return `${qa ? VERDICT_LABEL.failed : VERDICT_LABEL.rejected} ${stage.rejections}회`;
  }
  if (stage.isActive) return current && current.attempt > 1 ? `${current.attempt}회차 진행 중` : "진행 중";
  if (stage.status === "done") {
    const word = stage.id === "ready" ? "READY" : qa ? VERDICT_LABEL.passed : isVerdictStage(stage.id) ? VERDICT_LABEL.approved : "완료";
    return stage.attempts > 1 ? `${word} · ${stage.attempts}회차` : word;
  }
  return "대기";
}

function StageIcon({ stage }) {
  if (stage.status === "returned") {
    return stage.id === "qa" ? <XCircleIcon size={18} weight="fill" aria-hidden="true" /> : <ArrowBendUpLeftIcon size={18} weight="bold" aria-hidden="true" />;
  }
  // 진행 중 표시는 회전시키지 않는다(무한 반복 애니메이션 금지).
  if (stage.isActive) return <CircleNotchIcon size={18} weight="bold" aria-hidden="true" />;
  if (stage.status === "done") return <CheckCircleIcon size={18} weight="fill" aria-hidden="true" />;
  return <CircleDashedIcon size={18} aria-hidden="true" />;
}

// AI-NOTE: 되돌림 연결선은 행마다 그리는 세로 점선 조각(시작·중간·끝)이다. 행 높이가 글자 줄바꿈으로 달라져도
// 끊기지 않게 고정 높이 계산을 쓰지 않는다. 연결선은 반려가 해결(재검수 승인·QA 통과)될 때까지 남는다.
function returnPart(index, connector) {
  if (!connector) return "";
  const to = LANE_STAGES.findIndex((stage) => stage.id === connector.to);
  const from = LANE_STAGES.findIndex((stage) => stage.id === connector.from);
  if (index === to) return " is-return-start";
  if (index === from) return " is-return-end";
  if (index > to && index < from) return " is-return-mid";
  return "";
}

const NO_FRAME = new Set();

// AI-NOTE: frame 은 방금 바뀐 노드 id 집합(frames.js). 레인 전체는 lane:<id>(Seed 준비), 단계 행은 stage:<id>:<단계>.
// is-frame(방금 실행된 단계)과 is-active(다음에 실행될 단계)는 서로 다른 표시다.
export function LaneColumn({ lane, index, showSeed = false, frame = NO_FRAME }) {
  const StatusIcon = LANE_STATUS_ICON[lane.status];
  const { connector } = lane;
  const resolved = lane.returns.filter((item) => item.resolvedBy || item.supersededBy);
  const laneFrameId = `lane:${lane.id}`;
  return (
    <article
      data-frame-id={laneFrameId}
      className={`wfd-lane wfd-lane--${lane.status}${connector?.fresh ? " is-returning" : ""}${frame.has(laneFrameId) ? " is-frame" : ""}`}
      style={{ "--lane-index": index }}
      aria-labelledby={`wfd-lane-${lane.id}`}
    >
      <header className="wfd-lane__head">
        <span className="wfd-lane__key" aria-hidden="true">{lane.key}</span>
        <div className="wfd-lane__name">
          <h3 id={`wfd-lane-${lane.id}`}>
            <span className="sr-only">레인 {lane.key}, </span>
            {lane.title}
          </h3>
          <code>{lane.owns}</code>
        </div>
        <p className="wfd-lane__status">
          <StatusIcon size={15} weight="bold" aria-hidden="true" />
          {LANE_STATUS_TEXT[lane.status]}
        </p>
      </header>

      {showSeed && lane.lineage.seeded && <SeedLineage lineage={lane.lineage} laneKey={lane.key} />}

      <ol className="wfd-stages" aria-label={`레인 ${lane.key} 단계`}>
        {lane.stages.map((stage, stageIndex) => (
          <li
            key={stage.id}
            data-frame-id={`stage:${lane.id}:${stage.id}`}
            className={`wfd-stage wfd-stage--${stage.status}${stage.isActive ? " is-active" : ""}${returnPart(stageIndex, connector)}${connector?.fresh && stage.id === connector.to ? " is-return-target" : ""}${frame.has(`stage:${lane.id}:${stage.id}`) ? " is-frame" : ""}`}
            aria-current={stage.isActive ? "step" : undefined}
          >
            <span className="wfd-stage__card">
              <span className="wfd-stage__icon">
                <StageIcon stage={stage} />
              </span>
              <span className="wfd-stage__label">{stage.label}</span>
              <span className="wfd-stage__state">{stageText(stage, lane.current)}</span>
            </span>
          </li>
        ))}
      </ol>

      {connector ? (
        <p className="wfd-lane__return" role="note">
          <ArrowBendUpLeftIcon size={16} weight="bold" aria-hidden="true" />
          <span>
            <b>
              {stageLabel(connector.from)} {connector.from === "qa" ? "실패" : "반려"} → {RETURN_TARGET_LABEL[connector.to]} 되돌림
            </b>
            <ReturnTrack key={connector.eventId} connector={connector} />
            <span>
              {connector.issueId ? `${connector.issueId} · ` : ""}사유: {connector.reason}
            </span>
          </span>
        </p>
      ) : (
        <p className="wfd-lane__activity">
          {lane.lastEvent ? lane.lastEvent.text : lane.status === "queued" ? "Master AI 배정을 기다립니다." : lane.status === "seeding" ? "Seed가 규칙·구조를 읽는 중입니다." : "시작"}
        </p>
      )}

      {lane.issues.length > 0 && (
        <ul className="wfd-lane__issues" aria-label={`레인 ${lane.key} QA 지적 원장`}>
          {lane.issues.map((issue) => (
            <li key={issue.id} className={`is-${issue.status}`}>
              {issue.status === "resolved" ? <CheckCircleIcon size={14} weight="fill" aria-hidden="true" /> : <BugIcon size={14} weight="bold" aria-hidden="true" />}
              <b>{issue.id}</b>
              <span>
                {issue.status === "resolved" ? "독립 QA 통과로 해결" : "열림"} · 재현 {issue.occurrences}회
              </span>
            </li>
          ))}
        </ul>
      )}

      <dl className="wfd-lane__counts">
        <div>
          <dt>기획 검수</dt>
          <dd>{lane.counts.planReview}회</dd>
        </div>
        <div>
          <dt>개발 검수</dt>
          <dd>{lane.counts.devReview}회</dd>
        </div>
        <div>
          <dt>QA</dt>
          <dd>{lane.counts.qa}회</dd>
        </div>
      </dl>

      {resolved.length > 0 && (
        <ul className="wfd-lane__history" aria-label={`레인 ${lane.key} 해결된 되돌림`}>
          {resolved.map((item) => (
            <li key={item.eventId}>
              {item.resolvedBy ? <CheckCircleIcon size={14} weight="fill" aria-hidden="true" /> : <ArrowBendUpLeftIcon size={14} weight="bold" aria-hidden="true" />}
              {stageLabel(item.from)} {item.verdict === "failed" ? "실패" : "반려"} {item.attempt}회차 →{" "}
              {item.resolvedBy ? `${item.resolvedAttempt}회차 ${item.verdict === "failed" ? `${VERDICT_LABEL.passed}로` : `${VERDICT_LABEL.approved}으로`} 해결` : `${item.verdict === "failed" ? "재시도" : "재검수"}에서 다시 되돌림`}: {item.reason}
            </li>
          ))}
        </ul>
      )}
    </article>
  );
}
