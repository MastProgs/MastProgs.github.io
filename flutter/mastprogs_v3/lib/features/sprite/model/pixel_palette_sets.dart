// 팔레트 세트(AAP-64 등) 적용 도우미(React src/pixel/paletteSets.js 이식, 순수 함수).
// AI-NOTE: 원본 Hero Pixel Studio 의 postfx/mapping.js(buildColorTable)·color.js 규칙을 옮겼다.
// - 세트 색은 입력 순서를 지킨 중복 제거(dedupeHexList), 최근접 색은 OKLab 제곱 거리(원본 DEFAULT_STYLE.method 'oklab'),
//   동률은 앞쪽(엄격 < 비교). 포인트 색·추가 외곽선을 바꾼 "뒤"의 실제 출력 색마다 최근접을 고른다
//   (그래서 100% 에서는 외곽선까지 모든 불투명 픽셀이 세트 안 색이 된다).
// - 적용 비율(0..1): 출력 = 원래 색 + (세트 색 − 원래 색) × 비율, 채널마다 반올림. 0 은 그대로, 1 은 세트 색 그대로.
//   알파는 건드리지 않는다(투명 픽셀은 색도 그대로).
// AI-NOTE: Math.cbrt 는 dart:math 에 없어서 원본 브라우저 엔진(V8)이 쓰는 FreeBSD/fdlibm s_cbrt 를 그대로 옮겼다(cbrtFdlibm).
// 근사 pow(x, 1/3) 를 쓰면 마지막 비트가 달라 최근접 색이 드물게 바뀔 수 있다(test/fixtures 픽셀 해시로 검증).
import 'dart:math' as math;
import 'dart:typed_data';

import '../../../core/json.dart';
import '../../../core/js_compat.dart';
import 'pixel_layers.dart';

final RegExp _hexPattern = RegExp(r'^#?([0-9a-f]{6})$', caseSensitive: false);

String normalizeHex(Object? hex) {
  final match = _hexPattern.firstMatch((hex ?? '').toString().trim());
  if (match == null) throw FormatException('색은 #RRGGBB 형식이어야 합니다: $hex');
  return '#${match.group(1)!.toLowerCase()}';
}

Rgb _hexRgb(String hex) {
  final value = int.parse(hex.substring(1), radix: 16);
  return [(value >> 16) & 255, (value >> 8) & 255, value & 255];
}

List<String> dedupeHexList(Iterable<Object?> hexes) {
  final seen = <String>{};
  final colors = <String>[];
  for (final hex in hexes) {
    final norm = normalizeHex(hex);
    if (seen.add(norm)) colors.add(norm);
  }
  return colors;
}

class PaletteSet {
  const PaletteSet({required this.id, required this.name, required this.colors, required this.rgb, required this.lab});

  final String id;
  final String name;
  final List<String> colors;
  final List<Rgb> rgb;
  final List<List<double>> lab;
}

// pixel-palette-sets.json → [{ id, name, colors: '#rrggbb'[], rgb: [r,g,b][], lab }]
List<PaletteSet> buildPaletteSets(List<Json> json) => List.unmodifiable([
  for (final set in json)
    () {
      final colors = dedupeHexList(set['colors'] as List);
      final rgb = [for (final hex in colors) _hexRgb(hex)];
      return PaletteSet(id: set.str('id'), name: set.str('name'), colors: colors, rgb: rgb, lab: [for (final c in rgb) rgbToOklab(c)]);
    }(),
]);

double _srgbToLinear(int v) {
  final f = v / 255;
  return f <= 0.04045 ? f / 12.92 : math.pow((f + 0.055) / 1.055, 2.4).toDouble();
}

final ByteData _bits = ByteData(8);

double _fromWords(int high, int low) {
  _bits.setUint32(4, high & 0xffffffff, Endian.little);
  _bits.setUint32(0, low & 0xffffffff, Endian.little);
  return _bits.getFloat64(0, Endian.little);
}

const int _b1 = 715094163;
const int _b2 = 696219795;
const double _p0 = 1.87595182427177009643;
const double _p1 = -1.88497979543377169875;
const double _p2 = 1.621429720105354466140;
const double _p3 = -0.758397934778766047437;
const double _p4 = 0.145996192886612446982;

/// Math.cbrt(x) — FreeBSD msun s_cbrt.c(V8 base/ieee754 의 cbrt 와 같은 계산).
double cbrtFdlibm(double x) {
  _bits.setFloat64(0, x, Endian.little);
  var hx = _bits.getUint32(4, Endian.little);
  final low = _bits.getUint32(0, Endian.little);
  final sign = hx & 0x80000000;
  hx ^= sign;
  if (hx >= 0x7ff00000) return x + x;
  double t;
  if (hx < 0x00100000) {
    if ((hx | low) == 0) return x;
    t = _fromWords(0x43500000, 0) * x;
    _bits.setFloat64(0, t, Endian.little);
    final high = _bits.getUint32(4, Endian.little);
    t = _fromWords(sign | ((high & 0x7fffffff) ~/ 3 + _b2), 0);
  } else {
    t = _fromWords(sign | (hx ~/ 3 + _b1), 0);
  }
  var r = (t * t) * (t / x);
  t = t * ((_p0 + r * (_p1 + r * _p2)) + ((r * r) * r) * (_p3 + r * _p4));
  // 23비트로 0 에서 멀어지는 쪽 반올림: bits = (bits + 0x80000000) & 0xffffffffc0000000.
  _bits.setFloat64(0, t, Endian.little);
  var lo = _bits.getUint32(0, Endian.little) + 0x80000000;
  var hi = _bits.getUint32(4, Endian.little);
  if (lo > 0xffffffff) {
    lo -= 0x100000000;
    hi = (hi + 1) & 0xffffffff;
  }
  t = _fromWords(hi, lo & 0xc0000000);
  final s = t * t;
  r = x / s;
  final w = t + t;
  r = (r - t) / (w + r);
  return t + t * r;
}

