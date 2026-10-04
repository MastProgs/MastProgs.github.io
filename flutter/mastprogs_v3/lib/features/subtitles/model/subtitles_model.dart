// Voice to SRT 처리 원리(React src/subtitles/model.js 이식, 순수 함수). 화면(SubtitlesPage)은 buildWalkthrough 결과만 읽는다.
// AI-NOTE: 원본 문서·소스의 규칙을 작게 옮긴 것이다(실제 인식·정렬·AI 호출은 하지 않는다).
// - 자막 시간은 단어 정렬 시각에서만 만든다(cueFromWords). AI 응답은 글자가 같은 문장 묶음이어야 하고 시간 필드가 있으면 거부한다
//   (원본 internal/core/segment.go ValidateSentences). 문장 경계가 단어 중간이면 쓰지 않는다.
// - 표시 시간 보정(padDisplay): VAD 말소리가 이어질 때만 최대 0.3초 넓히고, 줄이지 않고, 앞뒤 자막을 넘지 않으며, 정렬 시각은 보존한다.
// - 교정 제안(validateProposal): 원본 review.go ReviewProposal 의 필드(id·text·reason·source·uncertainty·needsReview)만 허용, 시간 필드 거부.
// - 결과는 모두 고치지 않는 작은 값 객체다(화면은 한 번 만든 결과를 계속 쓴다).
import 'dart:math' as math;

import '../../../core/json.dart';
import '../../../core/js_compat.dart';

const int maxDisplayPadMs = 300;
const int pauseMarkMs = 300;
const int levelStepMs = 100;
const List<String> proposalFields = ['id', 'text', 'reason', 'source', 'uncertainty', 'needsReview'];

// 시간 필드로 보는 이름: start·end·time·duration·offset 로 시작하거나 Ms 로 끝나는 키(startMs, endMs, time, durationSec …).
final RegExp _timePrefix = RegExp(r'^(start|end|time|duration|offset)', caseSensitive: false);
final RegExp _msSuffix = RegExp(r'Ms$');

bool isTimeField(String key) => _timePrefix.hasMatch(key) || _msSuffix.hasMatch(key);

final RegExp _nonLetters = RegExp('[\\s.,!?…~\'"“”‘’·]');

String _letters(Object? text) => '$text'.replaceAll(_nonLetters, '');

class AlignedWord {
  const AlignedWord({required this.text, required this.startMs, required this.endMs, this.index, this.risk});

  factory AlignedWord.fromJson(Json json) => AlignedWord(text: json.str('text'), startMs: json.integer('startMs'), endMs: json.integer('endMs'));

  final String text;
  final int startMs;
  final int endMs;
  final int? index;

  /// 비교 모델이 다르게 들은 후보(없으면 null).
  final String? risk;

  Map<String, Object?> toJson() => {'text': text, 'startMs': startMs, 'endMs': endMs, if (index != null) 'index': index, if (index != null) 'risk': risk};
}

class TimeSpan {
  const TimeSpan({required this.startMs, required this.endMs});

  factory TimeSpan.fromJson(Json json) => TimeSpan(startMs: json.integer('startMs'), endMs: json.integer('endMs'));

  final int startMs;
  final int endMs;

  Map<String, Object?> toJson() => {'startMs': startMs, 'endMs': endMs};
}

/// 자막 한 줄. 단계마다 필드가 늘어난다(정렬 → 표시 시간 → id·문구 → 사람 결정).
class SubtitleCue {
  const SubtitleCue({
    this.from,
    this.to,
    required this.startMs,
    required this.endMs,
    this.spoken,
    this.displayStartMs,
    this.displayEndMs,
    this.id,
    this.text,
    this.hasDecision = false,
    this.decision,
    this.alignmentStale,
  });

  final int? from;
  final int? to;
  final int startMs;
  final int endMs;
  final String? spoken;
  final int? displayStartMs;
  final int? displayEndMs;
  final String? id;
  final String? text;

  /// applyDecisions 를 거친 자막이면 참(decision 키가 생김, 값은 null 일 수 있다).
  final bool hasDecision;
  final String? decision;
  final bool? alignmentStale;

