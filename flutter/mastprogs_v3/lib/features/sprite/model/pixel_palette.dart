// 픽셀 팔레트 도우미(React src/pixel/palette.js 이식, 순수 함수).
// AI-NOTE: 원본 프레임의 실제 색 목록(이산 팔레트)을 읽고, 포인트 색 무리(파란 머리 계열)만 목표 색으로 바꾼 대응표를 만든 뒤
// 픽셀마다 정확히 같은 RGB 를 표에서 찾아 바꾼다. 연속 색상 필터가 아니라 팔레트 항목 단위 교체다.
// 알파는 절대 바꾸지 않는다(원본의 0/255 그대로). 투명 픽셀(알파 0)은 색도 건드리지 않는다.
import 'dart:math' as math;
import 'dart:typed_data';

import '../../../core/js_compat.dart';
import 'pixel_layers.dart';

int rgbKey(int r, int g, int b) => (r << 16) | (g << 8) | b;

final RegExp _hexPattern = RegExp(r'^#?([0-9a-f]{6})$', caseSensitive: false);

/// '#rrggbb' 또는 'rrggbb' → [r, g, b]. 형식이 아니면 null.
Rgb? hexToRgb(Object? hex) {
  final match = _hexPattern.firstMatch((hex ?? '').toString().trim());
  if (match == null) return null;
  final value = int.parse(match.group(1)!, radix: 16);
  return [(value >> 16) & 255, (value >> 8) & 255, value & 255];
}

String rgbToHex(Rgb rgb) => '#${rgb.map((value) => value.toRadixString(16).padLeft(2, '0')).join()}';

/// JavaScript Math.round(x) = floor(x + 0.5).
int jsRound(num value) => (value + 0.5).floor();

List<double> rgbToHsl(Rgb rgb) {
  final rn = rgb[0] / 255;
  final gn = rgb[1] / 255;
  final bn = rgb[2] / 255;
  final max = math.max(rn, math.max(gn, bn));
  final min = math.min(rn, math.min(gn, bn));
  final l = (max + min) / 2;
  if (max == min) return [0, 0, l];
  final d = max - min;
  final s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  double h;
  if (max == rn) {
    h = (gn - bn) / d + (gn < bn ? 6 : 0);
  } else if (max == gn) {
    h = (bn - rn) / d + 2;
  } else {
    h = (rn - gn) / d + 4;
  }
  return [h * 60, s, l];
}

Rgb hslToRgb(List<double> hsl) {
  final h = hsl[0];
  final s = hsl[1];
  final l = hsl[2];
  if (s == 0) {
    final v = jsRound(l * 255);
    return [v, v, v];
  }
  final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  final p = 2 * l - q;
  double hue(double t) {
    var x = t;
    if (x < 0) x += 1;
    if (x > 1) x -= 1;
    if (x < 1 / 6) return p + (q - p) * 6 * x;
    if (x < 1 / 2) return q;
    if (x < 2 / 3) return p + (q - p) * (2 / 3 - x) * 6;
    return p;
  }

  // JS: (((h % 360) + 360) % 360) / 360 — Dart % 는 항상 0 이상이라 같은 값이 된다.
  final hn = (((h % 360) + 360) % 360) / 360;
  return [
    for (final value in [hue(hn + 1 / 3), hue(hn), hue(hn - 1 / 3)]) jsRound(value * 255),
  ];
}

double _clamp01(double value) => math.min(1, math.max(0, value));

