import { RUN_STATUS } from "./constants.js";
import { describeStep, getModeLabel } from "./model.js";

// AI-NOTE: 스크린리더 알림이 자동 재생 중 매 단계마다 쏟아지지 않도록, 재생 중에는 결함/재작업/완료처럼
// 흐름이 바뀌는 단계만 알린다. 수동으로 "다음 단계" 를 누른 경우에는 매번 결과를 알린다.

function isNotableStep(step) {
  return step.entries.some((entry) => entry.attempt > 1 || entry.outcome === "defect");
}

export function announcementFor(prev, next) {
  if (!prev || prev === next) return "";
  if (prev.mode !== next.mode) return `${getModeLabel(next.mode)} 경로로 바꾸고 처음 상태로 초기화했습니다.`;
  if (prev.failOn !== next.failOn) {
    return `QA 실패 시나리오를 ${next.failOn ? "켰" : "껐"}습니다. 처음 상태로 초기화했습니다.`;
  }
  if (next.cursor === 0 && prev.cursor !== 0) {
    return next.status === RUN_STATUS.RUNNING ? "처음부터 다시 재생합니다." : "처음 상태로 되돌렸습니다.";
  }
  if (next.status === RUN_STATUS.DONE && prev.status !== RUN_STATUS.DONE) {
    const last = describeStep(next.plan[next.cursor - 1]);
    return `${last.text}. 전체 ${next.plan.length}단계 실행을 마쳤습니다.`;
  }
  if (next.cursor > prev.cursor) {
    const step = next.plan[next.cursor - 1];
    if (next.status === RUN_STATUS.RUNNING && !isNotableStep(step)) return "";
    return `${next.cursor}단계, ${describeStep(step).text}`;
  }
  if (next.status === RUN_STATUS.PAUSED && prev.status === RUN_STATUS.RUNNING) {
    return next.pauseReason === "hidden" ? "화면이 가려져 일시정지했습니다." : "일시정지했습니다.";
  }
  if (next.status === RUN_STATUS.RUNNING && prev.status !== RUN_STATUS.RUNNING) return "재생합니다.";
  return "";
}