  int get displayStart => displayStartMs ?? startMs;
  int get displayEnd => displayEndMs ?? endMs;

  SubtitleCue copyWith({int? displayStartMs, int? displayEndMs, String? id, String? text, bool? hasDecision, String? decision, bool? alignmentStale}) =>
      SubtitleCue(
        from: from,
        to: to,
        startMs: startMs,
        endMs: endMs,
        spoken: spoken,
        displayStartMs: displayStartMs ?? this.displayStartMs,
        displayEndMs: displayEndMs ?? this.displayEndMs,
        id: id ?? this.id,
        text: text ?? this.text,
        hasDecision: hasDecision ?? this.hasDecision,
        decision: hasDecision == true ? decision : this.decision,
        alignmentStale: alignmentStale ?? this.alignmentStale,
      );

  Map<String, Object?> toJson() => {
    if (from != null) 'from': from,
    if (to != null) 'to': to,
    'startMs': startMs,
    'endMs': endMs,
    if (spoken != null) 'spoken': spoken,
    if (displayStartMs != null) 'displayStartMs': displayStartMs,
    if (displayEndMs != null) 'displayEndMs': displayEndMs,
    if (id != null) 'id': id,
    if (text != null) 'text': text,
    if (hasDecision) 'decision': decision,
    if (alignmentStale != null) 'alignmentStale': alignmentStale,
  };
}

// ── 단어 → 자막 ────────────────────────────────────────────
SubtitleCue cueFromWords(List<AlignedWord> words, int from, int to) {
  if (!(from >= 0 && to < words.length && from <= to)) throw RangeError('잘못된 단어 범위 $from..$to');
  final slice = words.sublist(from, to + 1);
  return SubtitleCue(from: from, to: to, startMs: slice.first.startMs, endMs: slice.last.endMs, spoken: slice.map((w) => w.text).join(' '));
}

// cuts: 그 단어 "뒤"에서 끊는 단어 번호들. 끊는 시각은 항상 단어 경계(앞 단어 끝 / 다음 단어 시작)다.
List<SubtitleCue> splitAtWordCuts(List<AlignedWord> words, Iterable<num> cuts) {
  final unique = <num>[];
  for (final cut in cuts) {
    if (!unique.contains(cut)) unique.add(cut);
  }
  final sorted = stableSorted(unique, (a, b) => a.compareTo(b));
  for (final cut in sorted) {
    if (!jsIsInteger(cut) || cut < 0 || cut >= words.length - 1) throw ArgumentError('단어 경계가 아님: $cut');
  }
  final cues = <SubtitleCue>[];
  var from = 0;
  for (final cut in [...sorted.map((c) => c.toInt()), words.length - 1]) {
    cues.add(cueFromWords(words, from, cut));
    from = cut + 1;
  }
  return cues;
}

// AI 문장 나누기 응답 → 끊는 단어 번호. 글자가 다르거나, 시간 필드가 있거나, 단어 중간에서 끊으면 null(그 묶음은 쓰지 않음).
// sentences 는 문자열 또는 {text, ...} 객체의 목록이다(그 밖의 값이면 null).
List<int>? sentencesToCuts(List<AlignedWord> words, Object? sentences) {
  if (sentences is! List || sentences.isEmpty) return null;
  final texts = <Object?>[];
  for (final item in sentences) {
    if (item is String) {
      texts.add(item);
    } else if (item is Map) {
      if (item.keys.any((key) => isTimeField('$key'))) return null;
      texts.add(item['text']);
    } else {
      return null;
    }
  }
  if (texts.any((text) => text is! String || _letters(text).isEmpty)) return null;
  if (_letters(texts.join()) != _letters(words.map((word) => word.text).join())) return null;
  // 단어별 누적 글자 수 경계와 문장별 누적 글자 수가 맞아야 한다.
  final wordEnds = <int>[];
  var total = 0;
  for (final word in words) {
    total += _letters(word.text).length;
    wordEnds.add(total);
  }
  final cuts = <int>[];
  var acc = 0;
  for (var i = 0; i < texts.length - 1; i += 1) {
    acc += _letters(texts[i]).length;
    final index = wordEnds.indexOf(acc);
    if (index < 0) return null;
    cuts.add(index);
  }
  return cuts;
}

