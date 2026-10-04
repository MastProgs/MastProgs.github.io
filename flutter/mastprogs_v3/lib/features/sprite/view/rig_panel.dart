// 골격 패널(React RigPanel.jsx 이식).
// AI-NOTE: 왼쪽 그림은 원본 골격 좌표(1254×1254)의 기준 자세(흐린 선)와, 현재 프레임의 원본 월드 각도로만 계산한 자세(FK, 진한 선)다.
// 스프라이트 픽셀 위에 겹치지 않는다(좌표계가 다르고, 원본 렌더러의 투영·머리 격자 맞춤을 흉내 내지 않음).
// 프레임 데이터에 각이 없는 뼈는 "값 없음"으로 두고 그리지 않는다. root·rootCells·headGrid·접지는 원본 값을 그대로 적는다.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../controller/pixel_studio_controller.dart';
import '../model/pixel_rig.dart';

// 원본 골격 캔버스(1254) 중 그릴 범위와 캔버스 픽셀 배율. 공격의 검 끝까지 들어가도록 잡았다.
const Rect _view = Rect.fromLTWH(150, 80, 1000, 1120);
const double _scale = 0.4;

String _angle(PosedBone posed, String missing) => posed.angle == null ? missing : '${posed.angle!.toStringAsFixed(1)}°';

String _delta(PosedBone posed) {
  final delta = posed.delta;
  if (delta == null) return '';
  return '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}°';
}

class RigPanel extends StatelessWidget {
  const RigPanel({super.key, required this.controller});

  final PixelStudioController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    final copy = controller.page.content.copy;
    final plantLabels = controller.page.content.plantLabels;
    final frame = controller.rig;
    if (frame == null) return const SizedBox.shrink();
    final rig = controller.studio!.rig;
    final pose = poseRig(rig, frame.rotWorld);
    final plants = plantPoints(rig, pose, frame.plant);
    String nameKo(String name) => rig.bonesByName[name]?.ko ?? name;
    String plantText(Object? kind) => kind == null ? '—' : (plantLabels['$kind'] ?? '$kind');
    final small = textStyle(size: 12.5, color: palette.ink3, tabular: true);
    final strong = textStyle(size: 12.5, weight: FontWeight.w600, color: palette.ink, tabular: true);

    final figure = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: AspectRatio(
            aspectRatio: _view.width / _view.height,
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.line1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Semantics(
                image: true,
                label: copy['rigCanvas'],
                child: CustomPaint(
                  painter: _RigPainter(
                    rig: rig,
                    pose: pose,
                    plants: plants,
                    rest: palette.line3,
                    near: palette.orange,
                    far: palette.infoText,
                    center: palette.ink,
                    guide: palette.line4,
                    plant: palette.lime,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(width: 16, height: 3, margin: const EdgeInsets.only(left: 4), color: palette.line3),
            Text(copy['rigRest']!, style: textStyle(size: 12, color: palette.ink3)),
            Container(width: 16, height: 3, margin: const EdgeInsets.only(left: 4), color: palette.orange),
            Text(copy['rigPosed']!, style: textStyle(size: 12, color: palette.ink3)),
          ],
        ),
      ],
    );

    String join(List<num> values) => values.map(formatJsNumber).join(', ');
    final facts = [
      (copy['rigPlant']!, '앞 ${plantText(frame.plant?['near'])} · 뒤 ${plantText(frame.plant?['far'])}'),
      (copy['rigRoot']!, '[${join(frame.root)}]'),
      (copy['rigRootCells']!, '[${join(frame.rootCells)}]'),
      (copy['rigHeadGrid']!, '[${join(frame.headGrid)}]'),
    ];

    final table = _RigTable(
      header: [copy['rigBone']!, copy['rigParent']!, copy['rigAngle']!, copy['rigDelta']!],
      rows: [
        for (final bone in rig.bones)
          (
            bone: bone,
            parent: bone.parent == null ? '—' : nameKo(bone.parent!),
            angle: _angle(pose[bone.name]!, copy['rigMissing']!),
            delta: pose[bone.name]!.posed ? _delta(pose[bone.name]!) : '',
            missing: !pose[bone.name]!.posed,
          ),
      ],
    );

    final extras = rig.extraLayers
        .map(
          (layer) =>
              '${layer.ko} → ${nameKo(layer.anchor)}${layer.follow != null ? '(${nameKo(layer.follow!.bone)} ${(layer.follow!.ratio * 100).round()}%)' : ''}',
        )
        .join(' · ');

    final data = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = math.max(1, ((constraints.maxWidth + 14) / (140 + 14)).floor());
            final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final (label, value) in facts)
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: small),
                        Text(value, style: strong),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        table,
        const SizedBox(height: 10),
        Text('${copy['extraLayers']}: $extras', style: textStyle(size: 12.5, color: palette.ink3, height: 1.5)),
      ],
    );

    return Semantics(
      container: true,
      label: copy['rigTitle'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            copy['rigTitle']!,
            style: textStyle(size: 13.5, weight: FontWeight.w600, color: palette.ink),
          ),
          const SizedBox(height: 10),
          if (mobile)
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [figure, const SizedBox(height: 16), data])
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 300, child: figure),
                const SizedBox(width: 20),
                Expanded(child: data),
              ],
            ),
        ],
      ),
    );
  }
}

