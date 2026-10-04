// 화면 문구와 사례 데이터. 공개 연락처(전화, 이메일, 주소, 생년월일)와 외부 링크는 넣지 않는다.
// AI-NOTE: 사례 문구는 이력서에 근거한 실제 작업만 서술하고, 생산성 비율이나 비용·시간 절감 수치는 쓰지 않는다.
// 소개·회사 경력·학력·역량·연락처 칸 데이터는 src/content/resume.js 에 있다.

// AI-NOTE: 사용자 명시 요청으로 "설명용 데모" 안내 문구와 "AI 워크플로우 엔지니어" 직함을 화면에서 모두 뺐다.
// 대체 직함·슬로건·다른 안내 문구를 새로 만들지 않는다. 이름은 "김형준" 만 표시한다.

// AI-NOTE: (갱신, 사용자 최신 지시 "3 4 번이 별도로 있는데 … 3번으로 핵심 구현 … 하위 항목으로 … srt 도 추가")
// core 는 03 핵심 구현 묶음 섹션이고, workflow·sprite·subtitles 는 그 안 하위 항목의 앵커다(예전 #workflow·#sprite 링크가 계속 맞는다).
export const SECTION_IDS = Object.freeze({
  core: "core",
  workflow: "workflow",
  sprite: "sprite",
  subtitles: "subtitles",
  cases: "cases",
  about: "about",
  // 소개 상단의 항상 보이는 연락처 칸. 사용자 최신 지시로 헤더·고정 바·모바일 메뉴의 "연락" 링크는 없앴고, 칸은 그대로 보인다.
  contact: "contact",
  career: "career",
  skills: "skills",
});

// 이력서 바로가기. 헤더 열이 쓴다(고정 바·모바일 메뉴는 NAV_LINKS).
// AI-NOTE: 사용자 최신 지시("이력/학력역량/회사경력 바로 가는 게 너무 뜬금없이")로 본문 중간(예전 히어로)의 바로가기 묶음은 없앴다.
export const RESUME_LINKS = Object.freeze([
  { href: `#${SECTION_IDS.about}`, label: "소개" },
  { href: `#${SECTION_IDS.skills}`, label: "학력·역량" },
  { href: `#${SECTION_IDS.career}`, label: "회사 경력" },
]);

export const RESUME_NAV_HEADING = "이력";

export const IDENTITY = Object.freeze({
  name: "김형준",
});

export const HEADER_COLUMNS = Object.freeze([
  {
    heading: "하는 일",
    items: ["AI 업무 워크플로우 설계", "멀티 에이전트 검수·QA 체계", "서버·라이브 운영"],
  },
  {
    heading: "배경",
    items: ["QA 엔지니어 출신", "게임 서버·라이브 운영", "AI 석사", "창업·서비스·계약 수행"],
  },
]);

// AI-NOTE: 사용자 지시(이력서 순서)에 맞춰 화면 섹션 순서와 같게 둔다:
// (갱신) 소개 → 학력·역량 → 핵심 구현 → 회사 경력 → 작업 사례. 상위 섹션 다섯 개만 둔다.
// AgentWorkflow·스프라이트·Voice to SRT 바로가기는 03 핵심 구현 안의 하위 목차(CORE.items)가 맡는다.
export const NAV_LINKS = Object.freeze([
  { href: `#${SECTION_IDS.about}`, label: "소개" },
  { href: `#${SECTION_IDS.skills}`, label: "학력·역량" },
  { href: `#${SECTION_IDS.core}`, label: "핵심 구현" },
  { href: `#${SECTION_IDS.career}`, label: "회사 경력" },
  { href: `#${SECTION_IDS.cases}`, label: "작업 사례" },
]);

export const STICKY_BAR = Object.freeze({
  label: "섹션 바로가기",
  // 이 높이(px)만큼 내려가면 고정 바가 나타난다. 계약값 400px.
  revealAfter: 400,
});

