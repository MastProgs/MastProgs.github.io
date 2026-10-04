import { useEffect } from "react";
import { RUN_STATUS, STEP_INTERVAL_MS } from "../workflow/constants.js";
import { ACTION } from "../workflow/reducer.js";

// AI-NOTE: 단계마다 setTimeout 하나만 예약하고, cursor/status 가 바뀌면 이전 타이머를 정리한다.
// 끝 단계에서 리듀서가 done 으로 바꾸면 더 이상 예약하지 않으므로 무한 재실행이 생기지 않는다.
// 탭이 가려지면 일시정지만 하고, 다시 보일 때 자동 재개하지 않는다(사용자가 재생을 눌러 재개).
export function useWorkflowPlayer(state, dispatch) {
  useEffect(() => {
    if (state.status !== RUN_STATUS.RUNNING) return undefined;
    const timer = window.setTimeout(() => dispatch({ type: ACTION.TICK }), STEP_INTERVAL_MS);
    return () => window.clearTimeout(timer);
  }, [state.status, state.cursor, dispatch]);

  useEffect(() => {
    const handleVisibility = () => {
      if (document.hidden) dispatch({ type: ACTION.PAUSE, reason: "hidden" });
    };
    document.addEventListener("visibilitychange", handleVisibility);
    return () => document.removeEventListener("visibilitychange", handleVisibility);
  }, [dispatch]);
}
