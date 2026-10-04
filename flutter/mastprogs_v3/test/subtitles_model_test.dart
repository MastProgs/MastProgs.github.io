// Voice to SRT 순수 모델 ↔ React 기준(test/fixtures/subtitles-golden.json) 차등 비교와 경계·실패 입력 검사.
// 원본 tests/subtitles.test.mjs 의 규칙(시간 필드 거부, 글자 변경 거부, 단어 중간 경계 거부, VAD ≤300ms, 결정 반영, 2600ms 재생기)을 같은 기대값으로 고정한다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/core/json.dart';
import 'package:mastprogs_v3/features/subtitles/model/subtitles_content.dart';
import 'package:mastprogs_v3/features/subtitles/model/subtitles_model.dart';

import 'support/fixtures.dart';

void main() {
  final content = SubtitlesContent.fromJson(readData('subtitles'));
  final fix = content.fixture;
  final walk = buildWalkthrough(fix);
  final golden = asJson(readFixture('subtitles-golden'));

  test('walkthrough equals the React buildWalkthrough output', () {
    expect(walk.toJson(), equals(golden['walkthrough']));
  });

  test('final cues and SRT for every golden decision state', () {
    for (final state in golden.objs('states')) {
      final decisions = state.texts('decisions');
      final cues = finalCues(walk, decisions);
      expect([for (final cue in cues) cue.toJson()], equals(state['cues']), reason: state.str('decision'));
      expect(toSrt(cues), state['srt'], reason: state.str('decision'));
    }
  });

  test('break times come only from aligned word times', () {
    expect(walk.split.codexCuts, [4, 9]);
    expect(walk.split.claudeCuts, [4]);
    expect(walk.split.agreed, [4]);
    expect(walk.split.disputed, [9]);
    expect(walk.split.cuts, [4, 9]);
    expect(fix.debate.length, lessThanOrEqualTo(2));
    for (final cue in walk.cues) {
      expect(cue.startMs, fix.words[cue.from!].startMs);
      expect(cue.endMs, fix.words[cue.to!].endMs);
    }
  });

  test('sentence validation rejects changed letters, time fields, empty sentences and mid-word boundaries', () {
    final words = fix.words;
    final joined = (fix.codexSentences as List).join(' ');
    expect(sentencesToCuts(words, ['자 그럼 오늘 일정부터 확인할게요', '먼저 장비를 점검하고 광장에서 모입시다 아 잠깐만요']), isNull);
    expect(sentencesToCuts(words, ['자 그럼 오늘 일정부터 확인할게요']), isNull);
    expect(
      sentencesToCuts(words, [
        {'text': joined, 'startMs': 0},
      ]),
      isNull,
    );
    expect(
      sentencesToCuts(words, [
        {'text': joined, 'end': 10},
      ]),
      isNull,
    );
    expect(sentencesToCuts(words, [joined, ' . ']), isNull);
    expect(sentencesToCuts(words, ['자 그럼 오늘 일정', '부터 확인할게요 먼저 장비를 점검하고 광장애서 모입시다 아 잠깐만요']), isNull);
    expect(
      sentencesToCuts(words, [
        {'text': '자, 그럼 오늘 일정부터 확인할게요.'},
        {'text': '먼저 장비를 점검하고 광장애서 모입시다. 아, 잠깐만요!', 'reason': 'x'},
      ]),
      [4],
    );
    expect(sentencesToCuts(words, []), isNull, reason: 'empty response');
    expect(sentencesToCuts(words, 'not a list'), isNull);
    expect(sentencesToCuts(words, [42]), isNull, reason: 'non-text item');
    expect(
      sentencesToCuts(words, [
        {'text': 7},
      ]),
      isNull,
      reason: 'non-string text',
    );
    expect(() => splitAtWordCuts(words, [11]), throwsArgumentError);
    expect(() => splitAtWordCuts(words, [1.5]), throwsArgumentError);
    expect(() => splitAtWordCuts(words, [-1]), throwsArgumentError);
    expect(() => cueFromWords(words, 3, 2), throwsRangeError);
    expect(splitAtWordCuts(words, [9, 4, 4.0]).map((cue) => [cue.from, cue.to]).toList(), [
      [0, 4],
      [5, 9],
      [10, 11],
    ], reason: 'dedupe + numeric sort');
  });

  test('pauses use the longer of the word gap and the VAD silence; levels are 0..9 per 100 ms', () {
    expect(
      [
        for (final pause in walk.pauses) [pause.after, pause.ms],
      ],
      [
        [4, 640],
        [9, 420],
      ],
    );
    const words = [AlignedWord(text: '가', startMs: 0, endMs: 900), AlignedWord(text: '나', startMs: 950, endMs: 1500)];
    expect(wordPauses(words, const [TimeSpan(startMs: 0, endMs: 500), TimeSpan(startMs: 1000, endMs: 1500)]).map((p) => p.ms), [500]);
    expect(wordPauses(words), isEmpty, reason: '50 ms gap is below the 300 ms mark');
    expect(walk.levels.length, fix.durationMs ~/ 100);
    expect(walk.levels.every((level) => level >= 0 && level <= 9), isTrue);
    expect(levelsFor(fix.words, fix.durationMs), walk.levels);
  });

  test('display padding: at most 0.3 s, only into VAD speech, never shrinks, never crosses neighbours, raw times preserved', () {
    expect([walk.whole.startMs, walk.whole.endMs], [300, 7180]);
    expect([walk.whole.displayStartMs, walk.whole.displayEndMs], [260, 7480]);
    expect(
      [
        for (final cue in walk.cues) [cue.displayStartMs, cue.displayEndMs],
      ],
      [
        [260, 2700],
        [3100, 5900],
        [6150, 7480],
      ],
    );
    for (final (i, cue) in walk.cues.indexed) {
      expect(cue.displayStartMs! <= cue.startMs && cue.displayEndMs! >= cue.endMs, isTrue);
      expect(cue.startMs - cue.displayStartMs!, lessThanOrEqualTo(maxDisplayPadMs));
      expect(cue.displayEndMs! - cue.endMs, lessThanOrEqualTo(maxDisplayPadMs));
      if (i > 0) expect(cue.displayStartMs!, greaterThanOrEqualTo(walk.cues[i - 1].displayEndMs!));
    }
    final tight = padDisplay(
      const [SubtitleCue(startMs: 1000, endMs: 2000), SubtitleCue(startMs: 2100, endMs: 3000)],
      const [TimeSpan(startMs: 500, endMs: 3600)],
    );
    expect(
      [
        for (final cue in tight) [cue.displayStartMs, cue.displayEndMs],
      ],
      [
        [700, 2100],
        [2100, 3300],
      ],
    );
    expect(
      [
        for (final cue in tight) [cue.startMs, cue.endMs],
      ],
      [
        [1000, 2000],
        [2100, 3000],
      ],
    );
    final silent = padDisplay(const [SubtitleCue(startMs: 1000, endMs: 2000)], const [TimeSpan(startMs: 5000, endMs: 6000)]);
    expect([silent.first.displayStartMs, silent.first.displayEndMs], [1000, 2000]);
    final noVad = padDisplay(const [SubtitleCue(startMs: 10, endMs: 20)], const []);
    expect([noVad.first.displayStartMs, noVad.first.displayEndMs], [10, 20], reason: 'no VAD → no padding');
  });

  test('proposal schema: time fields, unknown ids, extra fields and empty text are rejected', () {
    final ids = [for (final cue in walk.cues) cue.id!];
    final base = fix.rawProposals.first;
    expect(proposalFields, ['id', 'text', 'reason', 'source', 'uncertainty', 'needsReview']);
    expect(content.proposalFieldsShown, proposalFields);
    expect(walk.proposals, hasLength(1));
    expect(validateProposal(base, ids).ok, isTrue);
    expect(validateProposal({...base, 'startMs': 10}, ids).reason, '시간 변경 필드');
    expect(validateProposal({...base, 'endMs': 10}, ids).reason, '시간 변경 필드');
    expect(validateProposal({...base, 'durationSec': 1}, ids).reason, '시간 변경 필드');
    expect(validateProposal({...base, 'extra': 1}, ids).reason, '허용하지 않는 필드');
    expect(validateProposal({...base, 'id': 'cue-9'}, ids).reason, '알 수 없는 ID');
    expect(validateProposal({...base, 'text': '  '}, ids).reason, '빈 필수값');
    expect(validateProposal({...base, 'text': 3}, ids).reason, '빈 필수값');
    expect(validateProposal(null, ids).reason, '형식');
    expect(validateProposal('cue-2', ids).reason, '형식');
  });

  test('human decisions: pending/held keep the text, accepted replaces it and marks re-alignment; SRT follows', () {
    final pending = finalCues(walk, const {});
    final held = finalCues(walk, const {'cue-2': 'held'});
    final accepted = finalCues(walk, const {'cue-2': 'accepted'});
    expect(pending[1].text, fix.displayTexts[1]);
    expect(held[1].text, fix.displayTexts[1]);
    expect(accepted[1].text, walk.proposals.first.text);
    expect([pending[1].decision, held[1].decision, accepted[1].decision], ['pending', 'held', 'accepted']);
    expect(accepted[1].alignmentStale, isTrue);
    expect(pending[0].decision, isNull);
    for (final list in [pending, held, accepted]) {
      for (final (i, cue) in list.indexed) {
        expect([cue.displayStartMs, cue.displayEndMs], [walk.cues[i].displayStartMs, walk.cues[i].displayEndMs]);
      }
    }
    expect(formatSrtTime(3723004), '01:02:03,004');
    expect(formatSrtTime(-5), '00:00:00,000');
    expect(formatSrtTime(999.5), '00:00:01,000');
    expect(
      toSrt(accepted),
      [
        '1\n00:00:00,260 --> 00:00:02,700\n자, 그럼 오늘 일정부터 확인할게요.',
        '2\n00:00:03,100 --> 00:00:05,900\n먼저 장비를 점검하고 광장에서 모입시다.',
        '3\n00:00:06,150 --> 00:00:07,480\n아, 잠깐만요!',
      ].join('\n\n'),
    );
    expect(toSrt(held), contains('광장애서'));
    expect(toSrt(accepted.reversed.toList()), startsWith('1\n00:00:00,260'));
    expect(formatSeconds(40), '0.04초');
  });

  test('stage transport: prev/next/seek pause, play from the end restarts once, ticks stop at the last stage', () {
    final total = content.stages.length;
    expect(total, 6);
    expect(stageIntervalMs, 2600);
    StageState run(StageState state, StageAction action) => stageReducer(state, action, total);
    var state = const StageState(stage: 0, playing: false);
    expect(run(state, const StagePrev()), const StageState(stage: 0, playing: false));
    state = run(state, const StagePlay());
    expect(state, const StageState(stage: 0, playing: true));
    for (var i = 0; i < 10; i += 1) {
      state = run(state, const StageTick());
    }
    expect(state, StageState(stage: total - 1, playing: false));
    expect(identical(run(state, const StageTick()), state), isTrue);
    expect(run(state, const StagePlay()), const StageState(stage: 0, playing: true));
    expect(run(const StageState(stage: 2, playing: true), const StageNext()), const StageState(stage: 3, playing: false));
    expect(run(const StageState(stage: 2, playing: true), const StageSeek(5)), const StageState(stage: 5, playing: false));
    expect(run(const StageState(stage: 2, playing: true), const StageSeek(99)), const StageState(stage: 5, playing: false));
    const fractional = StageState(stage: 2, playing: true);
    expect(identical(run(fractional, const StageSeek(1.5)), fractional), isTrue, reason: 'non-integer seek is ignored');
    expect(run(const StageState(stage: 3, playing: true), const StageReset()), const StageState(stage: 0, playing: false));
    const same = StageState(stage: 1, playing: false);
    expect(identical(run(same, const StagePause()), same), isTrue);
  });
}
