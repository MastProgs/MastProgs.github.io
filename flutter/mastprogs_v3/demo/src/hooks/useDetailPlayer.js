import { useEffect } from "react";
import { RUN_STATUS } from "../workflow/constants.js";
import { DETAIL_ACTION } from "../workflow-detail/reducer.js";
import { DETAIL_STEP_MS, frameDelay } from "../workflow-detail/frames.js";

// 기존 import 호환(1배 속도 간격). 값은 workflow-detail/frames.js 에 있다.
export { DETAIL_STEP_MS };

// AI-NOTE: useWorkflowPlayer 와 같은 규칙. 단계마다 setTimeout 하나만 예약하고 cursor/status/speed/경로가 바뀌면 정리한다.
// 간격은 frameDelay(state.speed)(0.5·1·2배). done 이면 더 예약하지 않아 무한 재실행이 없고,
// 탭이 가려지면 일시정지만 한다(자동 재개 없음). 이전·위치 이동·경로 변경은 status 를 바꾸므로 예약된 타이머가 즉시 정리된다.
export function useDetailPlayer(state, dispatch) {
  const route = state.options.route;
  useEffect(() => {
    if (state.status !== RUN_STATUS.RUNNING) return undefined;
    const timer = window.setTimeout(() => dispatch({ type: DETAIL_ACTION.TICK }), frameDelay(state.speed));
    return () => window.clearTimeout(timer);
  }, [state.status, state.cursor, state.speed, route, dispatch]);

  useEffect(() => {
    const handleVisibility = () => {
      if (document.hidden) dispatch({ type: DETAIL_ACTION.PAUSE, reason: "hidden" });
    };
    document.addEventListener("visibilitychange", handleVisibility);
    return () => document.removeEventListener("visibilitychange", handleVisibility);
  }, [dispatch]);
}