// ── 쉼·소리 크기 ───────────────────────────────────────────
class WordPause {
  const WordPause({required this.after, required this.startMs, required this.endMs, required this.ms});

  final int after;
  final int startMs;
  final int endMs;
  final int ms;

  Map<String, Object?> toJson() => {'after': after, 'startMs': startMs, 'endMs': endMs, 'ms': ms};
}

// 단어 사이 간격과 VAD 의 쉼 중 긴 쪽(원본: 정렬이 단어 끝을 늘려 잡아도 실제 쉼을 알 수 있게).
List<WordPause> wordPauses(List<AlignedWord> words, [List<TimeSpan> vad = const [], int minMs = pauseMarkMs]) {
  final pauses = <WordPause>[];
  for (var i = 0; i < words.length - 1; i += 1) {
    final gapStart = words[i].endMs;
    final gapEnd = words[i + 1].startMs;
    var vadSilence = 0;
    for (var s = 0; s < vad.length - 1; s += 1) {
      final silenceStart = vad[s].endMs;
      final silenceEnd = vad[s + 1].startMs;
      if (silenceEnd > words[i].startMs && silenceStart < words[i + 1].endMs) vadSilence = math.max(vadSilence, silenceEnd - silenceStart);
    }
    final ms = math.max(gapEnd - gapStart, vadSilence);
    if (ms >= minMs) pauses.add(WordPause(after: i, startMs: gapStart, endMs: gapEnd, ms: ms));
  }
  return pauses;
}

// 0.1초마다 소리 크기 0~9(예시 데이터용 결정적 값: 단어 안은 4~8, 단어 밖은 0~1). 실제 앱은 PCM 에너지에서 만든다.
List<int> levelsFor(List<AlignedWord> words, int durationMs, [int stepMs = levelStepMs]) {
  final levels = <int>[];
  for (var i = 0; i * stepMs < durationMs; i += 1) {
    final t = i * stepMs;
    final mid = t + stepMs / 2;
    final index = words.indexWhere((word) => mid >= word.startMs && mid < word.endMs);
    levels.add(index < 0 ? (i % 3 == 0 ? 1 : 0) : 4 + ((index * 3 + i) % 5));
  }
  return levels;
}

// ── 표시 시간 보정 ─────────────────────────────────────────
// 앞 자막의 (넓힌) 표시 끝과 다음 자막의 정렬 시작을 넘지 않으므로 표시 시간끼리 겹치지 않는다. startMs·endMs(정렬 시각)는 그대로 둔다.
List<SubtitleCue> padDisplay(List<SubtitleCue> cues, List<TimeSpan> vad, [int maxPadMs = maxDisplayPadMs]) {
  final out = <SubtitleCue>[];
  for (var i = 0; i < cues.length; i += 1) {
    final cue = cues[i];
    final prevLimit = i > 0 ? out[i - 1].displayEndMs! : 0;
    final nextLimit = i < cues.length - 1 ? cues[i + 1].startMs.toDouble() : double.infinity;
    final startSeg = vad.where((seg) => seg.startMs <= cue.startMs && seg.endMs > cue.startMs).firstOrNull;
    final endSeg = vad.where((seg) => seg.startMs < cue.endMs && seg.endMs >= cue.endMs).firstOrNull;
    final displayStartMs = startSeg != null ? math.max(math.max(startSeg.startMs, cue.startMs - maxPadMs), prevLimit) : cue.startMs;
    final displayEndMs = endSeg != null ? math.min(math.min(endSeg.endMs, cue.endMs + maxPadMs).toDouble(), nextLimit).toInt() : cue.endMs;
    out.add(cue.copyWith(displayStartMs: math.min(displayStartMs, cue.startMs), displayEndMs: math.max(displayEndMs, cue.endMs)));
  }
  return out;
}

// ── 교정 제안 ──────────────────────────────────────────────
class ProposalCheck {
  const ProposalCheck({required this.ok, this.reason});

  final bool ok;
  final String? reason;
}