double _hueDistance(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

class PaletteEntry {
  const PaletteEntry({required this.key, required this.rgb, required this.count});

  final int key;
  final Rgb rgb;
  final int count;

  Map<String, Object?> toJson() => {
    'key': key,
    'rgb': [...rgb],
    'count': count,
  };
}

// 불투명 픽셀의 고유 색과 개수. 여러 프레임을 넘기면 합친다(모든 프레임에 같은 대응표를 쓰기 위해).
List<PaletteEntry> extractPalette(Iterable<Uint8List> pixelArrays) {
  final counts = <int, int>{};
  for (final data in pixelArrays) {
    for (var i = 0; i < data.length; i += 4) {
      if (data[i + 3] == 0) continue;
      final key = rgbKey(data[i], data[i + 1], data[i + 2]);
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }
  return stableSorted([
    for (final entry in counts.entries)
      PaletteEntry(key: entry.key, rgb: [(entry.key >> 16) & 255, (entry.key >> 8) & 255, entry.key & 255], count: entry.value),
  ], (a, b) => b.count != a.count ? b.count - a.count : a.key - b.key);
}

const double _accentMinSat = 0.18;
const double _accentHueRange = 40;
const List<double> _blueRange = [170, 270];

// 포인트 색 무리의 기준 색상(hue). 파란 계열(원본 용사의 머리)을 먼저 찾고, 없으면 가장 많이 쓰인 채도 높은 색을 쓴다.
double? detectAccentHue(List<PaletteEntry> palette) {
  final saturated = [
    for (final entry in palette)
      if (rgbToHsl(entry.rgb) case [_, final s, final l] when s >= 0.25 && l >= 0.15 && l <= 0.85) entry,
  ];
  final blue = [
    for (final entry in saturated)
      if (rgbToHsl(entry.rgb)[0] case final h when h >= _blueRange[0] && h <= _blueRange[1]) entry,
  ];
  final pool = blue.isNotEmpty ? blue : saturated;
  if (pool.isEmpty) return null;
  final best = stableSorted(pool, (a, b) => b.count != a.count ? b.count - a.count : a.key - b.key).first;
  return rgbToHsl(best.rgb)[0];
}

List<PaletteEntry> accentGroup(List<PaletteEntry> palette, double? accentHue) {
  if (accentHue == null) return const [];
  return [
    for (final entry in palette)
      if (rgbToHsl(entry.rgb) case [final h, final s, _] when s >= _accentMinSat && _hueDistance(h, accentHue) <= _accentHueRange) entry,
  ];
}

// 대응표(rgbKey → [r,g,b]). target 이 없으면 원본 그대로(빈 표). 무리 안 색의 명암 순서는 유지한다(음영 단계 보존).
Map<int, Rgb> buildPaletteMap(List<PaletteEntry> palette, Object? target) {
  final map = <int, Rgb>{};
  final targetRgb = target is String ? hexToRgb(target) : target as Rgb?;
  if (targetRgb == null) return map;
  final accentHue = detectAccentHue(palette);
  final group = accentGroup(palette, accentHue);
  if (group.isEmpty) return map;
  final targetHsl = rgbToHsl(targetRgb);
  final th = targetHsl[0];
  final ts = targetHsl[1];
  final tl = targetHsl[2];
  final weight = group.fold<int>(0, (sum, entry) => sum + entry.count);
  final refS = group.fold<double>(0, (sum, entry) => sum + rgbToHsl(entry.rgb)[1] * entry.count) / weight;
  final refL = group.fold<double>(0, (sum, entry) => sum + rgbToHsl(entry.rgb)[2] * entry.count) / weight;
  for (final entry in group) {
    final hsl = rgbToHsl(entry.rgb);
    final next = hslToRgb([th, _clamp01(refS > 0 ? (hsl[1] * ts) / refS : ts), _clamp01(hsl[2] + (tl - refL) * 0.6)]);
    map[entry.key] = next;
  }
  return map;
}

// 새 배열에 색만 바꿔 쓴다(입력은 그대로). 알파·투명 픽셀은 손대지 않는다.
Uint8List recolorPixels(Uint8List data, Map<int, Rgb>? map) {
  final out = Uint8List.fromList(data);
  if (map == null || map.isEmpty) return out;
  for (var i = 0; i < out.length; i += 4) {
    if (out[i + 3] == 0) continue;
    final next = map[rgbKey(out[i], out[i + 1], out[i + 2])];
    if (next == null) continue;
    out[i] = next[0];
    out[i + 1] = next[1];
    out[i + 2] = next[2];
  }
  return out;
}

// 캐시 키에 쓰는 정규화된 설정 문자열.
String paletteKey(Object? target) {
  if (target == null || (target is String && target.isEmpty)) return 'original';
  return rgbToHex(target is String ? (hexToRgb(target) ?? const [0, 0, 0]) : target as Rgb);
}
