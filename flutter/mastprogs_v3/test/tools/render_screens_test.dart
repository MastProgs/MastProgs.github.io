// 시각 점검용 화면 캡처(브라우저 QA 의 보조, 기본 실행에서는 건너뜀).
// 실행: flutter test test/tools/render_screens_test.dart --dart-define=RENDER_SCREENS=true
// 실제 번들 글꼴(Pretendard·Roboto Mono·Phosphor)을 읽어 네 경로 × 어두운/밝은 × 1440/390 을 build/qa-screens/*.png 로 남긴다.
// AI-NOTE: 테스트 엔진의 소프트웨어 렌더링이라 브라우저(CanvasKit) 결과와 글꼴 힌팅·안티앨리어싱이 조금 다를 수 있다. 최종 판정은 브라우저 QA 다.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/app/app.dart';
import 'package:mastprogs_v3/platform/host_platform.dart';

const bool _enabled = bool.fromEnvironment('RENDER_SCREENS');

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await load('Pretendard', ['assets/fonts/PretendardVariable.ttf']);
  await load('RobotoMono', ['assets/fonts/RobotoMono.ttf']);
  for (final (style, file) in [('Regular', 'Phosphor.ttf'), ('Bold', 'Phosphor-Bold.ttf'), ('Fill', 'Phosphor-Fill.ttf')]) {
    await load('packages/phosphor_flutter/Phosphor$style', ['packages/phosphor_flutter/lib/fonts/$file']);
  }
}

void main() {
  if (!_enabled) {
    test('screen rendering is opt-in (RENDER_SCREENS=true)', () {});
    return;
  }

  setUpAll(_loadFonts);

  final routes = {'main': '/?state=target', 'workflow': '/workflow', 'sprite': '/sprite', 'subtitles': '/subtitles'};
  const heights = {'main': 7600.0, 'workflow': 5200.0, 'sprite': 3600.0, 'subtitles': 4600.0};
  const mobileHeights = {'main': 13500.0, 'workflow': 9800.0, 'sprite': 6800.0, 'subtitles': 9400.0};

  for (final width in [1440.0, 390.0]) {
    for (final theme in ['dark', 'light']) {
      for (final entry in routes.entries) {
        testWidgets('render ${entry.key} $theme ${width.toInt()}', (tester) async {
          final height = (width < 500 ? mobileHeights : heights)[entry.key]!;
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final key = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: PortfolioApp(
                platform: MemoryHostPlatform(storedTheme: theme, reducedMotion: true),
                initialLocation: entry.value,
              ),
            ),
          );
          for (var i = 0; i < 60; i += 1) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
            await tester.pump(const Duration(milliseconds: 100));
          }
          // 작업 화면은 몇 프레임 진행한 상태도 본다.
          if (entry.key == 'workflow') {
            for (var i = 0; i < 15; i += 1) {
              final next = find.bySemanticsLabel('다음 프레임');
              await tester.tap(next.first, warnIfMissed: false);
              await tester.pump();
            }
          }
          for (var i = 0; i < 20; i += 1) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
            await tester.pump(const Duration(milliseconds: 100));
          }
          await tester.runAsync(() async {
            final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final name = 'build/qa-screens/flutter-${entry.key}-$theme-${width.toInt()}';
            Directory('build/qa-screens').createSync(recursive: true);
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            File('$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
            // 화면 한 장 크기 조각(세부 확인용).
            final tile = width < 500 ? 844.0 : 1100.0;
            for (var top = 0.0, index = 0; top < image.height; top += tile, index += 1) {
              final recorder = ui.PictureRecorder();
              final rect = Rect.fromLTWH(0, top, width, tile.clamp(0, image.height - top).toDouble());
              Canvas(recorder).drawImageRect(image, rect, Offset.zero & rect.size, Paint());
              final piece = await recorder.endRecording().toImage(rect.width.toInt(), rect.height.toInt());
              final pieceBytes = await piece.toByteData(format: ui.ImageByteFormat.png);
              File('$name-t$index.png').writeAsBytesSync(pieceBytes!.buffer.asUint8List());
              piece.dispose();
            }
            image.dispose();
          });
        });
      }
    }
  }
}