ProposalCheck validateProposal(Object? proposal, List<String> knownIds) {
  if (proposal is! Map) return const ProposalCheck(ok: false, reason: '형식');
  final keys = [for (final key in proposal.keys) '$key'];
  if (keys.any(isTimeField)) return const ProposalCheck(ok: false, reason: '시간 변경 필드');
  if (keys.any((key) => !proposalFields.contains(key))) return const ProposalCheck(ok: false, reason: '허용하지 않는 필드');
  if (!knownIds.contains(proposal['id'])) return const ProposalCheck(ok: false, reason: '알 수 없는 ID');
  final text = proposal['text'];
  if (text is! String || text.trim().isEmpty) return const ProposalCheck(ok: false, reason: '빈 필수값');
  return const ProposalCheck(ok: true);
}

class ReviewProposal {
  const ReviewProposal({
    required this.id,
    required this.text,
    required this.reason,
    required this.source,
    required this.uncertainty,
    required this.needsReview,
  });

  factory ReviewProposal.fromJson(Json json) => ReviewProposal(
    id: json.str('id'),
    text: json.str('text'),
    reason: json.str('reason'),
    source: json.str('source'),
    uncertainty: json.str('uncertainty'),
    needsReview: json.flag('needsReview'),
  );

  final String id;
  final String text;
  final String reason;
  final String source;
  final String uncertainty;
  final bool needsReview;

  Map<String, Object?> toJson() => {'id': id, 'text': text, 'reason': reason, 'source': source, 'uncertainty': uncertainty, 'needsReview': needsReview};
}

// decisions: { proposalId: "accepted" | "held" }. 수락된 제안만 화면 문구를 바꾸고, 그 자막은 다시 정렬할 상태가 된다.
List<SubtitleCue> applyDecisions(List<SubtitleCue> cues, List<ReviewProposal> proposals, [Map<String, String> decisions = const {}]) => [
  for (final cue in cues)
    () {
      final proposal = proposals.where((item) => item.id == cue.id).firstOrNull;
      final decision = proposal != null ? (decisions[proposal.id] ?? 'pending') : null;
      if (proposal != null && decision == 'accepted') {
        return cue.copyWith(text: proposal.text, hasDecision: true, decision: decision, alignmentStale: true);
      }
      return cue.copyWith(hasDecision: true, decision: decision, alignmentStale: false);
    }(),
];

// ── SRT ───────────────────────────────────────────────────
String formatSrtTime(num ms) {
  final rounded = ms.isFinite ? (ms + 0.5).floor() : 0;
  final value = math.max(0, rounded);
  return '${padZero(value ~/ 3600000)}:${padZero((value ~/ 60000) % 60)}:${padZero((value ~/ 1000) % 60)},${padZero(value % 1000, 3)}';
}

String formatSeconds(num ms) => '${(ms / 1000).toStringAsFixed(2)}초';

String toSrt(List<SubtitleCue> cues) {
  final sorted = stableSorted(cues, (a, b) => a.displayStart.compareTo(b.displayStart));
  return [
    for (final (index, cue) in sorted.indexed) '${index + 1}\n${formatSrtTime(cue.displayStart)} --> ${formatSrtTime(cue.displayEnd)}\n${cue.text}',
  ].join('\n\n');
}

// ── 예시 데이터 ─────────────────────────────────────────────
class DebateRound {
  const DebateRound({required this.round, required this.claude, required this.reason});

  final int round;
  final String claude;
  final String reason;

  Map<String, Object?> toJson() => {'round': round, 'claude': claude, 'reason': reason};
}

