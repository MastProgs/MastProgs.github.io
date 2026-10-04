import { useEffect, useRef } from "react";
import {
  CaretDownIcon,
  CaretRightIcon,
  CheckCircleIcon,
  CheckIcon,
  CircleDashedIcon,
  GitMergeIcon,
  HourglassIcon,
  UserFocusIcon,
  WarningCircleIcon,
  WarningIcon,
} from "@phosphor-icons/react";
import { STAGE } from "../../content/site.js";
import {
  LANE_RESIZE_MS,
  PHASE_STATUS,
  PHASE_STATUS_LABEL,
  REWORK_BADGE,
  ROUTE_FADE_MS,
  SKIPPED_CAPTION,
} from "../../workflow/constants.js";
import { nextRovingIndex } from "../../lib/roving.js";
import { prefersReducedMotion } from "../../lib/motion.js";
import { useHeightTransition } from "../../hooks/useHeightTransition.js";
import { MOBILE_QUERY, useMediaQuery } from "../../hooks/useMediaQuery.js";
import { LaneGroups } from "./LaneGroups.jsx";

const LANE_ICON = {
  [PHASE_STATUS.DONE]: CheckIcon,
  [PHASE_STATUS.FAULT]: WarningCircleIcon,
  [PHASE_STATUS.PENDING]: CircleDashedIcon,
};

const AREA_TRANSITION = { resizeMs: LANE_RESIZE_MS, fadeMs: ROUTE_FADE_MS };

const MERGE_STATUS_TEXT = { pending: "대기", waiting: "병합 대기", done: "병합" };

function TileBadge({ phase, gate }) {
  if (phase.status === PHASE_STATUS.FAULT) {
    return (
      <span className="tile__badge tile__badge--fault">
        <WarningIcon size={14} weight="bold" aria-hidden="true" />
        결함 발견
      </span>
    );
  }
  if (phase.status === PHASE_STATUS.GATED) {
    return (
      <span className="tile__badge tile__badge--gate">
        <HourglassIcon size={13} weight="bold" aria-hidden="true" />
        {gate.blockingLanes.join("·")} 복구 대기
      </span>
    );
  }
  if (phase.status === PHASE_STATUS.DONE && phase.reworked) return <span className="tile__badge tile__badge--repair">{REWORK_BADGE}</span>;
  if (phase.status === PHASE_STATUS.DONE) {
    return <CheckCircleIcon className="tile__check" size={28} weight="fill" aria-hidden="true" />;
  }
  if (phase.isNext) return <span className="tile__badge tile__badge--next">다음</span>;
  return null;
}

function TileFooter({ phase, gate }) {
  if (phase.status === PHASE_STATUS.SKIPPED) return null;
  if (phase.lanes) {
    return (
      <span className="tile__lanes">
        {phase.lanes.map((lane) => {
          const Icon = LANE_ICON[lane.status] ?? CircleDashedIcon;
          return (
            <span key={lane.lane} className={`lane-chip lane-chip--${lane.status}`}>
              <Icon size={12} weight="bold" aria-hidden="true" />
              {lane.lane}
              <span className="sr-only"> {PHASE_STATUS_LABEL[lane.status]}</span>
            </span>
          );
        })}
      </span>
    );
  }
  if (phase.status === PHASE_STATUS.GATED) {
    return (
      <span className="tile__gate">
        <HourglassIcon size={16} aria-hidden="true" />
        {gate.waitingLanes.join("·")} 대기
      </span>
    );
  }
  if (phase.human) {
    return (
      <span className="tile__human">
        <UserFocusIcon size={20} aria-hidden="true" />
        <span className="tile__human-text">{STAGE.humanLabel}</span>
      </span>
    );
  }
  return null;
}

function DirectLane({ nodes }) {
  return (
    <ol className="direct-lane" aria-label={STAGE.directLaneLabel}>
      {nodes.map((node) => (
        <li
          key={node.id}
          className={`direct-node direct-node--${node.status}${node.isCurrent ? " is-current" : ""}`}
        >
          <span className="direct-node__order" aria-hidden="true">{node.order}</span>
          <span className="direct-node__text">
            <span className="direct-node__label">{node.label}</span>
            <span className="direct-node__role">{node.role}</span>
          </span>
          {node.status === PHASE_STATUS.DONE && <CheckCircleIcon className="direct-node__check" size={22} weight="fill" aria-hidden="true" />}
          <span className="sr-only">, {PHASE_STATUS_LABEL[node.status]}{node.isCurrent ? ", 현재 단계" : ""}</span>
        </li>
      ))}
    </ol>
  );
}