// sRGB 8bit → OKLab(원본 color.js 와 같은 행렬).
List<double> rgbToOklab(Rgb rgb) {
  final r = _srgbToLinear(rgb[0]);
  final g = _srgbToLinear(rgb[1]);
  final b = _srgbToLinear(rgb[2]);
  final l = cbrtFdlibm(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = cbrtFdlibm(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = cbrtFdlibm(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return [
    0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s,
  ];
}

int nearestSetIndex(Rgb rgb, PaletteSet set) {
  final lab = rgbToOklab(rgb);
  var best = 0;
  var bestDist = double.infinity;
  for (var i = 0; i < set.lab.length; i += 1) {
    final q = set.lab[i];
    final d0 = lab[0] - q[0];
    final d1 = lab[1] - q[1];
    final d2 = lab[2] - q[2];
    // JS (a ** 2) 는 a * a 와 같은 값(정확히 표현되는 제곱)이다.
    final d = d0 * d0 + d1 * d1 + d2 * d2;
    if (d < bestDist) {
      best = i;
      bestDist = d;
    }
  }
  return best;
}

/// Number(value) 를 0..1 로 자른다(유한한 수가 아니면 0).
double clampRatio(Object? value) {
  final n = jsNumber(value);
  return n.isFinite ? math.min(1, math.max(0, n.toDouble())) : 0;
}

/// JavaScript Math.round(x) = floor(x + 0.5).
int _round(double value) => (value + 0.5).floor();

// 새 배열을 돌려준다. nearestCache(rgbKey → [r,g,b])를 주면 같은 세트 안에서 최근접 계산을 다시 쓴다.
Uint8List applyPaletteSet(Uint8List data, PaletteSet? set, Object? ratio, [Map<int, Rgb>? nearestCache]) {
  final t = clampRatio(ratio);
  final out = Uint8List.fromList(data);
  if (set == null || t == 0) return out;
  final cache = nearestCache ?? <int, Rgb>{};
  for (var i = 0; i < out.length; i += 4) {
    if (out[i + 3] == 0) continue;
    final key = (out[i] << 16) | (out[i + 1] << 8) | out[i + 2];
    var target = cache[key];
    if (target == null) {
      target = set.rgb[nearestSetIndex([out[i], out[i + 1], out[i + 2]], set)];
      cache[key] = target;
    }
    if (t == 1) {
      out[i] = target[0];
      out[i + 1] = target[1];
      out[i + 2] = target[2];
    } else {
      out[i] = _round(out[i] + (target[0] - out[i]) * t);
      out[i + 1] = _round(out[i + 1] + (target[1] - out[i + 1]) * t);
      out[i + 2] = _round(out[i + 2] + (target[2] - out[i + 2]) * t);
    }
  }
  return out;
}

class ColorShare {
  const ColorShare({required this.hex, required this.count, required this.share, required this.inSet});

  final String hex;
  final int count;
  final double share;
  final bool inSet;
}

class ColorShares {
  const ColorShares({required this.total, required this.entries, required this.inSetShare});

  final int total;
  final List<ColorShare> entries;
  final double inSetShare;
}

// 실제 출력의 색 점유율. 불투명 픽셀만 센다. set 을 주면 세트 안 색인지(inSet)와 세트 안 픽셀 비율을 함께 준다.
ColorShares colorShares(Uint8List data, [PaletteSet? set]) {
  final counts = <int, int>{};
  var total = 0;
  for (var i = 0; i < data.length; i += 4) {
    if (data[i + 3] == 0) continue;
    final key = (data[i] << 16) | (data[i + 1] << 8) | data[i + 2];
    counts[key] = (counts[key] ?? 0) + 1;
    total += 1;
  }
  final members = set?.colors.toSet();
  var inSetPixels = 0;
  final entries = <ColorShare>[];
  for (final entry in counts.entries) {
    final hex = '#${entry.key.toRadixString(16).padLeft(6, '0')}';
    final inSet = members?.contains(hex) ?? false;
    if (inSet) inSetPixels += entry.value;
    entries.add(ColorShare(hex: hex, count: entry.value, share: total > 0 ? entry.value / total : 0, inSet: inSet));
  }
  final sorted = stableSorted(entries, (a, b) => b.count != a.count ? b.count - a.count : (a.hex.compareTo(b.hex) < 0 ? -1 : 1));
  return ColorShares(total: total, entries: sorted, inSetShare: total > 0 ? inSetPixels / total : 0);
}
