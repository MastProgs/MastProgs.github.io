// 이력서 데이터(소개, 회사 경력, 학력, 기술, 연락처 칸). 화면 구성은 컴포넌트가 맡고, 사실 문구는 이 파일에서만 고친다.
// AI-NOTE: 근거 자료는 본인이 작성한 이력서(회사별 주요 업무 포함)와 자기소개서다. 회사·기간·역할·업무는 원문 범위를 넘겨 쓰지 않는다.
// 기간이 겹치는 항목(리치포켓과 알레프리서치코리아)도 원문 그대로 두며, 근무 연수를 합산하거나 겹친 이유를 추측해 쓰지 않는다.
// 지원처 이름이 들어간 제목과 개인 신상 항목(출생일, 군 복무, 거주지 등)은 공개 포트폴리오에 넣지 않는다.

export const PRESENT_LABEL = "현재";

export const PHOTO = Object.freeze({
  src: "/profile/myface4.png",
  width: 1086,
  height: 1448,
  alt: "김형준 프로필 사진",
});

export const ABOUT = Object.freeze({
  index: "01",
  heading: "소개",
  headline: "QA에서 개발자로, 그리고 AI로 일의 범위를 넓혀 왔습니다",
  story: [
    "게임업계에서 처음 맡은 일은 QA였습니다. 문제를 찾는 일도 흥미로웠지만 그 문제를 직접 고치는 개발자가 되고 싶어 회사를 그만두고 개발을 공부했고, 다시 게임업계로 돌아와 MMORPG·라이브 게임 서버와 웹 서버를 개발했습니다.",
    "AI의 발전 속도를 보고 이 분야를 제대로 배워야겠다고 판단해, ChatGPT가 등장하기 전 회사를 그만두고 대학원에서 인공지능을 공부했습니다. 이후 1인 창업으로 웹·Android 서비스를 직접 기획·개발·배포했고, 한국콜마·KETI와 장기 계약을 맺고 외주 업무를 진행하고 있습니다.",
    "한 가지 직무의 경계 안에서만 문제를 보지 않고, 모르는 영역을 배워 실제 결과로 연결하는 것이 제 일하는 방식입니다.",
  ],
  valuesHeading: "일하는 기준",
  values: [
    {
      title: "누구의 어떤 일을 줄일지 먼저 정합니다",
      body: "자동화 자체보다 자동화로 얻으려는 변화가 분명해야 합니다. 그 일에 맞게 입력과 역할, 검증 범위를 좁힌 시스템을 만듭니다.",
    },
    {
      title: "빠른 결과만큼 되돌릴 수 있는 구조를 봅니다",
      body: "AI가 빠르게 만든 결과도 그대로 믿지 않습니다. 오류를 발견하고 되돌려 고칠 수 있는 검증 단계를 함께 설계합니다.",
    },
    {
      title: "사람이 판단할 경계를 나눕니다",
      body: "매 단계를 사람이 승인하면 병목이 됩니다. 시스템이 스스로 검증할 부분과 사람에게 남길 판단을 구분합니다.",
    },
  ],
  highlightsHeading: "대표 경험",
  // href 는 같은 페이지의 사례 카드나 회사 경력 섹션으로만 연결한다(외부 링크 없음).
  highlights: [
    { label: "AI 개발 자동화", text: "Master AI 기반 작업 분배·교차 검토·실사용 QA·오류 복구 절차 구축", href: "#case-agentworkflow", linkLabel: "사례" },
    { label: "연구용 MLOps", text: "한국전자기술연구원 측정 데이터 플랫폼의 기본 서버 구축·외주 협업·연구원 운영 인계", href: "#case-keti", linkLabel: "사례" },
    { label: "현업 요청 대응", text: "이메일·Teams 요청을 AI 초기 작업으로 연결하고 최종 결과를 직접 검토·배포", href: "#case-intake", linkLabel: "사례" },
    { label: "게임 서비스", text: "게임 서버·운영 도구·웹 서버 개발과 라이브 서비스 대응", href: "#career", linkLabel: "경력" },
  ],
});

// AI-NOTE: 사용자가 직접 준 포트폴리오 주소. 외부 링크 금지 규칙의 유일한 예외이며, 이 상수와 정확히 같은 값만 링크가 된다.
// 주소를 바꾸거나 다른 외부 주소를 추가하려면 사용자 확인과 tests/privacy.test.mjs 예외 검사 수정이 함께 필요하다.
export const PORTFOLIO_URL = "https://github.com/MastProgs";

// AI-NOTE: 이메일·전화 칸은 의도적으로 비워 둔다. 본인이 나중에 value 만 채우면 소개 섹션과 연락 대화상자에 같이 표시된다.
// 값은 일반 텍스트로만 보여 주고 mailto/tel 링크로 만들지 않는다. 링크는 profile 칸의 PORTFOLIO_URL 하나뿐이다(contactHref).
// 값을 채우면 tests/privacy.test.mjs 의 빈 연락처 검사와 이메일·전화번호 패턴 검사도 함께 고쳐야 한다.
export const CONTACT = Object.freeze({
  heading: "연락처",
  buttonLabel: "연락",
  emptyValue: "준비 중",
  emptyNote: "연락처는 준비 중입니다. 입력되면 이 자리에 표시됩니다.",
  fields: Object.freeze([
    Object.freeze({ id: "email", label: "이메일", value: "" }),
    Object.freeze({ id: "phone", label: "전화", value: "" }),
    Object.freeze({ id: "profile", label: "포트폴리오", value: PORTFOLIO_URL }),
  ]),
});

