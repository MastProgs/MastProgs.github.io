# v3 AgentWorkflow 데모 체크리스트

이 문서가 진행 상태의 기준이다. 구현 항목은 실제로 작성한 것만 [x], 빌드·테스트·브라우저 검증은 호스트가 결과를 보고하기 전까지 [ ] 로 둔다.

## 구조

- [x] 순수 워크플로우 모델 `src/workflow/model.js` (계획 생성, 단계 상태, 게이트, 기록, 설명 문구)
- [x] 결정적 리듀서 `src/workflow/reducer.js` (타이머 없음, cursor 기반)
- [x] 중앙 상수 `src/workflow/constants.js`, 화면 문구·사례 데이터 `src/content/site.js`
- [x] 훅 분리: `useWorkflowPlayer`(타이머·탭 가림 일시정지), `useAnnouncement`, `useRevealOnce`
- [x] 컴포넌트 분리: header, hero, workflow(stage/transport/mode/timeline/detail/history), cases, profile, footer, modal
- [x] 스타일 분리: `src/styles/*.css`

## 워크플로우 동작

- [x] 단계 이름·순서: 기획, 검수, 개발, 검수, QA, Wiki, 통합 (검수 ID: `review-plan`, `review-dev`)
- [x] 7개 논리 단계(타일·눈금)와 실행 틱(카운터·기록) 분리: 실행 항목은 phaseId 또는 nodeId, phaseIndex 는 노드에서 null
- [x] 직접 처리(계약 반영): 요청 → Master AI 직접 처리 → 응답 3틱, 7단계 ID 와 분리, 7개 타일·눈금 30% 흐림 + "이 경로에서는 생략", 3노드 레인 + "단순 요청은 단계를 늘리지 않습니다", QA 실패 비활성 + "QA 단계가 없는 경로" (이전 개발→검수→통합 해석 폐기)
- [x] 순차: 실패 없음 7단계, 실패 시 QA 결함 → 개발 → 검수 → QA 재수행 후 Wiki 로 10단계, 재작업 타일 "재작업 1회"
- [x] 독립 병렬(계약 반영): 레인 A/B/C 가 각각 기획→검수→개발→검수→QA, 병합 게이트(눈금 5~6 사이), 공유 Wiki→통합 = 8틱, B 결함 시 B 만 개발→검수→QA 3틱 복구 = 11틱, 복구 중 A·C 병합 대기, 모두 통과 전 병합 불가 (이전 공유 기획·7/10틱 해석 폐기)
- [x] 재생 중 타일 선택 시 일시정지(cursor 유지), "실행 위치로" 로 선택 복귀
- [x] 실행 기록 최대 높이 180px 내부 스크롤, 최신 항목으로 자동 스크롤
- [x] 계약 문구·아이콘: 상태 칩 대기/실행 중/일시정지/완료, "다시 실행", "처음으로"(ArrowCounterClockwise), "설명용 실행", 사람 판단 UserFocus(soft blue), 결함 배지 Warning, 단계 간격 1100ms
- [x] 경로 변경·실패 토글 시 처음 상태로 초기화
- [x] 재생/일시정지/초기화/다시 재생/다음 단계, 타이머 정리, 탭 가림 시 일시정지
- [x] 끝에서 done 으로 멈춤(자동 재실행 없음), 일시정지 중 기록 중복 없음
- [x] 단계 탐색 선택 고정 후 재생하면 다시 실행 단계를 따라감
- [x] 완료/대기/결함/복구 대기/생략 상태를 문구와 색으로 함께 표시
- [x] 결함 반환 연결선(UI 요소, 장식 SVG 없음)
- [x] `?state=target`: 순차·실패, 5/10 일시정지, QA 1차 결함, 4단계 완료, Wiki/통합 대기

## 접근성·모션

- [x] 단계 타일 탭 목록: 로빙 tabindex, 화살표/Home/End, Enter/Space(네이티브 버튼)
- [x] 경로 선택 라디오 그룹: 로빙 tabindex, 화살표/Home/End
- [x] polite 라이브 영역 하나, 자동 재생 중에는 결함·재작업·완료만 알림
- [x] 네이티브 `<dialog>` 사례 상세(문제/내 역할/근거/한계): 포커스 이동, 배경 inert, 본문 스크롤 잠금, Esc, 닫기 버튼, 포커스 복귀
- [x] View Transitions 기능 감지 후 사례 이미지 공유 요소 전환, 미지원·동작 줄이기 시 즉시 전환
- [x] 섹션 등장 1회, IntersectionObserver 없거나 동작 줄이기면 항상 보임
- [x] 무한 반복 애니메이션·자동 소리 없음
- [x] 모바일: 헤더 메뉴, 사례 카드 네이티브 가로 스크롤(스크롤 가로채기 없음)
- [x] 600px 이하: 7단계 세로 행(64px), 왼쪽 눈금선·번호, QA→개발 왼쪽 점선 괄호, 결함 반환 문구, 선택된 QA 가 가로로 밀리지 않음
- [x] 600px 이하 독립 병렬: 레인 A/B/C 를 접을 수 있는 `<details>` 그룹 + 병합 게이트 + 공유 Wiki→통합
- [x] 600px 이하: 전송 막대 stage 안에서 sticky, 경로 선택·스위치·버튼 터치 영역 44px 이상, 세로 목록에서 위/아래 화살표 이동(aria-orientation)
- [x] 601~960px(태블릿): 타일 약 148px 유지, 눈금과 함께 가로 스크롤 + scroll-snap, 선택 타일을 스크롤 컨테이너 안에서만 가운데로 맞춤
- [x] 동작 줄이기: 전역 전환·애니메이션 즉시 처리
- [x] showModal 미지원/실패 대체 모드: 배경 형제 inert + aria-hidden, Tab 가두기, Esc 처리, 고정 배치, 닫을 때 복원·포커스 복귀
- [x] 데스크톱 P2: 현재+선택 타일의 선택 막대 제거(기준 화면에 없음), 전송 막대 오른쪽 문구를 계약대로 "설명용 실행"

## 이력서 구성 (사용자 최신 요청: 누구인지 알 수 있게, 연락처는 칸만)

- [x] 중앙 데이터 `src/content/resume.js`: 소개(경력 흐름·일하는 기준·대표 경험), 회사 경력 6곳(기간·회사·역할·업무·태그), 학력 2건, 기술 6분류, 연락처 칸 3개(값 비움)
- [x] 이름 김형준·원본 사진 myface4.png 유지, 연락처 값·주소·생년월일·병역·지원처 제목 없음, PDF 미포함
- [x] 페이지 순서 교정(사용자 최신 지시 "이력서니까 소개 자체를 제일 위로 올려, 그 다음 기술 같은거 적고, 그 다음에 워크플로우 를 메인 설명을 넣고, 이후 회사 이력 등등을 넣어"): 01 소개 → 02 학력·역량 → 03 AgentWorkflow(히어로 설명 + 기존 실행 화면) → 04 회사 경력 → 05 작업 사례 → 푸터. 유일한 h1 은 소개의 이름(김형준), 히어로 문구는 h2 로 낮추고 모양 유지. 헤더·고정 바·모바일 메뉴 링크도 같은 순서. 워크플로우 7단계·실행 번호는 변경 없음. `tests/resume.test.mjs` 에 순서·h1 회귀 검사 추가
- [x] 순서 교정 후 호스트 화면 확인(Codex 캡처 전까지 미완료). 기존 `?state=target` 기준 화면의 stage 위치(약 y440)는 이 교정으로 더 이상 첫 화면 기준이 아님
- [x] 01 소개(이전 03): 사진 + 연락처 칸(빈 값 "준비 중" 점선 칸), 자기소개 3문단, 일하는 기준 3개, 대표 경험 4개(사례·경력 내부 링크)
- [x] 04 회사 경력(번호 유지): 최신순 세로 색인, 회사·기간·역할·업무 모두 항상 표시, 진행 중 항목만 주황 점·"진행 중"
- [x] 02 학력·역량(이전 05): 학력 목록 + 분류별 기술 칩(숙련도 막대·별점·백분율 없음)
- [x] ~~연락 대화상자~~ → 사용자 지시("연락처는 바로 보여야지")로 대체: 소개 상단 신원 영역(이름·직함 → 연락처 칸 `#contact` → 사진)을 긴 소개 글보다 먼저 배치, 390px 에서는 사진을 이름 옆 88px 로 줄여 이름·연락처를 첫 화면에 둠. 헤더·고정 바·모바일 메뉴 "연락" 은 `#contact` 앵커, ContactDialog 는 렌더링하지 않음
- [x] 첫 화면 정체성: 헤더 "이력" 열(소개/회사 경력/학력·역량), 히어로 경력 흐름 한 줄 + 이력 바로가기(히어로 높이 유지 의도)
- [x] 스크롤 400px 이후 고정 섹션 바(이름·섹션 링크·연락), 숨김 시 inert, 앵커 scroll-margin 보정, 모바일 전송 막대 top 보정

## 모션·호환성 (이번 갱신)

