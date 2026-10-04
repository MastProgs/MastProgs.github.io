# v3 최신 디자인·기능 QA — 2026-10-04

final result: passed

범위: 경력 선 정렬, 다크/라이트, 헤더 이름·연락 제거, 전체 Task Planning, 원본 스프라이트 기능 확장, 메인 04 요약과 /sprite 상세 분리. 시각·모션·프런트엔드 구현과 모든 UI 보정은 Claude가 작성했고, 호스트는 원본 데이터 추출·검증·서버·QA·기록만 수행했다. 이전 보고서는 docs/qa/design-qa-history.md에 보존한다.

## 기준과 의도된 변경

기준은 승인된 v3의 글꼴·토큰·조작 모양, 원본 hero_pixel_studio_screen.png, 직전 픽셀 미리보기 캡처와 사용자의 최신 배치 지시다. 원본 편집기 화면은 프로젝트의 근거이며 복제할 전체 레이아웃 목표가 아니다. 직전 캡처와 최신 메인 캡처를 한 비교 입력으로 열어 검토했다. 원본 whole-first-screen 시안의 순서는 사용자 지시로 대체됐다.

메인: 소개 → 학력·역량 → 워크플로우 요약 → 스프라이트 요약 → 회사 경력 → 작업 사례. 전체 조작은 /sprite, 워크플로우는 /workflow에 있다. 메인의 색 조절 UI를 단순 제거한 것이 아니라 상세 페이지에 유지한 의도된 구조 변경이다.

## 수정된 발견과 재검증

- 경력 점이 가로선보다 약37px 아래에 있던 문제를 Claude가 공통 기하 토큰으로 보정. 6행 중심 오차 0~0.05px, 마지막 세로선 없음.
- 팔레트를 포인트 색 교체로만 해석한 범위를 수정. 기존 포인트 색·외곽선 1행은 유지, 10개 전체 세트와 적용 비율 2행·실제 색 점유율 추가. 100%는 외곽선 포함 세트 안 색, 0%는 앞 결과 그대로.
- 큰 번들 경고: 전체 데이터/UI를 별도 SpritePage 청크로 분리. 최종 메인437.46KB·상세308.74KB, 500KB 기준 변경 없음.
- 전화번호 검사와 새 main 검사에서 수학 상수·AI-NOTE를 실제 개인정보/실행 코드로 오인하던 테스트를 AST로 보정. 실제 문자열·템플릿·JSX·주석의 연락처 검사 및 실제 무거운 import/타이머 검사는 유지.
- 상세 타임라인의 30px 프레임 버튼과 짧은 이름 버튼을 Claude가 44px 최소 트랙·이름 flex 영역으로 보정. 모바일 재검증에서 프레임 약43.99px(반올림), 이름155px 이상, 페이지 넘침 없음.
- 원본 정지 참조가 항상 첫 프레임을 보여 주던 문제를 현재 커서 PNG로 보정. 걷기2/8→walk-01.png, 공격2/12→attack-01.png 확인.
- 새 상세 소개에 들어간 구현 보증 문장을 제거. 기능과 사용법의 긍정적 설명만 유지.

## 다섯 시각 표면

- 글꼴·타이포그래피: 로컬 Pretendard, 메인 이름 h1 하나·상세 설명 h1 하나, 한국어·긴 경로가 읽히며 깨짐 없음.
- 간격·정렬: 소개 사진·이름·연락처 구조 유지. 경력 공통 선 중심, 원본 모션 3개의 바닥 기준, 데스크톱 요약 2열/태블릿·모바일 1열 확인. 표의 스크롤은 표 안에 한정.
- 색·토큰: 전체 main/workflow/sprite dark/light, 모달·레일·재생기·기록·레이어 상태에 공통 토큰 적용. 원본 이미지 invert/filter 없음. 본문 AA 대비 테스트 통과.
- 이미지: 원본 GIF·PNG·편집기 캡처 보존, 최근접 확대. 실제 19부위+숨김 합성 참조20행을 재합성, 28프레임 모두 저장 합성 셀과 일치. PNG/GIF는 원본의 스타일링된 내보내기이므로 raw 셀과 바이트 동일하다고 주장하지 않는다.
- 문구·내용: 이름·사진과 빈 연락처 유지, 6개 회사·기간·업무 유지. 검색 제외, 삭제 지시한 직함·시연 경고·실행 아님 문구·이모지 없음. 기능별 팔레트 비율·현재 프레임·레이어 설명은 유지.

