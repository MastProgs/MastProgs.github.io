// 접근성 링크(<a href>) 클릭 처리 규칙(브라우저 API 없는 순수 판정, platform_web 이 캡처 단계에서 쓴다).
// AI-NOTE: 원본 React <a href> 와 같은 동작을 위해
// - 보통 왼쪽 클릭: 브라우저 기본 이동만 막고(preventDefault) 전파는 둔다 → 엔진이 tap 을 한 번 보내 앱의 onPressed(라우터·새 탭)가 한 번 실행.
// - Ctrl/Cmd/Shift/Alt 클릭·가운데/오른쪽 버튼: 브라우저 기본 동작(새 탭·새 창 등)을 그대로 두고 전파만 막는다(stopPropagation)
//   → 엔진이 tap 을 보내지 않아 앱 이동이 겹치지 않는다. 엔진은 pointerdown(뷰)·pointerup(전역)을 버블 단계에서 받아
//   200ms 뒤 tap 으로 되살리므로, 같은 포인터의 down/up 도 캡처 단계에서 함께 막는다.
enum LinkClickAction { ignore, preventDefault, stopPropagation }

LinkClickAction semanticLinkClickAction({
  required bool onSemanticLink,
  required int button,
  required bool ctrl,
  required bool meta,
  required bool shift,
  required bool alt,
}) {
  if (!onSemanticLink) return LinkClickAction.ignore;
  if (button != 0 || ctrl || meta || shift || alt) return LinkClickAction.stopPropagation;
  return LinkClickAction.preventDefault;
}
