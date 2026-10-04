import { useEffect, useRef } from "react";
import { prefersReducedMotion } from "../lib/motion.js";
import { followScrollDelta } from "../workflow-detail/frames.js";

// 프레임을 옮기는 동작. 첫 렌더·처음으로·옵션/경로 변경(lastAction reset/options/route/null)에서는 스크롤하지 않는다.
const FRAME_ACTIONS = new Set(["tick", "next", "prev", "seek"]);
// 사람이 직접 고른 동작은 휠·터치로 멈춘 따라가기를 다시 켠다.
const MANUAL_ACTIONS = new Set(["next", "prev", "seek", "play"]);

// AI-NOTE: 현재 프레임 따라가기. 주 강조 노드(data-frame-id)가 고정 재생 막대 아래 보이는 영역 밖에 있을 때만 그 위치로 옮긴다
// (이미 보이면 움직이지 않음). 동작 줄이기면 즉시, 아니면 부드럽게 스크롤한다. 포커스는 건드리지 않는다(조작 버튼 포커스 유지).
// 자동 재생 중 사용자가 휠·터치로 읽기 시작하면 다음 수동 조작(이전·다음·위치·재생)까지 자동 재생 따라가기를 멈춘다.
export function useFrameFollow({ rootRef, barRef, primary, cursor, lastAction, enabled }) {
  const suspended = useRef(false);

  useEffect(() => {
    const suspend = () => {
      suspended.current = true;
    };
    window.addEventListener("wheel", suspend, { passive: true });
    window.addEventListener("touchmove", suspend, { passive: true });
    return () => {
      window.removeEventListener("wheel", suspend);
      window.removeEventListener("touchmove", suspend);
    };
  }, []);

  useEffect(() => {
    if (MANUAL_ACTIONS.has(lastAction)) suspended.current = false;
  }, [lastAction, cursor]);

  // 따라가기를 직접 껐다 켜면(끔→켬) 휠·터치 멈춤을 풀고, 일시정지 중이어도 현재 주 강조로 바로 옮긴다.
  const wasEnabled = useRef(enabled);

  useEffect(() => {
    const reenabled = enabled && !wasEnabled.current;
    wasEnabled.current = enabled;
    if (reenabled) suspended.current = false;
    if (!enabled || !primary) return;
    if (!reenabled && !FRAME_ACTIONS.has(lastAction)) return;
    if (!reenabled && lastAction === "tick" && suspended.current) return;
    const root = rootRef.current;
    const node = root?.querySelector(`[data-frame-id="${primary}"]`);
    if (!node) return;
    // 강조 노드는 모두 막대보다 아래에 있으므로, 스크롤 뒤에는 막대가 top:0 에 붙는다. 그 높이만큼을 가려지는 영역으로 본다.
    const safeTop = barRef.current?.offsetHeight ?? 0;
    const delta = followScrollDelta(node.getBoundingClientRect(), safeTop, window.innerHeight);
    if (delta === null) return;
    const reduced = prefersReducedMotion();
    window.scrollBy({ top: delta, behavior: reduced ? "auto" : "smooth" });
  }, [enabled, primary, cursor, lastAction, rootRef, barRef]);
}
