// Voice to SRT 상세 페이지(/subtitles) 문구·사실·예시 데이터. SubtitlesPage(lazy 청크)와 node:test 만 import 한다.
// AI-NOTE: 사실은 사용자 승인 하에 원본 저장소의 README, docs/wiki(architecture·decisions·features/recognition·features/editor-review)와
// 소스(worker/engine.py, internal/core/review.go, internal/server/segment.go·segment_debate.go)를 읽어 정리했다
// (데모 저장소 docs/reference/voice-to-srt/source-facts.json, 원본 해시 기록). 최신 문서가 예전 결정을 대체한다.
// - 개인 AI 로그·녹음·미디어·설정·env 는 읽지 않았고 넣지 않는다. 앱 실행·모델 내려받기·실제 AI 호출 없음.
// - 품질·속도·정확도 수치, 출시 상태는 쓰지 않는다. "개발 중이지만 기능은 구현됨" 은 사용자가 확인한 사실이다.
// - 핵심 경계(정확히 지킨다): AI 는 시간을 만들지 않는다. 문장 나누기 응답은 원래 글자와 같은 문장 묶음만 허용되고,
//   교정 제안 형식(review.go ReviewProposal)은 id·text·reason·source·uncertainty·needsReview 뿐이며 시간 필드는 거부된다.
//   끊는 시각은 강제 정렬 단어 시각에서, 표시 시간은 VAD 로 최대 0.3초까지만 넓힌다(원래 정렬 시각은 보존).
// AI-NOTE: 아래 WALKTHROUGH_FIXTURE 는 처리 원리를 보여 주려고 새로 쓴 짧은 가상 대사·시각이다(원본 녹음·전사·로그 아님).
// 화면에는 경고 문구 없이 "예시 대사" 로만 부른다. 배열은 모두 고정(freeze)된 작은 데이터다.

const freezeDeep = (value) => {
  if (value && typeof value === "object") {
    for (const child of Object.values(value)) freezeDeep(child);
    Object.freeze(value);
  }
  return value;
};

export const SUBTITLES_PAGE = freezeDeep({
  backLabel: "이력서로 돌아가기",
  eyebrow: "Voice to SRT 상세",
  title: "들린 말은 로컬 모델이, 끊을 곳과 문구는 AI가 제안하고, 시간은 단어 정렬이 정하는 한국어 자막 도구",
  status: "개발 중 · 아래 기능은 구현되어 있습니다",
  intro: [
    "영상의 한국어 대사를 로컬 GPU에서 인식하고, 단어마다 실제 소리 난 시각을 맞춘 뒤 읽기 좋은 자막으로 나눕니다.",
    "AI(Codex·Claude)는 단어 시각·쉼·파형·문맥을 보고 끊을 위치를 고르고 문구 교정을 제안합니다. 합의된 끊김은 단어 정렬 시각에 맞춰 적용되고, 문구 교정 제안은 사람이 수락하거나 보류합니다.",
  ],
  openCase: "사례 요약 보기",
  sections: {
    flow: "처리 흐름",
    walkthrough: "과정 따라가기",
    boundary: "AI가 하는 일과 하지 않는 일",
    editor: "편집기에서 할 수 있는 일",
    structure: "구성과 데이터가 머무는 곳",
    uses: "이렇게 씁니다",
  },
});

