// 원본 v8 레이어·셀 데이터 도우미(React src/pixel/layers.js 이식, 순수 함수).
// AI-NOTE: 원본 Hero Pixel Studio(studio-src/style.js)의 unpack·sourceFrame 과 같은 규칙이다.
// - 셀 data 는 base64 RLE: 3바이트마다 [개수 uint16 LE, 마스터 색 번호 1바이트]. 펼친 길이가 w×h 와 다르면 오류.
// - 합성: 레이어 0번(맨 아래)부터 차례로, 'composite'(원본이 저장해 둔 합성 참조, 숨김)와 숨긴 레이어는 건너뛰고,
//   색 번호가 0 이 아닌 픽셀은 덮어쓴다(마지막 불투명이 이김). 0 은 투명.
// - 색: 마스터 번호 i 의 색 = PALETTE_DEFS[i - 1](pixel-source-colors.json). 0 번은 투명이라 색이 없다.
// 위치는 다시 계산하지 않는다. 모든 프레임은 원본의 같은 84×89 캔버스·같은 기준점(pivotX·soleRow)에 있다.
import 'dart:convert';
import 'dart:typed_data';

import '../../../core/json.dart';

const String compositeLayer = 'composite';

final RegExp _motionOfKey = RegExp(r'^([a-z]+)-(\d+)$');

class PixelLayer {
  const PixelLayer({required this.index, required this.name, required this.visible, required this.isComposite});

  final int index;
  final String name;
  final bool visible;
  final bool isComposite;
}

class PixelCel {
  const PixelCel({required this.x, required this.y, required this.w, required this.h, required this.data});

  factory PixelCel.fromJson(Json json) =>
      PixelCel(x: json.integer('x'), y: json.integer('y'), w: json.integer('w'), h: json.integer('h'), data: json.str('data'));

  final int x;
  final int y;
  final int w;
  final int h;

  /// base64 RLE 원문.
  final String data;
}

class PixelFrame {
  const PixelFrame({
    required this.index,
    required this.key,
    required this.motion,
    required this.step,
    required this.ms,
    required this.advance,
    required this.cels,
  });

  final int index;
  final String key;
  final String motion;
  final int step;
  final int ms;
  final num? advance;
  final List<PixelCel?> cels;
}

class CelBounds {
  const CelBounds({required this.x, required this.y, required this.w, required this.h});

  final int x;
  final int y;
  final int w;
  final int h;

  Map<String, Object?> toJson() => {'x': x, 'y': y, 'w': w, 'h': h};
}

// 셀 하나를 w×h 색 번호 배열로 펼친다(원본 unpack 의 RLE 부분).
Uint8List decodeCel(PixelCel cel) {
  final bytes = base64.decode(cel.data);
  if (bytes.length % 3 != 0) throw const FormatException('RLE 길이가 3의 배수가 아닙니다');
  final raw = Uint8List(cel.w * cel.h);
  var pos = 0;
  for (var i = 0; i < bytes.length; i += 3) {
    final n = bytes[i] | (bytes[i + 1] << 8);
    if (pos + n > raw.length) throw const FormatException('셀 픽셀 수가 크기보다 많습니다');
    raw.fillRange(pos, pos + n, bytes[i + 2]);
    pos += n;
  }
  if (pos != raw.length) throw const FormatException('셀 픽셀 수가 크기와 다릅니다');
  return raw;
}

typedef Rgb = List<int>;

// 원본 PALETTE_DEFS([[이름, "rrggbb"], ...]) → 색 표. table[0] = null(투명), table[i] = defs[i - 1] 의 RGB.
List<Rgb?> sourceColorTable(List<Object?> defs) => [
  null,
  for (final def in defs)
    () {
      final value = int.parse((def as List)[1] as String, radix: 16);
      return <int>[(value >> 16) & 255, (value >> 8) & 255, value & 255];
    }(),
];

/// 화면이 쓰는 레이어 모델. 셀 펼침 결과는 모델 안에 한 번만 보관한다(데이터 크기로 상한이 정해짐).
class PixelLayerModel {
  PixelLayerModel._({
    required this.res,
    required this.width,
    required this.height,
    required this.pivotX,
    required this.soleRow,
    required this.crownRow,
    required this.layers,
    required this.frames,
    required this.motions,
  }) : compositeIndex = layers.indexWhere((layer) => layer.isComposite),
       defaultVisibility = List.unmodifiable([for (final layer in layers) layer.visible]);

  factory PixelLayerModel.fromJson(Json json) {
    final layers = [
      for (final (index, layer) in json.objs('layers').indexed)
        PixelLayer(index: index, name: layer.str('name'), visible: layer['visible'] == true, isComposite: layer.str('name') == compositeLayer),
    ];
    final frames = <PixelFrame>[];
    for (final (index, frame) in json.objs('frames').indexed) {
      final key = frame.str('key');
      final match = _motionOfKey.firstMatch(key);
      if (match == null) throw FormatException('프레임 이름 형식이 다릅니다: $key');
      final cels = [for (final cel in frame['cels'] as List) cel == null ? null : PixelCel.fromJson(asJson(cel))];
      if (cels.length != layers.length) throw FormatException('셀 수가 레이어 수와 다릅니다: $key');
      frames.add(
        PixelFrame(
          index: index,
          key: key,
          motion: match.group(1)!,
          step: int.parse(match.group(2)!),
          ms: frame.integer('ms'),
          advance: frame['advance'] as num?,
          cels: List.unmodifiable(cels),
        ),
      );
    }
    final motions = <String, List<int>>{};
    for (final frame in frames) {
      motions.putIfAbsent(frame.motion, () => []).add(frame.index);
    }
    return PixelLayerModel._(
      res: json.integer('res'),
      width: json.integer('width'),
      height: json.integer('height'),
      pivotX: json.integer('pivotX'),
      soleRow: json.integer('soleRow'),
      crownRow: json.integer('crownRow'),
      layers: List.unmodifiable(layers),
      frames: List.unmodifiable(frames),
      motions: {for (final entry in motions.entries) entry.key: List.unmodifiable(entry.value)},
    );
  }

