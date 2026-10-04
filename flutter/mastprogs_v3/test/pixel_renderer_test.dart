// 픽셀 화면의 그리기 경계 검증(FQ-001).
// 1) 직선 알파 → 사전 곱셈 변환 규칙, 2) 설치 엔진의 ui.Image 읽기 결과(반투명·0·255),
// 3) React 기준 test/fixtures/renderer-golden.json(어니언 18 · 중심 맞춤 6)을 순수 모델과 컨트롤러 경로 모두로 SHA-256 비교,
// 4) 실제 어니언 무대 그림을 올렸다 읽었을 때 반투명 잔상 색이 밝아지지 않음을 확인한다.
// 예상값 파일은 테스트에서만 읽는다(실행 코드는 직접 계산).
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/content/content_repository.dart';
import 'package:mastprogs_v3/core/json.dart';
import 'package:mastprogs_v3/features/portfolio/portfolio_content.dart';
import 'package:mastprogs_v3/features/sprite/controller/pixel_studio_controller.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_layers.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_outline.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_palette_sets.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_pipeline.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_rig.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_studio_content.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_timeline.dart';
import 'package:mastprogs_v3/features/sprite/model/sprite_meta.dart';
import 'package:mastprogs_v3/features/sprite/view/pixel_image_view.dart';

import 'support/fake_timers.dart';
import 'support/fixtures.dart';

String sha(Uint8List bytes) => sha256.convert(bytes).toString();

Future<ui.Image> upload(Uint8List straight, int width, int height) {
  final done = Completer<ui.Image>();
  uploadStraightRgba(straight, width, height, done.complete);
  return done.future;
}

Future<ui.Image> uploadRaw(Uint8List bytes, int width, int height) {
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(bytes, width, height, ui.PixelFormat.rgba8888, done.complete);
  return done.future;
}

Future<Uint8List> readBack(ui.Image image, ui.ImageByteFormat format) async {
  final data = await image.toByteData(format: format);
  return data!.buffer.asUint8List();
}

