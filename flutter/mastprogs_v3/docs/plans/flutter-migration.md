# React fcdfc01 → Flutter web 기술 이식 계획

## 기준과 소유권

- 기준은 커밋 `fcdfc01050778a34c97294a8455b967daaf168a9`의 `demo/` 실제 코드·데이터·테스트, `demo/AGENTS.md`, `demo/docs/plans/demo.md`, `demo/docs/reference/*`다. 시각 판정은 현재 React 화면 및 Claude의 계약과 QA 캡처를 함께 쓴다. 계약 JSON의 과거 문구보다 최신 코드·테스트·AGENTS 결정이 우선이다.
- Flutter 대상은 `flutter/mastprogs_v3`. 원본 저장소에는 미추적 Flutter scaffold(`lib/main.dart`, `test/widget_test.dart`, `web/`, `pubspec.yaml`, `AGENTS.md`)가 있다. 이 Plan worktree에는 현재 `demo/`만 존재한다. 구현 시작 때 Master가 scaffold를 보존한 상태로 구현 작업 공간에 제공해야 한다. 원본의 미추적 v2 사진, React 스냅샷 및 React 설정 제외 파일도 그대로 둔다.
- 이 문서는 한 개의 논리적 통합 작업이다. Plan 검토·동결 후 Master가 실제 Flutter 화면·상호작용·모션 구현을 Claude에게 배정한다. Codex 개발 Full 실행은 하지 않는다. 사람 검토 전 Flutter 커밋·푸시 금지.
- Flutter 3.41.9 / Dart 3.11.5 설치본을 사용한다. CLI·SDK 업그레이드 없음. 네이티브 Flutter 위젯과 CustomPainter 및 원본 픽셀 바이트로 구현하며 React/JS 런타임·iframe·WebView를 삽입하지 않는다. Deprecated API 금지.
- 코드·Wiki는 이 Plan에서 변경하지 않는다. 아래 체크박스는 구현 후 증거가 통과할 때 갱신한다.

## 범위 및 구조

- [ ] 공통: 네 경로 `/`, `/workflow`, `/sprite`, `/subtitles`와 상세 경로의 연속 끝 슬래시(`/workflow///` 등), 직접 진입·새로고침·뒤로가기. 그 밖의 경로는 404 화면이 아닌 메인 이력서로 보인다(`demo/src/App.jsx:24-29,41-60`). `?state=target`은 현재 React와 같이 메인 reveal만 끄는 비교 진입점이다. 경로 전환 때 프레임 상태는 누출되지 않는다.
- [ ] 테마: 기본 dark, light 전 경로, `mastprogs-theme` 단일 로컬 저장 키에 `dark|light`만 쓰고 읽기 실패는 dark. 새 탭은 같은 테마. 그 외 상태·개인정보·방문 정보 저장 금지. 디자인 토큰은 React `src/styles/theme.css`와 현재 화면을 기준으로 Claude가 이식한다.
- [ ] 콘텐츠: 한국어 원문은 `src/content/{resume,site,workflowDetail,pixelStudio,subtitles}.js` 및 참조 JSON에서 고정 데이터로 옮긴다. 화면 문자열 `워크플로우` 표준, 원래 회사별 기간 겹침·역할·직무 유지, 새 수치·직함·설명용 고지 발명 금지. 변경 가능한 복수 경로 값은 Dart 상수/콘텐츠 모듈 하나로 둔다.
- [ ] UI 접근성: 44px 이상 조작 영역, 명확한 시각 포커스, 키보드 및 터치 동등성, 모달 포커스 격리·Esc·닫은 뒤 원래 카드로 복귀, 이전/다음 경계에서 포커스 보존, 모션 감소와 숨김 탭 처리. 다른 앵커로 이동할 때 페이지 가로 스크롤 탈취 금지.
- [ ] 개인정보/배포: 메인 이름 김형준·원본 사진, 소개 상단의 비어 있는 이메일·전화 `준비 중`, 포트폴리오 칸의 정확한 `https://github.com/MastProgs` 하나만 새 탭 외부 링크. 다른 외부 주소·mailto/tel·원격 폰트·분석·인증·SEO 메타/OG·sitemap·실제 AI/ASR 호출 없음. Flutter 빌드 `index.html`의 `robots noindex,noarchive`와 localhost 응답 `X-Robots-Tag: noindex, noarchive`를 검사한다. 호스팅 헤더는 정적 배포 방식에 맞게 확인하되 기존 React 설정을 수정하지 않는다.