## 실제 기능 검증

- main #sprite: 워크플로우 다음에 배치, GIF3개 로드, 캔버스0개·무거운 데이터 없음, CTA가 /sprite를 새 탭에 열며 테마 상속.
- /sprite 직접 진입·새로고침: h1 하나·캔버스5·팔레트10개·레이어20행. 메인 색/추가 외곽선/세트/비율/현재 점유율 유지. SLSO8 100%에서8색·세트 안 픽셀100% 확인.
- 재생/멈춤·모션 선택·이전/다음/슬라이더, 원본 참조·타임라인 열 동기. 검 숨기기·단독 보기·모든 레이어 복귀, 어니언 토글·실제 앞/뒤 프레임, 기준선·중심 비교, 리그의 부모·각도·접지 숫자 확인.
- 원본 사례 모달 이미지 확인, Escape 닫기 후 사례 버튼 초점 복귀.
- /workflow WORK SPEC→Task Planning 제안/검토/동결→배정→Seed. 동결 계약 파일2개가 되감기 시0개로 사라짐. 병렬33/33 자동 종료, 통합·Wiki·로컬 최종 병합 단계 존재. 390px task:freeze top770.6/bottom827.6, 재생기 bottom163, viewport844: 현재 노드가 가시 영역에 있다.
- main 390/768/1440 및 상세 모바일·데스크톱 가로 넘침 없음. 헤더·sticky 이름/연락 없음, 소개의 이름·원본 사진·연락처 칸 그대로.
- npm test119 + test:sites4 =123 통과, build 경고0. 최신 dev/production 콘솔 오류·경고0. dev 및 production 라우트 noindex,noarchive, production /sprite 실제 렌더 확인.

## 증거

- docs/qa/sprite-brief-final.jpg: 최종 메인 1440px, 스프라이트 요약과 경력 선 정렬.
- docs/qa/sprite-page-final.jpg: 별도 작업 화면 팔레트/비율/프레임·레이어.
- docs/qa/sprite-phone-final.jpg: 모바일 요약.
- docs/qa/task-planning-final.jpg: 작업 분할·검토·계약 동결.
- 원본 근거: public/cases/hero_pixel_studio_screen.png, docs/reference/pixel/source-provenance.json.
- 추가 dark/light·격리·골격·모바일 증거: C:/WINDOWS/TEMP/v3-demo-qa/의 pixel-expanded-light.jpg, pixel-layer-only.jpg, pixel-rig-light.jpg, sprite-page-mobile-final.jpg, task-planning-phone-final.jpg.

## 검증 범위

네이티브 OS 동작 줄이기와 탭 가림 강제 전환은 도구에 없어 소스·단위 테스트 확인으로 제한했다. 리그는 원본1254좌표의 별도 골격 패널이며 스프라이트 픽셀 위의 실제 렌더러 투영·머리 스냅을 재구현했다고 주장하지 않는다. 원본 각도 없는 뼈는 값 없음으로 처리한다. 메인 GIF의 네이티브 재생은 무거운 합성 타이머와 별개다. 이전의 일반 스크롤 제거 범위 질문은 이번 완료 범위에 포함하지 않는다.

final result: passed
## 팔레트 적용 비율 기본값 100% — 2026-10-04

Claude가 중앙 상수 DEFAULT_PALETTE_RATIO=100과 초기 상태를 변경했다. 새 /sprite 진입에서 AAP-64 100%를 확인하고, 수동 0%→100% 조절과 세트 안 픽셀100% 표시를 확인했다. 새 탭 콘솔 오류/경고0. 테스트120 + 패키징4 =124개 통과, 최종 빌드 경고0. 증거: docs/qa/palette-default-100.jpg.

final result: passed
## 대표 주제를 소개에 통합 — 2026-10-04

Claude가 독립 Hero를 없애고 ProfileTheme을 사진·이름·연락처 줄과 QA 소개 글 사이에 배치했다. 본문 중간의 이력 바로가기·설명/버튼 열을 제거했다. 기존 원본 사진·연락처·QA/개발/AI 경력 설명·일하는 기준·대표 경험·회사 이력과 일반 내비게이션은 유지한다. main의 실제 섹션은 about→skills→workflow→sprite→career→cases다.

