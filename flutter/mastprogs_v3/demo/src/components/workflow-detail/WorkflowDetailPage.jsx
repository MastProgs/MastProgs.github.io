import { useEffect } from "react";
import { ArrowLeftIcon } from "@phosphor-icons/react";
import { DETAIL_COPY } from "../../content/workflowDetail.js";
import { ThemeToggle } from "../ThemeToggle.jsx";
import { WorkflowPlayer } from "./WorkflowPlayer.jsx";

// AI-NOTE: /workflow 상세 페이지. 독립 병렬이 기본 화면이다(사용자 요청: 들어오자마자 이해되게).
// 테마는 main.jsx 의 같은 ThemeProvider 를 쓰므로 메인에서 고른 테마(저장된 dark|light)로 새 탭이 열린다.
// 사용자 최신 요청: 위쪽 "독립 병렬 / 순차·직접 처리" 탭은 시뮬레이터 안 경로 선택과 겹치므로 없앴다. 경로 선택은
// WorkflowPlayer(selectable) 안의 "직접 처리 / 순차 / 독립 병렬" 하나뿐이며, 세 경로가 같은 음악 재생기형 프레임 조작을 쓴다.
// 옛 WorkflowStage 는 이 페이지에서 마운트하지 않는다(파일·테스트용 호환만 남김).
export function WorkflowDetailPage() {
  useEffect(() => {
    const previous = document.title;
    document.title = `${DETAIL_COPY.eyebrow} · 김형준`;
    return () => {
      document.title = previous;
    };
  }, []);

  return (
    <div className="shell wfd-shell" id="top">
      <header className="wfd-top">
        <a className="wfd-top__back" href="/">
          <ArrowLeftIcon size={18} aria-hidden="true" />
          {DETAIL_COPY.backLabel}
        </a>
        <ThemeToggle compact />
      </header>

      <main className="wfd-page">
        <section className="wfd-intro" aria-labelledby="wfd-title">
          <p className="wfd-intro__eyebrow">{DETAIL_COPY.eyebrow}</p>
          <h1 id="wfd-title" className="wfd-intro__title">{DETAIL_COPY.title}</h1>
          <div className="wfd-intro__body">
            {DETAIL_COPY.intro.map((line) => (
              <p key={line}>{line}</p>
            ))}
          </div>
        </section>

        <WorkflowPlayer route="parallel" selectable />
      </main>
    </div>
  );
}
