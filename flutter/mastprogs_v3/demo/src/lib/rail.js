// 사례 레일 계산. DOM 측정값({ scrollLeft, clientWidth, scrollWidth }, 카드 { left, width })만 받는 순수 함수라 테스트할 수 있다.
// AI-NOTE: 기울기는 -1~1 비율로만 돌려주고 각도는 CSS(--tilt × 최대 각도)가 정한다. 그래야 동작 줄이기·좁은 화면에서
// CSS 미디어 쿼리 하나로 기울기를 끌 수 있고, 스크롤 위치는 네이티브 스크롤이 그대로 결정한다.

const clamp = (value, min, max) => Math.min(max, Math.max(min, value));

function viewportCenter(viewport) {
  return viewport.scrollLeft + viewport.clientWidth / 2;
}

// 화면 가운데에 가장 가까운 카드 인덱스. 카드가 없으면 -1.
export function centeredIndex(viewport, items) {
  const center = viewportCenter(viewport);
  let best = -1;
  let bestDistance = Infinity;
  items.forEach((item, index) => {
    const distance = Math.abs(item.left + item.width / 2 - center);
    if (distance < bestDistance) {
      best = index;
      bestDistance = distance;
    }
  });
  return best;
}

// 카드 중심이 화면 가운데에서 떨어진 정도(-1 왼쪽 끝 ~ 0 가운데 ~ 1 오른쪽 끝).
export function tiltRatio(item, viewport) {
  const half = viewport.clientWidth / 2;
  if (!(half > 0)) return 0;
  const ratio = clamp((item.left + item.width / 2 - viewportCenter(viewport)) / half, -1, 1);
  // 반올림 결과가 -0 이면 0 으로 맞춘다(스타일 문자열 "-0" 방지).
  return Math.round(ratio * 1000) / 1000 || 0;
}

// 카드를 화면 가운데에 두는 scrollLeft. 스크롤 가능 범위 안으로 자른다.
export function scrollLeftToCenter(item, viewport) {
  const max = Math.max(0, viewport.scrollWidth - viewport.clientWidth);
  return clamp(item.left + item.width / 2 - viewport.clientWidth / 2, 0, max);
}

// 이전/다음 버튼 대상. 범위를 벗어나면 null(버튼 비활성).
export function stepIndex(active, delta, count) {
  const target = active + delta;
  return target >= 0 && target < count ? target : null;
}
