import { useEffect, useState } from "react";
import { ArrowLeftIcon } from "@phosphor-icons/react";
import { SPRITE_PAGE } from "../../content/pixelStudio.js";
import { CASES } from "../../content/site.js";
import { ThemeToggle } from "../ThemeToggle.jsx";
import { CaseDialog } from "../cases/CaseDialog.jsx";
import { PixelStudioPreview } from "../cases/PixelStudioPreview.jsx";

const PIXEL_CASE = CASES.find((item) => item.id === "case-pixel");

// AI-NOTE: /sprite 상세 페이지. 사용자 최신 지시로 작업 사례 레일 아래에 있던 전체 Hero Pixel Studio 미리보기를
// 이 페이지로 옮겼다(포인트 색·외곽선, 2행 팔레트 세트·비율, 20행 타임라인, 프레임·어니언·기준점, 골격, 무작위 재생, 원본 비교 모두 유지).
// App.jsx 가 lazy 로 불러오므로 레이어·팔레트·골격 데이터는 이 페이지 청크에만 들어간다.
// 머리글은 /workflow 와 같은 모양(이력서로 돌아가기 + 테마 전환), 테마는 main.jsx 의 같은 ThemeProvider 를 쓴다.
// "사례 자세히 보기" 는 메인 레일과 같은 CaseDialog 로 원본 편집기 화면 캡처를 보여 준다.
export function SpritePage() {
  const [caseOpen, setCaseOpen] = useState(false);

  useEffect(() => {
    const previous = document.title;
    document.title = `${SPRITE_PAGE.eyebrow} · 김형준`;
    return () => {
      document.title = previous;
    };
  }, []);

  return (
    <div className="shell wfd-shell sprite-shell" id="top">
      <header className="wfd-top">
        <a className="wfd-top__back" href="/">
          <ArrowLeftIcon size={18} aria-hidden="true" />
          {SPRITE_PAGE.backLabel}
        </a>
        <ThemeToggle compact />
      </header>

      <main className="wfd-page">
        <section className="wfd-intro" aria-labelledby="sprite-page-title">
          <p className="wfd-intro__eyebrow">{SPRITE_PAGE.eyebrow}</p>
          <h1 id="sprite-page-title" className="wfd-intro__title">{SPRITE_PAGE.title}</h1>
          <div className="wfd-intro__body">
            {SPRITE_PAGE.intro.map((line) => (
              <p key={line}>{line}</p>
            ))}
          </div>
        </section>

        <PixelStudioPreview onOpenCase={() => setCaseOpen(true)} />
      </main>

      <CaseDialog item={caseOpen ? PIXEL_CASE : null} onClose={() => setCaseOpen(false)} />
    </div>
  );
}