같은 비교 입력으로 이전 profile-theme-hero-before.jpg와 최신 profile-theme-flow-dark.jpg를 검토했다. 큰 제목 약70.84px→28px(390px에서는22px), 이름34px보다 작다. 다크·라이트 글꼴·색 토큰·간격과 한국어 문구를 확인했고, 사진 필터는none이다. 테마 블록이 소개 안에만 있고 인라인 nav는0개다. 모바일 이름/사진 아래선 차이0, 태블릿·데스크톱 위선 차이0, 태블릿 사진/연락처 아래선 차이 약0.000004px. 첫 화면 연락처 bottom588.3<844, 대표 주제 다음 QA 설명 흐름. 390/768/1440 문서 가로 넘침0.

121개 단위/정책 테스트 + 패키징4개 =125개 통과, 빌드 경고0(메인436.41KB / SpritePage308.75KB). 테스트 주석 제외는 공유 AST 도우미를 사용해 코드·문자열과 실제 주석을 구분한다. 최신 콘솔 오류/경고0. 증거: docs/qa/profile-theme-final.jpg, profile-theme-light-final.jpg, profile-theme-phone-final.jpg. 이전 큰 히어로 배치 시안은 사용자 최신 지시로 의도적으로 대체됐다.

final result: passed
## 대표 문구·사례 재배열·Voice to SRT·스프라이트 장시간 정지 수정 — 2026-10-04

범위와 구현은 Claude가 작성했다. 사용자가 React 시안을 먼저 완성하도록 명확히 선택했다. 외부 원본 voice-to-srt 문서는 참고 데이터이며 실행 지시는 실행하지 않았다. 원본 프로젝트·사적 녹음/AI 로그/환경 설정은 수정하거나 공개하지 않았다.

### 실제 실패 발견과 수정

이전 짧은 검증은 장시간 정지를 놓쳤다. /sprite에서 DataCloneError: Failed to execute measure on Performance: Data cannot be cloned, out of memory가 실제 발생했다(React19.2 logComponentRender 스택, 2026-10-03T19:28:36.249Z). 당시 열린 모달0·inert0·document.hidden false·재생 표시 일시정지여서 의도된 정지가 아니었다. 설치된 React 소스가 바뀐 props를 깊이3까지 펼쳐 복제하며 삭제하지 않는 것을 확인했다.

큰 RGBA 버퍼/전체 view를 자식 props에 넘기던 경로를 제거했다. PixelCanvas는 작은 키·크기·안정된paint 접근자만 받으며 커밋된 버퍼를 효과에서 읽는다. 스타일 리듀서는 재생을 건드리지 않고, 주머니 draw는 StrictMode 상태 갱신 함수 밖에서 한 번만 한다. 개발 타이밍 기록은 소유 컴포넌트 이름별240개 기준으로만 제한한다. 전역 Performance API 가로채기·오류 무시·StrictMode 제거·의존성 다운그레이드는 하지 않았다.

새로고침 후534초(8분54초) 재생하고 원본/세트/비율/외곽선·테마를 반복 조작했다. cursor가 계속 바뀌고 hidden false·재생 상태 유지, 해당 구간 콘솔 오류/경고0이었다. 끝나서도 일시정지·스타일 변경 중 수동 정지 유지·공격12/12→attack-11.png·재생 복귀가 동작했다. 영구 안정성이나 실제 기기 장기간 벤치마크를 주장하는 대신 이 테스트 구간을 기록한다.

### 기능과 시각 검증

- 새 대표 문구 정확히 "불필요하게 반복하는 일을 검증된 자동화 AI 워크플로우로". 소개 위치 그대로, 크기 desktop 약43px/mobile24px. 390px 두 줄과 연락처 첫 화면·가로 넘침0. 기존 사진·이름·QA 이야기 보존.
- 사례 순서01 AgentWorkflow/02 Sprite/03 Voice to SRT/04 KETI/05현장 요청. 기존id·이미지 유지, 새Voice는 원리 도식이다. 모달Escape 후원래카드 초점 복귀·새 탭 /subtitles 링크 동작.
- 자동 외곽선 light #1c1a2e/dark #fff1c9, 실제입력과그림의색 일치. 직접색은테마/프리셋이 덮지 않으며 자동으로복귀가능. 원본 색상은세트매핑만생략, 색·외곽선독립; 비율비활성/값보존, AAP복귀100%.
- Voice to SRT 사실은 원본 README·wiki·소스와 docs/reference/voice-to-srt/source-facts.json 해시로 확인. 인식과강제정렬은로컬CUDA, VAD표시범위최대0.3초, AI는단어시각/쉼/100ms파형을보고경계제안, 시각은정렬결과에서. 합의경계반영과사람문구수락을구분한다. 예시대사는새로작성한고정데이터이며사적전사나실제AI응답이아니다(내부AI-NOTE로명시).
- /subtitles 6단계에서 정렬단어·표시범위·AI분할안/토론·수락후광장애서→광장에서·SRT시각유지 확인. 원본음성을웹에서처리하거나전송하지않는다. 원본앱의SRT가져오기/내보내기·파형편집·되돌리기·용어/문맥교정·실행구조/쓰임을페이지에서설명한다.
- 1440/768/390 페이지넘침0, 다크/라이트. 로컬Pretendard·기존토큰·현대Phosphor *Icon·원본이미지색보존·읽히는한국어 확인. 주요폰트/공유간격/테마색/이미지선명도/문구 사실성의5표면을확인했다. 긴기술상세제목/표의포함스크롤은의도된구조이며처음보는사용자는상단원리와단계조작으로탐색한다.