export const HERO = Object.freeze({
  // AI-NOTE: 첫 화면에서 이 사람이 누구인지 바로 보이도록 경력 흐름을 한 줄로 둔다. 기간 합산이나 직함 추정 없이 이력서 순서만 쓴다.
  arc: ["게임 QA", "게임 서버·라이브 운영", "인공지능학 석사", "1인 창업·장기 계약 외주"],
  arcLabel: "경력 흐름",
  // AI-NOTE: 사용자 최신 지시로 이 두 줄은 01 소개 안의 대표 주제(사진·연락처 줄 바로 아래)다. 예전 큰 히어로의 설명 문단과
  // 두 버튼(워크플로우 체험·작업 사례)은 같은 내용이 03 핵심 구현의 WorkflowSummary 와 내비게이션에 있어 소개 흐름을 끊지 않도록 뺐다.
  // AI-NOTE: 사용자 최신 지시로 문구를 정확히 "불필요하게 반복하는 일을 검증된 자동화 AI 워크플로우로" 로 바꿨다.
  // 따옴표·마침표 등 문장부호를 덧붙이지 않는다. 두 줄로 나눈 것은 표시용이며 Hero.jsx 가 줄 사이에 실제 공백 문자를 넣는다.
  lines: ["불필요하게 반복하는 일을", "검증된 자동화 AI 워크플로우로"],
});

// AI-NOTE: STAGE.index 는 예전 WorkflowStage 의 기본값(외부 API 호환)으로만 남긴다. 메인 화면의 번호는 CORE(03 + 하위 01)가 정한다.
// STAGE.title 은 핵심 구현 하위 항목 AgentWorkflow 의 제목으로 그대로 쓴다.
export const STAGE = Object.freeze({
  index: "03",
  title: "AgentWorkflow — 요청 하나가 검증된 결과가 되기까지",
  rulerLabel: "단계",
  failToggle: "QA 실패 시나리오",
  failDisabledHint: "QA 단계가 없는 경로",
  reworkHint: "재작업 포함",
  humanLabel: "사람 판단 (필요 시)",
  detailHeading: "선택한 단계",
  followCursor: "실행 위치로",
  historyHeading: "실행 기록",
  historyEmpty: "재생하거나 다음 단계를 누르면 실행 기록이 쌓입니다.",
  directLaneLabel: "직접 처리 경로",
  laneGroupsLabel: "레인별 진행",
  sharedLabel: "공유 단계: Wiki → 통합",
});

// AI-NOTE: 메인 이력서의 워크플로우 요약(사용자 요청: 메인은 짧게, 상세는 /workflow 새 탭). 측정 수치·안내 문구 없음.
export const WORKFLOW_SUMMARY = Object.freeze({
  steps: [
    { label: "사람 ↔ Master AI", text: "사람은 Master AI 한 곳에 요청하고, Master AI가 경로를 정해 작업을 나눕니다." },
    { label: "독립 파이프라인", text: "서로 의존하지 않는 작업은 레인마다 기획·검수·개발·검수·QA를 따로 거칩니다." },
    { label: "병합 게이트 → 통합 · Wiki", text: "모든 레인이 QA를 통과해야 병합하고, 통합 검증 뒤 Wiki에 기록합니다." },
  ],
  returnNote: "검수 반려·QA 실패는 그 레인만 앞 단계로 되돌려 고칩니다.",
  humanNote: "사람은 범위와 권한이 걸린 지점에서만 결정합니다.",
  linkLabel: "상세 흐름 보기",
  linkHint: "(새 탭에서 열림)",
});

