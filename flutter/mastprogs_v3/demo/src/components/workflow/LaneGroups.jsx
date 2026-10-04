import { CaretRightIcon, CheckIcon, CircleDashedIcon, GitMergeIcon, HourglassIcon, WarningCircleIcon } from "@phosphor-icons/react";
import { STAGE } from "../../content/site.js";
import { FAULT_LANE, PHASE_STATUS, PHASE_STATUS_LABEL, REWORK_BADGE } from "../../workflow/constants.js";

const ROW_ICON = {
  [PHASE_STATUS.DONE]: CheckIcon,
  [PHASE_STATUS.FAULT]: WarningCircleIcon,
  [PHASE_STATUS.GATED]: HourglassIcon,
  [PHASE_STATUS.PENDING]: CircleDashedIcon,
  [PHASE_STATUS.PARTIAL]: CircleDashedIcon,
};

const MERGE_TEXT = { pending: "대기", waiting: "병합 대기", done: "병합 완료" };

// AI-NOTE: 600px 이하 독립 병렬 전용. 레인 A/B/C 를 네이티브 <details> 로 접고 펼치며(키보드·스크린리더 기본 지원),
// 레인 아래에 병합 게이트를 두고 이어지는 공유 Wiki→통합은 아래 세로 단계 목록이 맡는다. 데스크톱·태블릿에서는 CSS 로 숨긴다.
export function LaneGroups({ lanes, mergeGate }) {
  return (
    <div className="lane-groups" role="group" aria-label={STAGE.laneGroupsLabel}>
      {lanes.map((lane) => {
        const Icon = ROW_ICON[lane.status] ?? CircleDashedIcon;
        return (
          <details key={lane.lane} className={`lane-group lane-group--${lane.status}`} open={lane.lane === FAULT_LANE}>
            <summary className="lane-group__summary">
              <CaretRightIcon className="lane-group__caret" size={16} aria-hidden="true" />
              <span className="lane-group__name">레인 {lane.lane}</span>
              <span className="lane-group__status">
                <Icon size={14} weight="bold" aria-hidden="true" />
                {PHASE_STATUS_LABEL[lane.status]}
                {lane.reworked ? ` · ${REWORK_BADGE}` : ""}
              </span>
            </summary>
            <ol className="lane-group__rows">
              {lane.rows.map((row) => {
                const RowIcon = ROW_ICON[row.status] ?? CircleDashedIcon;
                return (
                  <li key={row.phaseId} className={`lane-row lane-row--${row.status}`}>
                    <span>{row.label}</span>
                    <span className="lane-row__status">
                      <RowIcon size={13} weight="bold" aria-hidden="true" />
                      {PHASE_STATUS_LABEL[row.status]}
                    </span>
                  </li>
                );
              })}
            </ol>
          </details>
        );
      })}
      {mergeGate && (
        <p className={`lane-merge lane-merge--${mergeGate.status}${mergeGate.isCurrent ? " is-current" : ""}`}>
          <GitMergeIcon size={16} aria-hidden="true" />
          <span>
            {mergeGate.label} · {MERGE_TEXT[mergeGate.status]}
            {mergeGate.status === "waiting" ? ` (${mergeGate.blockingLanes.join("·")} 복구 중)` : ""}
          </span>
        </p>
      )}
      <p className="lane-shared">{STAGE.sharedLabel}</p>
    </div>
  );
}