- [x] Phosphor 사용 아이콘 전부 비권장 별칭 대신 `*Icon` 이름으로 교체(설치된 2.1.10 선언 확인)
- [x] 경로 선택 표시기 슬라이드(translateX 280ms, ResizeObserver 재측정, 측정 전 항목 배경 유지)
- [x] 경로·실패 토글 변경 시 타임라인 영역 높이+페이드 전환(280ms), 높이 같으면 150ms 페이드
- [x] 결함 타일 1회 2px 흔들림(240ms), 결함·재작업 배지 1회 팝(220ms), 반복 없음
- [x] 사례 레일: 네이티브 가로 스크롤 + scroll-snap center, rAF 기울기(±8deg, 761px 이상·동작 허용 시만), 가운데 카드 활성·목차 강조, 01/04 카운터, 이전/다음 44px 버튼(끝에서 aria-disabled), 목차 클릭 시 레일 안에서만 이동 후 카드 포커스
- [x] 동작 줄이기: 위 효과 모두 즉시 처리 또는 비활성(전역 규칙 + 미디어 쿼리 + JS 측 prefersReducedMotion)

## 계약과 남은 차이 (이번 범위 밖, 알려진 항목)

- [ ] 모바일 단계 상세·실행 기록을 탭으로 전환(현재는 위아래로 쌓인 두 영역)
- [ ] 결함 반환 호를 SVG 경로로 그리기 + stroke-dashoffset 그리기·재생 헤드 호 따라 이동(현재는 CSS 테두리 기반 UI 연결선)
- [ ] 사례 카드 56px 헤더 바 구조(현재 카드 구조 유지)

## 사실·개인정보

