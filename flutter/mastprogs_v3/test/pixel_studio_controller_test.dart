// /sprite 컨트롤러 동작(React usePixelPreview·studio·playback 규칙 + 계획 동결 항목):
// 원본 프레임 길이(ms) 그대로의 타이머, 화면 밖·탭 가림·동작 줄이기, 자동 연출 차례 0..6, 세트·비율 선택도 연출 중단, 색 설정은 재생 유지,
// 모션 직접 선택(셔플 끔·같은 모션 유지·hold 반복)과 셔플 재개, 어니언 0.1..1, 레이어 보기, 캐시 상한, 장시간 재생.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/content/content_repository.dart';
import 'package:mastprogs_v3/core/json.dart';
import 'package:mastprogs_v3/features/portfolio/portfolio_content.dart';
import 'package:mastprogs_v3/features/sprite/controller/pixel_studio_controller.dart';
import 'package:mastprogs_v3/features/sprite/model/lru_cache.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_layers.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_palette_sets.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_playback.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_rig.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_studio.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_studio_content.dart';
import 'package:mastprogs_v3/features/sprite/model/sprite_meta.dart';

import 'support/fake_timers.dart';
import 'support/fixtures.dart';

/// 원본 테스트의 고정 난수(seeded)와 같은 선형 합동 생성기.
Rng seeded(int seed) {
  var state = seed;
  return () {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    return state / 0x80000000;
  };
}

