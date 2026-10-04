// showModal 을 쓸 수 없는 환경을 위한 대화상자 대체 동작: 배경 비활성화와 Tab 포커스 가두기.
const FOCUSABLE =
  'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

// AI-NOTE: 대화상자에서 body 까지 올라가며 각 조상의 형제 요소를 inert + aria-hidden 처리한다(inert 미지원 브라우저도 보조기기에서는 숨김).
// 반환된 함수가 원래 상태로 되돌리며, 원래 inert/aria-hidden 이던 요소는 건드리지 않는다.
export function inertOutside(element) {
  const changed = [];
  let node = element;
  while (node && node.parentElement && node !== document.body) {
    for (const sibling of node.parentElement.children) {
      if (sibling === node || sibling.inert || sibling.getAttribute("aria-hidden") === "true") continue;
      if (sibling.tagName === "SCRIPT" || sibling.tagName === "STYLE") continue;
      sibling.inert = true;
      sibling.setAttribute("aria-hidden", "true");
      changed.push(sibling);
    }
    node = node.parentElement;
  }
  return () => {
    for (const sibling of changed) {
      sibling.inert = false;
      sibling.removeAttribute("aria-hidden");
    }
  };
}

export function trapTabKey(event, container) {
  if (event.key !== "Tab") return;
  const items = [...container.querySelectorAll(FOCUSABLE)].filter((item) => item.getClientRects().length > 0);
  if (items.length === 0) {
    event.preventDefault();
    return;
  }
  const first = items[0];
  const last = items[items.length - 1];
  const active = document.activeElement;
  if (event.shiftKey && (active === first || !container.contains(active))) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && (active === last || !container.contains(active))) {
    event.preventDefault();
    first.focus();
  }
}