- [x] ~~히어로·스테이지·푸터에 "설명용 데모 · 실제 AI 실행 아님"~~ → 계약 변경(사용자 명시 요청): 안내 문구·"설명용 실행"·"(설명용)" 꼬리표·사례 한계의 시뮬레이션 문장·푸터 안내·직함 "AI 워크플로우 엔지니어"(예전 표기 포함) 모두 제거. 이름 "김형준"만 표시, 대체 직함·경고 없음. 헤더 직함 칸은 이름 칸과 합침. 회귀 테스트 `tests/privacy.test.mjs`
- [x] 연락 링크는 소개 첫 화면의 항상 보이는 빈 연락처 칸(#contact)으로 이동하며, 팝업을 요구하지 않음
- [x] 생산성 비율·절감 수치·실서비스 상태·실제 AI API 없음
- [x] `index.html` lang=ko, robots noindex,noarchive, SEO/OG 메타 없음
- [x] Vite server/preview 127.0.0.1 바인딩 + X-Robots-Tag, `public/_headers`
- [x] 원본 이미지(사례 4장, 프로필 사진)와 로컬 Pretendard 폰트만 사용

## 테스트 작성

- [x] `tests/workflow.test.mjs`: 직접 경로 QA 비활성, 순차 복구 순서, 고유 ID, 일시정지/재개/초기화/다시 재생 기록 중복 없음, 병렬 게이트, 토글 초기화, done 동작, target 상태, 알림 억제
- [x] 계약 기준으로 경로 테스트 재작성: 직접 3틱(7단계 미실행), 경로별 실행 총수 3/3/7/10/8/11, 병렬 레인 독립 진행·병합 게이트·B 단독 복구·병합 불가 구간, 타일 선택 일시정지·실행 위치 복귀
- [x] `tests/roving.test.mjs`: 키보드 이동 규칙
- [x] `tests/privacy.test.mjs`: 연락처·외부 호출·SEO·헤더 구조 검사
- [x] `npm test` 스크립트 추가, 기존 `build`·`test:sites` 유지
- [x] `tests/resume.test.mjs`: 이름·사진 유지, 회사 6곳 기간·역할 원문 일치, "현재" 표기·연수 합산 없음, 학력·기술 분류(평가 수치 없음), 연락처 칸 비어 있음, 개인 신상·지원처 문구 없음, 내부 링크 대상 존재
- [x] `tests/rail.test.mjs`: 가운데 카드 계산, 기울기 부호·범위·-0 방지, 가운데 맞춤 스크롤 범위, 이전/다음 끝 처리
- [x] `tests/icons.test.mjs`: Phosphor 는 `*Icon` 이름만 import, 설치된 패키지 선언에 존재
- [x] `tests/privacy.test.mjs` 갱신: 연락처 값 비어 있음, download/PDF 미포함, 이미지 경로에 resume.js 포함

## 호스트 검증 (결과 보고 전까지 미완료)

- [x] `npm test` 통과 (61개)
- [x] `npm run test:sites` 통과 (4개)
- [x] `npm run build` 통과 (빌드 경고 0건) (`dist/client/index.html`, `dist/server/index.js`, `dist/.openai/hosting.json`)
- [ ] 브라우저 1440x1100 `?state=target` 이 시각 기준 이미지와 일치
- [x] 브라우저 키보드 조작(탭 목록, 라디오 그룹, 대화상자 포커스 복귀) 확인
- [ ] 브라우저 모바일 폭(390px) 메뉴, 세로 단계 행, 병렬 레인 그룹, 문서 가로 넘침 없음 확인
- [ ] 브라우저 태블릿 폭(768px) 타임라인 가로 스크롤·선택 타일 가시성 확인
- [ ] 직접 처리·독립 병렬(실패 켬/끔) 재생 끝까지 확인
- [ ] design-qa 재캡처 및 판정 (호스트)
- [ ] prefers-reduced-motion 에서 모든 콘텐츠 표시 확인
- [x] 응답 헤더 X-Robots-Tag 확인 (dev, preview; HTTP 200)
- [ ] 1440x1100 `?state=target` 에서 헤더 "이력" 열·히어로 경력 흐름/이력 링크 추가 후에도 stage 시작 위치(약 y440) 유지 확인
- [ ] 고정 섹션 바: 400px 이후 표시, 숨김 시 Tab 으로 들어가지 않음, 앵커 이동 시 제목 가림 없음, 390px 에서 모바일 전송 막대와 겹침 없음
- [ ] 소개·회사 경력·학력·역량 1440/768/390 배치, 문서 가로 넘침 없음, 390px 첫 화면에 이름·연락처 칸 표시, "연락" 앵커 이동 시 고정 바에 가리지 않음
- [ ] 경로 표시기 슬라이드·타임라인 높이 전환·결함 흔들림 확인, 동작 줄이기에서 즉시 처리
- [ ] 사례 레일: 휠·터치·스크롤바 네이티브 스크롤, 이전/다음·목차·키보드 포커스 시 가운데 맞춤, 760px 이하 기울기 없음

## 워크플로우 요약 + /workflow 상세 페이지 (사용자 최신 요청)

구현(Claude):

- [x] 메인 03 은 `WorkflowSummary`(사람↔Master → 독립 파이프라인·되돌림 → 병합 게이트·통합·Wiki 3단 요약)로 교체, Hero 와 섹션 순서·`#workflow`·번호 유지, "상세 흐름 보기" 는 `/workflow` 새 탭(noopener noreferrer)
- [x] `App.jsx` pathname 분기로 `/workflow`(끝 슬래시 허용) 상세 페이지, 라우터 의존성 없음
- [x] 추가 모듈 `src/workflow-detail/{model,reducer,records}.js` + 예시 데이터 `src/content/workflowDetail.js`, 기존 `buildPlan(mode, failOn)`·리듀서·테스트 API 변경 없음
- [x] 상세 화면 컴포넌트 `src/components/workflow-detail/*`(페이지, 재생 막대, 대화, 레인 보드, 레인 열, 기록 탐색기), 스타일 `src/styles/workflow-{summary,detail}.css`
- [x] 독립 병렬 기본: 사람↔Master 대화 → Master 배정(배정선 레인 순서 지연 전환) → A/B/C 세 레인 모두 펼침(모바일은 세로로 쌓되 펼친 상태)
- [x] 레인별 독립 일정: A 기획 검수 반려→기획 수정→재검수, B 개발 검수 반려→수정→재검수, C QA 실패→개발→검수→QA 재시도, 다른 레인 계속 진행. 되돌림 점선 연결선 + 현재 사유 + 회차 유지, 해결된 되돌림 이력 표시, 무한 반복 없음
- [x] 병합 게이트는 모든 레인 QA 통과 후에만 열림 → 병합 → 빌드 → 통합 QA → Wiki, 이 예시 흐름에서 사람은 범위·권한이 걸린 지점에서만 답함(항상 정확히 두 번이라는 규칙 아님)
- [x] 기록 예시 탐색기: index/current/ledger/timeline/decisions/events.jsonl/state.json, task-planning 라운드, 레인별 01-planning 라운드 JSON + 승인본 plan.md, 02-development 검수 라운드·변경 요약, 03-qa attempt-NNN/result.json·md + issue-ledger.json/md, 04-completed manifest, 04-integration, 05-wiki, raw/invocations(prompt/command/stdout/stderr). 모두 같은 cursor 에서 파생, 새 파일/갱신 표시, 처음으로 누르면 비워짐
- [x] 재생/일시정지/처음으로/다음 단계, 단계당 타이머 1개 정리, 탭 가림 일시정지, done 정지, 44px 조작, 라이브 영역(자동 재생 중 반려·실패·병합·완료만), 동작 줄이기 즉시 처리
- [x] 순차·직접 처리는 상세 페이지 두 번째 탭에서 기존 `WorkflowStage` 재사용(번호·제목 props)
- [x] 기존 타일 배지 넘침 수정: "사람 판단 (필요 시)"·레인 칩·상태 배지 줄바꿈 허용, 타일 안쪽 폭 제한, 타일 최소 높이(글자 잘림 없음)
- [x] 테스트 `tests/workflow-detail.test.mjs`(기획 반려, 개발 반려, QA 복구·원장, 독립 진행, 병합 차단, 기록·이벤트 일관성, 재생·초기화, 라우팅 구성) 추가 및 `npm test` 에 포함, `tests/resume.test.mjs` 순서 검사를 `WorkflowSummary` 로 갱신

호스트 검증(결과 보고 전까지 미완료):

- [x] `npm test`, `npm run build`, `npm run test:sites` 통과
- [x] dev/preview 에서 `/workflow` 직접 진입·새로고침 동작(SPA 대체), Sites 워커에서도 `/workflow` 가 index.html 로 응답하는지 확인
- [x] 1440 에서 세 레인 가로 3열·배정선 정렬, 768/390 에서 세로로 쌓인 펼친 레인, 문서 가로 넘침 없음
- [x] 되돌림 점선이 줄바꿈된 행에서도 끊기지 않음, 기록 탐색기 선택·따라가기·처음으로 비움
- [x] 메인 기존 타일(직접/순차/병렬)의 배지가 첫·마지막 타일 오른쪽 여백 안에 들어옴 재캡처
- [ ] 동작 줄이기·키보드만으로 조작, 탭 가림 시 일시정지

QA 수정(Claude):

- [x] 바깥 재생 영역 클래스를 `.wfd-run`/`.wfd-run__bar` 로 분리(포커스·sticky·모바일 선택자 포함), 레인 단계 행 `.wfd-stage` 에 크림 배경·여백이 번지지 않게 하고 단계 이름을 밝은 글자로 고정
- [x] `state.json` 레인 stage: 배정 전 `null`, `"ready"` 는 READY·병합 레인에만. 배정 전·종료 시점 테스트 추가
- [x] 사람 개입 문구를 "이 흐름에서…"로 한정(고정 두 지점 규칙 아님)
- [x] QA 지적 번호를 실제 형식인 레인 범위 `QF-001` 로 변경(예시 데이터·테스트)
- [x] 호스트: 1440/390 첫 화면 재캡처로 단계 이름 표시·행 전체 폭·되돌림 연결선 확인, `npm test` 재실행

## 최신 사진 정렬 및 검증

- [x] Claude가 원본 사진을 소개 왼쪽 기준선으로 이동하고 이름·연락처를 바로 오른쪽으로 묶음
- [x] PC: 사진/이름 위 기준선 차이 0, 사진/연락처 아래 기준선 차이 0.001px 미만
- [x] 모바일 390px: 사진/이름 아래 기준선 일치, 연락처가 첫 화면 안에 표시되고 문서 가로 넘침 없음
- [x] 제거 요청된 안내 문구와 임의 직함이 실제 DOM에서 표시되지 않음
- [x] Babel AST 기반 UI 문자열 회귀 검사로 AI-NOTE를 보존하면서 제거된 문구의 재등장 차단
- [x] 600px 이하 "사람 판단 (필요 시)" 숨김(1px clip) 폐기, 64px 행 안에 전체 문구 표시(역할 문구가 말줄임으로 양보), 되돌림 괄호 간격 유지
- [x] 호스트: 390px 순차/직접/병렬에서 "사람 판단 (필요 시)" 전체 표시·말줄임 없음·타일 경계 안, 44px 조작·QA 되돌림 괄호·키보드 유지 확인
- [ ] 스크롤 처리 범위 확정 및 적용: 사용자 답변 대기(스크롤바/내부 스크롤/페이지 이동 자체를 구분해야 함)


## 최신 워크플로우 호스트 검증 결과

- [x] 기능/개인정보/모델 61개 + 패키징 4개, 빌드 성공 및 경고 0건
- [x] 1440/768/390 실제 브라우저 레인 배치·문서 가로 넘침 없음
- [x] 병렬 펼침 지연, A 기획 반려/B 개발 반려/C QA 실패, 재수정·회차·병합 대기 확인
- [x] 자동 재생 21/21 종료, 재QA 원장 해결, 다시 실행/초기화 시 대화·기록 초기화
- [x] 기록 파일 Enter 선택·고정·따라가기, 새 파일/갱신 표시
- [x] 메인 상세 보기 새 탭·돌아가기, 프로덕션 상세 주소 직접 진입·새로고침, 검색 제외 헤더/meta
- [x] 최신 design-qa 판정 passed, 실제 화면/기록 캡처 docs/qa 보존
- [x] 최신 로드 콘솔 오류/경고 0건, 최종 git diff/check 및 소스 직접 검토
- [ ] 네이티브 동작 줄이기·document.hidden 전환 실행 검증: 도구 환경 미지원(소스 가드 확인 완료)

## 순차 기획 반려 · 병렬 이질 진행 · WORK SPEC · Seed 계보 (사용자 최신 요청)

- [x] 시나리오 엔진 `getScenario({ route, seed, planReject, qaFail })`(model.js), 기존 export 는 기본 시나리오(병렬·Seed 켬)에 묶어 호환, 리듀서 `SET_OPTION`(옵션 변경 시 cursor·선택·기록 초기화), records 는 시나리오 인자(기본값 병렬)
- [x] 공용 `WorkflowPlayer`: 상단 독립 병렬 탭과 두 번째 탭의 순차·독립 병렬 라디오가 같은 컴포넌트·엔진 사용(예전 7단계 A/B/C 칩 화면 미사용), 직접 처리는 기존 화면 + 옵션 전부 비활성
- [x] 순차·병렬 경로: 사람↔Master 대화 → WORK SPEC(범위·완료 기준·소유 경로) 카드 → 지시 배정 → (Seed) → 레인 기획
- [x] 순차 '기획 검수 실패 시나리오'(기본 켬): 기획 → 반려 → 되돌림 표식 1회 이동(동작 줄이기 정지) → 같은 Planning Author 수정 → 재검수 승인 → 개발. QA 실패 옵션 독립
- [x] 병렬 고정 예시: A 한 번에 통과·READY 대기(틱 4), C 기획 반려 2회·개발 반려 1회 후 READY(틱 10), B 같은 QF-001 QA 실패 2회 후 3회차 통과(틱 12). READY 레인 재실행 없음, 원장은 한 항목 재현 횟수 갱신·독립 QA 통과로만 해결
- [x] 통합: 통합 기획 → 조립 병합(명세에 동결한 A·B·C 순서, 완료 순서는 A·C·B) → 통합 구현 → 통합 검수 → 빌드 → 통합 QA → Wiki → 시작 브랜치 로컬 병합(푸시 없음)
- [x] 'Seed AI 과정 보기'(순차·병렬): 레인별 Author/Reviewer Seed(읽기 전용) → Planning/Development sibling fork, 재작업은 같은 child resume, Seed 재실행 없음, QA·Wiki 독립. 병렬은 계보 보기 옵션임을 안내(실제 `--seed` 와 `--parallel` 동시 사용 불가). 속도·캐시·비용 수치 없음
- [x] 단계 수: 병렬 Seed 표시 켬/끔 모두 30(실제 Seed·계보·기록 동일), 순차 기본(두 실패·Seed) 20, 실패 없음·Seed 끔 14
- [x] `tests/workflow-detail.test.mjs` 재작성(새 일정, 순차 반려 켬/끔, 직접 경로 제외, 두 병렬 화면 공용 엔진, READY 순서·대기, 원장, 통합 순서, Seed 켬/끔·계보·QA 비상속, 기록 일관성, 재생·옵션 초기화)
- [x] 호스트: `npm test` 69개, `npm run build` 경고 0건, `npm run test:sites` 4개
- [x] 호스트: 1440/768/390 WORK SPEC·Seed·순차/병렬·되돌림 캡처, 확장 터치 영역·키보드, 문서/글자 넘침 없음 확인. 네이티브 동작 줄이기·탭 가림 검사는 기존 환경 제한 항목으로 유지


## Master·Seed·반려 최신 호스트 결과

- [x] 순차 검수 반려 옵션 기본 켬/끔·QA 독립·옵션 초기화, 이동 표식 실제 136.236px→0px(1회)
- [x] A 먼저 READY, C 두 번 기획/한 번 개발 반려 후 READY, B 동일 지적 두 번 실패 후 3회차 QA 해결, A/C 대기 유지
- [x] 두 병렬 화면 공용 모델·확장된 3레인·옛 공유 타일 미사용
- [x] Master 명세 선행·역할별 읽기 전용 Seed·sibling fork·같은 child resume·독립 QA retry resume·Wiki 비상속
- [x] 순차 Seed 옵션, 병렬 Seed 패널 숨김에도 실제 계보/기록/30단계 유지
- [x] 실제 자동 재생 순차20/20·병렬30/30 종료, 통합→Wiki→최종 병합, 고정 병합 순서 A/B/C
- [x] 직접 처리3/3 및 옵션 중복 제거·모두 비활성, 390/768/1440 넘침 없음·키보드/기록 보기
- [x] 69+4 테스트·빌드 경고0·최신 콘솔0·noindex·임시 소스 정리·최종 diff 점검
- [x] design-qa 최신 passed 및 docs/qa/master-seed-final.jpg 보존

## 경로 선택 하나 · 음악 재생기형 프레임 조작 (사용자 최신 요청)

- [x] 위쪽 '독립 병렬 / 순차·직접 처리' 탭 제거, `/workflow` 에서 `WorkflowStage` 미마운트. 경로 선택은 `WorkflowPlayer selectable` 안의 `ModeSwitch`(직접 처리 / 순차 / 독립 병렬, 기본 독립 병렬) 하나
- [x] 직접 처리를 공용 엔진에 추가(`getScenario({ route: "direct" })`): 요청 → Master 직접 처리 → 응답 3프레임, 명세·Seed·검수·QA 없음, 옵션 스위치 대신 이유 한 줄, 기록 `01-direct/change-summary.md`
- [x] 공용 `DetailTransport`: 이전 프레임·재생/일시정지·다음 프레임·처음으로, 0..total 정수 슬라이더(aria-valuetext), 프레임 번호·제목, 0.5/1/2배 속도, '현재 프레임 따라가기'(기본 켬). 쉬는·고정 상태 모두 같은 둥근 판, aria-disabled 경계, 44px 조작, 전역 단축키 없음
- [x] 리듀서 `PREV`·`SEEK`·`SET_ROUTE`·`SET_SPEED`: 이전·위치·다음은 일시정지, 0 은 idle·끝은 done, 끝에서 뒤로 가능, done 에서 재생은 1회 다시 재생(반복 없음), 경로·옵션 변경 시 0 으로 초기화·타이머 정리, 속도 유지
- [x] `src/workflow-detail/frames.js`: 방금 바뀐 노드 전부(`data-frame-id`) + 주 강조 우선순위(반려·QA 실패 → Master·명세·Seed → 레인 → 통합 → 대화), `followScrollDelta`. `useFrameFollow`: 가려지거나 화면 밖일 때만 스크롤(동작 줄이기 즉시), 첫 렌더·초기화·경로/옵션 변경 시 스크롤 없음, 포커스 이동 없음, 휠·터치 후 다음 수동 조작까지 자동 재생 따라가기 멈춤
- [x] 프레임 수: 병렬 30, 순차 기본 20(실패 없음·Seed 끔 14), 직접 3
- [x] `tests/workflow-detail.test.mjs`: 세 경로 이전·위치 경계/일시정지/다시 재생, 경로·옵션 초기화·속도 유지, 타이머 속도·정리, QA 해결 → 되감기 → 열림·미래 QA 파일 없음·다시 앞으로 중복 없음, 병렬 동시 변경 노드 전부·우선순위, 직접 3프레임·옵션 없음, 선택기·재생기 하나, 따라가기 스크롤 계산
- [x] 호스트: `npm test` 82개, `npm run build` 경고 0건, `npm run test:sites` 4개
- [x] 호스트: 1440/768/390 둥근 판(고정 포함), 반응형 배치·문서 넘침 없음, 슬라이더/버튼 키보드·44px 터치 영역
- [x] 호스트: 세 경로 공용 조작·직접 처리 자동 종료·이전/슬라이더·현재 이벤트 복수 강조·가시 영역 따라가기·일시정지 중 재활성화 확인. 네이티브 터치/동작 줄이기/탭 가림은 기존 환경 제한 항목으로 유지


## 프레임 플레이어 최종 검증 (2026-10-04)

- [x] 초기 단일 경로 선택 3개·독립 병렬 기본, 재생기 1개
- [x] 이전/다음/위치 이동·끝에서 이전·옵션/경로 초기화·속도 보존, 현재 프레임 제목/접근성 전체 문구
- [x] 실제 QA 원장 해결→되감기→열림, 미래 QA 파일 2개→0개
- [x] 프레임9 A/B/C 변경 동시 강조·C 반려 우선, 가시 영역 안으로 이동, 조작부 키보드 초점 유지
- [x] 따라가기 끔→켬 재개, 모바일 접근성·44px 영역, 390/768/1440 넘침 없음
- [x] 82+4 테스트·빌드 경고0·프로덕션 진입/새로고침·noindex·최신 콘솔0
- [x] 초기/고정 둥근 플레이어 전후 비교·최신 design-qa passed·docs/qa/unified-player-final.jpg

## 경력 점선 기하 · 다크/라이트 테마 · 픽셀 미리보기 · Task Planning (사용자 최신 요청)

구현(Claude):

- [x] A. 회사 경력 타임라인: 점·가로선·세로선을 `.career-list` 기하 토큰(`--career-dot/rule/line/indent`)에서 계산. 점 중심 = 각 행 border-top 중심(top = -(rule+dot)/2), 세로선은 행마다 자기 가로선 중심 → 다음 가로선 중심, 마지막 행은 세로선 없음(첫·마지막 경계 깔끔). 데스크톱·태블릿·모바일 공통, 6개 회사·기간·업무 유지
- [x] B. 테마: 색 토큰을 `src/styles/theme.css` 한 곳으로(어두운 기본 = 기존 값 그대로, `html[data-theme="light"]` 밝은 값). 상태는 `src/theme/theme.js`(순수: dark|light 허용 목록·저장 키 하나·적용) + `ThemeContext.jsx`(Provider 하나, 다른 탭 storage 이벤트 반영) + `ThemeToggle.jsx`(44px, 헤더·모바일 헤더·고정 바·/workflow 상단). `main.jsx` 가 첫 그림 전에 적용. 메인·/workflow 의 하드코딩 어두운 판 색(재생기·보드·레인·기록·대화상자·사례 레일·태그·경력 점)을 토큰으로 바꿔 밝은 테마에서 의도적으로 밝은 판 + 어두운 글자. 이미지 invert/filter 없음
- [x] B. 개인정보 예외 문서화: 저장은 `localStorage` 의 테마 값("dark"|"light") 하나뿐, 연락처·진행·분석 저장 없음
- [x] B. 헤더·고정 바에서 이름(왼쪽 위)과 "연락"(헤더·모바일 메뉴·고정 바) 제거. 이름·사진·항상 보이는 연락처 칸은 소개, 이름은 푸터에 유지
- [x] C. Hero Pixel Studio 라이브 미리보기(`PixelStudioPreview`, 사례 레일 아래·카드 버튼 밖, "사례 자세히 보기" 로 같은 대화상자): 원본 v8 PNG 28장을 공통 캔버스(여백 1px)에서 최근접 확대로 다시 그림, 이산 팔레트 교체(프리셋 5 + 포인트 색 직접), '추가 외곽선' 켬/끔 + 색, 재생/일시정지·무작위 섞기·현재 모션, 원본 GIF/정지 프레임 병기, 발바닥 줄·기준점 표시
- [x] C. 섞은 주머니로 걷기·달리기·공격 모두 등장·연속 반복 없음, 완전한 사이클 뒤에만 전환(걷기·달리기 2회, 공격 1회), 손대기 전까지만 팔레트·외곽선 자동 연출. 화면 밖·탭 가림·언마운트 시 멈춤, 동작 줄이기면 정지 시작, 크기 제한 캐시·setTimeout 하나
- [x] C. 순수 도우미 `src/pixel/{palette,outline,playback,cache,sprite}.js`, 메타데이터는 `src/pixel/assets.js` 가 JSON import(네트워크 없음). 사례 '한계' 문구를 미리보기 포함 사실에 맞게 갱신, 원본 편집기 캡처 유지
- [x] D. 병렬 전체 Task Planning: WORK SPEC(요청 명세, 레인 미지정) → Task Planning Author 작업축 제안(A 화면·B API·C 이력 카드: 소유 경로·인터페이스·수용 기준·미완료 의존 없음) → Reviewer 검토 승인(독립성·소유 겹침·통합 단계 공유 소유·인터페이스·QA) → Task Contract 동결(병합 순서 A→B→C) → 지시 배정 → 레인별 Seed → 레인 기획. 이벤트 `task`(task-split/review/freeze), `deriveTaskPlan`, 프레임 id `task:split|review|freeze`(Master 등급), 기록 `00-request/task-planning/{proposal-001,round-001}.json`·`task-contract.{json,md}`, 레인 lane-context 는 승인된 계약을 출처로 함, merge.json source = task-contract
- [x] D. 순차는 엔진 Task Planning 없이 WORK SPEC 에 "작업축 1개" 이유 표시, 직접 처리 변화 없음. 범위 질문 기록은 `00-request/scope-question.md`
- [x] D. 프레임 수: 병렬 30 → 33(DISPATCH_STEP 5→8, MERGE_STEP 21→24), 순차 20/18/14, 직접 3 그대로
- [x] 테스트: `tests/theme.test.mjs`(허용 목록·저장 키·차단 저장소·Provider 공유·토글 위치·토큰 완전성·AA 대비·필터 금지), `tests/pixel.test.mjs`(알파/투명 보존·이산 교체·명암 순서·외곽선 원본 보존·가장자리 칼끝·주머니·사이클·캐시·정리·중첩 버튼), `tests/resume.test.mjs` 연락 내비 없음·소개 연락처 유지, `tests/workflow-detail.test.mjs` 새 프레임 수·Task Planning 순서/승인/되감기/프레임/순차 비적용. `package.json` test 스크립트에 두 파일 추가

호스트 검증(완료 · 검증 범위는 최신 design-qa.md 참조):

- [x] `npm test`, `npm run build` 경고 0, `npm run test:sites`
- [x] 1440/768/390 경력 점 중심과 가로선·세로선 정렬(첫·마지막 포함) 실측
- [x] 어두운/밝은 테마 메인·/workflow(대화상자·레일·재생기·레인·기록·옵션) 캡처, 새 탭 테마 유지, 넘침 없음
- [x] 픽셀 미리보기 실제 프레임 로드·팔레트/외곽선 변화·모션 섞기·화면 밖 멈춤·동작 줄이기 초기 정지 분기(소스·단위 테스트)·44px 조작
- [x] /workflow 병렬 33프레임 자동 재생·Task Planning 3프레임 강조/따라가기/제목·되감기 시 계약 파일 사라짐
- [x] 콘솔 오류/경고 0, noindex 유지

## Hero Pixel Studio 확장: 팔레트 세트 2행 · 레이어/프레임 · 어니언 · 기준점 · 골격 (사용자 최신 요청)

구현(Claude, 작성 완료 · 호스트 검증 완료):

- [x] 기존 1행(포인트 색 프리셋 5 + 직접 고르기 + '추가 외곽선'/색) 유지, 아래 2행 `PaletteSetRow`: 원본 내장 팔레트 10종(AAP-64·ENDESGA 64·Resurrect 64·Apollo·ENDESGA 32·Lospec500·CC-29·SLSO8·Pear36·DB32) 선택 + '팔레트 적용 비율' 0..100%. 순서 = 레이어 합성 → 포인트 색 → 외곽선 → 세트(OKLab 최근접, 입력 순서 중복 제거, 동률 앞쪽 — 원본 `postfx/mapping.js`·`color.js`). 세트 견본(현재 프레임에 쓰인 색 표시)·실제 색 점유율 막대/상위 8색·세트 안 픽셀 비율
- [x] 큰 캔버스 = 원본 v8 64 해상도 20레이어 실제 합성(`src/pixel/layers.js`: 원본 `style.js` unpack RLE[개수 u16 LE, 마스터 번호] + sourceFrame 합성 규칙, 색 = PALETTE_DEFS[i-1]). PNG 다시 읽기 없음, 원본 GIF/현재 커서 PNG 비교는 그대로
- [x] `LayerTimeline`: 레이어 20행(위가 앞, composite 는 점선 참조 행) × 현재 모션 프레임, 새 셀/같은 셀/없음, 재생 헤드 열, 눈 버튼 보이기/숨기기, 이름 버튼 선택, 칸 누르면 선택+멈춤, 이전/재생/다음 + 프레임 슬라이더(멈춤), 표는 자체 스크롤
- [x] `StudioInspector`: 선택 레이어 실제 셀 미리보기·셀 상자(큰 캔버스 점선 상자)·'선택 레이어만 보기'·'모든 레이어 원래대로', 어니언(이전 붉게/다음 푸르게, 현재 아래, 켬/끔·불투명도, 걷기·달리기 반복 연결, 공격 끝 없음), 기준선·십자선(pivotX 38·soleRow 79·crownRow 23), 공통 기준점 vs 프레임마다 잘라 가운데 맞춤 비교 + 실제 이동량
- [x] `RigPanel`: 원본 골격 1254 좌표의 기준 자세 + 현재 프레임 rot_world 로 계산한 FK(값 없는 뼈는 그리지 않고 '값 없음'), 뼈·부모·월드 각·기준 대비 표, 접지(plant)·root·rootCells·headGrid, 추가 레이어(견갑 30% 따름 등)
- [x] 커서 하나(`playback`)가 모든 캔버스·타임라인·어니언·골격 수치를 구동. 원본 프레임 길이·섞은 주머니·화면 밖/탭 가림 멈춤·동작 줄이기 초기 정지 분기(소스·단위 테스트) 유지. 가공·대응표·최근접 캐시 모두 크기 제한
- [x] 테스트 `tests/pixel-studio.test.mjs`(데이터·RLE·재합성 = 저장된 composite 참조 28프레임, 여러 레이어 동시 변화, 숨김/격리, 10세트 100% 소속·알파, 0% 동일·중간 단조, 어니언 경계·현재 위, 기준선·중심 이동량, 골격 기준각 = attack 0 rot_world·FK 길이·값 없음, 배선) + package.json test 스크립트

디자인 QA 메모(작성자): 데스크톱은 무대+조작판 / 그 아래 작업 화면(타임라인 왼쪽, 보조 화면 오른쪽, 골격 전체 폭). 1100px 이하 한 열, 760px 이하 보조 화면·세트 상세·골격 한 열. 타임라인은 가로·세로 모두 자기 상자 안에서만 스크롤(페이지 가로 넘침 없어야 함). 모든 버튼·범위 입력 44px.

호스트 검증(완료 · 검증 범위는 최신 design-qa.md 참조):

- [x] `npm test`(새 `pixel-studio` 포함), `npm run build` 경고 0, `npm run test:sites`
- [x] 원본 저장 합성 셀 28프레임과 색 번호 일치(스타일링된 원본 PNG/GIF는 비교 참조), 세트·비율 0/50/100% 변화, 외곽선+100% 세트 색
- [x] 타임라인 재생 헤드 동기·칸/슬라이더/이전·다음 멈춤, 레이어 숨김/격리/원래대로, 어니언 공격 경계, 기준선 토글, 골격 패널 각도 갱신, 밝은/어두운 테마
- [x] 1440/768/390 페이지 가로 넘침 없음, 콘솔 오류 0

## 스프라이트 요약(메인 04) + /sprite 상세 페이지 (사용자 최신 요청)

구현(Claude, 작성 완료 · 호스트 검증 완료):

- [x] 메인 순서 01 소개 → 02 학력·역량 → 03 AgentWorkflow → 04 스프라이트(`SpriteBrief`, `#sprite`) → 05 회사 경력 → 06 작업 사례 → 푸터. `NAV_LINKS`(모바일 메뉴·고정 바)에 '스프라이트' 추가, 헤더 이력 열·이름·연락 없음 그대로
- [x] `SpriteBrief`: 원본 걷기·달리기·공격 GIF(2배 최근접, 같은 발바닥 줄, 동작 줄이기면 첫 프레임 PNG) + 기술 요약 4줄 + '스프라이트 작업 화면 보기'(`/sprite` 새 탭, noopener noreferrer). `pixel-assets.json` 만 import, 레이어 데이터·타이머·캔버스 없음
- [x] `/sprite`(`SPRITE_ROUTE`, 뒤 슬래시 허용) = `SpritePage`: `/workflow` 형 머리글(이력서로 돌아가기 + 테마 전환), h1 하나, 기존 `PixelStudioPreview` 전체(포인트 색·외곽선, 2행 세트·비율, 20행 타임라인, 프레임·어니언·기준점·중심 비교, 골격, 무작위 재생, 원본 GIF/정지 비교) 그대로, '사례 자세히 보기' = 기존 `CaseDialog`(사례 04 원본 화면 캡처)
- [x] 사례 레일에서 미리보기 마운트 제거(사례 04 카드·화면 캡처 근거 유지). `App.jsx` 가 `SpritePage` 를 lazy 청크로 분리(경고 한도 변경 없음)
- [x] 테스트: `tests/sprite-page.test.mjs` 신규, `resume`·`pixel`·`theme` 순서·번호·lazy·Provider 단언 갱신, package.json test 스크립트

호스트 검증(완료 · 검증 범위는 최신 design-qa.md 참조):

- [x] `npm test`, `npm run build` 경고 0(메인·/sprite 청크 각각 500KB 미만), `npm run test:sites`
- [x] `/sprite`·`/sprite/` 직접 진입·새로고침, 뒤로 가기 링크, 테마 유지(새 탭), 사례 대화상자 열기/닫기
- [x] 메인 04 GIF 재생·동작 줄이기 정지 분기(소스·단위 테스트), 1440/768/390 가로 넘침 없음, 고정 바 링크 이동, 콘솔 오류 0
- [x] /sprite 에서 기존 픽셀 검증 항목(28프레임 합성 일치, 100% 세트·0% 동일, 원본 정지 프레임 커서 동기, 44px 눈·프레임·레이어 이름) 회귀 없음

## /sprite 팔레트 적용 비율 기본 100% (사용자 최신 요청)

- [x] 중앙 상수 `DEFAULT_PALETTE_RATIO = 100`(`src/content/pixelStudio.js`, `DEFAULT_SET_ID` 옆), `usePixelPreview` 초기값으로 사용. AAP-64 기본·0..100 슬라이더 의미·0% = 포인트 색/외곽선 결과 유지
- [x] `tests/pixel-studio.test.mjs` 기본값 계약 테스트 추가
- [x] 호스트: `npm test`, `npm run build`, `npm run test:sites`
- [x] 호스트: /sprite 새로 열기 시 AAP-64 100% 표시·적용, 직접 0%→100% 조절 확인

## 최종 호스트 검증 — 2026-10-04

- [x] 120개 단위·정책 테스트 + Sites 패키징 4개 = 124개 통과. 최종 빌드 경고 0, 메인 437.46KB / SpritePage 308.75KB(경고 한도 변경 없음).
- [x] 원본 28프레임 재합성 = 저장 합성 셀, 실제 19부위 + 숨김 합성 참조 행, 팔레트 10종 100% 소속·0% 기존 색 결과 유지·알파 보존.
- [x] 메인 순서·04 스프라이트 GIF 3개·새 탭 링크, /sprite 직접 진입·새로고침·테마 상속·원본 사례 대화상자·Escape 초점 복귀.
- [x] main 390/768/1440, /sprite 모바일·데스크톱, /workflow 모바일 Task Contract 동결에서 가로 넘침 없음. 프레임 최소 폭 약44px(부동소수점 반올림), 짧은 레이어 이름 버튼도 넓은 영역 확보.
- [x] 회사 6행 점 중심/가로선 오차 0~0.05px, 마지막 세로선 없음. 헤더·고정 바 이름/연락 없음, 소개의 이름·사진·연락처 칸 유지.
- [x] Task Planning 제안→검토→동결, 실제 계약 파일 2개→되감기 0개, 병렬 33/33 자동 종료, 모바일 현재 task:freeze가 고정 재생기 아래 가시 영역에 위치.
- [x] 최종 콘솔 오류/경고 0. dev /sprite, production / · /sprite · /sprite/ · /workflow HTTP200 + noindex,noarchive. 프로덕션 /sprite 렌더 확인, 임시 preview 서버 종료·뷰포트 override 복원.

네이티브 OS 동작 줄이기/탭 가림 전환은 브라우저 도구가 제공하지 않아 강제 전환 실험을 하지 않았다. 초기 정지·정지 이미지·visibilitychange·타이머 해제 분기는 소스와 단위 테스트로 확인했다. 기본 메인 GIF는 네이티브 재생이며, 전체 편집 화면의 타이머는 /sprite에서만 동작한다.

## 대표 주제를 소개 안으로 (사용자 최신 요청)

"워크플로우 제목글씨가 너무 커 … 이력/학력역량/회사경력 바로 가는 게 너무 뜬금없이 … 이 개념이 나를 대표하는 주제 … 내 사진과 연락처 바로 아래쪽 라인 … 그 아래에 QA에서 개발자로 … 설명식". 이 항목이 위 54·60·112·122행의 히어로 배치·크기를 대체한다.

- [x] `App.jsx` 에서 학력·역량과 `WorkflowSummary` 사이의 독립 `Hero` 제거. 02 다음 곧바로 03 요약(`.wf-summary` 위 간격 72px 직접 지정)
- [x] `Hero.jsx` → `ProfileTheme`(같은 파일, `HERO.arc`·`HERO.lines` 재사용): 01 소개 안, 사진·이름·연락처 줄 바로 아래·"QA에서 개발자로" 제목/소개 글 앞, 같은 왼쪽 기준선. h2, 28px(≤760px 22px 두 줄)로 이름보다 작게
- [x] 본문 중간 이력 바로가기 묶음(`hero__resume`)·설명 문단·버튼 2개 제거(`HERO.lede/primary/secondary` 삭제). 헤더 "이력" 열·고정 바·모바일 메뉴 변경 없음
- [x] `header-hero.css` 의 `.hero*` 규칙을 `.profile-theme*` 로 교체, AI-NOTE 갱신(App·ProfileSection·Hero·site.js·CSS)
- [x] `tests/resume.test.mjs`: 주석 제외 소스로 App 에 Hero 없음·Skills 다음 WorkflowSummary, 소개 순서 이름→연락처→사진→대표 주제→QA 제목→소개 글, 대표 주제 h2·인라인 nav 없음, h1 1개
- [x] `AGENTS.md` 에 "Profile theme placement" 지속 선호 추가, 예전 히어로 문구는 superseded 표시
- [x] 호스트: `npm test` 121개 + `test:sites` 4개 = 125개, `npm run build` 경고 0
- [x] 호스트: 390/768/1440 배치 실측, 1280 다크·라이트 소개 캡처와 390 모바일 캡처 비교(이전: `profile-theme-intro-before.jpg`, `profile-theme-hero-before.jpg`). 가로 넘침 0, 첫 화면 이름·연락처 유지, 대표 주제 데스크톱28px/모바일22px(이름34px).

## 대표 문구 교체 · 사례 순서 · Voice to SRT · 스프라이트 외곽선/원본 색상 · 장시간 재생 멈춤 (사용자 최신 요청)

구현(Claude, 작성 완료 · 호스트 검증 완료):

- [x] 대표 주제 문구를 정확히 "불필요하게 반복하는 일을 검증된 자동화 AI 워크플로우로"(`HERO.lines` 두 줄, 문장부호 추가 없음)로 교체, 줄 사이 JSX 실제 공백(CSS `::before` 제거). 같은 위치(소개 안, 사진·연락처 아래, QA 소개 위). 데스크톱 `clamp(32px, 3.4vw, 44px)`·굵기 800 두 줄, ≤760px `clamp(22px, 6.4vw, 30px)`(390px 에서 둘째 줄 한 줄 목표). 예전 "이름보다 작게" AGENTS 규칙 대체
- [x] 사례 순서 01 AgentWorkflow → 02 Hero Pixel Studio → 03 Voice to SRT(새 `case-subtitles`) → 04 KETI → 05 현장 요청 처리. 기존 id 유지, 카운터·목차는 `CASES` 에서 계산, 사례 번호를 언급한 AI-NOTE 갱신. 메인 6섹션·`/workflow`·`/sprite` 변경 없음
- [x] 사례 매체 두 종류: 원본 이미지(기존 근거·캡션·대화상자 포커스 그대로) / 처리 원리 도식(`mediaKind: "diagram"`, `CaseDiagram` = 의미 목록 + Phosphor 아이콘, 캡션 "처리 원리 도식 · 원본 문서와 소스 기준"). 원본 앱 화면 캡처는 만들지 않음. 대화상자에 상세 페이지 새 탭 링크(상세가 있는 사례만)
- [x] `/subtitles`(`SUBTITLES_ROUTE`, lazy `SubtitlesPage`, 끝 슬래시 허용): `/workflow` 형 머리글·h1 하나·테마, 소개(개발 중 · 기능 구현) → 처리 흐름 8단계(실행 위치: 로컬/로컬 GPU/외부 CLI/사람) → 과정 따라가기 → AI가 하는/하지 않는 일 + 제안 허용 필드 → 편집기 기능 → 구성·데이터 위치 → 쓰임. 사례 요약 대화상자(자기 링크 숨김). 메인 섹션·내비게이션 추가 없음
- [x] 과정 따라가기(`SubtitleWalkthrough`): 가상 예시 대사 고정 데이터(`WALKTHROUGH_FIXTURE`, 단어 12개)로 6단계(음성 인식·위험 표시 → 단어 정렬·발화/화면 문구 분리 → VAD 표시 보정 ≤0.3초 → AI 나누기·Codex/Claude 토론 2회·합의만 반영 → 교정 제안 수락/보류/되돌리기·재정렬 필요 표시 → SRT). 공용 시간축에서 단계마다 새 요소 강조, 이전/재생/다음/처음으로(누를 때만 재생, 끝에서 멈춤, 탭 가림 멈춤). 실제 인식·네트워크·업로드·저장·오디오 없음
- [x] 순수 모듈 `src/subtitles/model.js`(단어 → 자막 시각, 같은 글자 문장 검증·시간 필드 거부·단어 중간 거부, 쉼 = 단어 간격과 VAD 쉼 중 긴 쪽, 0.1초 소리 크기, 표시 보정, 제안 검증, 결정 반영, SRT, 단계 리듀서), 내용 `src/content/subtitles.js`(원본 README·wiki·소스 기준 사실, 해시는 `docs/reference/voice-to-srt/source-facts.json`)
- [x] 외곽선 자동/직접(`src/pixel/studio.js` `styleReducer`·`effectiveOutlineColor`): 어두운 테마 = 기존 프리셋 색, 밝은 테마 = 프리셋 `outlineLight` 어두운 색, 직접 고른 색은 프리셋·테마·자동 연출이 덮지 않음, '자동 색' 버튼으로 복귀, 켬/끔 독립. 색 입력·캔버스·캐시 키가 같은 유효 색 사용
- [x] 2행 팔레트 세트 맨 앞 '원본 색상'(`SOURCE_SET_ID`, 매핑 건너뜀, 1행 '원본'과 별개): 비율 슬라이더 비활성(값 보존)·"—" 표시, 견본 = 현재 출력 색, 세트 안 비율 숨김. 기본 AAP-64·100% 유지, 알 수 없는 id 만 첫 세트로
- [x] 장시간 재생 멈춤 원인 수정: 큰 RGBA 배열·훅 반환 객체 전체를 props 로 넘기지 않음(`PixelCanvas` = `paint`·`kind`·문자열 `frameKey`, 이미지 ref 는 레이아웃 효과에서만 갱신), `LayerTimeline`·`StudioInspector` 좁은 props, 동작 객체 메모. 주머니 꺼냄은 `planTick` 으로 갱신 함수 밖 한 번(오래된 커서 가드). 색 설정은 재생을 멈추지 않음. 개발 모드 전용 `trimOwnedTimings`(이 화면 컴포넌트 이름별 상한, 전역 지우기·가로채기 없음, StrictMode 유지). 크기 제한 캐시 유지
- [x] 테스트: `tests/pixel-runtime.test.mjs`(원본 색상 우회·알파·기본값, 외곽선 자동/직접·대비, 밝은 외곽선 + 100% 세트 소속, 색 설정 비멈춤, StrictMode 순수 재생 칸·오래된 커서, 가벼운 props, 타이밍 상한·정리), `tests/subtitles.test.mjs`(단어 시각 끊기, 문장 검증, 쉼·소리 크기, 표시 보정, 제안 필드, 결정·SRT, 단계 재생기, 고정 작은 데이터, 경로·lazy·h1, 무네트워크, 사실·금지 문구, 사례 순서·이미지·도식). `resume`·`pixel-studio` 갱신, package.json test 스크립트

호스트 검증(완료):

- [x] `npm test`, `npm run test:sites`, `npm run build` 경고 0(메인·/sprite·/subtitles 청크 경고 한도 변경 없음)
- [x] 소개 대표 문구 390/768/1440 다크·라이트: 첫 화면 연락처 유지, 390px 둘째 줄 한 줄, 가로 넘침 0
- [x] 사례 레일 01–05 순서·카운터·목차, Voice to SRT 도식 카드·대화상자(포커스·Esc·복귀)·새 탭 링크, 원본 이미지 사례 회귀 없음
- [x] `/subtitles`·`/subtitles/` 직접 진입·새로고침, 단계 이동·재생·수락/보류/되돌리기·SRT 반영, 다크/라이트, 390/768/1440 넘침 없음, 콘솔 0
- [x] /sprite 밝은 테마 자동 외곽선(어두운 색)·직접 색 유지·'자동 색' 복귀, '원본 색상' 선택 시 매핑 없음·비율 비활성, AAP-64 100% 기본
- [x] /sprite 새로 고친 뒤 장시간 재생 스트레스(이전 재현 7분 이상): 멈춤·DataCloneError 없음, 색 설정 변경 중 재생 유지
## 최종 검증 — React 시안 우선 완성 (2026-10-04)

- [x] 사용자 기술 결정: 현재 메인·/workflow·/sprite·/subtitles는 React + Vite 시안으로 먼저 완성. 원본 Voice to SRT 앱은 Electron + Go + Python/CUDA이고 별개다.
- [x] 단위·정책 테스트144 + Sites 패키징4 =148개 통과. 최종 빌드 경고0, 메인457.58KB·SpritePage313.43KB·SubtitlesPage36.88KB, 경고 한도 변경 없음.
- [x] 원문 요청 멘트 정확히 일치(실제 JSX 공백), 소개 내부 위치 유지, 데스크톱 약43px·모바일24px. 390px 각 줄 높이30.24px로 실제 두 줄·연락처 첫 화면 유지, 문서 넘침0.
- [x] 사례 01 AgentWorkflow →02 Hero Pixel Studio →03 Voice to SRT →04 KETI →05 현장 요청 처리. Voice 카드 도식·모달·Esc 초점 복귀·새 탭 상세 링크 확인.
- [x] 원본 색상 선택(매핑 없음·비율 비활성), AAP-64 복귀100%, 원본 포인트 색 별개 유지. 테마 자동 외곽선 밝은 화면 #1c1a2e /어두운 화면 #fff1c9 확인. 직접 선택 색 보존은 순수 모델 테스트로 확인.
- [x] /sprite 새로 로드 후 534초(8분54초) 연속 재생·다수 옵션 반복 조작. 매 확인 시 숨김false·프레임 변화·일시정지 버튼 상태, 최신 오류/경고0. 이후 일시정지 유지·프레임12/12와attack-11.png 동기·재생 복귀까지 확인.
- [x] 자막 6단계 이동, 단어 정렬·VAD 표시 보정·AI 경계 의견/2회 토론·합의 시각·문구 수락→SRT 반영 확인. 같은 글자/시간 필드 검증·보류/되돌리기·재정렬 필요 상태는 테스트 통과. 실제 외부 호출·모델 실행·녹음 전송 없이 원리 설명.
- [x] /subtitles 데스크톱1440·태블릿768·모바일390, 다크·라이트·넘침0. 프로덕션 /subtitles·/subtitles/ 직접 진입 HTTP200 +noindex,noarchive, 프로덕션 화면/최신 콘솔0 확인.
- [x] 기존 DataCloneError 기록은 수정 전 실패 증거로 보존. 최종 콘솔 판정은 작성 완료 후 새로고침 시각부터만. 원본 voice-to-srt 코드/미디어는 실행·수정하지 않음. 임시 production preview 종료·뷰포트 복원.

## 03 핵심 구현 묶음 (사용자 최신 요청)

"메인 화면에서, 3 4 번이 별도로 있는데, 차라리 3번으로 핵심 구현? 뭐 이렇게 묶어서, 하위 항목으로 보여주는게 좋을듯 여기에 srt 도 추가하자". 이 항목이 위 277행의 03 AgentWorkflow·04 스프라이트 별도 섹션 순서와 329행의 "메인 섹션·내비게이션 추가 없음"을 대체한다.

구현(Claude, 작성 완료 · 호스트 검증 완료):

- [x] 메인 순서 01 소개 → 02 학력·역량 → 03 핵심 구현(`CoreSection`, `#core`, h2) → 04 회사 경력 → 05 작업 사례 → 푸터. `CAREER.index` 04, `CASES_RAIL.index` 05(사례 카드 01–05 번호는 그대로)
- [x] 하위 항목(h3, 탭 아님, 모두 펼침) 03.01 AgentWorkflow(`#workflow`, `WorkflowSummary` 재사용) → 03.02 Sprite 파이프라인(`#sprite`, `SpriteBrief` 재사용, 원본 GIF 3개만) → 03.03 Voice to SRT(`#subtitles`, 새 `SubtitlesBrief`). 공통 틀 `CoreItem`(article + 번호 + h3 + 소개), 순서·번호는 `CORE.items`, 묶음 안 하위 목차(44px 칩)
- [x] Voice to SRT 요약: 사례 03 의 처리 도식을 `CaseDiagram` 으로 재사용 + 시간/AI 역할/사람 승인 세 줄(`SRT_BRIEF`) + '처리 과정 자세히 보기'(`/subtitles` 새 탭, noopener noreferrer). `content/subtitles.js`·`subtitles/model.js`·단계 재생기 import 없음
- [x] `NAV_LINKS` 다섯 개(소개·학력·역량·핵심 구현·회사 경력·작업 사례), 헤더 이력 열·이름/연락 없음 그대로. `STAGE.index` 는 예전 `WorkflowStage` 기본값으로 유지
- [x] AI-NOTE 갱신(App·site.js·WorkflowSummary·SpriteBrief·CSS), `tests/resume.test.mjs` 순서·번호·내비 갱신과 구문 트리 기반 묶음 검사(부모 h2 하나·자식 순서·앵커·h3·새 탭 링크·무거운 import 없음), `tests/subtitles.test.mjs` 의 예전 "메인에 없음" 검사 대체
- [x] 호스트: `npm test`, `npm run test:sites`, `npm run build` 경고 0(메인 청크 500KB 미만, 한도 변경 없음)
- [x] 호스트: 390/768/1440 다크·라이트 배치, `#workflow`·`#sprite`·`#subtitles`·`#core` 이동, 세 새 탭 링크, 이전 화면(`core-group-before.jpg`)과 비교, 콘솔 0
호스트 결과: 단위·정책146 + 패키징4 =150개 통과. 빌드 경고0(메인460.00KB, Sprite313.43KB, Subtitles36.88KB). 실제 DOM main 5개 section/about→skills→core→career→cases, #core h2 하나·article/h3 3개·각 /workflow /sprite /subtitles 새 탭 링크 확인. 모바일390·태블릿768·데스크톱1440 넘침0, dark/light, 정상 진입에서 그룹 reveal opacity1. 하위 #subtitles top79.64px로 sticky 아래 표시, SRT 링크가 실제 새 탭 열림, 최신 콘솔0. 상세 페이지 로직과 픽셀 버퍼/개발 타이밍 메모리 보정 코드는 변경하지 않았다. 기존 부모 AGENTS 탐색 Glob은 Claude 도구에서 거부됐으나 호스트 확인 결과 상위 4개 디렉터리의 AGENTS.md는 없었으며, 현재 demo/AGENTS.md와 사용자 제공 규칙은 적용했다.

## 포트폴리오 링크 (사용자 최신 요청)

사용자가 직접 준 `https://github.com/MastProgs` 를 연락처 칸에 넣는다. 예전 "외부 프로필 링크 없음" 규칙의 이 주소 하나에 대한 예외다.

구현(Claude, 작성 완료 · 호스트 검증 완료):

- [x] `resume.js` 에 `PORTFOLIO_URL` 상수, `profile` 칸 라벨 '외부 프로필' → '포트폴리오'(id 유지), 값은 상수. 이메일·전화는 빈 값 유지. `contactHref` 는 profile 칸 값이 상수와 정확히 같을 때만 주소를 돌려준다
- [x] `ContactSlots` 는 `contactHref` 가 있을 때만 새 탭 링크(`target="_blank"`, `rel="noopener noreferrer"`), 그 밖의 값은 일반 텍스트. 사진·이름·배치 변경 없음
- [x] `profile.css` `.contact-slot__link`: 기존 값 글자 크기·줄바꿈 상속, 밑줄과 `:focus-visible` 포커스 링만 추가
- [x] `tests/privacy.test.mjs`: resume.js 의 정확한 상수 선언 한 줄만 외부 주소 검사에서 제외, 다른 파일의 같은 주소 반복 금지, 빈 이메일·전화 검사 유지. `tests/resume.test.mjs`: 라벨/id·정확한 주소·다른 주소는 링크 아님·링크 속성 검사
- [x] AI-NOTE 갱신(resume.js·ContactSlots·privacy 테스트), AGENTS.md 예외 기록
- [x] 호스트: `npm test`, `npm run test:sites`, `npm run build`
- [x] 호스트: 390/768/1440 다크·라이트에서 포트폴리오 링크 줄바꿈·키보드 포커스·새 탭 속성(target/rel), 첫 화면 이름·연락처 유지, 콘솔 0
호스트 결과(2026-10-04): 단위·정책148 + Sites 패키징4 =152개 통과. 빌드 경고0, 메인460.21KB(경고 한도 변경 없음). 실제 표시 '포트폴리오', 정확한 href·target=_blank·rel=noopener noreferrer, 이메일/전화 '준비 중', 키보드 focus-visible 2px 확인. 390/768/1440 다크·라이트 넘침0, 새로 로드한 검증 탭 오류·경고0. 외부 사이트로 이동하지 않고 링크 속성을 검증했다. 개인정보 테스트의 '주소' 단어는 설명 주석과 실제 데이터가 구분되도록 기존 stripComments를 재사용하여 검사했고, 실제 개인정보 패턴은 그대로 유지했다. 증거: docs/qa/portfolio-link-final.jpg. 임시 탭 종료·뷰포트와 원래 dark 테마 복원.

## /subtitles '사례 요약 보기' 다크 테마 흰 글자 (사용자 보고)

원인: `.srt-intro__case { color: var(--stage-ink) }` 가 특이성이 같은 뒤쪽 `.srt-btn { color: var(--ink) }` 에 덮였다. 소개 판 `.wfd-intro` 는 어두운 테마에서도 밝은 stage 판이라 글자가 rgb(243,242,239)로 보였다.

구현(Claude, 작성 완료 · 호스트 검증 완료):

- [x] `subtitles.css`: 단독 규칙을 `.srt-btn` 규칙들 뒤의 `.srt-btn.srt-intro__case` 로 옮김. 기본 stage-line 테두리 + stage-ink 글자, hover·focus-visible 은 stage-ink-3 테두리 + stage-ink 글자(밝은 판에서 안 보이는 `--hover-wash` 미사용). 포커스 링은 기존 `.wfd-intro :focus-visible` 그대로. 공용 `.srt-btn`·테마 토큰·모델·스프라이트·워크플로우 변경 없음
- [x] AI-NOTE(한국어)로 같은 특이성 캐스케이드 함정 기록
- [x] `tests/subtitles.test.mjs`: 기본/hover/focus-visible 규칙이 stage-ink 를 쓰고 페이지 테마 토큰(--ink, --ink-2, --hover-wash)을 쓰지 않으며 같은 상태의 공용 `.srt-btn` 규칙보다 뒤에 있는지, 색을 가진 단독 `.srt-intro__case` 규칙이 없는지 검사
- [x] 호스트: `npm test`, `npm run test:sites`, `npm run build` 경고 0
- [x] 호스트: /subtitles 다크·라이트에서 버튼 기본·hover·키보드 포커스 글자색(stage-ink) 확인, 390/768/1440 넘침 0, 콘솔 0
호스트 결과(2026-10-04): 단위·정책149 + 패키징4 =153개 통과, 빌드 경고0. 다크 모드 실제 글자색 rgb(22,22,22), 소개 배경 rgb(235,233,228) 확인(기존 글자 rgb(243,242,239)). 다크·라이트 모두 기본/hover/focus-visible 글자색 유지, 2px 키보드 포커스 링·사례 창 열림/Esc 닫기·원래 버튼 초점 복귀 정상. 390/768/1440 다크·라이트 문서 넘침0, 최종 로드 이후 콘솔 오류·경고0. 검증 중 CUA 키 입력 한 번이 시간 초과했으나 이후 DOM/같은 사례 창 조작은 정상이며 앱 오류는 없었다. CSS 테스트에서 JS 전용 주석 파서를 사용한 오류는 CSS 블록 주석 처리로 수정 후 전체 테스트 재통과. 임시 탭 종료·뷰포트·원래 dark 테마 복원. 증거: docs/qa/subtitles-button-contrast-final.jpg.

## 용어 통일: 워크플로 → 워크플로우 (사용자 지시)

"자꾸 워크플로 라고 하지말고 워크플로우 라고 해. 문구 전부 변경할 것." 한국어 표기만 바꾸고 영어 식별자(`workflow`, `AgentWorkflow`)·경로·API·시각/모션·동작은 그대로다.

구현(Claude, 작성 완료 · 호스트 검증 완료):

- [x] 화면 문구: `site.js` 역량 항목 "AI 업무 워크플로우 설계", 핵심 구현 lede "직접 설계하고 구현한 워크플로우와 도구입니다.", `PhaseTimeline` aria-label "워크플로우 단계"(예전 `WorkflowStage` 경로)
- [x] 한국어 주석: `site.js`·`App.jsx`·`workflow/constants.js`·`theme/theme.js`·`SpriteBrief.jsx`·`WorkflowSummary.jsx`, 테스트 주석(`resume`·`sprite-page`), 이 계획서 제목·항목. AI-NOTE 는 지우지 않고 표기만 갱신
- [x] 보존: 외부 참고 문서(`docs/reference/*`)와 승인된 시각 계약 `docs/design/claude-visual-contract.json` 은 출처 증거라 원문 유지. AGENTS.md 의 사용자 원문 인용도 그대로
- [x] `tests/privacy.test.mjs`: 금지 직함에 "AI 워크플로 엔지니어"와 "AI 워크플로우 엔지니어" 둘 다 유지. 새 회귀 검사는 JS/JSX 화면 문자열(구문 트리)과 src·public·worker·index.html 텍스트 원문(CSS 는 원문만, JS 파서 미사용)에서 `워크플로(?!우)` 금지
- [x] AGENTS.md 에 최신 용어 표준 기록
- [x] 호스트: `npm test`, `npm run test:sites`, `npm run build` 경고 0
- [x] 호스트: 메인·/workflow·/sprite·/subtitles 에서 바뀐 문구 표시, 넘침·콘솔 0
호스트 결과(2026-10-04): 단위·정책150 + 패키징4 =154개 통과, 빌드 경고0. src/index/public/worker와 dist/client의 이전 표기 검색0. 실제 메인 'AI 업무 워크플로우 설계'·핵심 구현 설명 표기 확인. 메인·/workflow·/sprite·/subtitles의 본문 및 aria-label 이전 표기0, 문서 가로 넘침0, 새 로드 이후 오류·경고0. 기존 올바른 워크플로우가 중복 치환되지 않으며 영어 API·경로·동작 변경 없음. 원문 참조 자료와 금지 문구 검사/정규식 반례는 보존했다. Claude의 프로젝트 루트 검색은 도구 범위에서 거부되어, 호스트가 전체 배포 소스 및 빌드 결과를 직접 검색해 누락 없음을 확인했다. 증거: docs/qa/workflow-wording-final.jpg. 임시 검증 탭 종료.