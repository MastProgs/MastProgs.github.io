import { useEffect, useRef, useState } from "react";
import { ListIcon, XIcon } from "@phosphor-icons/react";
import { HEADER_COLUMNS, NAV_LINKS, RESUME_LINKS, RESUME_NAV_HEADING } from "../content/site.js";
import { ThemeToggle } from "./ThemeToggle.jsx";

// AI-NOTE: 사용자 최신 지시로 왼쪽 위 이름과 "연락"(헤더·모바일 메뉴)을 뺐다. 이름·사진·항상 보이는 연락처 칸은
// 01 소개(#contact)에, 이름은 푸터에 그대로 있다. 오른쪽 끝에는 테마 전환 버튼 하나만 둔다(좁은 화면은 메뉴 버튼 옆).
export function SiteHeader() {
  const [menuOpen, setMenuOpen] = useState(false);
  const toggleRef = useRef(null);
  const menuRef = useRef(null);

  useEffect(() => {
    if (!menuOpen) return undefined;
    const handleKey = (event) => {
      if (event.key === "Escape") {
        setMenuOpen(false);
        toggleRef.current?.focus();
      }
    };
    const handlePointer = (event) => {
      if (!menuRef.current?.contains(event.target) && !toggleRef.current?.contains(event.target)) setMenuOpen(false);
    };
    document.addEventListener("keydown", handleKey);
    document.addEventListener("pointerdown", handlePointer);
    return () => {
      document.removeEventListener("keydown", handleKey);
      document.removeEventListener("pointerdown", handlePointer);
    };
  }, [menuOpen]);

  const closeMenu = () => setMenuOpen(false);

  return (
    <header className="site-header">
      <div className="site-header__grid">
        {HEADER_COLUMNS.map((column) => (
          <div key={column.heading} className="site-header__cell site-header__column">
            <p className="site-header__heading">{column.heading}</p>
            <ul className="site-header__items">
              {column.items.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </div>
        ))}
        {/* 계약 변경: 단일 "프로필" 링크 대신 이력 섹션 세 곳으로 바로 가는 목록(Gil 식 헤더 열). */}
        <nav className="site-header__cell site-header__column site-header__resume" aria-label="이력 바로가기">
          <p className="site-header__heading">{RESUME_NAV_HEADING}</p>
          <ul className="site-header__items">
            {RESUME_LINKS.map((link) => (
              <li key={link.href}>
                <a className="site-header__resume-link" href={link.href}>{link.label}</a>
              </li>
            ))}
          </ul>
        </nav>
        <div className="site-header__tools">
          <ThemeToggle compact />
          <button
            ref={toggleRef}
            type="button"
            className="site-header__menu-toggle"
            aria-expanded={menuOpen}
            aria-controls="mobile-menu"
            aria-label={menuOpen ? "메뉴 닫기" : "메뉴 열기"}
            onClick={() => setMenuOpen((value) => !value)}
          >
            {menuOpen ? <XIcon size={22} aria-hidden="true" /> : <ListIcon size={22} aria-hidden="true" />}
          </button>
        </div>
      </div>
      <nav
        ref={menuRef}
        id="mobile-menu"
        className="mobile-menu"
        aria-label="주요 메뉴"
        hidden={!menuOpen}
      >
        <ul>
          {NAV_LINKS.map((link) => (
            <li key={link.href}>
              <a href={link.href} onClick={closeMenu}>{link.label}</a>
            </li>
          ))}
        </ul>
      </nav>
    </header>
  );
}