// 처리 흐름(원리). where: 실행 위치.
export const SUBTITLE_PIPELINE = freezeDeep([
  { id: "extract", where: "로컬", label: "음성 추출", text: "FFprobe로 오디오 트랙을 고르고, FFmpeg가 원본 음성을 PCM으로 뽑아 파형과 VAD(말소리 구간 검출)를 만듭니다." },
  { id: "asr", where: "로컬 GPU", label: "음성 인식", text: "빠른 처리는 고른 모델 하나, 정밀 처리는 Qwen 한국어·Whisper large-v3·large-v2·turbo 중 둘 이상을 같은 구간에 차례로 돌려 비교합니다. 모델은 한 번에 하나만 GPU에 올립니다." },
  { id: "align", where: "로컬 GPU", label: "단어 정렬", text: "Qwen 강제 정렬기가 발화 기준 텍스트를 원본 오디오에 맞춰 단어마다 시작·끝을 절대 밀리초로 저장합니다. 화면 문구와 발화 기준 텍스트는 따로 둡니다." },
  { id: "pad", where: "로컬", label: "표시 시간 보정", text: "정렬이 말끝·첫소리를 짧게 잡았고 VAD상 말소리가 이어지면, 자막 표시 시간만 최대 0.3초 넓힙니다. 줄이지 않고 앞뒤 자막을 넘지 않으며 단어 시각은 그대로 둡니다." },
  { id: "split", where: "외부 CLI", label: "AI 문장 나누기", text: "AI는 단어 시각·쉰 길이·0.1초마다의 소리 크기(0~9)를 보고 어디서 끊을지만 정합니다. 돌려준 문장의 글자가 원래와 다르면 쓰지 않고, 시간은 단어 시각에서 가져옵니다." },
  { id: "review", where: "외부 CLI", label: "교차 검토", text: "Codex와 Claude가 서로 모른 채 제안한 뒤, 끊는 위치가 갈린 곳은 앞뒤 글·쉰 길이·소리 크기와 상대 판단을 보고 최대 두 번 다시 판단합니다. 합의만 반영하고 남은 차이는 제안으로 남깁니다." },
  { id: "human", where: "사람", label: "사람 검토", text: "교정 제안은 이유·근거와 함께 표시되고, 사람이 고르거나 고쳐서 수락하거나 보류합니다. AI 작업 전 상태는 실행 취소 한 번으로 되돌립니다." },
  { id: "export", where: "로컬", label: "SRT", text: "시간순으로 번호를 다시 붙여 SRT로 내보냅니다(UTF-8 BOM 선택). 기존 SRT는 UTF-8 BOM·CP949로 가져와 다시 정렬할 수 있습니다." },
]);

export const SUBTITLE_BOUNDARY = freezeDeep({
  does: {
    title: "AI가 하는 일",
    items: [
      "정렬된 단어 사이에서 읽기 좋은 끊는 위치 고르기(20자 안팎, 최대 30자·6초)",
      "인식 후보·용어·앞뒤 자막·영상 설명(선택한 영상 화면)을 보고 문구 교정 제안",
      "교차 검토에서 상대 제안에 동의·반대와 그 이유·근거 남기기",
    ],
  },
  doesNot: {
    title: "AI가 하지 않는 일",
    items: [
      "시간 만들기: 응답에 시간 필드가 있으면 버리고, 끊는 시각은 단어 정렬에서 가져옵니다",
      "글자 바꿔 끼우기: 문장 나누기 응답의 글자가 원래 자막과 다르면 그 묶음을 쓰지 않습니다",
      "문구 바로 덮어쓰기: 문구 교정은 제안으로만 붙고, 사람이 고치거나 승인·보류한 자막은 건드리지 않습니다",
      "오디오 듣기: 오디오는 외부로 보내지 않습니다",
    ],
  },
  proposalFields: ["id", "text", "reason", "source", "uncertainty", "needsReview"],
  proposalNote: "교정 제안 응답에서 허용하는 필드. 시간 변경 필드·알 수 없는 ID·빈 필수값은 반영하지 않습니다.",
});

export const SUBTITLE_EDITOR = freezeDeep([
  { label: "파형 · 타임라인", text: "FFmpeg가 뽑은 실제 PCM 파형, 재생·탐색·구간 반복·속도 변경, 타임라인 확대와 재생 위치 따라가기" },
  { label: "자막 편집", text: "양끝 드래그·숫자 입력으로 시간 조정, 문구 수정, 나누기·합치기·추가·삭제, 실행 취소·다시 실행" },
  { label: "나누기", text: "재생 위치에서 가장 가까운 어절 경계로 나누고, 정렬 단어가 있으면 단어 시각과 단어를 나눠 가져 다시 정렬하지 않아도 됩니다" },
  { label: "찾아 바꾸기", text: "찾은 곳 수 표시, 한 곳씩 이동, 바꾸기·모두 바꾸기(각각 실행 취소 가능)" },
  { label: "의심 목록", text: "모델 간 차이·누락·비정상 반복·거의 무음 구간·읽기 속도·정렬 실패를 표시하고 후보·이유·교정 차이를 비교" },
  { label: "SRT 가져오기 · 내보내기", text: "UTF-8 BOM·CP949 가져오기(손상 행은 행 번호로 안내), 시간순 내보내기, 빈 프로젝트는 기존 파일을 덮지 않음" },
]);