void main() {
  final page = SpritePageData(
    site: SiteContent.fromJson(readData('site')),
    content: PixelStudioContent.fromJson(readData('pixelStudio')),
    sprite: SpriteMeta.fromJson(readData('pixel-assets')),
  );
  final studio = SpriteStudioData(
    layers: PixelLayerModel.fromJson(asJson(readJsonFile('assets/data/pixel-layers.json'))),
    colorTable: sourceColorTable(readJsonFile('assets/data/pixel-source-colors.json') as List),
    sets: buildPaletteSets(asJsonList(readJsonFile('assets/data/pixel-palette-sets.json'))),
    rig: buildRig(asJson(readJsonFile('assets/data/pixel-rig.json'))),
    motionRig: asJson(readJsonFile('assets/data/pixel-motion-rig.json')),
  );

  PixelStudioController create(FakeTimers timers, {bool reduced = false, ValueNotifier<bool>? hidden, String theme = 'dark', int seed = 7}) {
    final controller = PixelStudioController(page: page, theme: theme, reducedMotion: reduced, pageHidden: hidden, rng: seeded(seed), timerFactory: timers.call)
      ..attachStudio(studio);
    addTearDown(controller.dispose);
    return controller;
  }

  test('original data: 20 layers, 28 frames, exact per-frame durations from pixel-assets.json', () {
    expect(studio.layers.layers, hasLength(20));
    expect(studio.layers.frames, hasLength(28));
    expect([studio.layers.width, studio.layers.height, studio.layers.pivotX, studio.layers.soleRow, studio.layers.crownRow], [84, 89, 38, 79, 23]);
    expect(studio.sets, hasLength(10));
    expect(page.sprite.frameMs, {
      'walk': [130, 110, 120, 110, 130, 110, 120, 110],
      'run': [90, 100, 80, 90, 90, 100, 80, 90],
      'attack': [60, 40, 60, 60, 120, 40, 40, 110, 90, 90, 90, 120],
    });
    for (final frame in studio.layers.frames) {
      expect(compositeFrame(studio.layers, frame.index).indices, equals(compositeReference(studio.layers, frame.index)), reason: frame.key);
    }
  });

  test('initial view state: sword, onion on at 0.35, guides on, shuffle on, AAP-64 at 100%, auto showcase', () {
    final timers = FakeTimers();
    final c = create(timers);
    expect(c.ready, StudioReady.ready);
    expect(studio.layers.layers[c.selectedLayer].name, 'sword');
    expect([c.onionOn, c.onionOpacity, c.guidesOn, c.shuffleOn, c.isolated], [true, 0.35, true, true, false]);
    expect([c.style.setId, c.style.ratio, c.style.presetId, c.style.outlineOn, c.showcase], ['aap64', 100, 'original', false, true]);
    expect(c.visibility, studio.layers.defaultVisibility);
    expect(c.playing, isTrue);
    expect(c.hasPendingTimer, isFalse, reason: 'not in view yet');
  });

  test('timer runs only while playing AND in view AND visible, each frame scheduled for its original ms', () {
    final timers = FakeTimers();
    final hidden = ValueNotifier(false);
    final c = create(timers, hidden: hidden);
    c.setInView(true);
    for (var i = 0; i < 40; i += 1) {
      final motion = page.sprite.motion(c.playback.motion);
      expect(timers.single.duration, Duration(milliseconds: motion.frames[c.playback.frame].ms), reason: 'step $i ${c.playback}');
      timers.fireActive();
    }
    c.setInView(false);
    expect(timers.active, isEmpty, reason: 'fully offscreen stops');
    c.setInView(true);
    hidden.value = true;
    expect(timers.active, isEmpty, reason: 'hidden tab stops');
    hidden.value = false;
    expect(timers.active, hasLength(1), reason: 'visible + in view + playing resumes');
    c.togglePlay();
    expect(timers.active, isEmpty);
  });

  test('reduced motion starts paused; play button is the only way to move', () {
    final timers = FakeTimers();
    final c = create(timers, reduced: true);
    c.setInView(true);
    expect(c.playing, isFalse);
    expect(timers.active, isEmpty);
    c.togglePlay();
    expect(timers.active, hasLength(1));
  });

  test('showcase: turn 0 원본/off → 1 진홍/off → 2 숲/on → 3 황금/on → 4 보라/off → 5 원본/off → 6 진홍/on', () {
    final ids = page.content.presetIds;
    expect(ids, ['original', 'crimson', 'forest', 'gold', 'violet']);
    final expected = [('original', false), ('crimson', false), ('forest', true), ('gold', true), ('violet', false), ('original', false), ('crimson', true)];
    for (final (turn, (preset, outline)) in expected.indexed) {
      final show = showcaseFor(turn, ids);
      expect([show.presetId, show.outline], [preset, outline], reason: 'turn $turn');
    }
    // 컨트롤러: 완전한 차례가 끝날 때마다 다음 연출이 적용된다(재생 중 그대로).
    final timers = FakeTimers();
    final c = create(timers);
    c.setInView(true);
    var turn = 0;
    while (c.playback.turn < 6) {
      timers.fireActive();
      if (c.playback.turn != turn) {
        turn = c.playback.turn;
        final show = showcaseFor(turn, ids);
        expect([c.style.presetId, c.style.outlineOn], [show.presetId, show.outline], reason: 'turn $turn');
        expect(c.playing, isTrue);
      }
    }
  });

  test('style changes never pause; any human style choice (incl. set and ratio) stops the showcase', () {
    for (final action in <void Function(PixelStudioController)>[
      (c) => c.selectPreset('gold'),
      (c) => c.setAccent('#123456'),
      (c) => c.toggleOutline(),
      (c) => c.setOutlineColor('#ABCDEF'),
      (c) => c.selectSet('slso8'),
      (c) => c.setRatio(35),
    ]) {
      final timers = FakeTimers();
      final c = create(timers);
      c.setInView(true);
      final timer = timers.single;
      action(c);
      expect(c.playing, isTrue);
      expect(timer.isActive, isTrue, reason: 'style edits do not re-arm or cancel the frame timer');
      expect(c.showcase, isFalse);
      // 이후 차례가 지나도 사람이 고른 설정 유지.
      final before = (c.style.presetId, c.style.outlineOn);
      while (c.playback.turn < 3) {
        timers.fireActive();
      }
      expect((c.style.presetId, c.style.outlineOn), before);
    }
  });

  test('manual pause is kept across style edits', () {
    final timers = FakeTimers();
    final c = create(timers);
    c.setInView(true);
    c.togglePlay();
    c.selectSet('db32');
    c.setRatio(50);
    expect(c.playing, isFalse);
    expect(timers.active, isEmpty);
  });

  test('outline colour: auto follows preset and theme (light = dark outline), manual is never overwritten', () {
    final timers = FakeTimers();
    final c = create(timers);
    expect(c.outlineColor, '#fff1c9');
    c.setTheme('light');
    expect(c.outlineColor, '#1c1a2e');
    c.selectPreset('crimson');
    expect(c.outlineColor, '#3b0f16');
    c.setOutlineColor('#00FF00');
    expect([c.outlineColor, c.style.outlineMode, c.style.outlineOn], ['#00ff00', 'manual', true]);
    c.selectPreset('forest');
    c.setTheme('dark');
    expect(c.outlineColor, '#00ff00');
    c.setOutlineAuto();
    expect(c.outlineColor, '#f3ffd9');
    c.setOutlineColor('not-a-colour');
    expect(c.style.outlineMode, 'auto', reason: 'invalid hex is ignored');
  });

  test('palette sets: source mode keeps the ratio, unknown ids are ignored, ratio clamps and rounds', () {
    final timers = FakeTimers();
    final c = create(timers);
    c.setRatio(62.4);
    expect(c.style.ratio, 62);
    c.setRatio(-5);
    expect(c.style.ratio, 0);
    c.setRatio('abc');
    expect(c.style.ratio, 0, reason: 'NaN ignored');
    c.setRatio(250);
    expect(c.style.ratio, 100);
    c.setRatio(40);
    c.selectSet(page.content.sourceSetId);
    expect([c.palette.mode, c.palette.set, c.style.ratio], ['source', null, 40]);
    c.selectSet('no-such-set');
    expect(c.palette.mode, 'source', reason: 'unknown ids never change the selection');
    c.selectSet('endesga32');
    expect([c.palette.mode, c.palette.set!.id, c.style.ratio], ['set', 'endesga32', 40]);
    // 0% 는 세트 직전 결과와 바이트 동일.
    c.setRatio(0);
    final zero = c.currentImage.data;
    c.selectSet(page.content.sourceSetId);
    expect(c.currentImage.data, equals(zero));
  });

  test('selectMotion: switches off shuffle, resets frame/loop only for a different motion, keeps playing; hold loops the same motion', () {
    final timers = FakeTimers();
    final c = create(timers);
    c.setInView(true);
    timers.fireActive();
    timers.fireActive();
    final current = c.playback.motion;
    final frame = c.playback.frame;
    c.selectMotion(current);
    expect([c.playback.motion, c.playback.frame, c.shuffleOn, c.playing], [current, frame, false, true]);
    final other = page.sprite.motions.map((m) => m.id).firstWhere((id) => id != current);
    final turn = c.playback.turn;
    c.selectMotion(other);
    expect([c.playback.motion, c.playback.frame, c.playback.loop, c.playback.turn, c.playing], [other, 0, 0, turn, true]);
    // hold: 셔플 끔이면 같은 모션을 계속 돈다.
    for (var i = 0; i < 60; i += 1) {
      timers.fireActive();
      expect(c.playback.motion, other);
    }
    // 셔플을 다시 켜면 다음 모션은 지금 모션이 아니다.
    c.toggleShuffle();
    while (c.playback.motion == other) {
      timers.fireActive();
    }
    expect(c.playback.motion, isNot(other));
  });

  test('frame inspection pauses: prev/next wrap for loops and clamp for attack; slider and cell pick pause', () {
    final timers = FakeTimers();
    final c = create(timers);
    c.setInView(true);
    c.selectMotion('walk');
    c.stepFrameBy(-1);
    expect([c.playing, c.playback.frame], [false, 7], reason: 'walk wraps');
    expect(timers.active, isEmpty);
    c.togglePlay();
    c.selectMotion('attack');
    c.stepFrameBy(-1);
    expect([c.playing, c.playback.frame], [false, 0], reason: 'attack clamps at the start');
    c.selectFrame(99);
    expect(c.playback.frame, 11);
    c.stepFrameBy(1);
    expect(c.playback.frame, 11, reason: 'attack clamps at the end');
    c.togglePlay();
    c.selectCell(3, 4);
    expect([c.selectedLayer, c.playback.frame, c.playing], [3, 4, false]);
  });

  test('onion opacity accepts only finite numbers clamped to 0.1..1; neighbours stay in the motion', () {
    final timers = FakeTimers();
    final c = create(timers);
    c.setOnionOpacity(0.02);
    expect(c.onionOpacity, 0.1);
    c.setOnionOpacity(4);
    expect(c.onionOpacity, 1);
    c.setOnionOpacity(double.nan);
    expect(c.onionOpacity, 1);
    c.setOnionOpacity('0.5');
    expect(c.onionOpacity, 0.5);
    c.setOnionOpacity('x');
    expect(c.onionOpacity, 0.5);
    c.selectMotion('attack');
    c.selectFrame(0);
    expect([c.neighbors.prev, c.neighbors.next], [null, 1]);
    c.selectMotion('run');
    c.selectFrame(0);
    expect([c.neighbors.prev, c.neighbors.next], [7, 1]);
  });

  test('layer view: toggle, isolate, reset; isolation renders only the selected layer pixels', () {
    final timers = FakeTimers();
    final c = create(timers);
    final sword = c.selectedLayer;
    c.toggleLayer(sword);
    expect(c.visibility[sword], isFalse);
    c.toggleIsolate();
    expect(c.effectiveVisibility, isolateLayer(studio.layers, sword));
    expect(c.frameKey(PixelImageKind.current), contains('|${visibilityKey(isolateLayer(studio.layers, sword))}|'));
    c.resetLayers();
    expect([c.isolated, c.visibility], [false, studio.layers.defaultVisibility]);
  });

  test('caches stay bounded over a simulated 10-minute run (no exceptions, frame cache ≤ 96)', () {
    final timers = FakeTimers();
    final c = create(timers);
    c.setInView(true);
    var elapsed = 0;
    var step = 0;
    while (elapsed < 10 * 60 * 1000) {
      final timer = timers.single;
      elapsed += timer.duration.inMilliseconds;
      timer.fire();
      // 그리는 쪽이 하는 것처럼 매 프레임 그림을 만든다(어니언 포함).
      c.stageImage;
      if (step % 50 == 0) {
        c.selectSet(studio.sets[step ~/ 50 % studio.sets.length].id);
        c.setRatio(step % 100);
      }
      step += 1;
    }
    final sizes = c.cacheSizes;
    expect(sizes.frames, lessThanOrEqualTo(frameCacheLimit));
    expect(sizes.maps, lessThanOrEqualTo(mapCacheLimit));
    expect(sizes.nearest, lessThanOrEqualTo(nearestCacheLimit));
    expect(step, greaterThan(5000));
  });

  test('LRU cache evicts the least recently used entry and disposes evicted values', () {
    final evicted = <String>[];
    final cache = LruCache<String, String>(3, onEvict: evicted.add);
    for (final key in ['a', 'b', 'c']) {
      cache.set(key, key);
    }
    cache.get('a');
    cache.set('d', 'd');
    expect(cache.size, 3);
    expect(cache.get('b'), isNull);
    expect(evicted, ['b']);
    expect(cache.get('a'), 'a');
    cache.clear();
    // 남은 순서는 c, d, a(방금 읽은 a 가 가장 최근) 이므로 그 순서로 정리된다.
    expect(evicted, ['b', 'c', 'd', 'a']);
    expect(() => LruCache<String, String>(0), throwsArgumentError);
  });

  test('shuffle bag: every bag holds all three motions, no back-to-back repeats, resumeFrom avoids the current motion', () {
    for (final seed in [1, 42, 2026]) {
      final bag = ShuffleBag(['walk', 'run', 'attack'], seeded(seed));
      final draws = [for (var i = 0; i < 300; i += 1) bag.next()];
      for (var i = 0; i < draws.length; i += 3) {
        expect((draws.sublist(i, i + 3)..sort()), ['attack', 'run', 'walk']);
      }
      for (var i = 1; i < draws.length; i += 1) {
        expect(draws[i], isNot(draws[i - 1]));
      }
      for (var round = 0; round < 50; round += 1) {
        bag.next();
        final current = ['walk', 'run', 'attack'][round % 3];
        bag.resumeFrom(current);
        final next3 = [bag.next(), bag.next(), bag.next()];
        expect(next3.first, isNot(current));
        expect((next3..sort()), ['attack', 'run', 'walk']);
      }
    }
    expect(() => ShuffleBag<String>([]), throwsStateError);
  });

  test('planTick ignores stale timers and draws from the bag only at the end of the last cycle', () {
    final motions = page.sprite.frameMs;
    var draws = 0;
    String draw() {
      draws += 1;
      return 'run';
    }

    const walkEnd = PlaybackState(motion: 'walk', frame: 7, loop: 1, turn: 0);
    // 같은 값이라도 새로 만든 상태(그 사이 다른 조작)면 오래된 타이머다(const 는 같은 객체라 copyWith 로 새로 만든다).
    expect(planTick(snapshot: walkEnd, latest: walkEnd.copyWith(), motions: motions, hold: false, draw: draw), isNull);
    expect(draws, 0);
    final update = planTick(snapshot: walkEnd, latest: walkEnd, motions: motions, hold: false, draw: draw)!;
    expect(draws, 1);
    expect(update(walkEnd), const PlaybackState(motion: 'run', frame: 0, loop: 0, turn: 1));
    const mid = PlaybackState(motion: 'walk', frame: 7, loop: 0, turn: 0);
    planTick(snapshot: mid, latest: mid, motions: motions, hold: false, draw: draw);
    expect(draws, 1, reason: 'first of two walk cycles does not draw');
    const held = PlaybackState(motion: 'attack', frame: 11, loop: 0, turn: 3);
    expect(
      planTick(snapshot: held, latest: held, motions: motions, hold: true, draw: draw)!(held),
      const PlaybackState(motion: 'attack', frame: 0, loop: 0, turn: 3),
    );
    expect(draws, 1);
  });

  test('fallback: if the original data cannot be built, the preview stays on the original GIF', () {
    final timers = FakeTimers();
    final c = PixelStudioController(page: page, theme: 'dark', reducedMotion: false, timerFactory: timers.call);
    addTearDown(c.dispose);
    c.markFallback(StateError('no data'));
    expect(c.ready, StudioReady.fallback);
    c.setInView(true);
    expect(timers.active, hasLength(1), reason: 'the GIF/static frame still follows the cursor timing');
  });

  test('styleReducer guards: invalid preset/accent/set are no-ops; showcase ignored once touched', () {
    final content = page.content;
    final initial = StudioStyle.initial(content);
    expect(identical(styleReducer(content, studio.sets, initial, const PresetStyle('nope')), initial), isTrue);
    expect(identical(styleReducer(content, studio.sets, initial, const AccentStyle('#12')), initial), isTrue);
    expect(identical(styleReducer(content, studio.sets, initial, const SetStyle('nope')), initial), isTrue);
    expect(identical(styleReducer(content, studio.sets, initial, const OutlineAutoStyle()), initial), isTrue);
    final touched = styleReducer(content, studio.sets, initial, const RatioStyle(10));
    expect(identical(styleReducer(content, studio.sets, touched, const ShowcaseStyle(presetId: 'gold', outline: true)), touched), isTrue);
  });
}