void main() {
  final layers = PixelLayerModel.fromJson(asJson(readJsonFile('assets/data/pixel-layers.json')));
  final table = sourceColorTable(readJsonFile('assets/data/pixel-source-colors.json') as List);
  final sets = buildPaletteSets(asJsonList(readJsonFile('assets/data/pixel-palette-sets.json')));
  final golden = asJson(readFixture('renderer-golden'));
  final onionCases = golden.objs('onion');
  final centerCases = golden.objs('center');

  group('premultiplyRgba (upload boundary)', () {
    test('fractional alpha: RGB = round(c * a / 255), alpha kept', () {
      expect(premultiplyRgba(Uint8List.fromList([100, 50, 25, 128])), [50, 25, 13, 128]);
      expect(premultiplyRgba(Uint8List.fromList([255, 255, 255, 1])), [1, 1, 1, 1]);
      expect(premultiplyRgba(Uint8List.fromList([255, 128, 1, 254])), [254, 127, 1, 254]);
    });

    test('alpha 255 is byte-identical, alpha 0 becomes transparent black', () {
      expect(premultiplyRgba(Uint8List.fromList([12, 200, 99, 255, 0, 0, 0, 0])), [12, 200, 99, 255, 0, 0, 0, 0]);
      expect(premultiplyRgba(Uint8List.fromList([80, 90, 100, 0])), [0, 0, 0, 0]);
    });

    test('matches floor(c * a / 255 + 0.5) for every channel/alpha pair and never mutates the input', () {
      final input = Uint8List(256 * 256 * 4);
      for (var c = 0; c < 256; c += 1) {
        for (var a = 0; a < 256; a += 1) {
          final i = (c * 256 + a) * 4;
          input.setAll(i, [c, 255 - c, c ~/ 2, a]);
        }
      }
      final before = Uint8List.fromList(input);
      final out = premultiplyRgba(input);
      expect(input, before);
      expect(identical(out, input), isFalse);
      for (var i = 0; i < input.length; i += 4) {
        final a = input[i + 3];
        for (var k = 0; k < 3; k += 1) {
          expect(out[i + k], (input[i + k] * a / 255 + 0.5).floor(), reason: 'c=${input[i + k]} a=$a');
        }
        expect(out[i + 3], a);
      }
    });
  });

  group('installed engine readback', () {
    test('rgba8888 is premultiplied: straight bytes uploaded directly brighten (the FQ-001 defect)', () async {
      final image = await uploadRaw(Uint8List.fromList([100, 50, 25, 128]), 1, 1);
      addTearDown(image.dispose);
      expect(await readBack(image, ui.ImageByteFormat.rawStraightRgba), [199, 100, 50, 128]);
    });

    test('upload boundary keeps fractional, opaque and transparent pixels', () async {
      final straight = Uint8List.fromList([100, 50, 25, 128, 12, 200, 99, 255, 0, 0, 0, 0, 232, 64, 64, 89]);
      final image = await upload(straight, 4, 1);
      addTearDown(image.dispose);
      expect(await readBack(image, ui.ImageByteFormat.rawRgba), premultiplyRgba(straight), reason: 'engine stores exactly the premultiplied copy');
      final back = await readBack(image, ui.ImageByteFormat.rawStraightRgba);
      expect(back.sublist(4, 12), [12, 200, 99, 255, 0, 0, 0, 0], reason: 'alpha 255 / 0 unchanged');
      for (final i in [0, 12]) {
        expect(back[i + 3], straight[i + 3]);
        for (var k = 0; k < 3; k += 1) {
          expect((back[i + k] - straight[i + k]).abs(), lessThanOrEqualTo(1), reason: 'pixel ${i ~/ 4} channel $k');
        }
      }
    });
  });

  group('renderer-golden.json (React fcdfc01)', () {
    test('fixture holds 18 onion and 6 recenter cases with the premultiplied rgba8888 contract', () {
      expect(onionCases, hasLength(18));
      expect(centerCases, hasLength(6));
      expect(golden['renderer'], {'pixelFormat': 'rgba8888', 'alpha': 'premultiplied', 'sdkEvidence': isA<String>()});
    });

    final aap64 = sets.firstWhere((set) => set.id == 'aap64');
    PixelImage run(int frameIndex) =>
        processFrame(model: layers, table: table, frameIndex: frameIndex, visibility: layers.defaultVisibility, pad: 1, set: aap64, ratio: 1, nearestCache: {});

    for (final expected in onionCases) {
      final motion = expected.str('motion');
      final step = expected.integer('step');
      final opacity = (expected['opacity'] as num).toDouble();
      test('onion $motion step $step opacity $opacity (pure model)', () {
        final frames = layers.motions[motion]!;
        final near = onionNeighbors(frames.length, step, isLooping(motion));
        expect({'prev': near.prev, 'next': near.next}, expected['neighbors']);
        final current = run(frames[step]);
        expect([current.width, current.height], [expected['width'], expected['height']]);
        final prev = near.prev == null ? null : tintPixels(run(frames[near.prev!]).data, onionTintPrev, opacity);
        final next = near.next == null ? null : tintPixels(run(frames[near.next!]).data, onionTintNext, opacity);
        expect(sha(composeOver([prev, next, current.data], current.data.length)), expected['sha256']);
      });
    }

    for (final expected in centerCases) {
      final frameIndex = expected.integer('frameIndex');
      test('recenter frame $frameIndex (pure model)', () {
        final current = processFrame(model: layers, table: table, frameIndex: frameIndex, visibility: layers.defaultVisibility, pad: 1);
        final centered = recenterByBounds(current.data, current.width, current.height, guideCoordinates(layers, 1));
        final box = centered.box!;
        expect({
          'dx': centered.dx,
          'dy': centered.dy,
          'box': {'x': box.x, 'y': box.y, 'w': box.w, 'h': box.h},
        }, expected['metadata']);
        expect(sha(centered.data), expected['sha256']);
      });
    }
  });

  group('controller images (what the canvas uploads)', () {
    final page = SpritePageData(
      site: SiteContent.fromJson(readData('site')),
      content: PixelStudioContent.fromJson(readData('pixelStudio')),
      sprite: SpriteMeta.fromJson(readData('pixel-assets')),
    );
    final studio = SpriteStudioData(
      layers: layers,
      colorTable: table,
      sets: sets,
      rig: buildRig(asJson(readJsonFile('assets/data/pixel-rig.json'))),
      motionRig: asJson(readJsonFile('assets/data/pixel-motion-rig.json')),
    );

    PixelStudioController create() {
      final controller = PixelStudioController(page: page, theme: 'dark', reducedMotion: true, timerFactory: FakeTimers().call)..attachStudio(studio);
      addTearDown(controller.dispose);
      return controller;
    }

    void moveTo(PixelStudioController c, String motion, int step) {
      c.selectMotion(motion);
      c.selectFrame(step);
      expect([c.playback.motion, c.playback.frame], [motion, step]);
    }

    test('stage image hashes equal all 18 React onion composites (AAP-64 100%, original preset, outline off)', () {
      final c = create();
      for (final expected in onionCases) {
        moveTo(c, expected.str('motion'), expected.integer('step'));
        c.setOnionOpacity((expected['opacity'] as num).toDouble());
        final stage = c.imageFor(PixelImageKind.stage);
        expect(sha(stage.data), expected['sha256'], reason: '${expected['motion']} ${expected['step']} ${expected['opacity']}');
      }
    });

    test('centered comparison image equals all 6 React recenter cases (source colours)', () {
      final c = create()..selectSet('source');
      for (final expected in centerCases) {
        final frameIndex = expected.integer('frameIndex');
        final motion = layers.motions.entries.firstWhere((entry) => entry.value.contains(frameIndex));
        moveTo(c, motion.key, motion.value.indexOf(frameIndex));
        expect(c.frameIndex, frameIndex);
        final meta = expected.obj('metadata');
        expect([c.centering.dx, c.centering.dy], [meta['dx'], meta['dy']]);
        expect(sha(c.imageFor(PixelImageKind.centered).data), expected['sha256'], reason: 'frame $frameIndex');
      }
    });

    test('uploaded onion stage reads back as the straight model colours (ghosts do not brighten)', () async {
      final c = create();
      moveTo(c, 'walk', 0);
      c.setOnionOpacity(0.35);
      final stage = c.imageFor(PixelImageKind.stage);
      final straight = Uint8List.fromList(stage.data);
      final image = await upload(stage.data, stage.width, stage.height);
      addTearDown(image.dispose);
      expect(stage.data, straight, reason: 'model bytes are not touched by the upload');
      expect(await readBack(image, ui.ImageByteFormat.rawRgba), premultiplyRgba(straight));
      final back = await readBack(image, ui.ImageByteFormat.rawStraightRgba);

      final naive = await uploadRaw(Uint8List.fromList(straight), stage.width, stage.height);
      addTearDown(naive.dispose);
      final naiveBack = await readBack(naive, ui.ImageByteFormat.rawStraightRgba);

      var fractional = 0;
      var naiveBrighter = 0;
      for (var i = 0; i < straight.length; i += 4) {
        final a = straight[i + 3];
        expect(back[i + 3], a);
        if (a == 0 || a == 255) {
          expect(back.sublist(i, i + 4), a == 0 ? [0, 0, 0, 0] : straight.sublist(i, i + 4), reason: 'pixel ${i ~/ 4}');
          continue;
        }
        fractional += 1;
        // 8비트 사전 곱셈을 되돌릴 때 생기는 양자화 폭(255 / a)만 허용한다.
        final tolerance = (255 / a).ceil();
        for (var k = 0; k < 3; k += 1) {
          expect((back[i + k] - straight[i + k]).abs(), lessThanOrEqualTo(tolerance), reason: 'pixel ${i ~/ 4} channel $k alpha $a');
        }
        if (naiveBack[i] + naiveBack[i + 1] + naiveBack[i + 2] > straight[i] + straight[i + 1] + straight[i + 2] + 3 * tolerance) naiveBrighter += 1;
      }
      expect(fractional, greaterThan(0), reason: 'the case really contains semi-transparent ghost pixels');
      expect(naiveBrighter, greaterThan(0), reason: 'without the conversion the same ghosts would read back brighter');
    });
  });
}
