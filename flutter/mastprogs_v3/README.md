# 김형준 포트폴리오 v3 · Flutter

React 완성본 `fcdfc01`을 기준으로 네 페이지를 네이티브 Flutter 위젯과 캔버스로 이식한 웹 앱입니다. 이 체크아웃은 Flutter 전용이며 React 소스(`demo/`)는 삭제되어 Git 커밋 `fcdfc01`에만 남아 있습니다. Flutter 앱은 React를 실행하거나 JavaScript로 모델 계산을 위임하지 않습니다.

## 실행과 검증

Flutter 3.41.9 / Dart 3.11.5에서 검증합니다.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --no-web-resources-cdn --no-wasm-dry-run
```

검사용 빌드는 `build/web`에 생성됩니다. 로컬 검토 서버는 사용자 요청으로 종료한 상태입니다. 서버는 상세 경로를 `index.html`로 재작성하고 모든 응답에 `X-Robots-Tag: noindex, noarchive`를 붙입니다. 서버 실행 파일은 작업용 임시 디렉터리에 있으며 이번 작업에서는 배포하지 않습니다.

## 페이지와 구현

- `/`: 소개·연락처, 학력·역량, 핵심 구현, 회사 경력, 작업 사례·모달
- `/workflow`: 직접 처리·순차·독립 병렬, 검수 반려·QA 재시도, Task Planning·Seed, 통합·Wiki, 프레임 플레이어와 로컬 기록
- `/sprite`: 원본 레이어 합성, 모션·팔레트·외곽선, 어니언, 기준점 비교, 레이어 타임라인·골격
- `/subtitles`: 음성 인식·단어 정렬·표시 시간·AI 검토 설명, 6단계 재생, 교정 수락·보류·되돌리기와 SRT 결과

화면과 인터랙션은 Claude가 이식했습니다. 콘텐츠·픽셀·골격은 원본 자료를 사용합니다.

## 자산과 비교 기준

- `assets/data/`: React 원본 상수·콘텐츠를 내보낸 JSON(사용자 후속 지시로 바뀐 범위는 `lib/core/json.dart` AI-NOTE에 기록)
- `assets/media/{profile,cases,pixel,fonts}`: React `demo/public/`의 원본 이미지·스프라이트·폰트 파일을 SHA256 동일하게 옮긴 것. 데이터의 공개 경로(`/profile/...` 등)는 `lib/core/public_assets.dart`의 `publicAsset`이 `assets/media/...` 키로 바꿉니다.
- `test/fixtures/`: 커밋 `fcdfc01` React에서 만든 고정 차등 기준값입니다. 출처 digest는 기록용으로 그대로 두며 다시 생성하지 않습니다.
- 기준값을 만들던 Node 내보내기 스크립트(`tools/export_react_*.mjs`)는 React 소스가 없어져 함께 삭제했습니다. 기준을 다시 확인해야 할 때만 `git show fcdfc01:...` 또는 별도 작업 트리로 Git 이력에서 복원합니다.
- React 시절 사용자 선호·디자인 지시는 `docs/reference/react-baseline-instructions.md`에 보존합니다.

## 검토 기준

세부 기능 계약은 `docs/plans/flutter-migration.md`, 실제 검토 결과와 캡처는 `docs/qa/flutter-review-notes.md`와 `docs/qa/flutter/`에 있습니다. 사용자 지시에 따라 Flutter 프로젝트는 로컬 커밋하며 푸시하지 않습니다.

## 검색 노출 설정

HTML의 `noindex, noarchive`를 유지하고 폰트·CanvasKit·이미지를 로컬 번들합니다. 이메일·전화는 사용자가 입력·포함을 확인한 값을 일반 텍스트로 보이고(빈 값이면 `준비 중`), 링크는 포트폴리오 URL 하나뿐입니다. 공개 배포 시에도 상세 경로 재작성과 검색 제외 헤더를 유지해야 합니다. 캔버스 렌더링과 검색 제외 설정은 인증이나 비공개 접근 제어를 제공하지 않습니다.
