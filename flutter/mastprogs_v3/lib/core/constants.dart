// 여러 화면이 함께 쓰는 고정 값(경로·문서 제목·저장 키). 바꿀 때는 이 파일 한 곳만 고친다.
// AI-NOTE: 경로 값은 React 상수(DETAIL_ROUTE · SPRITE_ROUTE · SUBTITLES_ROUTE)와 같고, 문서 제목은 React index.html 과
// 각 상세 페이지의 document.title(`${eyebrow} · 김형준`)과 같은 문자열이다. 미지 경로는 404 가 아니라 메인 이력서다.

const String mainRoutePath = '/';
const String workflowRoutePath = '/workflow';
const String spriteRoutePath = '/sprite';
const String subtitlesRoutePath = '/subtitles';

const String mainDocumentTitle = '김형준 · AgentWorkflow 데모';
const String workflowDocumentTitle = 'AgentWorkflow 상세 · 김형준';
const String spriteDocumentTitle = 'Sprite 파이프라인 상세 · 김형준';
const String subtitlesDocumentTitle = 'Voice to SRT 상세 · 김형준';

/// 테마 저장 키(값은 "dark" | "light" 만). 메인과 새 탭 상세 페이지가 같은 키를 읽는다.
const String themeStorageKey = 'mastprogs-theme';

/// 메인 비교 화면 진입점(?state=target): 섹션 등장 애니메이션만 끈다.
const String targetStateQuery = 'target';
