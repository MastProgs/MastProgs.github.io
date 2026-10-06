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

검사용 빌드는 `build/web`에 생성됩니다. GitHub Pages는 `/sprite` 같은 경로를 `index.html`로 재작성하지 않으므로 상세 화면은 `/#/workflow`, `/#/sprite`, `/#/subtitles`로 엽니다. 메인의 상세 링크는 같은 탭에서 이동합니다. 루트 `build_flutter.bat`는 빌드 결과를 배포 폴더 `docs/`에 복사합니다.

이력서와 상세 3개를 묶은 흰 배경 4쪽 PDF는 `web/portfolio.pdf`입니다. 내용 데이터가 바뀌면 `python tools/generate_portfolio_pdf.py`로 다시 만듭니다. 생성에는 ReportLab 4.4.9, fontTools 4.60.1, pypdf 6.10.0, Pillow가 필요합니다. `flutter test test/guards_test.dart`는 PDF에 기록된 콘텐츠 해시와 현재 JSON을 비교합니다.

## 페이지와 구현

- `/`: 소개·연락처, 학력·역량, 핵심 구현, 회사 경력, 작업 사례·모달
- `/#/workflow`: 직접 처리·순차·독립 병렬, 검수 반려·QA 재시도, Task Planning·Seed, 통합·Wiki, 프레임 플레이어와 로컬 기록
- `/#/sprite`: 원본 레이어 합성, 모션·팔레트·외곽선, 어니언, 기준점 비교, 레이어 타임라인·골격
- `/#/subtitles`: 음성 인식·단어 정렬·표시 시간·AI 검토 설명, 6단계 재생, 교정 수락·보류·되돌리기와 SRT 결과

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

HTML의 `noindex, noarchive`를 유지하고 폰트·CanvasKit·이미지를 로컬 번들합니다. 이메일·전화는 사용자가 입력·포함을 확인한 값을 일반 텍스트로 보이고(빈 값이면 `준비 중`), 외부 링크는 포트폴리오 URL 하나뿐입니다. PDF에는 같은 연락처가 들어 있고 `robots.txt`가 `/portfolio.pdf` 크롤링을 막습니다. 검색 제외 설정은 인증이나 비공개 접근 제어를 제공하지 않습니다.
