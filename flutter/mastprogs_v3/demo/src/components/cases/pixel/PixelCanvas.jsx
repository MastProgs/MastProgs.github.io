import { useEffect, useRef } from "react";

// 이미 가공한 RGBA 를 옮겨 그리는 작은 캔버스. 크기 확대는 CSS(최근접)로만 한다.
// AI-NOTE: 큰 RGBA 배열을 props 로 받지 않는다(React 개발 빌드가 바뀐 props 를 프레임마다 복제해 장시간 재생 시 메모리가 바닥났다).
// 문자열 frameKey 가 바뀌면 효과 안에서 훅의 안정된 접근자 paint(kind, canvas) 로 그 렌더의 이미지를 읽어 그린다.
export function PixelCanvas({ paint, kind, frameKey, width, height, className, label }) {
  const ref = useRef(null);
  useEffect(() => {
    paint(kind, ref.current);
  }, [paint, kind, frameKey]);
  return <canvas ref={ref} className={className} width={width} height={height} role="img" aria-label={label} />;
}
