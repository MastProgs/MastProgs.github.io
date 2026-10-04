# 구현 구조

## 실행 경로

`start-gpu.bat`가 `scripts/bootstrap.ps1`을 실행합니다. 준비 점검과 필요 시 독립 가상환경 설치, Go 빌드, Electron 데스크톱 앱 빌드를 마치면 앱 창을 실행합니다. 앱 창은 Go 실행 파일을 자식 프로세스로 띄우고, Go 서버는 내장 HTML/CSS/JS를 OS가 할당한 `127.0.0.1` 포트에 제공합니다. 앱을 닫으면 서버와 작업자가 함께 종료됩니다. 앱 창은 하나만 열리며 다시 실행하면 기존 창을 앞으로 가져옵니다. Node.js는 데스크톱 앱 빌드에만 쓰이고 CDN은 쓰지 않습니다.

## 경계와 자료 흐름

1. `internal/server`가 HTTP 요청, 세션·변경 요청 검증, 프로젝트 작업과 단일 GPU 작업 대기열을 처리합니다. `/api/projects` 계열은 프로젝트·미디어·SRT·작업·문장 나누기·교정 기능의 진입점이고 `/api/jobs/{id}`는 진행 상태를 제공합니다.
2. `internal/media`가 FFprobe로 메타데이터를 읽고 FFmpeg로 원본의 일부를 PCM으로 추출합니다. 큰 영상의 오디오를 전부 메모리에 적재하지 않습니다. 선택·입력·끌어놓기 모두 원본을 제자리에서 참조하며 복사하지 않습니다.
3. `internal/worker`가 지속 실행되는 Python 작업자와 요청 ID가 있는 JSONL로 통신합니다. 표준 출력은 응답 전용이고 진단은 표준 오류를 사용합니다. 취소·시간 초과·프로토콜 오류로 작업자가 종료되면 다음 요청에서 다시 시작할 수 있습니다.
4. `worker/engine.py`가 CUDA에서 Qwen 한국어 ASR, faster-whisper, Qwen 강제 정렬기를 호출합니다. 큰 모델은 순차적으로 전환하며 같은 모델의 연속 구간에서는 로드 상태를 재사용합니다. VAD와 PCM 에너지는 검토 근거를 제공하며 전사나 정렬을 증명하지 않습니다.
5. `internal/core`가 정수 밀리초 원본 타임라인, 자막 원후보·표시 글자·발화 글자·표시 시간, 이력, revision, SRT 직렬화와 교정 제안 검증을 담당합니다. 프로젝트는 디스크에 저장하지 않고 서버 메모리에만 둡니다. 편집기는 revision에 맞춰 서버에 반영하고 충돌을 감지합니다.

기본 자료 위치는 `%LOCALAPPDATA%/VoiceToSRT`입니다. 모델 캐시, 앱 실행 기록, 임시 추출물이 이 영역에 분리됩니다. 빌드 산출물과 Python 가상환경은 저장소의 Git 무시 대상 `.tools/`에 둡니다. 수동 Go/worker 실행도 기본적으로 앱 소유 Hugging Face 캐시를 사용하며 프로세스에 명시한 `HF_HOME`·`HF_HUB_CACHE`는 존중합니다.

UI 및 일반 동작은 [Windows 실행](features/windows-launch.md), [인식과 검토](features/recognition.md), [편집과 교정](features/editor-review.md)에 나눠 기록했습니다.
