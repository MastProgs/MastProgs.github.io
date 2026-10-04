// /sprite 장시간 재생의 네이티브 그림 생성 회귀(브라우저 soak 에서 99분 뒤 CanvasKit 힙 고갈).
// 원인: 올린 그림 캐시가 재생이 실제로 거치는 서로 다른 그림 수보다 작아 LRU 적중이 0 → 프레임마다 새 네이티브 그림 생성·삭제.
// 실제 컨트롤러와 PixelImageView 4개(무대·현재·레이어·중심 비교)로
// - 손대지 않은 기본 자동 연출: 연출 한 주기(프리셋 × 외곽선)를 다 돈 뒤 다음 주기 동안 새 업로드 0, 축출 0, 살아 있는 ui.Image 일정
// - soak 의 직접 설정(숲·SLSO8 100%·외곽선 자동·어니언 0.35·셔플): 한 바퀴 뒤 새 업로드 0
// - 사람이 고르면 한도가 한 스타일 묶음으로 줄고 넘친 그림은 즉시 dispose, 테마 전환 뒤에도 한도 유지
// 를 확인한다. 화면 그림의 바이트(골든)는 바꾸지 않는다.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/content/content_repository.dart';
import 'package:mastprogs_v3/core/json.dart';
import 'package:mastprogs_v3/features/portfolio/portfolio_content.dart';
import 'package:mastprogs_v3/features/sprite/controller/pixel_studio_controller.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_layers.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_palette_sets.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_playback.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_rig.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_studio_content.dart';
import 'package:mastprogs_v3/features/sprite/model/sprite_meta.dart';
import 'package:mastprogs_v3/features/sprite/view/pixel_image_view.dart';

