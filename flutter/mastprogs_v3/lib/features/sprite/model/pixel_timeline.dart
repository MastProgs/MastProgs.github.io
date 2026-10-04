// 프레임 커서·어니언 스킨·기준선·중심 비교 도우미(React src/pixel/timeline.js 이식, 순수 함수).
// AI-NOTE: 화면의 모든 캔버스·타임라인·어니언·골격 수치는 재생 상태 하나({ motion, frame })에서 나온다.
// - 반복 여부는 원본 engine-motion/*.json 의 loop 값 그대로: 걷기·달리기 반복, 공격 한 번(끝에서 멈춤).
// - 어니언은 같은 모션 안의 실제 앞/뒤 프레임만 쓴다. 반복 모션은 처음↔끝을 잇고, 공격은 처음 앞·끝 뒤가 없다.
//   다른 모션 프레임은 절대 섞지 않는다.
// - 원본 편집기(app.js)처럼 모든 프레임을 같은 캔버스·같은 기준점(pivotX)·같은 발바닥 줄(soleRow)에 놓는다(자동 자르기·가운데 맞춤 없음).
import 'dart:typed_data';

import 'pixel_layers.dart';

const Map<String, bool> motionLoop = {'walk': true, 'run': true, 'attack': false};

bool isLooping(String motionId) => motionLoop[motionId] ?? true;

// 이전/다음 프레임 버튼: 반복 모션은 돌아가고, 공격은 처음·끝에서 멈춘다.
int stepFrame(int length, int frame, int delta, bool loop) {
  final next = frame + delta;
  if (loop) return ((next % length) + length) % length;
  return next < 0 ? 0 : (next > length - 1 ? length - 1 : next);
}

class OnionNeighbors {
  const OnionNeighbors({required this.prev, required this.next});

  final int? prev;
  final int? next;

  @override
  bool operator ==(Object other) => other is OnionNeighbors && other.prev == prev && other.next == next;

  @override
  int get hashCode => Object.hash(prev, next);
}

// 어니언 이웃(같은 모션 안 단계 번호). 없으면 null.
OnionNeighbors onionNeighbors(int length, int frame, bool loop) {
  if (length < 2) return const OnionNeighbors(prev: null, next: null);
  if (loop) return OnionNeighbors(prev: (frame - 1 + length) % length, next: (frame + 1) % length);
  return OnionNeighbors(prev: frame > 0 ? frame - 1 : null, next: frame < length - 1 ? frame + 1 : null);
}

class GuideCoordinates {
  const GuideCoordinates({required this.pivotX, required this.soleRow, required this.crownRow});

  final int pivotX;
  final int soleRow;
  final int crownRow;
}

// 기준선 좌표(여백 pad 를 더한 공통 캔버스 기준, 픽셀 칸 번호).
GuideCoordinates guideCoordinates(PixelLayerModel model, int pad) =>
    GuideCoordinates(pivotX: model.pivotX + pad, soleRow: model.soleRow + pad, crownRow: model.crownRow + pad);

// 앞(이전)·뒤(다음) 프레임 색. Aseprite 기본처럼 이전은 붉게, 다음은 푸르게 물들인다.
const Rgb onionTintPrev = [232, 64, 64];
const Rgb onionTintNext = [56, 120, 240];
const double _tintMix = 0.6;

int _round(double value) => (value + 0.5).floor();

// 불투명 픽셀의 색을 tint 쪽으로 섞고 알파를 opacity 로 낮춘 새 배열.
Uint8List tintPixels(Uint8List data, Rgb tint, double opacity) {
  final out = Uint8List(data.length);
  final alpha = _round((opacity < 0 ? 0 : (opacity > 1 ? 1 : opacity)) * 255);
  for (var i = 0; i < data.length; i += 4) {
    if (data[i + 3] == 0) continue;
    out[i] = _round(data[i] + (tint[0] - data[i]) * _tintMix);
    out[i + 1] = _round(data[i + 1] + (tint[1] - data[i + 1]) * _tintMix);
    out[i + 2] = _round(data[i + 2] + (tint[2] - data[i + 2]) * _tintMix);
    out[i + 3] = alpha;
  }
  return out;
}

// 아래 → 위 순서로 겹친다(일반 src-over). 현재 프레임을 마지막에 주면 어니언은 항상 현재 아래에 깔린다.
Uint8List composeOver(List<Uint8List?> layers, int length) {
  final out = Uint8List(length);
  for (final src in layers) {
    if (src == null) continue;
    for (var i = 0; i < length; i += 4) {
      final sa = src[i + 3] / 255;
      if (sa == 0) continue;
      final da = out[i + 3] / 255;
      final oa = sa + da * (1 - sa);
      for (var c = 0; c < 3; c += 1) {
        out[i + c] = _round((src[i + c] * sa + out[i + c] * da * (1 - sa)) / oa);
      }
      out[i + 3] = _round(oa * 255);
    }
  }
  return out;
}

// 불투명 픽셀의 경계 상자(없으면 null).
CelBounds? opaqueBounds(Uint8List data, int w, int h) {
  var minX = w;
  var minY = h;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < h; y += 1) {
    for (var x = 0; x < w; x += 1) {
      if (data[(y * w + x) * 4 + 3] == 0) continue;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
  }
  return maxX < 0 ? null : CelBounds(x: minX, y: minY, w: maxX - minX + 1, h: maxY - minY + 1);
}

class Recentered {
  const Recentered({required this.data, required this.dx, required this.dy, required this.box});

  final Uint8List data;
  final int dx;
  final int dy;
  final CelBounds? box;
}

// 비교용: 프레임마다 실루엣 상자를 잘라 가운데(pivotX)·바닥(soleRow)에 맞췄다면 어디로 갔을지.
// 원본 픽셀을 그대로 정수 칸만큼 옮기며, dx·dy 는 실제 데이터에서 계산한 이동량이다(꾸며 낸 흔들림 없음).
Recentered recenterByBounds(Uint8List data, int w, int h, GuideCoordinates guides) {
  final box = opaqueBounds(data, w, h);
  final out = Uint8List(data.length);
  if (box == null) return Recentered(data: out, dx: 0, dy: 0, box: null);
  final dx = guides.pivotX - ((box.x + (box.w - 1) / 2)).floor();
  final dy = guides.soleRow - (box.y + box.h - 1);
  for (var y = 0; y < h; y += 1) {
    final ty = y + dy;
    if (ty < 0 || ty >= h) continue;
    for (var x = 0; x < w; x += 1) {
      final tx = x + dx;
      if (tx < 0 || tx >= w) continue;
      final s = (y * w + x) * 4;
      if (data[s + 3] == 0) continue;
      out.setRange((ty * w + tx) * 4, (ty * w + tx) * 4 + 4, data, s);
    }
  }
  return Recentered(data: out, dx: dx, dy: dy, box: box);
}
