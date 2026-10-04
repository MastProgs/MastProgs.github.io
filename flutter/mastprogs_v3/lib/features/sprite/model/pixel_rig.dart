// 원본 골격(hero-side.skeleton.json)과 프레임별 각도(engine-motion rot_world) 도우미(React src/pixel/rig.js 이식, 순수 함수).
// AI-NOTE: 좌표는 원본 골격 캔버스(1254×1254, y 아래로 증가) 그대로이고 스프라이트 픽셀 좌표가 아니다.
// - 각도 규칙: 뼈 각 = atan2(to.y − from.y, to.x − from.x)(도). 기준 자세에서 계산한 값이 원본 attack 첫 프레임 rot_world 와 같다.
// - 자세(FK): 부모의 회전 변화(현재 각 − 기준 각)로 자식의 시작점을 강체 회전시키고, 자신은 자기 길이 × 원본 각도로 뻗는다.
//   프레임 데이터에 각이 없는 뼈(걷기·달리기의 머리·더듬이 뿌리)와 그 자손은 추정하지 않고 "값 없음"으로 둔다.
// - 루트 이동(root/rootCells)은 단위가 렌더러 내부 배율에 묶여 있어 좌표에 섞지 않고 수치로만 보여 준다.
import 'dart:math' as math;

import '../../../core/json.dart';

const double _deg = math.pi / 180;

typedef Point2 = List<double>;

double _angleOf(Point2 from, Point2 to) => math.atan2(to[1] - from[1], to[0] - from[0]) / _deg;

Point2 _point(Object? value) => [for (final n in value as List) (n as num).toDouble()];

class RigBone {
  const RigBone({
    required this.name,
    required this.ko,
    required this.kind,
    required this.parent,
    required this.side,
    required this.from,
    required this.to,
    required this.length,
    required this.restAngle,
    required this.attach,
  });

  final String name;
  final String ko;
  final String? kind;
  final String? parent;
  final String side;
  final Point2 from;
  final Point2 to;
  final double length;
  final double restAngle;
  final Map<String, Point2>? attach;
}

class RigFollow {
  const RigFollow({required this.bone, required this.ratio});

  final String bone;
  final double ratio;
}

class RigExtraLayer {
  const RigExtraLayer({required this.name, required this.ko, required this.anchor, required this.follow});

  final String name;
  final String ko;
  final String anchor;
  final RigFollow? follow;
}

class HeroRig {
  const HeroRig({required this.canvas, required this.groundY, required this.crownY, required this.bones, required this.bonesByName, required this.extraLayers});

  final List<int> canvas;
  final double groundY;
  final double crownY;
  final List<RigBone> bones;
  final Map<String, RigBone> bonesByName;
  final List<RigExtraLayer> extraLayers;
}

HeroRig buildRig(Json skeleton) {
  final joints = skeleton.obj('joints');
  final source = skeleton.objs('bones');
  final byName = {for (final bone in source) bone.str('name'): bone};
  final ordered = <Json>[];
  void visit(Json bone) {
    if (ordered.contains(bone)) return;
    final parent = bone.strOrNull('parent');
    if (parent != null) visit(byName[parent]!);
    ordered.add(bone);
  }

  source.forEach(visit);
  final bones = [
    for (final bone in ordered)
      () {
        final fromRaw = joints[bone.str('from')];
        final toRaw = joints[bone.str('to')];
        if (fromRaw == null || toRaw == null) throw FormatException('골격 관절이 없습니다: ${bone.str('name')}');
        final from = _point(fromRaw);
        final to = _point(toRaw);
        final attach = bone.objOrNull('attach');
        return RigBone(
          name: bone.str('name'),
          ko: bone.str('ko'),
          kind: bone.strOrNull('kind'),
          parent: bone.strOrNull('parent'),
          side: bone.str('side'),
          from: from,
          to: to,
          length: math.sqrt(math.pow(to[0] - from[0], 2) + math.pow(to[1] - from[1], 2)),
          restAngle: _angleOf(from, to),
          attach: attach?.map((key, value) => MapEntry(key, _point(value))),
        );
      }(),
  ];
  final units = skeleton.obj('units');
  return HeroRig(
    canvas: [for (final n in skeleton['canvas'] as List) (n as num).toInt()],
    groundY: units.number('ground_y'),
    crownY: units.number('crown_y'),
    bones: List.unmodifiable(bones),
    bonesByName: {for (final bone in bones) bone.name: bone},
    extraLayers: [
      for (final layer in skeleton.objs('extra_layers'))
        RigExtraLayer(
          name: layer.str('name'),
          ko: layer.str('ko'),
          anchor: layer.str('anchor_bone'),
          follow: layer.objOrNull('follow') == null ? null : RigFollow(bone: layer.obj('follow').str('bone'), ratio: layer.obj('follow').number('ratio')),
        ),
    ],
  );
}