export const CASES = Object.freeze([
  {
    id: "case-agentworkflow",
    index: "01",
    title: "AgentWorkflow",
    summary: "Master AI가 경로를 정하고 역할별 AI가 기획·검수·개발·QA·Wiki·통합을 거치는 구조",
    tags: ["멀티 에이전트", "검수·QA", "복구와 재개"],
    image: { src: "/cases/master_overview.png", width: 2200, height: 650, alt: "Master AI가 Seed AI, 기획, 검수, 개발, 검수, QA, Wiki, 통합 단계를 감독하는 원본 구조도" },
    fit: "contain",
    problem: "AI 한 번의 응답을 그대로 쓰면 검토되지 않은 결함이 결과물에 남습니다.",
    role: [
      "사용자는 Master AI 하나와 대화하고, Master AI가 경로와 모델을 고르도록 구조를 설계",
      "기획 → 검수 → 개발 → 검수 → QA → Wiki → 통합 단계와 단계별 감독·중재 규칙 정의",
      "QA 결함은 개발로 되돌려 검수·QA를 다시 거치게 하는 복구·재개 흐름 설계",
    ],
    evidence: "원본 구조도: 단계 감독/중재, 오류 복구와 재개, 최종 보고까지 포함된 전체 lane 구성",
  },
  {
    id: "case-pixel",
    index: "02",
    title: "Hero Pixel Studio",
    summary: "32·64·128px 해상도와 5가지 모션을 비교하고 편집 가능한 Aseprite로 저장하는 도구",
    tags: ["32·64·128px", "5가지 모션", "Aseprite 저장"],
    image: { src: "/cases/hero_pixel_studio_screen.png", width: 1005, height: 1578, alt: "용사 픽셀 스튜디오 편집기 화면. 대기, 걷기, 달리기, 내려베기, 점프 모션을 해상도별로 비교" },
    fit: "cover",
    problem: "픽셀 캐릭터를 해상도와 모션마다 같은 기준으로 비교하고 수정할 수 있어야 했습니다.",
    role: [
      "32·64·128px 해상도를 같은 높이로 나란히 비교하는 화면 구성",
      "대기·걷기·달리기·내려베기·점프 5가지 모션 지원",
      "편집 가능한 Aseprite 파일로 저장하는 흐름 구현",
    ],
    evidence: "편집기 화면 캡처: 해상도·모션 비교 격자와 팔레트·저장 패널",
    limits: "위 이미지는 편집기 화면 캡처입니다. 스프라이트 상세 페이지의 라이브 미리보기는 원본 프로젝트의 레이어·셀·팔레트 세트·골격 데이터로 걷기·달리기·공격 프레임을 다시 그리며, 편집·저장 기능은 포함하지 않습니다.",
  },
  // AI-NOTE: Voice to SRT(사용자 승인 하에 F:/Devlop/voice-to-srt 의 README·docs/wiki·소스만 읽어 정리, docs/reference/voice-to-srt/source-facts.json).
  // 개발 중이지만 아래 기능은 구현되어 있다(사용자 확인). 품질·속도·정확도 수치, 출시 상태는 쓰지 않는다.
  // 핵심 경계: AI 는 끊을 위치(같은 글자의 문장 묶음)와 문구 교정 제안만 돌려주며, 시간 필드는 응답 형식에서 거부된다.
  // 자막 시간은 강제 정렬 단어 시각(+VAD 표시 보정 최대 0.3초)에서 나온다. 원본 앱 화면 캡처가 없어 매체는 처리 원리 도식이다.
  {
    id: "case-subtitles",
    index: "03",
    title: "Voice to SRT",
    summary: "로컬 음성 인식·단어 정렬로 자막 시간을 잡고, AI 교차 검토와 사람의 승인으로 SRT를 완성하는 한국어 자막 도구",
    tags: ["로컬 ASR·강제 정렬", "AI 교차 검토", "사람 승인 편집"],
    mediaKind: "diagram",
    diagram: {
      label: "Voice to SRT 처리 원리 도식: 원본 오디오에서 SRT 까지",
      steps: [
        { id: "audio", label: "원본 오디오", note: "FFmpeg PCM · VAD" },
        { id: "asr", label: "음성 인식", note: "Qwen 한국어 / Whisper" },
        { id: "align", label: "단어 정렬", note: "단어마다 시작·끝 ms" },
        { id: "split", label: "AI 문장 나누기", note: "단어 시각에서만 끊음" },
        { id: "review", label: "교차 검토", note: "Codex ↔ Claude" },
        { id: "human", label: "사람 승인 → SRT", note: "수락 · 보류 · 되돌리기" },
      ],
    },
    problem: "긴 영상의 한국어 대사를 자막으로 만들 때, 인식 문구와 시간을 매번 손으로 맞추고 읽기 좋은 길이로 다시 나누는 일이 반복됐습니다.",
    role: [
      "FFmpeg 음성 추출 → Qwen 한국어·faster-whisper 인식 → Qwen 강제 정렬로 단어 시각을 잡는 로컬 CUDA 파이프라인 구성",
      "AI는 정렬된 단어 시각·쉼·0.1초 소리 크기를 보고 끊을 위치만 고르고, 시간은 단어 시각에서 가져오도록 응답 형식을 제한",
      "Codex·Claude 교차 검토(의견이 갈리면 최대 2회 토론)와 이유가 붙은 교정 제안을 사람이 수락·보류하는 검토 흐름 구현",
      "파형·타임라인·자막 편집(나누기·합치기·실행 취소·찾아 바꾸기)과 SRT 가져오기·내보내기를 갖춘 Go + Electron 편집기 구현",
    ],
    evidence: "원본 저장소의 README·설계 문서·소스 코드를 읽고 정리한 처리 원리 도식입니다. 원본 앱 화면 캡처는 아닙니다.",
    limits: "현재 개발 중인 도구이며, 품질·속도 수치는 제시하지 않습니다. 오디오는 외부로 보내지 않고, AI 교정에는 자막 텍스트·모델 후보·용어·영상 설명과 켜 둔 경우의 영상 화면 몇 장만 전달됩니다.",
    detail: { label: "처리 과정 자세히 보기" },
  },
  {
    id: "case-keti",
    index: "04",
    title: "KETI 연구 데이터",
    summary: "반도체 측정 장비 데이터를 수집해 연구와 엣지 적용으로 잇는 흐름",
    tags: ["기본 서버", "데이터 전처리", "연구자 인계"],
    image: { src: "/cases/mlops_flow.png", width: 2200, height: 410, alt: "엣지 수집, 데이터레이크, 연구 활용, 엣지 적용 네 단계로 이어지는 원본 흐름도" },
    fit: "contain",
    problem: "현장 장비에서 나온 데이터를 연구자가 바로 쓸 수 있는 형태로 모으고 관리할 기반이 필요했습니다.",
    role: [
      "기본 서버와 관리 흐름을 구축하고 연구자에게 인계",
      "TXT 전처리 기능을 실제 서비스에 배포",
      "외주 업체와 협업해 전체 흐름을 맞춤",
    ],
    evidence: "원본 흐름도: 엣지 수집 → 데이터레이크(수집·적재, 기본 서버) → 연구 활용 → 엣지 적용",
    limits: "데이터레이크·학습·모델 관리 전체를 단독으로 만든 것은 아니며, 외주 업체와 협업한 범위입니다.",
  },
  {
    id: "case-intake",
    index: "05",
    title: "현장 요청 처리",
    summary: "현장 요청을 받아 AI가 초기 작업을 하고 사람이 최종 검토·배포하는 운영 구조",
    tags: ["요청 접수", "AI 초기 작업", "사람 최종 검토"],
    image: { src: "/cases/intake_flow.png", width: 2200, height: 410, alt: "요청 접수, 개인 서버, AI 초기 작업, 최종 검토 네 단계로 이어지는 원본 흐름도" },
    fit: "contain",
    problem: "이메일·Teams로 들어오는 현장 요청을 놓치지 않고 빠르게 첫 작업까지 진행해야 했습니다.",
    role: [
      "요청 접수 → 개인 서버 알림 → AI 초기 작업 → 사람 최종 검토로 이어지는 흐름 운영",
      "AI는 내용 확인과 기초 작업까지만 맡도록 범위를 정함",
      "설정 확인과 배포는 직접 검토 후 수행",
    ],
    evidence: "원본 흐름도: 최종 판단과 배포는 사람이 수행하는 운영 구조",
    limits: "AI 결과를 검토 없이 배포하지 않습니다. 처리량이나 절감 시간은 측정해 제시하지 않습니다.",
  },
]);

