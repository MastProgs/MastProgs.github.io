import { useEffect, useRef, useState } from "react";
import { NAV_LINKS, STICKY_BAR } from "../content/site.js";
import { ThemeToggle } from "./ThemeToggle.jsx";

// AI-NOTE: 스크롤 이벤트 대신 문서 상단에서 revealAfter(px) 위치에 둔 1px 감시 요소를 IntersectionObserver 로 본다.
// 감시 요소가 화면 위로 지나가면 바를 보이고, 숨김 상태에서는 inert 로 포커스·보조기기 트리에서 뺀다(중복 내비게이션 방지).
// IntersectionObserver 가 없으면 바를 띄우지 않으며, 페이지 상단 헤더·모바일 메뉴가 같은 링크를 제공한다.
// 사용자 최신 지시: 고정 바에도 이름과 "연락" 을 두지 않는다. 섹션 링크와 테마 전환만 있다.
export function StickyBar() {
  const sentinelRef = useRef(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const sentinel = sentinelRef.current;
    if (!sentinel || typeof IntersectionObserver !== "function") return undefined;
    const observer = new IntersectionObserver(([entry]) => {
      setVisible(!entry.isIntersecting && entry.boundingClientRect.top < 0);
    });
    observer.observe(sentinel);
    return () => observer.disconnect();
  }, []);

  return (
    <>
      <span ref={sentinelRef} className="sticky-sentinel" style={{ top: STICKY_BAR.revealAfter }} aria-hidden="true" />
      <div className={`sticky-bar${visible ? " is-visible" : ""}`} inert={!visible}>
        <div className="sticky-bar__inner">
          <nav className="sticky-bar__nav" aria-label={STICKY_BAR.label}>
            <ul>
              {NAV_LINKS.map((link) => (
                <li key={link.href}>
                  <a href={link.href}>{link.label}</a>
                </li>
              ))}
            </ul>
          </nav>
          <ThemeToggle compact />
        </div>
      </div>
    </>
  );
}
