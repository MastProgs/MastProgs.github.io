import { DEFAULT_FAIL_ON, DEFAULT_MODE, MODES, PHASE_IDS, RUN_STATUS } from "./constants.js";
import { buildPlan, isFailureAvailable } from "./model.js";

// AI-NOTE: 리듀서는 시간 개념 없이 결정적으로 동작한다. 자동 재생 간격은 useWorkflowPlayer 가 TICK 을 보내는 방식으로만 다룬다.
// cursor 는 "적용된 단계 수" 이며, 기록과 단계 상태는 모두 cursor 에서 다시 계산한다.

export const ACTION = Object.freeze({
  PLAY: "PLAY",
  PAUSE: "PAUSE",
  TICK: "TICK",
  NEXT: "NEXT",
  RESET: "RESET",
  REPLAY: "REPLAY",
  SET_MODE: "SET_MODE",
  SET_FAIL: "SET_FAIL",
  SELECT_PHASE: "SELECT_PHASE",
  FOLLOW_CURSOR: "FOLLOW_CURSOR",
});

// 실행 위치의 단계 ID. 직접 처리 노드나 병합 게이트처럼 7단계 밖의 실행 노드면 null 이다.
export function followPhase(plan, cursor) {
  const step = plan[cursor - 1] ?? plan[0];
  return step.entries[0].phaseId ?? null;
}

export function createInitialState({
  mode = DEFAULT_MODE,
  failOn = DEFAULT_FAIL_ON,
  cursor = 0,
  status = RUN_STATUS.IDLE,
  selectedPhaseId = null,
} = {}) {
  const safeMode = MODES.some((item) => item.id === mode) ? mode : DEFAULT_MODE;
  const plan = buildPlan(safeMode, failOn);
  const safeCursor = Math.min(Math.max(0, Math.trunc(cursor) || 0), plan.length);
  const pinned = PHASE_IDS.includes(selectedPhaseId);
  let safeStatus = status;
  if (safeCursor >= plan.length) safeStatus = RUN_STATUS.DONE;
  else if (safeStatus === RUN_STATUS.DONE) safeStatus = RUN_STATUS.PAUSED;
  return {
    mode: safeMode,
    failOn: Boolean(failOn),
    plan,
    cursor: safeCursor,
    status: safeStatus,
    pauseReason: null,
    selectedPhaseId: pinned ? selectedPhaseId : followPhase(plan, safeCursor),
    pinned,
  };
}

function advance(state) {
  if (state.cursor >= state.plan.length) return state;
  const cursor = state.cursor + 1;
  return {
    ...state,
    cursor,
    selectedPhaseId: state.pinned ? state.selectedPhaseId : followPhase(state.plan, cursor),
  };
}

function restart(state, status) {
  return { ...createInitialState({ mode: state.mode, failOn: state.failOn }), status };
}

export function workflowReducer(state, action) {
  switch (action.type) {
    case ACTION.PLAY: {
      if (state.status === RUN_STATUS.DONE) return restart(state, RUN_STATUS.RUNNING);
      if (state.status === RUN_STATUS.RUNNING) return state;
      // 재개 시 사용자가 고정한 단계 선택을 풀고 현재 실행 단계를 다시 따라간다.
      return {
        ...state,
        status: RUN_STATUS.RUNNING,
        pauseReason: null,
        pinned: false,
        selectedPhaseId: followPhase(state.plan, state.cursor),
      };
    }
    case ACTION.PAUSE: {
      if (state.status !== RUN_STATUS.RUNNING) return state;
      return { ...state, status: RUN_STATUS.PAUSED, pauseReason: action.reason ?? "user" };
    }
    case ACTION.TICK: {
      if (state.status !== RUN_STATUS.RUNNING) return state;
      const next = advance(state);
      return next.cursor >= next.plan.length ? { ...next, status: RUN_STATUS.DONE } : next;
    }
    case ACTION.NEXT: {
      if (state.status === RUN_STATUS.DONE) return state;
      const next = advance(state);
      const status = next.cursor >= next.plan.length ? RUN_STATUS.DONE : RUN_STATUS.PAUSED;
      return { ...next, status, pauseReason: status === RUN_STATUS.PAUSED ? "step" : null };
    }
    case ACTION.RESET:
      return restart(state, RUN_STATUS.IDLE);
    case ACTION.REPLAY:
      return restart(state, RUN_STATUS.RUNNING);
    case ACTION.SET_MODE: {
      if (action.mode === state.mode || !MODES.some((item) => item.id === action.mode)) return state;
      return createInitialState({ mode: action.mode, failOn: state.failOn });
    }
    case ACTION.SET_FAIL: {
      const failOn = Boolean(action.failOn);
      if (!isFailureAvailable(state.mode) || failOn === state.failOn) return state;
      return createInitialState({ mode: state.mode, failOn });
    }
    case ACTION.SELECT_PHASE: {
      if (!PHASE_IDS.includes(action.phaseId)) return state;
      // 계약: 재생 중 타일을 누르면 실행을 일시정지하고 cursor 는 바꾸지 않은 채 해당 단계 상세만 보여 준다.
      const running = state.status === RUN_STATUS.RUNNING;
      if (state.selectedPhaseId === action.phaseId && state.pinned && !running) return state;
      return {
        ...state,
        selectedPhaseId: action.phaseId,
        pinned: true,
        status: running ? RUN_STATUS.PAUSED : state.status,
        pauseReason: running ? "inspect" : state.pauseReason,
      };
    }
    case ACTION.FOLLOW_CURSOR: {
      if (!state.pinned) return state;
      return { ...state, pinned: false, selectedPhaseId: followPhase(state.plan, state.cursor) };
    }
    default:
      return state;
  }
}
