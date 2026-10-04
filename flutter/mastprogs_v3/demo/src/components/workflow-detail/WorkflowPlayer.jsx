import { useCallback, useMemo, useReducer, useRef, useState } from "react";
import { DETAIL_COPY } from "../../content/workflowDetail.js";
import { useDetailPlayer } from "../../hooks/useDetailPlayer.js";
import { useFrameFollow } from "../../hooks/useFrameFollow.js";
import { deriveFrameTargets } from "../../workflow-detail/frames.js";
import { DETAIL_ACTION, createDetailState, detailReducer, scenarioOf } from "../../workflow-detail/reducer.js";
import { deriveRecordChanges, deriveRecords } from "../../workflow-detail/records.js";
import { ModeSwitch } from "../workflow/ModeSwitch.jsx";
import { ConversationPanel } from "./ConversationPanel.jsx";
import { DetailTransport } from "./DetailTransport.jsx";
import { DirectPanel } from "./DirectPanel.jsx";
import { LaneBoard } from "./LaneBoard.jsx";
import { RecordsExplorer } from "./RecordsExplorer.jsx";
import { ScenarioOptions } from "./ScenarioOptions.jsx";

function announcementFor(state, scenario) {
  if (state.lastAction === "hidden") return "탭이 가려져 일시정지했습니다.";
  if (state.lastAction === "reset") return "처음으로 돌아갔습니다. 기록을 비웠습니다.";
  if (state.lastAction === "options") return "옵션을 바꿔 처음으로 돌아갔습니다.";
  if (state.lastAction === "route") return "경로를 바꿔 처음으로 돌아갔습니다.";
  if (state.lastAction === "pause") return "일시정지";
  const manual = ["next", "prev", "seek"].includes(state.lastAction);
  if (manual && state.cursor === 0) return "시작 전 프레임";
  return scenario.stepAnnouncement(state.cursor, { manual });
}

// AI-NOTE: 상세 재생기 하나. /workflow 페이지는 selectable 로 마운트해 경로 선택(직접 처리 / 순차 / 독립 병렬, 기본 독립 병렬)을
// 이 안에 한 번만 그린다(위쪽 경로 탭·중첩 탭·중복 재생 막대 없음). 세 경로 모두 같은 DetailTransport 프레임 조작을 쓴다
// (엔진은 workflow-detail/model.js getScenario 하나). 순서: 경로 선택·옵션 → 고정 재생기 → 사람↔Master 대화
// → (직접 처리) 직접 처리 흐름 | (순차·병렬) WORK SPEC·(병렬만) Task Planning·Seed·레인 보드·병합 게이트·통합 → 기록 예시.
// 경로·옵션을 바꾸면 리듀서가 cursor·기록·선택을 처음으로 돌리고 status 가 바뀌어 타이머가 정리된다.
// 방금 바뀐 노드는 frames.js deriveFrameTargets 로 모두 강조하고, 주 강조 하나를 useFrameFollow 가 따라간다(따라가기 기본 켬).
// 옛 WorkflowStage(마운트되지 않는 호환용)는 selectable 없이 route 만 넘겨 쓴다.
export function WorkflowPlayer({ route = "parallel", selectable = false }) {
  const [state, dispatch] = useReducer(detailReducer, { route }, createDetailState);
  const [follow, setFollow] = useState(true);
  const rootRef = useRef(null);
  const barRef = useRef(null);
  useDetailPlayer(state, dispatch);
  const scenario = scenarioOf(state);
  const { cursor } = state;
  const currentRoute = scenario.options.route;
  const direct = currentRoute === "direct";

  const messages = useMemo(() => scenario.deriveConversation(cursor), [scenario, cursor]);
  const spec = useMemo(() => scenario.deriveSpec(cursor), [scenario, cursor]);
  const taskPlan = useMemo(() => scenario.deriveTaskPlan(cursor), [scenario, cursor]);
  const lanes = useMemo(() => scenario.deriveLanes(cursor), [scenario, cursor]);
  const gate = useMemo(() => scenario.deriveMergeGate(cursor), [scenario, cursor]);
  const integration = useMemo(() => scenario.deriveIntegration(cursor), [scenario, cursor]);
  const directNodes = useMemo(() => scenario.deriveDirect(cursor), [scenario, cursor]);
  const records = useMemo(() => deriveRecords(cursor, scenario), [scenario, cursor]);
  const changes = useMemo(() => deriveRecordChanges(cursor, scenario), [scenario, cursor]);
  const targets = useMemo(() => deriveFrameTargets(scenario, cursor), [scenario, cursor]);
  const frame = useMemo(() => new Set(targets.ids), [targets]);
  const announcement = announcementFor(state, scenario);

  useFrameFollow({ rootRef, barRef, primary: targets.primary, cursor, lastAction: state.lastAction, enabled: follow });

  const play = useCallback(() => dispatch({ type: DETAIL_ACTION.PLAY }), []);
  const pause = useCallback(() => dispatch({ type: DETAIL_ACTION.PAUSE }), []);
  const reset = useCallback(() => dispatch({ type: DETAIL_ACTION.RESET }), []);
  const next = useCallback(() => dispatch({ type: DETAIL_ACTION.NEXT }), []);
  const prev = useCallback(() => dispatch({ type: DETAIL_ACTION.PREV }), []);
  const seek = useCallback((value) => dispatch({ type: DETAIL_ACTION.SEEK, cursor: value }), []);
  const setSpeed = useCallback((speed) => dispatch({ type: DETAIL_ACTION.SET_SPEED, speed }), []);
  const setRoute = useCallback((value) => dispatch({ type: DETAIL_ACTION.SET_ROUTE, route: value }), []);
  const setOption = useCallback((key, value) => dispatch({ type: DETAIL_ACTION.SET_OPTION, key, value }), []);
  const selectFile = useCallback((path) => dispatch({ type: DETAIL_ACTION.SELECT_FILE, path }), []);
  const followFiles = useCallback(() => dispatch({ type: DETAIL_ACTION.FOLLOW_FILES }), []);

  return (
    <div ref={rootRef} className={`wfd-run wfd-run--${currentRoute}`}>
      <div className="wfd-run__head">
        {selectable && (
          <div className="wfd-run__routes">
            <ModeSwitch value={currentRoute} onChange={setRoute} />
            <p className="wfd-run__route-hint">{DETAIL_COPY.routeHint}</p>
          </div>
        )}
        <ScenarioOptions route={currentRoute} values={scenario.options} onChange={setOption} />
      </div>
      <div ref={barRef} className="wfd-run__bar">
        <DetailTransport
          state={state}
          follow={follow}
          onPlay={play}
          onPause={pause}
          onReset={reset}
          onNext={next}
          onPrev={prev}
          onSeek={seek}
          onSpeed={setSpeed}
          onFollow={setFollow}
        />
      </div>
      <ConversationPanel messages={messages} frame={frame} />
      {direct ? (
        <DirectPanel nodes={directNodes} frame={frame} />
      ) : (
        <LaneBoard lanes={lanes} dispatched={scenario.isDispatched(cursor)} gate={gate} integration={integration} spec={spec} taskPlan={taskPlan} showSeed={scenario.options.seed} frame={frame} />
      )}
      <RecordsExplorer records={records} changes={changes} selectedPath={state.selectedPath} onSelect={selectFile} onFollow={followFiles} />
      <p className="sr-only" aria-live="polite" aria-atomic="true">
        {announcement}
      </p>
    </div>
  );
}