// AI-NOTE: Voice to SRT 상세 페이지(/subtitles, lazy 청크 SubtitlesPage). 상세 내용과 예시 데이터는 src/content/subtitles.js 에만 있다.
// (갱신, 사용자 최신 지시 "여기에 srt 도 추가하자") 예전의 "메인 섹션·내비게이션에 넣지 않음" 은 대체됐다. 메인 03 핵심 구현 하위
// 항목(SRT_BRIEF, #subtitles)과 사례 대화상자가 모두 새 탭으로 연다. 상위 내비게이션에는 따로 넣지 않는다(핵심 구현 하나로 묶임).
export const SUBTITLES_ROUTE = "/subtitles";

// AI-NOTE: 메인 Voice to SRT 요약. 사례 03(case-subtitles)의 원본 근거 문구만 줄여 쓰고, 처리 도식은 그 사례의 diagram 을 그대로 쓴다.
// subtitles.js(예시 데이터·단계 모델)는 메인 번들에 넣지 않는다. 품질·속도 수치 없음.
export const SRT_BRIEF = Object.freeze({
  title: "Voice to SRT — 단어 시각으로 시간을 잡는 한국어 자막",
  lede: "로컬 음성 인식과 단어 정렬로 시간을 잡고, AI는 끊을 위치와 문구만 제안하며, 사람이 승인해 SRT를 만듭니다.",
  points: [
    { label: "시간", text: "자막 시간은 강제 정렬된 단어 시각에서 가져오고, AI 응답의 시간 필드는 받지 않습니다." },
    { label: "AI 역할", text: "끊을 위치와 이유가 붙은 교정 제안만 돌려주며, Codex·Claude 의견이 갈리면 최대 2회 토론합니다." },
    { label: "사람 승인", text: "교정 제안을 수락·보류하고 되돌릴 수 있으며, 편집한 자막을 SRT로 내보냅니다." },
  ],
  linkLabel: "처리 과정 자세히 보기",
  linkHint: "(새 탭에서 열림)",
});

