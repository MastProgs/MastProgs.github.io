// 픽셀 순수 모델 ↔ React 기준(test/fixtures/pixel-golden.json, fcdfc01) 차등 비교.
// 원본 28프레임, 프리셋 5종 × 어두운/밝은 외곽선, 세트 10종 × 비율 0/0.35/1, 레이어 토글·단독 보기의 가공 RGBA 를
// SHA-256 으로 바이트 단위 비교하고, 원본 색 목록과 28개 골격 자세를 비교한다.
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/core/json.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_layers.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_palette.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_palette_sets.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_pipeline.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_rig.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_timeline.dart';

import 'support/fixtures.dart';

void expectClose(Object? actual, Object? expected, String path) {
  if (expected is num) {
    expect(actual, isA<num>(), reason: path);
    expect((actual as num).toDouble(), closeTo(expected.toDouble(), 1e-9), reason: path);
  } else if (expected is List) {
    expect(actual, isA<List>(), reason: path);
    expect((actual as List).length, expected.length, reason: path);
    for (var i = 0; i < expected.length; i += 1) {
      expectClose(actual[i], expected[i], '$path[$i]');
    }
  } else if (expected is Map) {
    expect(actual, isA<Map>(), reason: path);
    expect((actual as Map).keys.toSet(), expected.keys.toSet(), reason: path);
    for (final key in expected.keys) {
      expectClose(actual[key], expected[key], '$path.$key');
    }
  } else {
    expect(actual, expected, reason: path);
  }
}

void main() {
  final model = PixelLayerModel.fromJson(asJson(readJsonFile('assets/data/pixel-layers.json')));
  final table = sourceColorTable(readJsonFile('assets/data/pixel-source-colors.json') as List);
  final sets = buildPaletteSets(asJsonList(readJsonFile('assets/data/pixel-palette-sets.json')));
  final rig = buildRig(asJson(readJsonFile('assets/data/pixel-rig.json')));
  final motionRig = asJson(readJsonFile('assets/data/pixel-motion-rig.json'));
  final golden = asJson(readFixture('pixel-golden'));
  final sourcePalette = extractPalette([for (final frame in model.frames) indicesToRgba(compositeFrame(model, frame.index).indices, table)]);

  test('source palette equals the React extraction (counts and order)', () {
    expect([for (final entry in sourcePalette) entry.toJson()], equals(golden['sourcePalette']));
  });

  final cases = golden.objs('cases');
  test('fixture holds 228 processed-frame cases', () => expect(cases, hasLength(228)));

  for (final expected in cases) {
    test('frame hash ${expected['name']}', () {
      final options = expected.obj('options');
      final visibility = options['visibility'] == null ? model.defaultVisibility : (options['visibility'] as List).cast<bool>();
      final setId = options['setId'];
      final frame = processFrame(
        model: model,
        table: table,
        frameIndex: expected.integer('frameIndex'),
        visibility: visibility,
        pad: 1,
        accentMap: buildPaletteMap(sourcePalette, options['accent']),
        outlineRgb: options['outline'] != null ? hexToRgb(options['outline']) : null,
        set: sets.where((item) => item.id == setId).firstOrNull,
        ratio: (options['ratio'] as num? ?? 0).toDouble(),
        nearestCache: {},
      );
      expect(frame.width, expected['width']);
      expect(frame.height, expected['height']);
      expect(sha256.convert(frame.data).toString(), expected['sha256']);
      expect(opaqueBounds(frame.data, frame.width, frame.height)?.toJson(), equals(expected['bounds']));
    });
  }

  test('28 rig poses (frame detail, FK pose and plant points) match within 1e-9', () {
    final rigCases = golden.objs('rigCases');
    expect(rigCases, hasLength(28));
    for (final expected in rigCases) {
      final motionId = expected.str('motionId');
      final step = expected.integer('step');
      final detail = frameRig(motionRig, motionId, step)!;
      final pose = poseRig(rig, detail.rotWorld);
      final plant = plantPoints(rig, pose, detail.plant);
      final label = '$motionId-$step';
      expectClose(detail.toJson(), expected['detail'], '$label.detail');
      expectClose({for (final entry in pose.entries) entry.key: entry.value.toJson()}, expected['pose'], '$label.pose');
      expectClose([for (final point in plant) point.toJson()], expected['plant'], '$label.plant');
    }
  });
}
