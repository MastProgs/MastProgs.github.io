// 추가 외곽선 도우미(React src/pixel/outline.js 이식, 순수 함수).
// AI-NOTE: 원본이 그린 선(잉크)은 그대로 두고, 불투명 픽셀과 상하좌우로 맞닿은 투명 픽셀에만 한 칸 외곽선을 더한다
// (그래서 화면 이름이 "추가 외곽선"). 프레임 가장자리에 닿는 칼끝이 잘리지 않도록 모든 프레임을 같은 여백(pad)만큼
// 넓힌 공통 캔버스에 같은 위치로 옮긴 뒤 그린다 — 프레임마다 다시 가운데 맞추지 않으므로 기준점(pivot)이 흔들리지 않는다.
import 'dart:typed_data';

import 'pixel_layers.dart';

const int outlinePad = 1;

class PixelImage {
  const PixelImage({required this.data, required this.width, required this.height});

  /// RGBA 8bit(알파 0/255 원본 규칙, 어니언 합성만 중간 알파).
  final Uint8List data;
  final int width;
  final int height;
}

// w×h RGBA 를 사방 pad 만큼 넓힌 새 배열로 옮긴다(위치 이동은 모든 프레임 동일).
PixelImage padPixels(Uint8List data, int w, int h, [int pad = outlinePad]) {
  final pw = w + pad * 2;
  final ph = h + pad * 2;
  final out = Uint8List(pw * ph * 4);
  for (var y = 0; y < h; y += 1) {
    out.setRange(((y + pad) * pw + pad) * 4, ((y + pad) * pw + pad) * 4 + w * 4, data, y * w * 4);
  }
  return PixelImage(data: out, width: pw, height: ph);
}

// 새 배열을 돌려준다. 원래 불투명 픽셀(알파 > 0)은 한 바이트도 바꾸지 않고, 더한 외곽선 픽셀은 알파 255.
Uint8List addOutline(Uint8List data, int w, int h, Rgb rgb) {
  final out = Uint8List.fromList(data);
  bool opaque(int x, int y) => x >= 0 && y >= 0 && x < w && y < h && data[(y * w + x) * 4 + 3] > 0;
  for (var y = 0; y < h; y += 1) {
    for (var x = 0; x < w; x += 1) {
      final i = (y * w + x) * 4;
      if (data[i + 3] > 0) continue;
      if (opaque(x - 1, y) || opaque(x + 1, y) || opaque(x, y - 1) || opaque(x, y + 1)) {
        out[i] = rgb[0];
        out[i + 1] = rgb[1];
        out[i + 2] = rgb[2];
        out[i + 3] = 255;
      }
    }
  }
  return out;
}

// 원본 불투명 픽셀이 공통 캔버스의 가장자리 한 줄에 닿지 않는지(외곽선이 잘리지 않는지) 확인한다.
bool fitsWithOutline(Uint8List data, int w, int h) {
  for (var y = 0; y < h; y += 1) {
    for (var x = 0; x < w; x += 1) {
      if (data[(y * w + x) * 4 + 3] > 0 && (x == 0 || y == 0 || x == w - 1 || y == h - 1)) return false;
    }
  }
  return true;
}