// AI-NOTE: 사용자 최신 지시로 예전 03 AgentWorkflow·04 스프라이트를 03 핵심 구현 하나로 묶었다(상위 h2 하나, 하위 h3 셋).
// 하위 순서는 AgentWorkflow → Sprite 파이프라인 → Voice to SRT. 세 항목은 탭이 아니라 위에서 아래로 모두 보인다.
// 하위 번호(01–03)는 묶음 안 순서이며, 작업 사례 카드 번호와는 별개다.
export const CORE = Object.freeze({
  index: "03",
  title: "핵심 구현",
  lede: "직접 설계하고 구현한 워크플로우와 도구입니다.",
  navLabel: "핵심 구현 항목",
  items: [
    { id: SECTION_IDS.workflow, index: "01", label: "AgentWorkflow" },
    { id: SECTION_IDS.sprite, index: "02", label: "Sprite 파이프라인" },
    { id: SECTION_IDS.subtitles, index: "03", label: "Voice to SRT" },
  ],
});

// AI-NOTE: 메인 이력서의 스프라이트 요약(사용자 요청: 워크플로우 다음에 짧게, 전체 작업 화면은 /sprite 새 탭).
// 원본 GIF 만 보여 주며 메인에서는 레이어 합성·타이머를 돌리지 않는다. 수치는 원본 데이터에 있는 개수만 쓴다.
// (갱신) 이제 03 핵심 구현의 하위 항목 02 다. 번호는 CORE.items 가 정하므로 여기에는 두지 않는다.
export const SPRITE_ROUTE = "/sprite";

export const SPRITE_BRIEF = Object.freeze({
  title: "Sprite 파이프라인 — 원본 레이어로 다시 그리는 용사 스프라이트",
  lede: "직접 만든 용사 프로젝트의 레이어·셀·팔레트·골격 데이터를 브라우저에서 그대로 합성합니다.",
  previewLabel: "원본 용사 모션",
  points: [
    { label: "레이어 합성", text: "레이어 19개와 셀(걷기 8 · 달리기 8 · 공격 12)을 원본 규칙으로 합성" },
    { label: "색 파이프라인", text: "포인트 색 · 추가 외곽선 → 팔레트 세트 10종(OKLab 최근접) · 적용 비율 0–100%" },
    { label: "프레임 점검", text: "레이어 × 프레임 타임라인, 어니언 스킨, 기준점·발바닥 줄 비교" },
    { label: "골격", text: "원본 골격 좌표와 프레임별 각도, 걷기 · 달리기 · 공격 무작위 재생" },
  ],
  linkLabel: "스프라이트 작업 화면 보기",
  linkHint: "(새 탭에서 열림)",
});

export const CASES_RAIL = Object.freeze({
  index: "05",
  heading: "작업 사례",
  indexLabel: "작업 사례 바로가기",
  railLabel: "작업 사례 목록",
  prev: "이전 사례",
  next: "다음 사례",
  more: "자세히 보기",
});
