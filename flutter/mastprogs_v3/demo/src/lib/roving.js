// 탭/라디오 그룹의 화살표 키 이동 규칙. 대상 인덱스를 돌려주고, 처리하지 않는 키는 null.
export function nextRovingIndex(key, index, count, { orientation = "horizontal" } = {}) {
  if (count <= 0) return null;
  const prevKeys = orientation === "both" ? ["ArrowLeft", "ArrowUp"] : ["ArrowLeft"];
  const nextKeys = orientation === "both" ? ["ArrowRight", "ArrowDown"] : ["ArrowRight"];
  if (prevKeys.includes(key)) return (index - 1 + count) % count;
  if (nextKeys.includes(key)) return (index + 1) % count;
  if (key === "Home") return 0;
  if (key === "End") return count - 1;
  return null;
}