Point2 _rotateAbout(Point2 point, Point2 pivot, double radians) {
  final c = math.cos(radians);
  final s = math.sin(radians);
  final dx = point[0] - pivot[0];
  final dy = point[1] - pivot[1];
  return [pivot[0] + dx * c - dy * s, pivot[1] + dx * s + dy * c];
}

class PosedBone {
  const PosedBone({required this.from, required this.to, required this.angle, required this.delta, required this.posed});

  final Point2? from;
  final Point2? to;
  final double? angle;
  final double? delta;
  final bool posed;

  Map<String, Object?> toJson() => {'from': from, 'to': to, 'angle': angle, 'delta': delta, 'posed': posed};
}

// 한 프레임의 자세. 반환: name → { from, to, angle, delta, posed } (posed=false 면 from/to 는 null).
Map<String, PosedBone> poseRig(HeroRig rig, Map<String, Object?>? rotWorld) {
  final out = <String, PosedBone>{};
  for (final bone in rig.bones) {
    final raw = rotWorld?[bone.name];
    final angle = raw is num ? raw.toDouble() : null;
    final parent = bone.parent != null ? out[bone.parent] : null;
    if (angle == null || (bone.parent != null && !(parent?.posed ?? false))) {
      out[bone.name] = PosedBone(from: null, to: null, angle: angle, delta: null, posed: false);
      continue;
    }
    var from = bone.from;
    if (parent != null) {
      // 부모 기준 자세의 시작점을 축으로 부모 회전 변화만큼 돌린 뒤, 부모의 새 시작점으로 옮긴다.
      final parentRest = rig.bonesByName[bone.parent]!;
      final rotated = _rotateAbout(bone.from, parentRest.from, parent.delta! * _deg);
      from = [rotated[0] - parentRest.from[0] + parent.from![0], rotated[1] - parentRest.from[1] + parent.from![1]];
    }
    final to = [from[0] + math.cos(angle * _deg) * bone.length, from[1] + math.sin(angle * _deg) * bone.length];
    out[bone.name] = PosedBone(from: from, to: to, angle: angle, delta: angle - bone.restAngle, posed: true);
  }
  return out;
}

class PlantPoint {
  const PlantPoint({required this.side, required this.kind, required this.point});

  final String side;
  final String kind;
  final Point2 point;

  Map<String, Object?> toJson() => {'side': side, 'kind': kind, 'point': point};
}

// 접지 표시: 원본 plant 값(heel/toe/flat)에 따라 발 뼈에 붙은 원본 heel·toe 점을 자세로 옮긴다.
List<PlantPoint> plantPoints(HeroRig rig, Map<String, PosedBone> pose, Map<String, Object?>? plant) {
  final points = <PlantPoint>[];
  for (final side in const ['near', 'far']) {
    final kind = plant?[side] as String?;
    final name = '${side}_foot';
    final bone = rig.bonesByName[name];
    final posed = pose[name];
    if (kind == null || kind.isEmpty || bone?.attach == null || !(posed?.posed ?? false)) continue;
    final keys = kind == 'flat' ? const ['heel', 'toe'] : [kind];
    for (final key in keys) {
      final rest = bone!.attach![key];
      if (rest == null) continue;
      final rotated = _rotateAbout(rest, bone.from, posed!.delta! * _deg);
      points.add(PlantPoint(side: side, kind: key, point: [rotated[0] - bone.from[0] + posed.from![0], rotated[1] - bone.from[1] + posed.from![1]]));
    }
  }
  return points;
}

/// 프레임 수치(화면 읽기용). motionRig = pixel-motion-rig.json.
class FrameRigDetail {
  const FrameRigDetail({required this.ms, required this.root, required this.rootCells, required this.headGrid, required this.plant, required this.rotWorld});

  final num ms;
  final List<num> root;
  final List<num> rootCells;
  final List<num> headGrid;
  final Map<String, Object?>? plant;
  final Map<String, Object?>? rotWorld;

  Map<String, Object?> toJson() => {'ms': ms, 'root': root, 'rootCells': rootCells, 'headGrid': headGrid, 'plant': plant, 'rotWorld': rotWorld};
}

FrameRigDetail? frameRig(Json motionRig, String motionId, int step) {
  final motions = motionRig.obj('motions');
  final frames = motions[motionId] as List?;
  if (frames == null || step < 0 || step >= frames.length) return null;
  final frame = asJson(frames[step]);
  List<num> nums(String key) => (frame[key] as List).cast<num>();
  return FrameRigDetail(
    ms: frame['ms'] as num,
    root: nums('root'),
    rootCells: nums('rootCells'),
    headGrid: nums('headGrid'),
    plant: frame['plant'] == null ? null : asJson(frame['plant']),
    rotWorld: frame['rot_world'] == null ? null : asJson(frame['rot_world']),
  );
}

/// 화면 표시용 숫자(원본 JavaScript 의 Array.join 결과와 같은 모양: 정수 값은 소수점 없이).
String formatJsNumber(num value) {
  if (value is int) return '$value';
  if (value == value.truncateToDouble() && value.isFinite) return value.toInt().toString();
  return value.toString();
}
