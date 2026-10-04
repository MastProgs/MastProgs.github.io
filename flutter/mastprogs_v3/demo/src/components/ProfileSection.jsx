import { ArrowRightIcon } from "@phosphor-icons/react";
import { ABOUT, PHOTO } from "../content/resume.js";
import { IDENTITY, SECTION_IDS } from "../content/site.js";
import { useRevealOnce } from "../hooks/useRevealOnce.js";
import { ProfileTheme } from "./Hero.jsx";
import { ContactSlots } from "./resume/ContactSlots.jsx";

// 01 소개: 상단 신원 영역(이름·연락처 칸 + 원본 사진) 다음에 자기소개·일하는 기준·대표 경험.
// AI-NOTE: 사용자 지시("이력서니까 소개 자체를 제일 위로")에 따라 페이지 첫 섹션이며, 페이지의 유일한 h1 은 이름이다.
// 섹션 번호 줄은 같은 모양을 유지한 채 제목 요소가 아닌 문단으로 둬서 첫 제목이 사람을 가리키게 한다.
// AI-NOTE: 사용자 지시("연락처는 바로 보여야지. 나한테 연락하고 싶으면 바로 보여야 연락할거잖아")에 따라 연락처 칸은
// 대화상자가 아니라 이름 바로 아래에 항상 보이고(#contact), 긴 자기소개보다 먼저 나온다. DOM 순서는 이름 → 연락처 → 사진 → 대표 주제 → 소개 글이다.
// AI-NOTE: 사용자 지시("사진 위치도 좀 다시 잡고. 정렬이 하나도 안되어있고 동떨어진 느낌이야. 가로 세로 전부")에 따라
// 사진은 화면 오른쪽 끝이 아니라 섹션 왼쪽 기준선에 두고, 이름·연락처를 그 바로 오른쪽 한 열로 묶는다(배치는 profile.css 그리드).
// AI-NOTE: 사용자 최신 지시로 "불필요하게 반복하는 일을 검증된 자동화 AI 워크플로우로" 대표 주제(ProfileTheme, Hero.jsx)는
// 사진·이름·연락처 줄 바로 아래, "QA에서 개발자로" 자기소개 앞에 같은 왼쪽 기준선으로 둔다. 순서: 이름 → 연락처 → 사진 → 대표 주제 → 소개 글.
export function ProfileSection({ revealEnabled }) {
  const revealRef = useRevealOnce(revealEnabled);
  return (
    <section id={SECTION_IDS.about} className="profile resume-section" aria-labelledby="about-title" ref={revealRef}>
      <p className="section-title">
        <span className="section-title__index">{ABOUT.index}</span>
        <span>{ABOUT.heading}</span>
      </p>
      <div className="profile__intro">
        <h1 id="about-title" className="profile__name">
          {IDENTITY.name}
        </h1>
        <div id={SECTION_IDS.contact} className="profile__contact">
          <ContactSlots headingId="about-contact-title" className="contact-slots--inline" />
        </div>
        <img
          className="profile__photo"
          src={PHOTO.src}
          width={PHOTO.width}
          height={PHOTO.height}
          alt={PHOTO.alt}
          decoding="async"
        />
      </div>
      <ProfileTheme />
      <div className="profile__body">
        <div className="profile__text">
          <p className="profile__headline">{ABOUT.headline}</p>
          <div className="profile__story">
            {ABOUT.story.map((paragraph) => (
              <p key={paragraph}>{paragraph}</p>
            ))}
          </div>

          <div className="profile__blocks">
            <div className="profile__block">
              <h3 className="profile__block-title">{ABOUT.valuesHeading}</h3>
              <ol className="values-list">
                {ABOUT.values.map((value, index) => (
                  <li key={value.title} className="values-list__item">
                    <span className="values-list__num" aria-hidden="true">{String(index + 1).padStart(2, "0")}</span>
                    <span className="values-list__text">
                      <strong>{value.title}</strong>
                      <span>{value.body}</span>
                    </span>
                  </li>
                ))}
              </ol>
            </div>
            <div className="profile__block">
              <h3 className="profile__block-title">{ABOUT.highlightsHeading}</h3>
              <dl className="highlights">
                {ABOUT.highlights.map((item) => (
                  <div key={item.label} className="highlights__row">
                    <dt>{item.label}</dt>
                    <dd>
                      <span>{item.text}</span>
                      <a className="highlights__link" href={item.href}>
                        {item.linkLabel} 보기
                        <span className="sr-only">: {item.label}</span>
                        <ArrowRightIcon size={14} aria-hidden="true" />
                      </a>
                    </dd>
                  </div>
                ))}
              </dl>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
