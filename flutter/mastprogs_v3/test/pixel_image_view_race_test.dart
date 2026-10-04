// PixelImageView 업로드 경쟁: 오래된 프레임의 업로드가 늦게 끝나도, 그 사이 캐시에서 보여 준 새 프레임을 되돌리면 안 된다.
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/content/content_repository.dart';
import 'package:mastprogs_v3/core/json.dart';
import 'package:mastprogs_v3/features/portfolio/portfolio_content.dart';
import 'package:mastprogs_v3/features/sprite/controller/pixel_studio_controller.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_layers.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_palette_sets.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_rig.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_studio_content.dart';
import 'package:mastprogs_v3/features/sprite/model/sprite_meta.dart';
import 'package:mastprogs_v3/features/sprite/view/pixel_image_view.dart';

import 'support/fake_timers.dart';
import 'support/fixtures.dart';

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

  late PixelStudioController controller;
  late ValueNotifier<String> frameKey;

  Future<void> pumpView(WidgetTester tester) async {
    controller = PixelStudioController(page: page, theme: 'dark', reducedMotion: true, timerFactory: FakeTimers().call)..attachStudio(studio);
    addTearDown(controller.dispose);
    frameKey = ValueNotifier('A');
    addTearDown(frameKey.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder<String>(
          valueListenable: frameKey,
          builder: (context, key, _) => SizedBox(
            width: 86,
            height: 91,
            child: PixelImageView(controller: controller, kind: PixelImageKind.current, frameKey: key),
          ),
        ),
      ),
    );
  }

  ui.Image? shown(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(find.descendant(of: find.byType(PixelImageView), matching: find.byType(CustomPaint)));
    return (paint.painter as dynamic).image as ui.Image?;
  }

  Future<void> settleUploads(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }

  ui.Image cached(String key) => controller.imageCache.get('current#$key')!;

  testWidgets('back to the shown frame while an older upload is pending keeps the shown frame', (tester) async {
    await pumpView(tester);
    await settleUploads(tester);
    expect(shown(tester)!.isCloneOf(cached('A')), isTrue);

    frameKey.value = 'B'; // B 업로드 시작(대기 중)
    await tester.pump();
    frameKey.value = 'A'; // 이미 보이는 A 로 돌아옴
    await tester.pump();
    await settleUploads(tester); // 늦게 끝난 B 콜백
    expect(shown(tester)!.isCloneOf(cached('A')), isTrue, reason: 'late B must not replace the requested A');
    expect(controller.imageCache.get('current#B'), isNotNull, reason: 'late result is still cached for reuse');
  });

  testWidgets('cache hit for a new frame while an older upload is pending keeps the new frame', (tester) async {
    await pumpView(tester);
    await settleUploads(tester);
    frameKey.value = 'C';
    await tester.pump();
    await settleUploads(tester); // C 도 캐시에
    frameKey.value = 'B'; // B 업로드 대기
    await tester.pump();
    frameKey.value = 'C'; // 캐시 적중으로 C 표시
    await tester.pump();
    expect(shown(tester)!.isCloneOf(cached('C')), isTrue);
    await settleUploads(tester); // 늦게 끝난 B
    expect(shown(tester)!.isCloneOf(cached('C')), isTrue, reason: 'late B must not restore an obsolete frame');
  });
}