typedef _RigRow = ({RigBone bone, String parent, String angle, String delta, bool missing});

class _RigTable extends StatefulWidget {
  const _RigTable({required this.header, required this.rows});

  final List<String> header;
  final List<_RigRow> rows;

  @override
  State<_RigTable> createState() => _RigTableState();
}

class _RigTableState extends State<_RigTable> {
  final ScrollController _vertical = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cell = textStyle(size: 12.5, color: palette.ink, tabular: true);
    final head = textStyle(size: 12.5, weight: FontWeight.w600, color: palette.ink3);
    Widget box(Widget child, {double width = 120}) => Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line1)),
      ),
      child: child,
    );
    const widths = [190.0, 110.0, 90.0, 90.0];
    final total = widths.reduce((a, b) => a + b);
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.line1),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth > total ? constraints.maxWidth / total : 1.0;
          final w = [for (final width in widths) width * scale];
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: total * scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: palette.surface,
                    child: Row(
                      children: [for (final (i, label) in widget.header.indexed) box(Text(label, style: head), width: w[i])],
                    ),
                  ),
                  Flexible(
                    child: Scrollbar(
                      controller: _vertical,
                      child: SingleChildScrollView(
                        controller: _vertical,
                        child: Column(
                          children: [
                            for (final row in widget.rows)
                              Row(
                                children: [
                                  box(
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: row.bone.ko,
                                            style: cell.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                          TextSpan(
                                            text: '  ${row.bone.name}',
                                            style: textStyle(size: 11, mono: true, color: palette.ink3),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    width: w[0],
                                  ),
                                  box(
                                    Text(row.parent, style: cell.copyWith(color: row.missing ? palette.ink3 : palette.ink)),
                                    width: w[1],
                                  ),
                                  box(
                                    Text(row.angle, style: cell.copyWith(color: row.missing ? palette.ink3 : palette.ink)),
                                    width: w[2],
                                  ),
                                  box(
                                    Text(row.delta, style: cell.copyWith(color: row.missing ? palette.ink3 : palette.ink)),
                                    width: w[3],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RigPainter extends CustomPainter {
  const _RigPainter({
    required this.rig,
    required this.pose,
    required this.plants,
    required this.rest,
    required this.near,
    required this.far,
    required this.center,
    required this.guide,
    required this.plant,
  });

  final HeroRig rig;
  final Map<String, PosedBone> pose;
  final List<PlantPoint> plants;
  final Color rest;
  final Color near;
  final Color far;
  final Color center;
  final Color guide;
  final Color plant;

  @override
  void paint(Canvas canvas, Size size) {
    // 원본 캔버스는 400×448 픽셀에 그린 뒤 CSS 로 줄였다. 같은 비율로 맞춘다.
    final fit = size.width / (_view.width * _scale);
    canvas.scale(fit);
    Offset px(List<double> p) => Offset((p[0] - _view.left) * _scale, (p[1] - _view.top) * _scale);
    void line(List<double> a, List<double> b, Color color, double width, {bool dashed = false}) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = width
        ..style = PaintingStyle.stroke;
      final from = px(a);
      final to = px(b);
      if (!dashed) {
        canvas.drawLine(from, to, paint);
        return;
      }
      final length = (to - from).distance;
      final direction = (to - from) / length;
      for (var d = 0.0; d < length; d += 8) {
        canvas.drawLine(from + direction * d, from + direction * math.min(d + 4, length), paint);
      }
    }

    // 원본 단위의 바닥(ground_y)·정수리(crown_y) 줄.
    line([_view.left, rig.groundY], [_view.right, rig.groundY], guide, 1.5);
    line([_view.left, rig.crownY], [_view.right, rig.crownY], guide, 1, dashed: true);
    // 기준 자세(원본 관절 좌표 그대로).
    for (final bone in rig.bones) {
      line(bone.from, bone.to, rest, 3);
    }
    // 현재 프레임 각도로 계산한 자세. 뒤쪽 → 가운데 → 앞쪽 순서로 겹친다.
    for (final side in const ['far', 'back', 'center', 'near']) {
      for (final bone in rig.bones) {
        if (bone.side != side) continue;
        final posed = pose[bone.name]!;
        if (!posed.posed) continue;
        final color = side == 'near' ? near : (side == 'far' ? far : center);
        line(posed.from!, posed.to!, color, 4);
        canvas.drawCircle(px(posed.from!), 3, Paint()..color = color);
      }
    }
    for (final point in plants) {
      final p = px(point.point);
      canvas.drawRect(Rect.fromCenter(center: p, width: 8, height: 8), Paint()..color = plant);
    }
  }

  @override
  bool shouldRepaint(_RigPainter oldDelegate) =>
      !identical(pose, oldDelegate.pose) || rest != oldDelegate.rest || near != oldDelegate.near || center != oldDelegate.center;
}
