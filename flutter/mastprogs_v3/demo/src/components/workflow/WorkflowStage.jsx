import { useCallback, useMemo, useReducer } from "react";
import { SECTION_IDS, STAGE } from "../../content/site.js";
import { useAnnouncement } from "../../hooks/useAnnouncement.js";
import { useRevealOnce } from "../../hooks/useRevealOnce.js";
import { useWorkflowPlayer } from "../../hooks/useWorkflowPlayer.js";
import { MODE } from "../../workflow/constants.js";
import {
  deriveDirectNodes,
  deriveHistory,
  deriveLaneSummaries,
  deriveMergeGate,
  derivePhaseStates,
  deriveReturnConnector,
  describePhase,
  describeRouteNode,
  getIntegrationGate,
  getModeHint,
} from "../../workflow/model.js";
import { ACTION, createInitialState, followPhase, workflowReducer } from "../../workflow/reducer.js";
import { ScenarioOptions } from "../workflow-detail/ScenarioOptions.jsx";
import { WorkflowPlayer } from "../workflow-detail/WorkflowPlayer.jsx";
import { ModeSwitch } from "./ModeSwitch.jsx";
import { PhaseDetail } from "./PhaseDetail.jsx";
import { PhaseTimeline } from "./PhaseTimeline.jsx";
import { RunHistory } from "./RunHistory.jsx";
import { Transport } from "./Transport.jsx";

// AI-NOTE: 메인 페이지에는 더 이상 마운트하지 않는다(WorkflowSummary 로 대체). /workflow 상세의 "순차·직접 처리" 탭에서
// 같은 컴포넌트를 재사용하므로 섹션 id·번호·제목을 props 로 바꿀 수 있게 했다. 기본값은 이전 메인 화면과 같다.
export function WorkflowStage({ initialOptions, revealEnabled, sectionId = SECTION_IDS.workflow, index = STAGE.index, title = STAGE.title }) {
  const [state, dispatch] = useReducer(workflowReducer, initialOptions, createInitialState);
  useWorkflowPlayer(state, dispatch);
  const announcement = useAnnouncement(state);
  const revealRef = useRevealOnce(revealEnabled);

  const { mode, plan, cursor } = state;
  const phases = useMemo(() => derivePhaseStates(mode, plan, cursor), [mode, plan, cursor]);
  const gate = useMemo(() => getIntegrationGate(mode, plan, cursor), [mode, plan, cursor]);
  const mergeGate = useMemo(() => deriveMergeGate(mode, plan, cursor), [mode, plan, cursor]);
  const directNodes = useMemo(() => deriveDirectNodes(mode, plan, cursor), [mode, plan, cursor]);
  const laneSummaries = useMemo(
    () => (mode === MODE.PARALLEL ? deriveLaneSummaries(phases, mergeGate) : null),
    [mode, phases, mergeGate],
  );
  const history = useMemo(() => deriveHistory(plan, cursor), [plan, cursor]);
  const connector = useMemo(() => deriveReturnConnector(mode, phases), [mode, phases]);

  // AI-NOTE: 선택이 null 이면(직접 처리 노드, 병합 게이트) 7단계 탭 대신 실행 노드 설명을 패널에 보여 준다.
  const selected = phases.find((phase) => phase.id === state.selectedPhaseId) ?? null;
  const routeNode = selected ? null : describeRouteNode(mode, plan, cursor);
  const detail = selected
    ? { title: selected.label, lines: describePhase(selected, { mode, gate }), tabId: `phase-tab-${selected.id}` }
    : routeNode ?? { title: phases[0].label, lines: describePhase(phases[0], { mode, gate }), tabId: undefined };
  const showFollow = state.pinned && state.selectedPhaseId !== followPhase(plan, cursor);

  const play = useCallback(() => dispatch({ type: ACTION.PLAY }), []);
  const pause = useCallback(() => dispatch({ type: ACTION.PAUSE }), []);
  const reset = useCallback(() => dispatch({ type: ACTION.RESET }), []);
  const next = useCallback(() => dispatch({ type: ACTION.NEXT }), []);
  const setMode = useCallback((value) => dispatch({ type: ACTION.SET_MODE, mode: value }), []);
  const setFail = useCallback((value) => dispatch({ type: ACTION.SET_FAIL, failOn: value }), []);
  const select = useCallback((phaseId) => dispatch({ type: ACTION.SELECT_PHASE, phaseId }), []);
  const follow = useCallback(() => dispatch({ type: ACTION.FOLLOW_CURSOR }), []);

  return (
    <section id={sectionId} className="stage" aria-labelledby="stage-title" ref={revealRef}>
      <div className="stage__head">
        <h2 id="stage-title" className="stage__title">
          <span className="stage__index">{index}</span>
          <span>{title}</span>
        </h2>
        <ModeSwitch value={mode} onChange={setMode} />
      </div>

      {mode !== MODE.DIRECT ? (
        // AI-NOTE: 순차·독립 병렬 라디오는 /workflow 상단과 같은 WorkflowPlayer 를 쓴다(병렬 엔진 하나). key 로 경로가 바뀌면 새로 시작한다.
        <WorkflowPlayer key={mode} route={mode} />
      ) : (
        <>
          <div className="stage__panel">
            <Transport state={state} onPlay={play} onPause={pause} onReset={reset} onNext={next} onToggleFail={setFail} showFailToggle={false} />
            <ScenarioOptions route="direct" />
            <PhaseTimeline
              mode={mode}
              modeHint={getModeHint(mode)}
              transitionKey={`${mode}:${state.failOn}`}
              phases={phases}
              selectedId={selected?.id ?? null}
              connector={connector}
              gate={gate}
              mergeGate={mergeGate}
              directNodes={directNodes}
              laneSummaries={laneSummaries}
              onSelect={select}
            />
          </div>

          <div className="stage-foot">
            <PhaseDetail title={detail.title} lines={detail.lines} tabId={detail.tabId} onFollow={showFollow ? follow : undefined} />
            <RunHistory items={history} />
          </div>

          <p className="sr-only" aria-live="polite" aria-atomic="true">
            {announcement}
          </p>
        </>
      )}
    </section>
  );
}
