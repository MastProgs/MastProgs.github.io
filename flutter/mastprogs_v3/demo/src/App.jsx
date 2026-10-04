import { Suspense, lazy, useMemo } from "react";
import { ProfileSection } from "./components/ProfileSection.jsx";
import { SiteFooter } from "./components/SiteFooter.jsx";
import { SiteHeader } from "./components/SiteHeader.jsx";
import { StickyBar } from "./components/StickyBar.jsx";
import { CasesSection } from "./components/cases/CasesSection.jsx";
import { CoreSection } from "./components/core/CoreSection.jsx";
import { CareerSection } from "./components/resume/CareerSection.jsx";
import { SkillsSection } from "./components/resume/SkillsSection.jsx";
import { WorkflowDetailPage } from "./components/workflow-detail/WorkflowDetailPage.jsx";
import { SPRITE_ROUTE, SUBTITLES_ROUTE } from "./content/site.js";
import { DETAIL_ROUTE } from "./content/workflowDetail.js";

// AI-NOTE: /sprite 페이지(원본 레이어·팔레트 세트·골격 데이터 포함)는 무거워 별도 청크로 늦게 불러온다(빌드 500KB 경고 한도는 올리지 않는다).
// 메인 번들은 SpriteBrief(원본 GIF 만)만 갖는다. 불러오기 전에는 아무것도 그리지 않는다.
const SpritePage = lazy(() => import("./components/sprite/SpritePage.jsx").then((module) => ({ default: module.SpritePage })));
// AI-NOTE: /subtitles(Voice to SRT 상세)도 같은 방식의 별도 청크. (갱신) 메인에는 03 핵심 구현 안의 가벼운 요약(SubtitlesBrief, #subtitles)만
// 있고, 그 요약과 사례 03 대화상자가 새 탭으로 연다. 상세의 예시 데이터·단계 모델은 이 청크에만 있다.
const SubtitlesPage = lazy(() => import("./components/subtitles/SubtitlesPage.jsx").then((module) => ({ default: module.SubtitlesPage })));

// AI-NOTE: ?state=target 은 시각 기준 화면 비교용 진입점이다. 메인에서 WorkflowStage 를 요약으로 바꾼 뒤에는
// 섹션 등장 애니메이션을 끄는 용도로만 남는다(스크린샷이 흔들리지 않도록). TARGET_PRESET 자체는 기존 테스트가 계속 검증한다.
function readEntryOptions() {
  if (typeof window === "undefined") return { isTarget: false, isDetail: false, isSprite: false, isSubtitles: false };
  const isTarget = new URLSearchParams(window.location.search).get("state") === "target";
  // AI-NOTE: 라우터 의존성 없이 pathname 만 본다. /workflow·/workflow/ 는 워크플로우 상세, /sprite·/sprite/ 는 스프라이트 상세,
  // /subtitles·/subtitles/ 는 Voice to SRT 상세.
  const path = window.location.pathname.replace(/\/+$/, "") || "/";
  return { isTarget, isDetail: path === DETAIL_ROUTE, isSprite: path === SPRITE_ROUTE, isSubtitles: path === SUBTITLES_ROUTE };
}

// AI-NOTE: 사용자 최신 지시에 따른 섹션 순서(갱신: 예전 03 AgentWorkflow·04 스프라이트를 하나로 묶음):
// 01 소개 → 02 학력·역량 → 03 핵심 구현(CoreSection: AgentWorkflow → Sprite 파이프라인 → Voice to SRT 요약,
// 상세는 각각 /workflow·/sprite·/subtitles 새 탭) → 04 회사 경력 → 05 작업 사례 → 푸터.
// AI-NOTE: (갱신) 예전에 학력·역량과 WorkflowSummary(지금은 CoreSection 첫 하위 항목) 사이에 있던 큰 히어로는 사용자 최신 지시로 없앴다.
// 그 대표 주제 두 줄은 01 소개 안(사진·연락처 줄 바로 아래)의 ProfileTheme 으로 옮겼다. 여기에 다시 마운트하지 않는다.
export function App() {
  const entry = useMemo(readEntryOptions, []);
  const revealEnabled = !entry.isTarget;

  if (entry.isDetail) return <WorkflowDetailPage />;
  if (entry.isSprite) {
    return (
      <Suspense fallback={null}>
        <SpritePage />
      </Suspense>
    );
  }
  if (entry.isSubtitles) {
    return (
      <Suspense fallback={null}>
        <SubtitlesPage />
      </Suspense>
    );
  }

  // AI-NOTE: 연락처는 소개 상단의 항상 보이는 칸(#contact)에 있다(사용자 지시: "연락처는 바로 보여야지").
  // 사용자 최신 지시로 헤더·고정 바·모바일 메뉴의 "연락" 링크와 왼쪽 위 이름은 없앴다. 팝업(ContactDialog)은 렌더링하지 않는다.
  // 테마(어두운 기본/밝은)는 main.jsx 의 ThemeProvider 가 메인과 /workflow 에 함께 적용한다.
  return (
    <div className="shell" id="top">
      <SiteHeader />
      <StickyBar />
      <main>
        <ProfileSection revealEnabled={revealEnabled} />
        <SkillsSection revealEnabled={revealEnabled} />
        <CoreSection revealEnabled={revealEnabled} />
        <CareerSection revealEnabled={revealEnabled} />
        <CasesSection revealEnabled={revealEnabled} />
      </main>
      <SiteFooter />
    </div>
  );
}
