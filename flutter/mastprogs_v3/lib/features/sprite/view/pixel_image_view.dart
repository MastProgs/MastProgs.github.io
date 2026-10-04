// 이미 가공한 RGBA 를 최근접 확대로 그리는 작은 캔버스(React PixelCanvas.jsx 이식).
// AI-NOTE: 큰 RGBA 배열을 위젯 속성으로 받지 않는다. 짧은 frameKey 문자열이 바뀌면 컨트롤러에서 그 순간의 이미지를 받아 ui.Image 로 한 번 만든다.
// 만든 그림은 컨트롤러의 크기 제한 캐시(버려질 때 dispose)에 두고, 이 위젯은 복제 핸들(clone)만 들고 있다가 바뀌거나 사라질 때 dispose 한다
// (캐시에서 버려져도 그리던 그림이 망가지지 않음). 새 그림이 준비될 때까지는 이전 그림을 그대로 보여 준다(깜빡임 없음).
// AI-NOTE: 순수 모델의 RGBA 는 브라우저 ImageData 와 같은 직선(straight) 알파다(어니언의 tintPixels·composeOver 반투명 포함).
// ui.PixelFormat.rgba8888 은 사전 곱셈(premultiplied) 알파를 요구하므로, 올리는 순간에만 사본을 만들어 RGB 에 alpha/255 를 곱한다.
// 모델 바이트·해시·캐시의 원본 배열은 그대로 둔다(FQ-001: 그대로 올리면 [100,50,25,128] 이 [199,100,50,128] 로 밝아짐).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../controller/pixel_studio_controller.dart';

/// 직선 알파 RGBA → 사전 곱셈 RGBA 사본. RGB 는 round(c × a / 255)(0.5 올림), 알파는 그대로.
/// 알파 255 는 원본과 같고, 알파 0 은 RGB 0 이 된다. 입력 배열은 바꾸지 않는다.
Uint8List premultiplyRgba(Uint8List straight) {
  final out = Uint8List(straight.length);
  for (var i = 0; i + 3 < straight.length; i += 4) {
    final a = straight[i + 3];
    if (a == 0) continue;
    if (a == 255) {
      out.setRange(i, i + 4, straight, i);
      continue;
    }
    // 정수 c×a 에서 (c×a + 127) ~/ 255 는 floor(c×a/255 + 0.5) 와 같다.
    out[i] = (straight[i] * a + 127) ~/ 255;
    out[i + 1] = (straight[i + 1] * a + 127) ~/ 255;
    out[i + 2] = (straight[i + 2] * a + 127) ~/ 255;
    out[i + 3] = a;
  }
  return out;
}

/// 디버그 전용: 지금까지 올린 그림 수(재생 중 새 네이티브 그림이 생기지 않는지 테스트가 확인). 릴리스에서는 늘지 않는다.
int debugPixelUploadCount = 0;

/// 직선 알파 RGBA 를 사전 곱셈 사본으로 바꿔 ui.Image 로 올린다(이 화면의 유일한 픽셀 업로드 경계).
void uploadStraightRgba(Uint8List straight, int width, int height, ui.ImageDecoderCallback callback) {
  assert(() {
    debugPixelUploadCount += 1;
    return true;
  }());
  ui.decodeImageFromPixels(premultiplyRgba(straight), width, height, ui.PixelFormat.rgba8888, callback);
}

class PixelImageView extends StatefulWidget {
  const PixelImageView({super.key, required this.controller, required this.kind, required this.frameKey, this.semanticLabel});

  final PixelStudioController controller;
  final PixelImageKind kind;
  final String frameKey;
  final String? semanticLabel;

  @override
  State<PixelImageView> createState() => _PixelImageViewState();
}

class _PixelImageViewState extends State<PixelImageView> {
  ui.Image? _image;
  String? _shownKey;
  String? _pendingKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PixelImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frameKey != oldWidget.frameKey || widget.kind != oldWidget.kind) _load();
  }

  String get _cacheKey => '${widget.kind.name}#${widget.frameKey}';

  void _load() {
    final key = _cacheKey;
    if (key == _pendingKey) return;
    // 지금 원하는 프레임을 이미 보이고 있거나 캐시에서 바로 보이면, 더 오래된 대기 업로드는 화면에 쓰지 않는다
    // (늦게 끝난 콜백은 캐시에만 넣고 _pendingKey 가 달라 표시하지 않음 → 지난 프레임으로 되돌아가지 않는다).
    if (key == _shownKey) {
      _pendingKey = null;
      return;
    }
    final cached = widget.controller.imageCache.get(key);
    if (cached != null) {
      _pendingKey = null;
      _show(key, cached.clone());
      return;
    }
    _pendingKey = key;
    final pixels = widget.controller.imageFor(widget.kind);
    uploadStraightRgba(pixels.data, pixels.width, pixels.height, (image) {
      if (!mounted) {
        image.dispose();
        return;
      }
      widget.controller.imageCache.set(key, image);
      if (_pendingKey != key) return;
      _pendingKey = null;
      _show(key, image.clone());
    });
  }

  void _show(String key, ui.Image image) {
    final previous = _image;
    setState(() {
      _image = image;
      _shownKey = key;
    });
    previous?.dispose();
  }

  @override
  void dispose() {
    _image?.dispose();
    _image = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: widget.semanticLabel != null,
      label: widget.semanticLabel,
      child: CustomPaint(painter: _NearestPainter(_image), size: Size.infinite),
    );
  }
}

class _NearestPainter extends CustomPainter {
  const _NearestPainter(this.image);

  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    final current = image;
    if (current == null) return;
    paintImage(canvas: canvas, rect: Offset.zero & size, image: current, fit: BoxFit.fill, filterQuality: FilterQuality.none, isAntiAlias: false);
  }

  @override
  bool shouldRepaint(_NearestPainter oldDelegate) => !identical(image, oldDelegate.image);
}
