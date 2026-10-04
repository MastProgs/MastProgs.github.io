// 용사 스프라이트 메타데이터 정리(순수 함수). JSON 은 src/pixel/assets.js 가 import 해서 넘긴다(테스트는 파일을 직접 읽음).
// AI-NOTE: 원본 프레임은 모두 같은 84×89 공통 캔버스·같은 기준점(pivotX, soleRow)을 쓴다. 여기서는 위치를 다시 계산하지 않고
// 외곽선 여백(pad)만큼 모든 프레임을 똑같이 옮긴 화면 기하만 만든다(프레임별 재정렬·흔들림 없음).
import { OUTLINE_PAD } from "./outline.js";

export const MOTION_LABEL = Object.freeze({ walk: "걷기", run: "달리기", attack: "공격" });

export function buildSpriteModel(meta, pad = OUTLINE_PAD) {
  const motions = meta.motions.map((motion) => ({
    id: motion.id,
    label: MOTION_LABEL[motion.id] ?? motion.id,
    gif: motion.gif,
    frames: motion.frames.map((frame) => ({ src: frame.src, ms: frame.ms })),
  }));
  return Object.freeze({
    width: meta.width,
    height: meta.height,
    pad,
    canvasWidth: meta.width + pad * 2,
    canvasHeight: meta.height + pad * 2,
    pivotX: meta.pivotX + pad,
    soleRow: meta.soleRow + pad,
    motions,
    motionsById: Object.fromEntries(motions.map((motion) => [motion.id, motion])),
    frameCount: motions.reduce((sum, motion) => sum + motion.frames.length, 0),
  });
}