  final int res;
  final int width;
  final int height;
  final int pivotX;
  final int soleRow;
  final int crownRow;
  final List<PixelLayer> layers;
  final int compositeIndex;
  final List<PixelFrame> frames;
  final Map<String, List<int>> motions;

  /// 레이어 표시 기본값(원본 파일 그대로: composite 만 숨김).
  final List<bool> defaultVisibility;

  final Map<PixelCel, Uint8List> _decoded = Map.identity();

  Uint8List? celRaw(int frameIndex, int layerIndex) {
    final cel = frames[frameIndex].cels[layerIndex];
    if (cel == null) return null;
    return _decoded.putIfAbsent(cel, () => decodeCel(cel));
  }

  int? frameIndexOf(String motionId, int step) {
    final steps = motions[motionId];
    if (steps == null || step < 0 || step >= steps.length) return null;
    return steps[step];
  }
}

class CompositeResult {
  const CompositeResult(this.indices, this.owner);

  /// 색 번호(w×h).
  final Uint8List indices;

  /// 픽셀을 마지막으로 칠한 레이어 번호(-1 = 빈칸).
  final Int16List owner;
}

// 원본 sourceFrame 합성. visibility 는 레이어 수 길이의 참/거짓 배열(없으면 원본 표시값).
CompositeResult compositeFrame(PixelLayerModel model, int frameIndex, [List<bool>? visibility]) {
  final vis = visibility ?? model.defaultVisibility;
  final width = model.width;
  final indices = Uint8List(width * model.height);
  final owner = Int16List(width * model.height)..fillRange(0, width * model.height, -1);
  final frame = model.frames[frameIndex];
  for (var li = 0; li < model.layers.length; li += 1) {
    if (model.layers[li].isComposite || li >= vis.length || !vis[li]) continue;
    final cel = frame.cels[li];
    if (cel == null) continue;
    final raw = model.celRaw(frameIndex, li)!;
    for (var y = 0; y < cel.h; y += 1) {
      for (var x = 0; x < cel.w; x += 1) {
        final value = raw[y * cel.w + x];
        if (value == 0) continue;
        final p = (cel.y + y) * width + cel.x + x;
        indices[p] = value;
        owner[p] = li;
      }
    }
  }
  return CompositeResult(indices, owner);
}

// 원본이 저장해 둔 합성 참조 셀(숨김 레이어)을 캔버스 크기로 펼친다. 다시 합성한 결과와 같은지 검사할 때 쓴다.
Uint8List compositeReference(PixelLayerModel model, int frameIndex) {
  final out = Uint8List(model.width * model.height);
  final cel = model.frames[frameIndex].cels[model.compositeIndex];
  if (cel == null) return out;
  final raw = model.celRaw(frameIndex, model.compositeIndex)!;
  for (var y = 0; y < cel.h; y += 1) {
    out.setRange((cel.y + y) * model.width + cel.x, (cel.y + y) * model.width + cel.x + cel.w, raw, y * cel.w);
  }
  return out;
}

// 색 번호 → RGBA(알파 0/255 만). 원본 mapping.indexToRGBA 와 같은 규칙.
Uint8List indicesToRgba(Uint8List indices, List<Rgb?> table) {
  final out = Uint8List(indices.length * 4);
  for (var i = 0; i < indices.length; i += 1) {
    final idx = indices[i];
    if (idx == 0) continue;
    final rgb = idx < table.length ? table[idx] : null;
    if (rgb == null) throw FormatException('색 표에 없는 번호입니다: $idx');
    out[i * 4] = rgb[0];
    out[i * 4 + 1] = rgb[1];
    out[i * 4 + 2] = rgb[2];
    out[i * 4 + 3] = 255;
  }
  return out;
}

// 표시 상태 도우미. 모두 새 배열을 돌려준다(원본 기본값은 바꾸지 않음).
List<bool> toggleLayer(List<bool> visibility, int index) => [for (final (i, on) in visibility.indexed) i == index ? !on : on];

List<bool> isolateLayer(PixelLayerModel model, int index) => [for (final layer in model.layers) !layer.isComposite && layer.index == index];

String visibilityKey(List<bool> visibility) => visibility.map((on) => on ? '1' : '0').join();

/// 타임라인 칸 상태: 셀이 없음(empty) / 직전 프레임과 같은 셀(same, 위치·픽셀 동일) / 새 셀(key).
String celState(PixelLayerModel model, int frameIndex, int layerIndex, int? previousFrameIndex) {
  final cel = model.frames[frameIndex].cels[layerIndex];
  if (cel == null) return 'empty';
  if (previousFrameIndex == null) return 'key';
  final prev = model.frames[previousFrameIndex].cels[layerIndex];
  if (prev != null && prev.data == cel.data && prev.x == cel.x && prev.y == cel.y) return 'same';
  return 'key';
}

CelBounds? celBounds(PixelLayerModel model, int frameIndex, int layerIndex) {
  final cel = model.frames[frameIndex].cels[layerIndex];
  return cel == null ? null : CelBounds(x: cel.x, y: cel.y, w: cel.w, h: cel.h);
}