export const CAREER = Object.freeze({
  index: "04",
  heading: "회사 경력",
  lede: "게임 QA에서 서버 개발로, 이후 창업과 서비스 운영까지",
  currentBadge: "진행 중",
  // 최신순. end 가 null 이면 현재 진행 중이다.
  entries: Object.freeze([
    {
      id: "richpocket",
      company: "리치포켓",
      start: "2023.07",
      end: null,
      role: "1인 창업 · 서비스 개발",
      note: "한국콜마·KETI 장기 계약 외주",
      duties: [
        "MoneyCV 자동트레이딩, 주식마스터, 로또커스텀 등 웹·Android 서비스를 직접 기획·개발·배포",
        "Flutter·Python·Go 기반 서비스 운영 흐름 구축",
        "한국콜마: 웹·IT 인프라 유지보수와 기능 개발",
        "KETI(한국전자기술연구원): 연구용 MLOps 플랫폼의 기본 서버 구축과 운영 인계",
      ],
      tags: ["Flutter", "Python", "Go", "웹·Android"],
    },
    {
      id: "alephresearch",
      company: "알레프리서치코리아",
      start: "2024.04",
      end: "2024.07",
      role: "블록체인 코어 개발",
      note: "",
      duties: [
        "Cosmos SDK 기반 블록체인 코어 개발 참여",
        "Sui Framework 기반 DeFi 스테이킹 서비스 개발 참여",
      ],
      tags: ["Cosmos SDK", "Sui Framework"],
    },
    {
      id: "wemadeplus",
      company: "위메이드플러스",
      start: "2021.09",
      end: "2023.06",
      role: "게임 서버 · 웹 서버 개발",
      note: "",
      duties: [
        "NFT 소셜 플랫폼 Nallary의 서버와 AWS 서비스 환경 구성",
        "피싱 토네이도 챔피언십의 C++ 전환, 로그·덤프 처리, Azure 환경 구성",
        "Python FastAPI 기반 서버 프레임워크·채팅·스케줄러·코드 생성기 담당",
      ],
      tags: ["C++", "Python FastAPI", "AWS", "Azure"],
    },
    {
      id: "joycity",
      company: "조이시티",
      start: "2020.09",
      end: "2021.04",
      role: "라이브 게임 서버 개발",
      note: "",
      duties: [
        "프리스타일 라이브 서비스 리뉴얼과 콘텐츠 개발",
        "반복적인 개발·운영 업무를 위한 개발망 런처와 아이템 지급 도구 구현",
      ],
      tags: ["라이브 서비스", "운영 도구"],
    },
    {
      id: "hanbitsoft",
      company: "한빛소프트",
      start: "2020.02",
      end: "2020.05",
      role: "게임 서버 개발",
      note: "",
      duties: ["Gunslinger Stratos 프로젝트에서 AWS GameLift FlexMatch와 웹 서버를 연결하는 매치메이킹 중개 구조 구현"],
      tags: ["AWS GameLift FlexMatch", "매치메이킹"],
    },
    {
      id: "moaigames",
      company: "모아이게임즈",
      start: "2017.08",
      end: "2019.12",
      role: "MMORPG 서버 개발",
      note: "",
      duties: [
        "TRAHA의 서버 시스템과 콘텐츠를 초기 개발부터 라이브 서비스까지 구현",
        "C# 운영 도구 연동과 MSSQL 프로시저 기반 운영 작업 담당",
      ],
      tags: ["MMORPG", "C#", "MSSQL"],
    },
  ]),
});

export const SKILLS = Object.freeze({
  index: "02",
  heading: "학력·역량",
  educationHeading: "학력",
  education: Object.freeze([
    { id: "kookmin", date: "2023.02", school: "국민대학교 소프트웨어융합대학원", major: "인공지능학과", degree: "석사 졸업" },
    { id: "tukorea", date: "2018.02", school: "한국공학대학교", major: "게임공학과", degree: "학사 졸업" },
  ]),
  // AI-NOTE: 숙련도 막대·별점·백분율 같은 자기 평가 수치는 쓰지 않는다. 이력서의 "활용 가능 기술" 분류를 그대로 옮긴다.
  skillsHeading: "활용 가능 기술",
  groups: Object.freeze([
    { id: "ai", label: "AI", items: ["Codex", "Claude", "OpenClaw", "NanoClaw", "ADK", "CrewAI"] },
    { id: "lang", label: "프로그래밍", items: ["C++", "C#", "Python", "Go", "TypeScript/JavaScript", "Dart", "SQL"] },
    { id: "front", label: "프론트엔드", items: ["Flutter", "Vue", "React", "Electron"] },
    { id: "server", label: "서버·데이터", items: ["IOCP/Asio", "FastAPI", "MSSQL", "MySQL", "Redis", "MongoDB", "SQL·프로시저"] },
    { id: "infra", label: "OS·클라우드", items: ["Windows Server", "Linux/CentOS", "AWS", "Azure", "Naver Cloud Platform", "Firebase", "Cloudflare"] },
    { id: "delivery", label: "형상관리·배포", items: ["Git", "GitHub", "GitHub Actions", "Jenkins"] },
  ]),
});

// 기간 표시. end 가 null 이면 "현재" 로 쓴다. 연수 합산은 하지 않는다.
export function formatPeriod(entry) {
  return `${entry.start} – ${entry.end ?? PRESENT_LABEL}`;
}

export function isCurrentEntry(entry) {
  return entry.end === null;
}

export function contactValue(field) {
  const value = typeof field.value === "string" ? field.value.trim() : "";
  return value === "" ? null : value;
}

// 링크로 보여 줄 주소. profile 칸의 값이 PORTFOLIO_URL 과 정확히 같을 때만 돌려주고, 그 밖의 값은 null(일반 텍스트)이다.
export function contactHref(field) {
  return field.id === "profile" && contactValue(field) === PORTFOLIO_URL ? PORTFOLIO_URL : null;
}
