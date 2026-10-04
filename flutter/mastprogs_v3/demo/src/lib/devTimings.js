// 개발 모드 전용: React 개발 빌드가 남기는 컴포넌트 타이밍 항목(performance measure) 가운데 이 앱이 소유한
// 컴포넌트 이름만 일정 개수 이하로 유지한다.
// AI-NOTE: React 19.2 개발 빌드(logComponentRender)는 props 가 바뀐 컴포넌트마다 바뀐 props 를 펼친 detail 과 함께
// performance.measure("​" + 컴포넌트 이름) 를 남기고 지우지 않는다. /sprite 는 프레임마다 다시 그리므로 장시간 재생하면
// 항목이 계속 쌓인다(근본 원인인 큰 RGBA 배열 props 는 usePixelPreview 에서 없앴다. 이것은 남은 작은 항목의 상한일 뿐이다).
// - 전체 clearMeasures(), performance.measure 가로채기, 오류 숨기기는 하지 않는다. 소유한 이름 하나씩만 지운다.
// - 프로덕션 빌드에는 이런 항목이 없으며 이 함수도 호출하지 않는다(호출 쪽에서 import.meta.env.DEV 로 막는다).

export const REACT_TIMING_PREFIX = "​";
// 이름마다 남겨 둘 최대 항목 수. 넘으면 그 이름의 항목만 지운다.
export const OWNED_TIMING_BUDGET = 240;

export const timingNameFor = (componentName) => `${REACT_TIMING_PREFIX}${componentName}`;

// perf 는 Performance 와 같은 모양(getEntriesByName, clearMeasures)을 가진 객체. 지운 이름 목록을 돌려준다.
export function trimOwnedTimings(perf, componentNames, budget = OWNED_TIMING_BUDGET) {
  if (!perf || typeof perf.getEntriesByName !== "function" || typeof perf.clearMeasures !== "function") return [];
  const cleared = [];
  for (const component of componentNames) {
    const name = timingNameFor(component);
    if (perf.getEntriesByName(name, "measure").length > budget) {
      perf.clearMeasures(name);
      cleared.push(name);
    }
  }
  return cleared;
}
