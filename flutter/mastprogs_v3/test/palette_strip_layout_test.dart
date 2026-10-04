// /sprite 색 줄 배치 회귀: 현재 프레임 색 점유율 막대(높이 14, 테두리 안 12)와 세트 견본 줄(높이 8)이
// 실제로 높이를 가진 색 칸으로 그려지는지(예전에는 Row 가운데 정렬로 높이 0 → 빈 줄) 1440·390 두 너비에서 확인한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/features/sprite/view/palette_set_row.dart';

import 'support/finders.dart';
import 'widget_test.dart' show pumpApp, pumpUntilFound;

void main() {
  for (final width in [1440.0, 390.0]) {
    testWidgets('colour strips paint with positive height at ${width.toInt()}px', (tester) async {
      await pumpApp(tester, '/sprite', size: Size(width, width < 500 ? 9000 : 5000));
      await pumpUntilFound(tester, findText('Hero Pixel Studio 라이브 미리보기'));
      final boxes = find.descendant(of: find.byType(PaletteSetRow), matching: find.byType(ColoredBox)).evaluate().toList();
      expect(boxes, isNotEmpty);
      final painted = [for (final element in boxes) (size: (element.renderObject! as RenderBox).size, color: (element.widget as ColoredBox).color)];
      expect(painted.where((box) => box.size.height == 0), isEmpty, reason: 'no collapsed (empty) colour cells');
      final swatchCells = painted.where((box) => box.size.height == 8 && box.size.width > 0).toList();
      final shareCells = painted.where((box) => box.size.height == 12 && box.size.width > 0).toList();
      expect(swatchCells.length, greaterThanOrEqualTo(10 * 8), reason: 'every palette set strip is filled');
      expect(shareCells, isNotEmpty, reason: 'current-frame share bar is filled');
      for (final box in [...swatchCells, ...shareCells]) {
        expect(box.color.a, 1.0, reason: 'opaque source colour');
      }
    });
  }
}