/// WALKTHROUGH_FIXTURE(가상 대사·정수 ms). 원본 녹음·전사·로그가 아니다.
class WalkthroughFixture {
  WalkthroughFixture.fromJson(Json json)
    : durationMs = json.integer('durationMs'),
      referenceModel = json.obj('models').str('reference'),
      compareModel = json.obj('models').str('compare'),
      words = [for (final word in json.objs('words')) AlignedWord.fromJson(word)],
      compareDiffIndex = json.obj('compareDiff').integer('index'),
      compareDiffText = json.obj('compareDiff').str('text'),
      vad = [for (final seg in json.objs('vad')) TimeSpan.fromJson(seg)],
      displayTexts = json.strings('displayTexts'),
      codexSentences = json.obj('split').obj('codex')['sentences'],
      codexReason = json.obj('split').obj('codex').str('reason'),
      claudeSentences = json.obj('split').obj('claude')['sentences'],
      claudeReason = json.obj('split').obj('claude').str('reason'),
      debate = [
        for (final round in json.obj('split').objs('debate'))
          DebateRound(round: round.integer('round'), claude: round.str('claude'), reason: round.str('reason')),
      ],
      rawProposals = json.objs('proposals'),
      proposalOpinions = json.texts('proposalOpinions');

  final int durationMs;
  final String referenceModel;
  final String compareModel;
  final List<AlignedWord> words;
  final int compareDiffIndex;
  final String compareDiffText;
  final List<TimeSpan> vad;
  final List<String> displayTexts;
  final Object? codexSentences;
  final String codexReason;
  final Object? claudeSentences;
  final String claudeReason;
  final List<DebateRound> debate;

  /// 응답 원문(검증 전). 형식이 맞는 것만 buildWalkthrough 가 제안으로 받는다.
  final List<Json> rawProposals;
  final Map<String, String> proposalOpinions;
}

class SplitResult {
  const SplitResult({
    required this.codexCuts,
    required this.claudeCuts,
    required this.agreed,
    required this.disputed,
    required this.resolved,
    required this.cuts,
    required this.debate,
    required this.codexReason,
    required this.claudeReason,
  });

  final List<int> codexCuts;
  final List<int> claudeCuts;
  final List<int> agreed;
  final List<int> disputed;
  final List<int> resolved;
  final List<int> cuts;
  final List<DebateRound> debate;
  final String codexReason;
  final String claudeReason;

  Map<String, Object?> toJson() => {
    'codexCuts': codexCuts,
    'claudeCuts': claudeCuts,
    'agreed': agreed,
    'disputed': disputed,
    'resolved': resolved,
    'cuts': cuts,
    'debate': [for (final round in debate) round.toJson()],
    'codexReason': codexReason,
    'claudeReason': claudeReason,
  };
}

class Walkthrough {
  const Walkthrough({
    required this.durationMs,
    required this.words,
    required this.rawText,
    required this.vad,
    required this.whole,
    required this.pauses,
    required this.levels,
    required this.split,
    required this.cues,
    required this.proposals,
  });

  final int durationMs;
  final List<AlignedWord> words;
  final String rawText;
  final List<TimeSpan> vad;
  final SubtitleCue whole;
  final List<WordPause> pauses;
  final List<int> levels;
  final SplitResult split;
  final List<SubtitleCue> cues;
  final List<ReviewProposal> proposals;

  Map<String, Object?> toJson() => {
    'durationMs': durationMs,
    'words': [for (final word in words) word.toJson()],
    'rawText': rawText,
    'vad': [for (final seg in vad) seg.toJson()],
    'whole': whole.toJson(),
    'pauses': [for (final pause in pauses) pause.toJson()],
    'levels': levels,
    'split': split.toJson(),
    'cues': [for (final cue in cues) cue.toJson()],
    'proposals': [for (final proposal in proposals) proposal.toJson()],
  };
}