export const SUBTITLE_STRUCTURE = freezeDeep({
  parts: [
    { label: "Electron", text: "데스크톱 창" },
    { label: "Go", text: "내장 로컬 화면·서버, GPU 작업 큐 하나" },
    { label: "Python CUDA worker", text: "음성 인식·강제 정렬, 한 번에 모델 하나" },
    { label: "FFprobe · FFmpeg", text: "트랙 선택·PCM 추출·파형" },
  ],
  local: { title: "로컬에 남는 것", items: ["원본 미디어(복사하지 않고 경로로 참조)", "오디오·파형·VAD", "음성 인식·단어 정렬 결과"] },
  external: { title: "AI 교정을 켰을 때만 외부 CLI로", items: ["자막 텍스트·모델 후보", "용어·영상 설명", "선택한 영상 화면 몇 장(끌 수 있음)"] },
});

export const SUBTITLE_USES = freezeDeep([
  { label: "게임·영상 대사 한국어 자막", text: "미디어를 끌어놓고 처리 방식(빠른/정밀)과 모델을 고르면, 구간이 끝날 때마다 자막이 바로 나타납니다." },
  { label: "기존 SRT 다듬기", text: "가져온 SRT의 화면 문구는 그대로 두고, 발화 기준 텍스트로 선택 구간을 다시 정렬합니다. 사람이 조정한 표시 시간은 덮지 않습니다." },
  { label: "용어·끊는 위치 검토", text: "영상 설명과 게임 용어, 선택한 영상 화면을 함께 주고 교차 검토를 돌린 뒤, 갈린 의견을 나란히 보고 고릅니다." },
]);

// ── 과정 따라가기 ──────────────────────────────────────────
export const WALKTHROUGH_COPY = freezeDeep({
  fixtureLabel: "예시 대사 한 구간",
  transportLabel: "단계 이동",
  prev: "이전 단계",
  next: "다음 단계",
  play: "단계 차례로 보기",
  pause: "일시정지",
  restart: "처음부터 다시 보기",
  reset: "처음으로",
  stageList: "처리 단계",
  timelineLabel: "시간축(초)",
  words: "정렬 단어",
  levels: "0.1초 소리 크기(0~9)",
  vad: "VAD 말소리",
  raw: "정렬 시각",
  display: "표시 시간",
  pauseMark: "쉼",
  cut: "끊는 위치",
  spoken: "발화 기준 텍스트",
  displayText: "화면 문구",
  accept: "수락",
  hold: "보류",
  undo: "되돌리기",
  stale: "발화 기준 텍스트가 바뀌어 단어 정렬을 다시 해야 하는 상태",
  agree: "의견 일치",
  differ: "서로 다름",
  round: "토론",
});

// 단계(6). 각 단계 설명은 원본 문서의 실제 동작이다.
export const WALKTHROUGH_STAGES = freezeDeep([
  { id: "asr", label: "음성 인식", title: "원문은 문장부호 없이 한 덩어리로 들어옵니다", text: "기준 모델(Qwen 한국어) 결과가 자막 문구가 되고, 비교 모델과 단어 내용이 다른 곳은 위험 표시가 붙습니다." },
  { id: "align", label: "단어 정렬", title: "단어마다 실제 소리 난 시각을 붙입니다", text: "강제 정렬기는 발화 기준 텍스트(문장부호 없음)를 원본 오디오에 맞춥니다. 화면 문구는 따로 둡니다." },
  { id: "pad", label: "표시 시간", title: "말소리가 이어지면 표시 시간만 조금 넓힙니다", text: "VAD상 말소리가 계속되는 경계는 최대 0.3초까지 넓히고, 정렬 시각은 그대로 보존합니다." },
  { id: "split", label: "AI 나누기", title: "AI는 단어 사이 중 끊을 곳만 고릅니다", text: "AI에는 단어 시각·쉰 길이·0.1초 소리 크기가 숫자로 갑니다. 갈린 곳은 토론 후 합의만 반영하고, 새 자막의 시각은 단어 시각에서 옵니다." },
  { id: "review", label: "교정 · 검토", title: "문구 교정은 이유가 붙은 제안이고, 사람이 결정합니다", text: "제안은 바로 원문을 바꾸지 않습니다. 수락·보류·되돌리기를 눌러 결과를 바꿔 보세요." },
  { id: "srt", label: "SRT", title: "시간순으로 번호를 붙여 내보냅니다", text: "화면 문구와 표시 시간이 SRT가 됩니다. 앞 단계에서 고른 결정이 그대로 반영됩니다." },
]);