## Flutter web 플랫폼 경계

- [ ] **렌더러·글꼴 네트워크**: 설치된 Flutter 3.41.9의 `flutter build web -h -v`에서 `--[no-]web-resources-cdn` 기본값이 ON임을 확인했다. 구현 빌드는 `flutter build web --no-web-resources-cdn`으로 자체 호스트 CanvasKit을 `build/web/canvaskit/`에 포함하고 생성된 bootstrap의 로컬 선택 및 실제 요청을 확인한다. 설치된 엔진의 `configuration.dart:358-359`는 누락 글리프 fallback 기본 주소가 `https://fonts.gstatic.com/s/`임을 보여 준다. 자체 번들 Pretendard·아이콘 폰트로 화면의 한글/기호/아이콘 글리프를 모두 덮고, Flutter 표준 loader 설정의 `fontFallbackBaseUrl`을 같은 출처의 `/fonts/`로 지정한다. 필요한 fallback 글리프가 있다면 라이선스 확인 후 해당 파일도 로컬 번들한다. 사용자가 허용된 GitHub 링크를 누르기 전의 페이지 로드·로컬 조작에서 외부 요청이 1건이라도 나면 실패다. 표준 `web/flutter_bootstrap.js`의 `_flutter.loader.load({config: ...})`만 설정에 사용하며 앱 로직이나 React/JS 런타임을 넣지 않는다. 사용 API는 [Flutter 웹 초기화 문서](https://docs.flutter.dev/platform-integration/web/initialization)의 현재 설정 항목과 설치 SDK에서 확인하고 deprecated `loadEntrypoint`는 사용하지 않는다.
- [ ] **URL·제목**: Flutter 기본 hash URL 대신 설치 SDK의 비 deprecated `flutter_web_plugins` `usePathUrlStrategy()`를 쓰고, 앱 라우터가 `pathname`에서 연속 끝 슬래시를 제거한 뒤 네 경로를 판정한다. 모르는 경로는 React처럼 메인 이력서. 로컬/실배포 서버는 History API 진입을 `index.html`로 재작성하되 존재하지 않는 정적 자산에는 실제 404를 보낸다([Flutter URL 전략 문서](https://docs.flutter.dev/ui/navigation/url-strategies)). `<base href="/">` 기준도 일치시킨다. 브라우저 제목은 메인·미지 경로 `김형준 · AgentWorkflow 데모`(`demo/index.html:7`), `/workflow` `AgentWorkflow 상세 · 김형준`(`WorkflowDetailPage.jsx:14-17`), `/sprite` `Sprite 파이프라인 상세 · 김형준`(`SpritePage.jsx:20-23`), `/subtitles` `Voice to SRT 상세 · 김형준`(`SubtitlesPage.jsx:29-32`); 상세를 떠나면 메인 제목으로 복귀한다.
- [ ] **HTML·비공개 헤더**: 원본 저장소의 기본 `web/index.html`은 `<html>`에 `lang`이 없고 `A new Flutter project.` description, `mastprogs_v3` title, manifest 링크가 있다. 이를 React 기준 `lang="ko"`, 정확한 기본 제목, `<meta name="robots" content="noindex, noarchive">`로 바꾸고 description·기본 PWA manifest 링크/제목을 제거한다. React `vite.config.mjs`·`public/_headers`는 수정하지 않는다. 격리 QA는 Python 표준 라이브러리 `ThreadingHTTPServer`의 **임시 외부 작업 폴더** 핸들러로 `build/web`을 `127.0.0.1`에 제공한다. 핸들러가 모든 응답에 `X-Robots-Tag: noindex, noarchive`를 추가하고 자산이 아닌 History API 경로만 `index.html`로 재작성하게 한다(추적 대상 config 파일 생성·커밋 없음). 최종 호스팅도 동등한 헤더와 rewrite가 준비되어야 공개 가능하며 이번 Plan은 배포하지 않는다. `curl`/브라우저 네트워크 기록에서 문서·끝 슬래시·미지 경로의 HTTP 200+헤더, 없는 자산 404, `gstatic.com`을 포함한 외부 요청 0을 검증한다.

## 페이지·모델·에셋 매핑

| Flutter 목적 모듈/화면(제안) | React 기준 | 고정 계약 |
| --- | --- | --- |
| `lib/app/{router,theme,content}` | `App.jsx`, `main.jsx`, `theme/*`, `styles/theme.css`, `content/{resume,site}.js` | 모든 경로·테마·앵커·문구를 하나의 앱 상태로 결합. Flutter scaffold 기본 카운터 제거는 구현 시 Claude 소유. |
| `lib/features/portfolio/*` | `ProfileSection`, `Hero`/`ProfileTheme`, `SkillsSection`, `CoreSection`, `CareerSection`, `CasesSection`, `CaseDialog`, `SiteHeader`, `StickyBar`, `SiteFooter` | 01 소개 → 02 학력·역량 → 03 핵심 구현 → 04 회사 경력 → 05 작업 사례 → 푸터. 03은 상위 h2 상당의 제목 하나와 항상 펼친 03.01 AgentWorkflow, 03.02 Sprite 파이프라인, 03.03 Voice to SRT. 다섯 상위 내비, 하위 앵커 `#workflow/#sprite/#subtitles`. 사례 01 AgentWorkflow, 02 Pixel, 03 SRT, 04 KETI, 05 현장 요청. 레일의 가운데 맞춤·앞뒤·키보드 포커스·모달. |
| `lib/features/workflow/model/*` | `src/workflow-detail/{model,reducer,frames,records}.js`, `src/content/workflowDetail.js` | 브라우저 API 없는 순수 Dart 시나리오·커서·기록 파생. 구형 `src/workflow/*`는 현재 `/workflow`에 마운트되지 않으므로 7타일 화면을 이식 대상으로 오인하지 않는다. |
| `lib/features/workflow/view/*` | `WorkflowDetailPage`, `WorkflowPlayer`, `DetailTransport`, `ConversationPanel`, `SpecPanel`, `TaskPlanPanel`, `SeedLineage`, `LaneBoard`/`LaneColumn`, `RecordsExplorer`, `useDetailPlayer`, `useFrameFollow` | 유일한 직접/순차/독립 병렬 선택기와 플레이어. 레인 A/B/C는 모바일에서도 모두 펼침. 재생기 sticky 모양·프레임 강조·따라가기 규칙 포함. |
| `lib/features/sprite/model/*` | `src/pixel/{layers,palette,paletteSets,outline,pipeline,studio,timeline,rig,playback,cache,sprite}.js`, `usePixelPreview` | 인덱스 셀 RLE 복호화 → 20행 실제 합성 → 색 표 → 공통 패딩 → 포인트 색 → 추가 외곽선 → 세트 OKLab/비율. 재생·스타일·가시성 상태 분리. 순수 Dart, 상한 캐시. |
| `lib/features/sprite/view/*` | `SpritePage`, `PixelStudioPreview`, `PixelCanvas`, `LayerTimeline`, `StudioInspector`, `PaletteSetRow`, `RigPanel` | CustomPainter/원본 픽셀의 최근접 확대. 원본 GIF/PNG와 편집기 증거 이미지 비교, 실제 레이어 토글·단독 보기·어니언·기준점·골격이 한 커서를 따른다. |
| `lib/features/subtitles/model/*` | `src/subtitles/model.js`, `src/content/subtitles.js` | 고정 가상 문구/정수 ms 데이터와 순수 문장 분할·VAD 보정·제안·결정·SRT. 실제 음성 인식·파일 편집기는 포트폴리오 화면 범위가 아니다. |
| `lib/features/subtitles/view/*` | `SubtitlesPage`, `SubtitleWalkthrough`, `SubtitlesBrief`, `CaseDiagram` | 원본 자료 기반 처리 흐름 8개와 경계·편집기·구조·용도 섹션, 6단계 예시 플레이어. 사례 03은 원본 앱 스크린샷인 척하지 않는 원리 도식. |

원본 정적 에셋은 `demo/public/profile/myface4.png`, `demo/public/cases/{master_overview,hero_pixel_studio_screen,mlops_flow,intake_flow}.png`, `demo/public/pixel/hero/`의 GIF·정적 프레임을 변경 없이 번들한다. 스프라이트의 `src/content/pixel-{assets,layers,source-colors,palette-sets,rig,motion-rig}.json`은 데이터 에셋이며 기본 화면에는 큰 레이어 모델을 로드하지 않는다. `pixel-layers.json` 실제 값은 20행(19 표시 + 숨긴 composite), 28프레임(walk 8/run 8/attack 12), 84×89, pivotX 38, soleRow 79, crownRow 23, 팔레트 세트 10개다. `SpriteBrief`는 원본 GIF 3개만 사용한다. Pretendard는 기존 패키지의 허용된 TTF 추출 가능성을 확인해 자체 번들하고, 적절한 비 deprecated Flutter Phosphor 계열 패키지로 아이콘 형태를 맞춘다. 모든 에셋 경로·라이선스·원본 SHA-256은 구현 시작 때 manifest로 고정한다.

## 동작 동결: 워크플로우

- 기본은 `parallel`, 33프레임. 커서=적용한 프레임 수 `0..total`; 같은 시나리오+커서는 대화·WORK SPEC·Task Planning·Seed·레인·병합·통합·파일 트리/내용/변경 이력이 항상 같다. 직접 3프레임; 기본 순차(Seed·기획 반려·QA 실패 ON) 20프레임. 모드/옵션 변경은 커서와 기록 초기화, 속도는 유지.
- 병렬 앞부분: 사람↔Master 범위 대화 → Master WORK SPEC(요청 범위·완료 조건만) → 전역 Task Planning의 제안/검토 승인/계약 동결(`task:split|review|freeze`) → 배정(8번 index, 화면 프레임 9) → 레인별 Seed → 레인별 계획. 계약에는 A UI/B API/C 이력 축, 소유 경로·인터페이스·수용 기준·미완료 레인 의존 없음·공유 통합 소유자·병합 순서 A/B/C가 있다. 순차에는 전역 Task Planning을 만들지 않고 단일 의존 축 이유가 WORK SPEC에 있다. 직접에는 WORK SPEC/Seed/검수/QA가 없다.
- 병렬 A 첫 통과·READY 선착, C 기획 검수 두 차례 반려와 개발 검수 한 차례 반려 뒤 READY 두 번째, B 동일 `QF-001` 반복 QA 실패 뒤 독립 QA 통과로만 원장 닫고 READY 마지막. READY 레인은 다시 실행되지 않는다. 전원 QA 통과까지 병합 게이트 잠김. 그 뒤 통합 계획 → 선언 순서 A/B/C 조립 병합(24번 index) → 통합 개발/검수/빌드/QA → Wiki → 시작 브랜치로 로컬 최종 병합(푸시 없음). 사람은 범위·권한만 판단한다.
- Seed는 읽기 전용 Author/Reviewer 부모에서 계획/개발 자식이 sibling으로 갈라지는 계보. 같은 자식 세션을 재작업 때 resume, Seed 재실행 없음. 독립 QA/Wiki는 Seed·구현자 문맥 상속 없음; QA 재시도는 같은 QA 세션 resume. 병렬 Seed 표시 스위치는 **33프레임을 변경하지 않는 표시 전용**(실제 `--seed`+`--parallel` 실행 주장 금지). 순차 Seed는 옵션이다.
- 단일 전송 바: 이전/재생·일시정지/다음/처음, 정수 슬라이더, 0.5/1/2배는 프레임 간격만 변경, 따라가기 기본 ON. 이전·다음·seek는 멈춤. 0=idle, 끝=done, 끝에서 재생은 한 번 처음부터, 무한 반복 없음. 숨김 탭은 정지하고 자동 재개하지 않는다. 프레임 따라가기는 첫 렌더/리셋/경로·옵션 변경 때 움직이지 않으며 보이지 않는 주요 앵커만 스크롤, 포커스 이동 금지, 휠/터치 직후 자동 추적은 다음 수동 프레임 동작까지 멈춘다. reduced motion은 즉시 이동.
- 타이머 기준은 `DETAIL_STEP_MS=1500`ms와 `frameDelay=round(1500/speed)` (`demo/src/workflow-detail/frames.js:9-14`): 0.5배=3000ms, 1배=1500ms, 2배=750ms. 경로 변경 `SET_ROUTE`는 커서·기록·선택 파일을 초기화하지만 직접 경로 **밖에서** 바꾸면 현재 Seed 표시 값을 이어 가고, 직접 경로에서 나올 때는 경로 기본값을 다시 쓴다(`demo/src/workflow-detail/reducer.js:93-97`). 순차의 기획 반려·QA 실패 옵션은 새 경로 기본값이며 속도는 유지한다(`reducer.js:39,88-101`).
- 파일 탐색기는 `records.js`의 같은 커서 이벤트로 실제 목록·내용·현재 변경을 계산한다. 제안/검토 전에는 동결 계약이 없고 되감으면 미래 승인·파일·QF-001 해결이 사라진다. 로컬 디스크 쓰기·AI 호출·측정 수치·상태 저장 없음.
- 파일 고정은 `SELECT_FILE`로 `selectedPath`에 저장하며 이후 프레임이 바뀌어도 그 파일이 있는 동안 내용을 고정한다. 파일이 현재 커서에 없으면 화면은 최신 파일로 대체 표시한다. `FOLLOW_FILES`는 `selectedPath=null`로 만들어 최신 변경 파일 따라가기로 복귀한다. 처음으로·경로·옵션의 `restart`도 선택을 비운다(`demo/src/workflow-detail/reducer.js:26-33,82-97`; `demo/src/components/workflow-detail/RecordsExplorer.jsx:24-31`).

## 동작 동결: 픽셀

- RLE는 3바이트 `[count uint16 LE, palette index]`; 셀 픽셀 수 불일치는 오류. 원본 0색=투명, composite 참조 레이어/숨긴 레이어 제외, 아래에서 위로 마지막 불투명 색이 이김. 모든 동작은 같은 캔버스·기준점; 실제 각 프레임 composite 참조 색 인덱스와 비교한다.
- 기본 1행 포인트 프리셋 original과 직접 색, 외곽선 on/off+auto/manual. 추가 외곽선은 원래 잉크를 덮지 않는 1픽셀이며 캔버스 패딩으로 검이 잘리지 않는다. 어두운 테마 auto는 프리셋 `outline`, 밝은 테마 auto는 `outlineLight`; manual은 프리셋/테마/자동 연출이 덮지 않고 `자동 색`으로 복귀. 색 입력·캔버스·캐시 키는 같은 유효색.
- 2행은 **별개의** `source`(원본 색상, 세트 변환만 우회)와 10개 실제 세트. 기본 `aap64`, 100%. source에서는 비율 값을 보존하며 슬라이더 비활성, 견본은 현재 출력색. 세트 색은 입력 순서 중복 제거, OKLab 거리 엄격 `<` 동률은 앞 색. 변환은 외곽선 **뒤** 모든 불투명 픽셀에 적용. 0%는 세트 직전 RGBA와 바이트 동일, 100%는 외곽선 포함 모든 불투명 RGB가 세트 소속, 중간은 채널별 반올림, 알파 원본 보존. 색 점유율·세트 소속 마크도 실제 출력에서 계산.
- 타임라인은 20행×해당 모션 프레임, 셀 없음/새 셀/직전과 동일/합성 참조 상태를 실제 셀로 표시. 레이어 표시 토글·단독 보기·기본값 복원, 선택 셀 단독 캔버스. 이전·다음·슬라이더 직접 고르기는 재생을 멈추며 walk/run은 wrap, attack은 clamp. 어니언은 같은 모션의 실제 앞/뒤, 각각 빨강/파랑, 현재 아래, opacity 초기 0.35. pivot/sole/crown 가이드·십자선, 공통 기준점과 실제 픽셀 바운드로 매 프레임 잘라 맞춘 비교/이동량. 골격은 원본 1254 좌표계 기준 자세와 프레임 rot_world FK/plant/root 수치이며 스프라이트 좌표의 관절처럼 겹치지 않는다. 데이터 없는 뼈는 `값 없음`.
- 초기 보기 상태는 레이어 원본 표시값, 선택 레이어 `sword`, 어니언 켬, 기준선 켬, 셔플 켬이다. 캔버스 생성이 실패하면 원본 GIF를 보이는 React의 실패 경로도 보존하고, 캔버스가 가능할 때는 PNG/GIF를 실제 셀 합성의 대용으로 사용하지 않는다.
- 셔플 주머니는 walk/run/attack 한 번씩 완전 순환, 주머니 경계 연속 중복 없음, 모션 변경은 walk/run 2사이클·attack 1사이클 완료 뒤. 직접 선택 후 재개도 같은 모션 바로 반복 금지. 스타일/팔레트/외곽선 변경은 **재생을 멈추지 않음**; 사람의 최초 색 선택은 자동 색 연출만 중지. 숨김·화면 밖·언마운트는 타이머 중지, reduced motion은 시작 일시정지. 프레임·타임라인·어니언·골격은 한 커서. 캐시 상한과 오래된 타이머 방지; 새로고침 후 9분 초과 연속 재생에서 멈춤/메모리 증가/예외 없어야 한다.
- 실제 프레임 타이머는 `sprite.motionsById[snapshot.motion].frames[snapshot.frame].ms`(`demo/src/hooks/usePixelPreview.js:139-153`)를 매 프레임 한 번 예약한다. `demo/src/content/pixel-assets.json:8-133`의 ms 배열은 walk `[130,110,120,110,130,110,120,110]`, run `[90,100,80,90,90,100,80,90]`, attack `[60,40,60,60,120,40,40,110,90,90,90,120]`; 균일 간격으로 바꾸지 않는다. `showcaseFor(turn,presetIds)`(`demo/src/pixel/playback.js:57-61`)는 완전한 차례가 끝나 `turn>=1`부터 `turn % 5`의 프리셋으로 바꾸고 외곽선은 `floor(turn/2)%2===1`일 때 켠다(`usePixelPreview.js:156-160`). 실제 프리셋 순서 `original,crimson,forest,gold,violet`이므로 turn 0 원본/끔 → 1 진홍/끔 → 2 숲/켬 → 3 황금/켬 → 4 보라/끔 → 5 원본/끔 → 6 진홍/켬. `styleReducer`의 프리셋·직접 색·외곽선뿐 아니라 **세트 선택/비율 변경도** `touched=true`로 만들어 이후 연출을 멈춘다(`demo/src/pixel/studio.js:56-83`). 재생 상태는 그대로다.
- 모션 직접 선택 `selectMotion`은 `bagRef.resumeFrom(id)`와 `shuffleOn=false`를 수행한다(`demo/src/hooks/usePixelPreview.js:271-275`). 다른 모션이면 프레임·loop를 0으로 바꾸되 `playing`은 건드리지 않고, 같은 모션이면 현재 커서를 유지한다. 셔플 OFF의 hold에서는 같은 모션을 계속 순환한다(`demo/src/pixel/playback.js:48-54`); 다시 켤 때 현재 모션으로 `resumeFrom`하여 다음 주머니가 현재 모션을 곧바로 반복하지 않는다(`usePixelPreview.js:266-270`). `setOnionOpacity`는 유효 숫자만 0.1..1로 clamp한다(`usePixelPreview.js:304-306`). `IntersectionObserver` 설정의 `threshold`는 0.2지만 콜백은 **`entry.isIntersecting`**을 `inView`에 넣는다(`usePixelPreview.js:121`). 따라서 0.2 미만이어도 일부가 보이고 `isIntersecting=true`이면 재생하며, 완전히 화면 밖 `false`에서 멈춘다. 타이머 활성은 재생 중·`inView`·문서 보임 세 조건의 AND(`usePixelPreview.js:81-86,139-153`). 프레임/맵/세트별 최근접 LRU 한도는 `FRAME_CACHE_LIMIT=96`, `MAP_CACHE_LIMIT=12`, `NEAREST_CACHE_LIMIT=10`, 최근접 항목 초과 재생성 기준 `NEAREST_ENTRY_LIMIT=4096`(`usePixelPreview.js:17-20,50-54,190-193`). 메인 `SpriteBrief`는 reduced motion에서 원본 GIF 대신 **그 모션의 첫 프레임 PNG**를 쓴다(`demo/src/components/sprite/SpriteBrief.jsx:12-26`).

## 동작 동결: 자막

- `SUBTITLE_PIPELINE` 8개(음성 추출/인식/단어 정렬/표시 시간/AI 문장 나누기/교차 검토/사람 검토/SRT), `SUBTITLE_BOUNDARY`, `SUBTITLE_EDITOR`, `SUBTITLE_STRUCTURE`, `SUBTITLE_USES`를 실제 문구 그대로 보여 준다. 이는 원본 Electron·Go·Python/CUDA 앱의 출처 있는 기능 **설명**이다. Flutter 포트폴리오에서 원본 음성/영상 열기·업로드·ASR·GPU·외부 CLI·SRT 파일 가져오기/내보내기 기능을 새로 실행하는 요구가 아니다.
- `WALKTHROUGH_FIXTURE`는 12단어/7,600ms/6단계의 고정 가상 예시. 음성 인식 비교 위험 → 발화 텍스트와 화면 문구 분리 및 정수 ms 강제 정렬 → VAD 연결 구간에서 표시 경계만 ≤300ms 확장(단어 원시 시각 유지, 이웃 넘지 않음) → 글자가 같은 문장만 단어 경계에서 분리(시간 필드 거부), Codex/Claude 의견 갈림 최대 2회 후 합의만 적용 → `id,text,reason,source,uncertainty,needsReview` 제안 수락/보류/되돌리기(수락하면 문구 변경과 `alignmentStale`, 시간 자동 변경 없음) → 결정 반영한 시간순 SRT. 쉼은 단어 간격·VAD 중 긴 값, 크기 자료는 100ms 0..9.
- 6단계 이전/다음/seek는 멈춤; 버튼을 눌러야 재생, 끝에서 정지, 끝에서 재생은 한 번 처음부터, 숨김 탭 정지. 이 예시는 합성 데이터이며 외부 AI·음성·저장 기능이 없다.
- 자막 예시 재생 간격은 `STAGE_INTERVAL_MS=2600`ms(`demo/src/subtitles/model.js:197`); `SubtitleWalkthrough.jsx:29-33`은 재생 중 단계마다 단일 timeout을 예약·정리한다. 0.5/1/2배 옵션은 이 플레이어에 없고, 수락·보류 결정은 화면 상태에만 남아 새로 고침 시 사라진다(`SubtitleWalkthrough.jsx:19-34`).

## 검증 계약과 인계

- [ ] React 호스트에서 **원본 헬퍼를 직접 import하고 훅·화면의 상수/전환을 별도 source trace로 고정하는 생성기**로 기준 JSON 및 픽셀 바이트 SHA-256 fixture를 산출한다. 워크플로우: 세 경로·옵션 조합의 모든 cursor에 `steps/events`, 대화, spec/task/seed/레인/게이트/통합, records 목록·선택 내용·현재 변경, `SELECT_FILE/FOLLOW_FILES` 선택·되감기·최신 따라가기, `SET_ROUTE`의 Seed 이전/직접 복귀와 속도 유지, reducer 전송 시퀀스, `frameDelay`의 3000/1500/750ms. 픽셀: 28프레임 기본 인덱스·owner·RGBA/합성 참조, **JSON의 모션별 모든 frame ms**, 대표 프레임의 가시성·outline auto/manual·테마·source/10세트·비율 0/중간/100·어니언·rig·셔플 고정 RNG, `showcaseFor` turn 0..6과 세트/비율 touched 중단, `selectMotion`의 shuffle OFF/hold·재개 전환, 어니언 opacity 0.1/1 clamp, Observer threshold 0.2와 `isIntersecting` 참/거짓 전환, 캐시 상한, reduced-motion SpriteBrief PNG 자산 선택. 자막: fixture 단계·분리 거부·VAD 경계·제안 거부·수락/보류/되돌리기·SRT와 2600ms 타이머. 순수 헬퍼 밖의 값은 원본 소스 상수·조작 경로를 판독해 trace에 넣고 실제 브라우저에서 타이머/가시성/이미지 선택을 별도 검증한다. 생성기/fixture는 테스트 지원물이지 런타임 JS가 아니다. 버전/입력 SHA를 명시하고 원본 변경 시만 재생성한다.
- [ ] Dart 순수 모델은 생성된 예상 상태/바이트 해시와 차등 검증한다. 비교 대상은 문자열·순서·커서·세션·파일 내용·원장·픽셀 RGBA까지 포함한다. 정적 대략값이나 스크린샷만으로 컨트롤 구현 통과 판정 금지. 실패/경계 입력도 의미 있는 별도 검증.
- [ ] 실제 브라우저는 격리된 `127.0.0.1` Python `ThreadingHTTPServer`로 Flutter `build/web`을 열고 390/768/1440, dark/light, 네 경로·연속 끝 슬래시·미지 경로, 새 탭·포커스·모달·레일·모션 감소·숨김 탭, 워크플로우 0/중간/끝/되감기, 픽셀 옵션과 장시간, 자막 6단계/SRT를 React와 비교 캡처·런타임으로 검증한다. 원본과 Flutter의 차이는 Claude reviewer가 시각·동작 충실도를 판정하고 Claude 구현자가 고친다.
- [ ] 완료 게이트: `flutter analyze` 경고/오류 0, `flutter test` 전부 통과, `flutter build web --no-web-resources-cdn` 경고/오류 0, 브라우저 콘솔 0·외부 요청 0 및 기능 QA, 최종 `git diff` 점검. 이후 **사람이 직접 화면 검토**할 수 있도록 캡처·미해결 차이·재현 절차를 전달한다. 사람 검토 전 커밋·푸시하지 않는다.

## 이번 조사에서 확인한 누락·충돌 위험

- `demo/docs/design/claude-visual-contract.json`에는 초기 헤더 직함·7타일 화면·4사례 같은 예전 내용이 남아 있다. 현재 `App.jsx`, `site.js`, `WorkflowPlayer` 및 최신 AGENTS/테스트가 상충 항목을 덮으므로 구현은 현재 화면에 맞춘다.
- 현재 `/workflow`는 구형 `src/workflow/model.js`의 7단계 UI가 아닌 `workflow-detail/*` 한 재생기다. 구형 테스트가 통과해도 상세 페이지 대체 근거가 아니다.
- 원본 Voice to SRT Wiki 문서는 원본 데스크톱 앱 기능을 서술한다. React 상세 페이지는 그 사실을 설명하는 합성 6단계 미니 플레이어일 뿐이다. 원본 앱 전체 실행 기능으로 범위를 넓히지 않는다.
- 데모의 일부 과거 AI-NOTE/AGENTS 문구는 최신 요청으로 대체됐다(예: 색 설정 시 재생 중단, 메인의 03·04 분리, 포트폴리오 외부 링크 없음). **최신 코드·테스트**의 현재 의미를 fixture로 동결한다.