// 화면은 이 결과(작은 고정 객체)만 읽는다. 사람의 결정(decisions)은 SRT 단계에서 finalCues 로 반영한다.
Walkthrough buildWalkthrough(WalkthroughFixture fixture) {
  final words = fixture.words;
  final vad = fixture.vad;
  final whole = padDisplay([cueFromWords(words, 0, words.length - 1)], vad);
  final pauses = wordPauses(words, vad);
  final levels = levelsFor(words, fixture.durationMs);
  final codexCuts = sentencesToCuts(words, fixture.codexSentences);
  final claudeCuts = sentencesToCuts(words, fixture.claudeSentences);
  if (codexCuts == null || claudeCuts == null) throw StateError('예시 문장 나누기 응답이 원래 글자와 다릅니다');
  // 두 AI 가 같은 곳은 바로, 갈린 곳은 토론 마지막 판단이 동의일 때만 반영한다.
  final agreed = [
    for (final cut in codexCuts)
      if (claudeCuts.contains(cut)) cut,
  ];
  final disputed = [
    for (final cut in [...codexCuts, ...claudeCuts])
      if (!(codexCuts.contains(cut) && claudeCuts.contains(cut))) cut,
  ];
  final lastRound = fixture.debate.lastOrNull;
  final resolved = lastRound != null && lastRound.claude == '동의' ? disputed : <int>[];
  final cuts = stableSorted([...agreed, ...resolved], (a, b) => a - b);
  final cues = [for (final (i, cue) in padDisplay(splitAtWordCuts(words, cuts), vad).indexed) cue.copyWith(id: 'cue-${i + 1}', text: fixture.displayTexts[i])];
  final knownIds = [for (final cue in cues) cue.id!];
  final proposals = [
    for (final raw in fixture.rawProposals)
      if (validateProposal(raw, knownIds).ok) ReviewProposal.fromJson(raw),
  ];
  return Walkthrough(
    durationMs: fixture.durationMs,
    words: [
      for (final (index, word) in words.indexed)
        AlignedWord(
          text: word.text,
          startMs: word.startMs,
          endMs: word.endMs,
          index: index,
          risk: fixture.compareDiffIndex == index ? fixture.compareDiffText : null,
        ),
    ],
    rawText: words.map((word) => word.text).join(' '),
    vad: vad,
    whole: whole.first,
    pauses: pauses,
    levels: levels,
    split: SplitResult(
      codexCuts: codexCuts,
      claudeCuts: claudeCuts,
      agreed: agreed,
      disputed: disputed,
      resolved: resolved,
      cuts: cuts,
      debate: fixture.debate,
      codexReason: fixture.codexReason,
      claudeReason: fixture.claudeReason,
    ),
    cues: cues,
    proposals: proposals,
  );
}

List<SubtitleCue> finalCues(Walkthrough walkthrough, Map<String, String> decisions) => applyDecisions(walkthrough.cues, walkthrough.proposals, decisions);

// ── 단계 이동(재생기) ───────────────────────────────────────
// state: { stage, playing }. 이전·다음·고르기는 멈춘다. 끝에서 재생하면 처음부터 한 번 다시(자동 반복 없음).
const int stageIntervalMs = 2600;

class StageState {
  const StageState({required this.stage, required this.playing});

  final int stage;
  final bool playing;

  @override
  bool operator ==(Object other) => other is StageState && other.stage == stage && other.playing == playing;

  @override
  int get hashCode => Object.hash(stage, playing);

  @override
  String toString() => 'StageState($stage, playing: $playing)';
}

sealed class StageAction {
  const StageAction();
}

class StagePrev extends StageAction {
  const StagePrev();
}

class StageNext extends StageAction {
  const StageNext();
}

class StageSeek extends StageAction {
  const StageSeek(this.stage);

  final Object? stage;
}

class StagePlay extends StageAction {
  const StagePlay();
}

class StagePause extends StageAction {
  const StagePause();
}

class StageReset extends StageAction {
  const StageReset();
}

class StageTick extends StageAction {
  const StageTick();
}

StageState stageReducer(StageState state, StageAction action, int total) {
  final last = total - 1;
  int clamp(int value) => math.min(last, math.max(0, value));
  switch (action) {
    case StagePrev():
      return StageState(stage: clamp(state.stage - 1), playing: false);
    case StageNext():
      return StageState(stage: clamp(state.stage + 1), playing: false);
    case StageSeek(:final stage):
      return jsIsInteger(stage) ? StageState(stage: clamp((stage! as num).toInt()), playing: false) : state;
    case StagePlay():
      return StageState(stage: state.stage >= last ? 0 : state.stage, playing: true);
    case StagePause():
      return state.playing ? StageState(stage: state.stage, playing: false) : state;
    case StageReset():
      return const StageState(stage: 0, playing: false);
    case StageTick():
      if (!state.playing) return state;
      return state.stage + 1 >= last ? StageState(stage: last, playing: false) : StageState(stage: state.stage + 1, playing: true);
  }
}