import 'support/fake_timers.dart';
import 'support/fixtures.dart';

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
  final frames = studio.layers.frames.length;
  final period = page.content.presetIds.length * 4; // showcaseFor 의 프리셋·외곽선 주기(차례 수)

  test('derived budgets: 10 showcase styles per theme, 4 kinds × 28 frames, documented hard bound', () {
    expect(page.content.presetIds, ['original', 'crimson', 'forest', 'gold', 'violet']);
    expect(frames, 28);
    for (final theme in ['dark', 'light']) {
      expect(showcaseStyleCount(page.content, theme), 10, reason: '5 presets × outline off/on (auto colour of $theme)');
    }
    expect(showcaseImageBudget(10, frames), 10 * 4 * 28 + imageCacheHeadroom); // 1136
    expect(styleImageBudget(frames), 4 * 28 + imageCacheHeadroom); // 128
    expect(showcaseImageBudget(10, frames), lessThanOrEqualTo(imageCacheHardLimit));
    expect(showcaseImageBudget(1000, frames), imageCacheHardLimit, reason: 'hard bound for any content');
  });

  Future<(PixelStudioController, FakeTimers, int Function())> harness(WidgetTester tester, {required String theme, int seed = 11}) async {
    final timers = FakeTimers();
    final controller = PixelStudioController(page: page, theme: theme, reducedMotion: false, rng: seeded(seed), timerFactory: timers.call)
      ..attachStudio(studio);
    addTearDown(controller.dispose);
    controller.setInView(true);

    var liveImages = 0;
    void track(ObjectEvent event) {
      if (event.object is! ui.Image) return;
      if (event is ObjectCreated) liveImages += 1;
      if (event is ObjectDisposed) liveImages -= 1;
    }

    FlutterMemoryAllocations.instance.addListener(track);
    addTearDown(() => FlutterMemoryAllocations.instance.removeListener(track));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Column(
            children: [
              for (final kind in PixelImageKind.values)
                SizedBox(
                  width: 86,
                  height: 91,
                  child: PixelImageView(controller: controller, kind: kind, frameKey: controller.frameKey(kind)),
                ),
            ],
          ),
        ),
      ),
    );
    return (controller, timers, () => liveImages);
  }

  Future<void> tick(WidgetTester tester, FakeTimers timers) async {
    timers.fireActive();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1)));
    await tester.pump();
  }

  testWidgets('untouched automatic showcase: after complete periods, another full period uploads nothing and evicts nothing', (tester) async {
    final (controller, timers, live) = await harness(tester, theme: 'dark');
    expect(controller.showcase, isTrue);
    expect(controller.imageBudget, showcaseImageBudget(10, frames));
    final start = debugPixelUploadCount;
    final styles = <String>{};

    // 연출 주기를 여러 번(셔플 순서는 무작위라 스타일×모션 조합이 다 채워질 때까지) 돈다.
    while (controller.playback.turn < period * 6) {
      await tick(tester, timers);
      styles.add('${controller.style.presetId}|${controller.style.outlineOn}');
    }
    expect(styles, hasLength(10), reason: 'every showcase preset/outline combination was played');
    final uploadsBefore = debugPixelUploadCount;
    final liveBefore = live();
    final endTurn = controller.playback.turn + period;
    while (controller.playback.turn < endTurn) {
      await tick(tester, timers);
    }
    expect(controller.showcase, isTrue, reason: 'auto demo kept running');
    expect(debugPixelUploadCount - uploadsBefore, 0, reason: 'a further complete showcase period re-uses every uploaded image');
    expect(live(), liveBefore);
    // 서로 다른 그림은 연출 작업 묶음(10 스타일 × 4 종류 × 28 프레임) 안이고, 한도에 닿지 않아 한도 축출이 없다.
    // (업로드 수와의 작은 차이는 첫 바퀴의 같은 키 중복 업로드로, 교체된 쪽은 set 에서 dispose 된다.)
    expect(controller.cacheSizes.images, lessThanOrEqualTo(10 * PixelImageKind.values.length * frames));
    expect(controller.cacheSizes.images, lessThan(controller.imageBudget));
    expect(debugPixelUploadCount - start - controller.cacheSizes.images, lessThanOrEqualTo(imageCacheHeadroom));
    expect(controller.playing, isTrue);
  });

  testWidgets('soak settings (picked style): after one full round, playback uploads nothing and live images stay flat', (tester) async {
    final (controller, timers, live) = await harness(tester, theme: 'light');
    controller
      ..selectPreset('forest')
      ..selectSet('slso8')
      ..toggleOutline();
    expect([controller.style.presetId, controller.style.setId, controller.style.ratio, controller.style.outlineOn], ['forest', 'slso8', 100, true]);
    expect([controller.onionOn, controller.onionOpacity, controller.shuffleOn, controller.playing], [true, 0.35, true, true]);
    expect(controller.imageBudget, styleImageBudget(frames), reason: 'manual styling permanently stops the showcase → tighter bound');

    final seen = <String>{};
    for (var i = 0; (seen.length < 3 || i < 200) && i < 2000; i += 1) {
      await tick(tester, timers);
      seen.add(controller.playback.motion);
    }
    final uploads = debugPixelUploadCount;
    final liveBefore = live();
    for (var i = 0; i < 600; i += 1) {
      await tick(tester, timers);
    }
    expect(debugPixelUploadCount - uploads, 0);
    expect(live(), liveBefore);
    expect(controller.cacheSizes.images, lessThanOrEqualTo(styleImageBudget(frames)));
  });

  testWidgets('picking a style shrinks the cache at once (evicted images disposed); theme switch keeps a bounded budget', (tester) async {
    final (controller, timers, live) = await harness(tester, theme: 'dark');
    while (controller.playback.turn < period) {
      await tick(tester, timers);
    }
    expect(controller.cacheSizes.images, greaterThan(styleImageBudget(frames)), reason: 'showcase filled more than one style');
    final liveBefore = live();
    final cachedBefore = controller.cacheSizes.images;

    controller.setTheme('light');
    expect(controller.imageBudget, showcaseImageBudget(showcaseStyleCount(page.content, 'light'), frames));
    await tick(tester, timers);

    controller.selectPreset('violet'); // 사람이 고름 → 연출 영구 중단
    await tester.pump();
    expect(controller.showcase, isFalse);
    expect(controller.imageBudget, styleImageBudget(frames));
    expect(controller.cacheSizes.images, lessThanOrEqualTo(styleImageBudget(frames)));
    expect(live(), lessThan(liveBefore), reason: 'evicted images were disposed, not leaked (cached $cachedBefore before)');

    controller.setTheme('dark');
    expect(controller.imageBudget, styleImageBudget(frames), reason: 'theme does not re-open the showcase budget');
    for (var i = 0; i < 100; i += 1) {
      await tick(tester, timers);
    }
    expect(controller.cacheSizes.images, lessThanOrEqualTo(styleImageBudget(frames)));
  });
}
