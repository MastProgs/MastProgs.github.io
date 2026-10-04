// 모션 재생 순서 도우미(순수 함수).
// AI-NOTE: 걷기·달리기·공격을 "섞은 주머니(shuffle bag)"에서 하나씩 꺼낸다. 한 주머니에 세 모션이 모두 한 번씩 들어 있어
// 모두 나오고, 주머니가 바뀌는 경계에서도 같은 모션이 연달아 나오지 않게 첫 항목을 바꾼다. 모션 전환은 항상 한 사이클이
// 끝난 뒤(마지막 프레임 다음)에만 일어난다 — 중간 프레임에서 끊지 않는다. 난수는 주입해 테스트에서 고정한다.

export function shuffle(items, rng = Math.random) {
  const out = [...items];
  for (let i = out.length - 1; i > 0; i -= 1) {
    const j = Math.floor(rng() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

export function createShuffleBag(items, rng = Math.random) {
  if (!items.length) throw new Error("empty bag");
  let bag = [];
  let last = null;
  return {
    next() {
      if (bag.length === 0) {
        bag = shuffle(items, rng);
        if (items.length > 1 && bag[0] === last) {
          const swap = 1 + Math.floor(rng() * (bag.length - 1));
          [bag[0], bag[swap]] = [bag[swap], bag[0]];
        }
      }
      last = bag.shift();
      return last;
    },
    // 직접 고른 모션(current)에서 다시 섞기를 시작할 때: 남은 주머니를 버리고 current 를 마지막으로 삼아
    // 다음 꺼냄이 지금 모션과 겹치지 않게 한다.
    resumeFrom(current) {
      bag = [];
      last = current;
    },
  };
}

// 모션마다 한 차례에 도는 사이클 수. 짧은 걷기·달리기는 두 번, 공격은 한 번(자연스러운 한 동작).
export const TURN_CYCLES = Object.freeze({ walk: 2, run: 2, attack: 1 });
export const cyclesFor = (motionId) => TURN_CYCLES[motionId] ?? 1;

export const cycleDuration = (motion) => motion.frames.reduce((sum, frame) => sum + frame.ms, 0);

// 재생 상태 { motion, frame, loop, turn } 를 한 프레임 앞으로. 마지막 사이클이 끝나면 pickNext() 로 다음 모션.
// hold 가 참이면(무작위 섞기 끔) 같은 모션을 계속 돈다.
export function stepPlayback(state, motionsById, { pickNext, hold = false }) {
  const motion = motionsById[state.motion];
  const frame = state.frame + 1;
  if (frame < motion.frames.length) return { ...state, frame };
  const loop = state.loop + 1;
  if (hold || loop < cyclesFor(state.motion)) return { ...state, frame: 0, loop: hold ? 0 : loop };
  return { motion: pickNext(), frame: 0, loop: 0, turn: state.turn + 1 };
}

// 자동 연출(사람이 팔레트·외곽선을 직접 고르기 전까지만): 차례마다 프리셋을 돌리고 외곽선은 두 차례마다 켠다.
export function showcaseFor(turn, presetIds) {
  const ids = presetIds.length ? presetIds : ["original"];
  return { presetId: ids[turn % ids.length], outline: Math.floor(turn / 2) % 2 === 1 };
}