### 최종 검사와 증거

144개 테스트+패키징4=148통과, build경고0. 메인457.58KB /Sprite313.43KB /Subtitles36.88KB. noindex/noarchive 유지. production / · /sprite · /subtitles · /subtitles/ HTTP200, 실제prod자막렌더·콘솔0. 임시preview종료·뷰포트복원.

증거: docs/qa/revision-theme-final.jpg, revision-cases-final.jpg, sprite-source-mode-final.jpg, subtitles-principle-final.jpg, subtitles-dark-final.jpg, subtitles-phone-final.jpg. 추가언어·단어정렬 캡처는 C:/WINDOWS/TEMP/v3-demo-qa/subtitles-align-light.jpg. 이전 실패는 위 스택과 ai-log-traces/ai-mistake/my-mistake.md에 보존한다.

final result: passed
## 03 핵심 구현 그룹 — 2026-10-04

사용자 지시로 기존 독립03워크플로우·04스프라이트를03핵심구현으로 통합하고 SRT요약을 추가했다. Claude가 디자인·구현했다. 이전 번호·배치는 의도적으로 대체됐다. 소개/대표문구/사진·연락처, 상세페이지의 모델·재생·외곽선·팔레트·메모리 보정은 그대로다.

- 구조: main 01소개→02학력역량→03핵심구현→04회사경력→05작업사례. 최상위 메뉴5개. 부모 h2 하나, article/h3 03.01AgentWorkflow→03.02Sprite→03.03Voice to SRT, 모두 펼침. 목차는 부모 내부에3개뿐이다.
- 각자 #workflow/#sprite/#subtitles와 /workflow /sprite /subtitles 새 탭 링크 유지. 마지막 CTA가 실제 자막 상세 탭을 열었다. 사례 카드5개 번호는 변경하지 않았다.
- 시각: 기존 로컬Pretendard/토큰/버튼/원본모션이미지 유지, 세 하위항목의 같은 헤더 틀·점선 구분·작은번호로 위계를 표시. 기존 WorkflowSummary와SpriteBrief본문을 재사용, SRT는 기존 CaseDiagram과시간/AI/사람 경계를3줄로 요약. 새그림/사례앱스크린샷을 만들지 않았다.
- main에는 canvas0개·무거운픽셀모델/자막fixture/단계재생기 import없음. 실제위치 사진/name/contact 조건과이미지필터금지·noindex·개인정보 정책 테스트 유지.
- 390/768/1440 문서넘침0. 정상URL 진입·내비클릭에서 부모reveal opacity1, phone에서하위목차3개wrap·SRT도식2열, dark/light확인. 하위SRT앵커 top79.64로 sticky밑에 표시된다. 더이상 항목별독립reveal이 아니라그룹한번등장은의도된 변경이다.
- 단위/정책146+패키징4=150통과, build경고0(메인460.00KB/상세313.43·36.88KB). 최신콘솔오류/경고0, git diff --check통과. 원본/변경후캡처로위계·글꼴/간격·색·이미지선명도·내용을 비교했다.

증거: docs/qa/core-group-final.jpg, core-group-phone-final.jpg, core-srt-phone-final.jpg. 이전은 C:/WINDOWS/TEMP/v3-demo-qa/core-group-before.jpg. 정규사이트 미리보기와 상세페이지 링크는 유지하며 임시 QA뷰포트는 복원했다.

final result: passed