// 단계 타일은 탭 목록, 아래 상세 패널은 탭 패널이다. 화살표/Home/End 로 이동하면 바로 선택된다.
export function PhaseTimeline({ mode, modeHint, transitionKey, phases, selectedId, connector, gate, mergeGate, directNodes, laneSummaries, onSelect }) {
  const tabRefs = useRef([]);
  const scrollRef = useRef(null);
  const areaRef = useHeightTransition(transitionKey, AREA_TRANSITION);
  const vertical = useMediaQuery(MOBILE_QUERY);
  const orderOf = (id) => phases.find((phase) => phase.id === id)?.order ?? 1;
  const hasSelection = phases.some((phase) => phase.id === selectedId);
  const isDirect = Boolean(directNodes);

  // AI-NOTE: 태블릿 가로 스크롤에서 선택된 타일이 보이도록 타임라인 컨테이너만 가로로 맞춘다. 페이지 스크롤은 건드리지 않는다.
  const firstScroll = useRef(true);
  useEffect(() => {
    const scroller = scrollRef.current;
    const instant = firstScroll.current || prefersReducedMotion();
    firstScroll.current = false;
    if (!scroller || scroller.scrollWidth <= scroller.clientWidth + 1) return;
    const index = phases.findIndex((phase) => phase.id === selectedId);
    const tile = tabRefs.current[index];
    if (!tile) return;
    const tileRect = tile.getBoundingClientRect();
    const scrollerRect = scroller.getBoundingClientRect();
    const left = scroller.scrollLeft + (tileRect.left - scrollerRect.left) - (scroller.clientWidth - tileRect.width) / 2;
    scroller.scrollTo({ left: Math.max(0, left), behavior: instant ? "auto" : "smooth" });
  }, [selectedId, phases]);

  const handleKeyDown = (event, index) => {
    const target = nextRovingIndex(event.key, index, phases.length, { orientation: vertical ? "both" : "horizontal" });
    if (target === null) return;
    event.preventDefault();
    onSelect(phases[target].id);
    tabRefs.current[target]?.focus();
  };

  return (
    <div ref={areaRef} className={`timeline-area timeline-area--${mode}`}>
      {modeHint && <p className="route-caption">{modeHint}</p>}
      {isDirect && <DirectLane nodes={directNodes} />}
      {laneSummaries && <LaneGroups lanes={laneSummaries} mergeGate={mergeGate} />}
      <div className="timeline-scroll" ref={scrollRef}>
      <div className={`timeline${isDirect ? " is-dimmed" : ""}`}>
        <div className="ruler">
          <span className="ruler__label" aria-hidden="true">{STAGE.rulerLabel}</span>
          {phases.map((phase) => (
            <span
              key={phase.id}
              className={`ruler__mark${phase.isCurrent ? " is-current" : ""}`}
              style={{ gridColumn: phase.order }}
              aria-hidden="true"
            >
              <span className="ruler__tick" />
              <span className="ruler__num">{phase.order}</span>
            </span>
          ))}
          {mergeGate && (
            <span
              className={`merge-gate merge-gate--${mergeGate.status}${mergeGate.isCurrent ? " is-current" : ""}`}
              style={{ gridColumn: `${orderOf("qa")} / ${orderOf("wiki") + 1}` }}
            >
              <GitMergeIcon size={14} aria-hidden="true" />
              {mergeGate.label} · {MERGE_STATUS_TEXT[mergeGate.status]}
            </span>
          )}
          {connector && (
            <p
              className="connector"
              style={{ gridColumn: `${orderOf(connector.to)} / ${orderOf(connector.from) + 1}` }}
            >
              <span className="connector__label">{connector.text}</span>
              <span className="connector__arc" aria-hidden="true">
                <CaretDownIcon className="connector__head" size={16} weight="fill" />
              </span>
            </p>
          )}
        </div>
        <div className="tiles-wrap">
          <div
            className="tiles"
            role="tablist"
            aria-label="워크플로우 단계"
            aria-orientation={vertical ? "vertical" : "horizontal"}
          >
            {phases.map((phase, index) => {
              const selected = phase.id === selectedId;
              const focusable = selected || (!hasSelection && index === 0);
              const classes = [
                "tile",
                `tile--${phase.status}`,
                phase.isCurrent ? "is-current" : "",
                selected ? "is-selected" : "",
              ]
                .filter(Boolean)
                .join(" ");
              return (
                <button
                  key={phase.id}
                  ref={(node) => {
                    tabRefs.current[index] = node;
                  }}
                  id={`phase-tab-${phase.id}`}
                  type="button"
                  role="tab"
                  aria-selected={selected}
                  aria-controls="phase-panel"
                  tabIndex={focusable ? 0 : -1}
                  className={classes}
                  onClick={() => onSelect(phase.id)}
                  onKeyDown={(event) => handleKeyDown(event, index)}
                >
                  <span className="tile__order" aria-hidden="true">{phase.order}</span>
                  <TileBadge phase={phase} gate={gate} />
                  <span className="tile__title">{phase.label}</span>
                  <span className="tile__role">{phase.status === PHASE_STATUS.SKIPPED ? SKIPPED_CAPTION : phase.role}</span>
                  <TileFooter phase={phase} gate={gate} />
                  <span className="sr-only">
                    , {phase.order}단계, {PHASE_STATUS_LABEL[phase.status]}
                    {phase.reworked ? `, ${REWORK_BADGE}` : ""}
                    {phase.isCurrent ? ", 현재 단계" : ""}
                  </span>
                </button>
              );
            })}
          </div>
          {connector && (
            <span
              className="return-bracket"
              aria-hidden="true"
              style={{ "--from": orderOf(connector.to), "--to": orderOf(connector.from) }}
            >
              <CaretRightIcon className="return-bracket__head" size={14} weight="fill" />
            </span>
          )}
        </div>
      </div>
      </div>
    </div>
  );
}