// 예시 데이터(가상 대사). 시각은 모두 정수 밀리초(원본처럼 절대 시각).
export const WALKTHROUGH_FIXTURE = freezeDeep({
  durationMs: 7600,
  models: { reference: "Qwen 한국어", compare: "Whisper large-v3" },
  words: [
    { text: "자", startMs: 300, endMs: 480 },
    { text: "그럼", startMs: 520, endMs: 860 },
    { text: "오늘", startMs: 900, endMs: 1180 },
    { text: "일정부터", startMs: 1220, endMs: 1760 },
    { text: "확인할게요", startMs: 1800, endMs: 2520 },
    { text: "먼저", startMs: 3160, endMs: 3460 },
    { text: "장비를", startMs: 3500, endMs: 3900 },
    { text: "점검하고", startMs: 3940, endMs: 4520 },
    { text: "광장애서", startMs: 4560, endMs: 5100 },
    { text: "모입시다", startMs: 5140, endMs: 5780 },
    { text: "아", startMs: 6200, endMs: 6420 },
    { text: "잠깐만요", startMs: 6460, endMs: 7180 },
  ],
  // 비교 모델이 다르게 들은 단어(단어 번호 → 후보).
  compareDiff: { index: 8, text: "광장에서" },
  vad: [
    { startMs: 260, endMs: 2700 },
    { startMs: 3100, endMs: 5900 },
    { startMs: 6150, endMs: 7600 },
  ],
  // 화면 문구(문장부호 포함). 자막 순서별. 발화 기준 텍스트는 단어에서 만든다.
  displayTexts: ["자, 그럼 오늘 일정부터 확인할게요.", "먼저 장비를 점검하고 광장애서 모입시다.", "아, 잠깐만요!"],
  // 문장 나누기 응답: 글자만 같은 문장 묶음(시간 없음). Codex 는 두 곳, Claude 는 처음에 한 곳.
  split: {
    codex: { sentences: ["자 그럼 오늘 일정부터 확인할게요", "먼저 장비를 점검하고 광장애서 모입시다", "아 잠깐만요"], reason: "0.64초·0.42초 쉼 뒤에서 말이 끊기고, '아'는 따로 떼는 외침이다" },
    claude: { sentences: ["자 그럼 오늘 일정부터 확인할게요", "먼저 장비를 점검하고 광장애서 모입시다 아 잠깐만요"], reason: "0.64초 쉼에서 한 번 끊는다" },
    debate: [
      { round: 1, claude: "반대", reason: "'아'가 앞 문장 말끝에 붙어 들릴 수 있다" },
      { round: 2, claude: "동의", reason: "모입시다 뒤 0.42초 쉼과 앞뒤 1초 소리 크기 0~1 구간을 보면 새 발화가 시작된다" },
    ],
  },
  // 교정 제안(review.go ReviewProposal 과 같은 필드만).
  proposals: [
    {
      id: "cue-2",
      text: "먼저 장비를 점검하고 광장에서 모입시다.",
      reason: "장소 뒤에는 조사 '에서'가 자연스럽고, 비교 모델 후보도 '광장에서'로 들었다",
      source: "Whisper large-v3 후보 · 앞뒤 자막",
      uncertainty: "낮음",
      needsReview: true,
    },
  ],
  // 교차 검토에서 두 AI 의 같은 제안 여부.
  proposalOpinions: { codex: "광장에서", claude: "광장에서" },
});
