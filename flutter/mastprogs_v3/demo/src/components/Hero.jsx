import { Fragment } from "react";
import { HERO } from "../content/site.js";

// AI-NOTE: 계약 변경(이력서 요구 반영). 위쪽에 경력 흐름 한 줄을 둔다.
// 사용자 명시 요청으로 데모 안내 pill 은 뺐다. 다시 넣지 않는다.
// AI-NOTE: (갱신, 사용자 최신 지시가 예전 "학력·역량 다음, WorkflowSummary 앞의 큰 히어로" 배치를 대체)
// "워크플로우 제목글씨가 너무 커 … 이 개념이 나를 대표하는 주제 … 내 사진과 연락처 바로 아래쪽 라인 … 그 아래에 QA에서 개발자로 … 설명식".
// 그래서 독립 섹션이 아니라 01 소개 안의 대표 주제 블록이다: ProfileSection 이 사진·이름·연락처 줄 바로 다음, 자기소개 글 앞에 렌더링한다.
// 제목은 h2(유일한 h1 은 소개의 이름). (갱신) 사용자 최신 지시("더 크고 강하게")로 예전 "이름보다 작게" 규칙을 대체해
// 데스크톱에서는 이름보다 크게 둔다(header-hero.css .profile-theme__title).
// 두 줄 사이 공백은 CSS ::before 가 아니라 JSX 의 실제 공백 문자다. 복사·스크린리더에서도 한 문장으로 이어진다.
// 이력/학력역량/회사경력 바로가기 묶음과 오른쪽 설명·버튼 열은 사용자 지시("뜬금없이")로 뺐다. 이력 바로가기는 헤더·고정 바·모바일 메뉴에만 남는다.
// 파일 이름은 기존 참조를 줄이려고 Hero.jsx 를 유지한다. App.jsx 에는 더 이상 마운트하지 않는다.
export function ProfileTheme() {
  return (
    <div className="profile-theme">
      <p className="profile-theme__arc">
        <span className="sr-only">{HERO.arcLabel}: </span>
        {HERO.arc.map((step, index) => (
          <span key={step} className="profile-theme__arc-step">
            {index > 0 && <span className="profile-theme__arc-sep" aria-hidden="true">→</span>}
            {step}
          </span>
        ))}
      </p>
      <h2 id="profile-theme-title" className="profile-theme__title">
        {HERO.lines.map((line, index) => (
          <Fragment key={line}>
            {index > 0 && " "}
            <span className={`profile-theme__line profile-theme__line--${index + 1}`}>{line}</span>
          </Fragment>
        ))}
      </h2>
    </div>
  );
}
