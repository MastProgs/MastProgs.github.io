// /workflow 상세 페이지 재생 리듀서. 타이머 없이 cursor 만 움직인다(타이머는 useDetailPlayer 훅).
// AI-NOTE: 기존 src/workflow/reducer.js 의 API 와 테스트는 그대로 두고, 상세 페이지 전용으로 따로 둔다.
// state.options 가 시나리오(route·seed·planReject·qaFail)를 정하고, 옵션·경로를 바꾸면 cursor·선택·기록이 처음으로 돌아간다.
// 프레임 조작: 이전·위치 이동·다음은 언제나 일시정지로 멈춘다. 화면·기록·원장은 모두 cursor 에서 다시 파생되므로
// 되감으면 미래 기록·지적이 남지 않고, 다시 앞으로 가도 중복되지 않는다. 끝(total)은 done, 0 은 idle, 그 사이는 paused.
// 재생 속도(state.speed)는 처음으로·옵션·경로 변경 뒤에도 유지한다(보는 사람의 선택).
import { RUN_STATUS } from "../workflow/constants.js";
import { DEFAULT_SPEED, SPEEDS, normalizeSpeed } from "./frames.js";
import { getScenario, normalizeScenario } from "./model.js";

export const DETAIL_ACTION = Object.freeze({
  PLAY: "play",
  PAUSE: "pause",
  RESET: "reset",
  NEXT: "next",
  PREV: "prev",
  SEEK: "seek",
  TICK: "tick",
  SELECT_FILE: "selectFile",
  FOLLOW_FILES: "followFiles",
  SET_OPTION: "setOption",
  SET_ROUTE: "setRoute",
  SET_SPEED: "setSpeed",
});

export function createDetailState(options = {}) {
  const scenarioOptions = normalizeScenario(options);
  const scenario = getScenario(scenarioOptions);
  const cursor = scenario.clamp(options.cursor ?? 0);
  let status = options.status ?? RUN_STATUS.IDLE;
  if (cursor === scenario.total) status = RUN_STATUS.DONE;
  return { options: scenarioOptions, status, cursor, selectedPath: null, lastAction: null, speed: normalizeSpeed(options.speed ?? DEFAULT_SPEED) };
}

export const scenarioOf = (state) => getScenario(state.options);

// 같은 시나리오로 처음 상태를 다시 만들되 재생 속도는 유지한다.
const restart = (state, options, lastAction) => ({ ...createDetailState({ ...options, speed: state.speed }), lastAction });

const advance = (state, status) => {
  const { total } = scenarioOf(state);
  const cursor = Math.min(state.cursor + 1, total);
  return { ...state, cursor, status: cursor === total ? RUN_STATUS.DONE : status };
};

// 수동 이동(이전·위치). 끝이면 done, 0 이면 idle, 그 사이는 paused.
const moveTo = (state, target, lastAction) => {
  const { total, clamp } = scenarioOf(state);
  const cursor = clamp(target);
  let status = RUN_STATUS.PAUSED;
  if (cursor === total) status = RUN_STATUS.DONE;
  else if (cursor === 0) status = RUN_STATUS.IDLE;
  if (cursor === state.cursor && status === state.status) return state;
  return { ...state, cursor, status, lastAction };
};

export function detailReducer(state, action) {
  switch (action.type) {
    case DETAIL_ACTION.PLAY:
      if (state.status === RUN_STATUS.RUNNING) return state;
      if (state.status === RUN_STATUS.DONE) return { ...restart(state, state.options, "play"), status: RUN_STATUS.RUNNING };
      return { ...state, status: RUN_STATUS.RUNNING, lastAction: "play" };
    case DETAIL_ACTION.PAUSE:
      if (state.status !== RUN_STATUS.RUNNING) return state;
      return { ...state, status: RUN_STATUS.PAUSED, lastAction: action.reason === "hidden" ? "hidden" : "pause" };
    case DETAIL_ACTION.RESET:
      return restart(state, state.options, "reset");
    case DETAIL_ACTION.NEXT:
      if (state.status === RUN_STATUS.DONE) return state;
      return { ...advance(state, RUN_STATUS.PAUSED), lastAction: "next" };
    case DETAIL_ACTION.PREV:
      if (state.cursor === 0) return state;
      return moveTo(state, state.cursor - 1, "prev");
    case DETAIL_ACTION.SEEK: {
      const value = Number(action.cursor);
      if (!Number.isFinite(value)) return state;
      return moveTo(state, value, "seek");
    }
    case DETAIL_ACTION.TICK:
      if (state.status !== RUN_STATUS.RUNNING) return state;
      return { ...advance(state, RUN_STATUS.RUNNING), lastAction: "tick" };
    case DETAIL_ACTION.SELECT_FILE:
      if (typeof action.path !== "string" || action.path === state.selectedPath) return state;
      return { ...state, selectedPath: action.path };
    case DETAIL_ACTION.FOLLOW_FILES:
      if (state.selectedPath === null) return state;
      return { ...state, selectedPath: null };
    case DETAIL_ACTION.SET_OPTION: {
      const next = normalizeScenario({ ...state.options, [action.key]: action.value });
      if (Object.keys(next).every((key) => next[key] === state.options[key])) return state;
      return restart(state, next, "options");
    }
    case DETAIL_ACTION.SET_ROUTE: {
      // 경로를 바꾸면 그 경로의 기본 옵션으로 처음부터(순차의 실패 옵션 기본 켬 등). Seed 보기 선택만 이어 간다.
      const next = normalizeScenario({ route: action.route, seed: state.options.route === "direct" ? undefined : state.options.seed });
      if (next.route === state.options.route) return state;
      return restart(state, next, "route");
    }
    case DETAIL_ACTION.SET_SPEED:
      // 목록(0.5·1·2배)에 없는 값은 무시한다. 재생 중이면 다음 타이머부터 새 간격을 쓴다.
      if (!SPEEDS.includes(action.speed) || action.speed === state.speed) return state;
      return { ...state, speed: action.speed };
    default:
      return state;
  }
}
