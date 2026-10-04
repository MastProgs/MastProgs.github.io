// 원본 골격(hero-side.skeleton.json)과 프레임별 각도(engine-motion rot_world) 도우미(순수 함수).
// AI-NOTE: 좌표는 원본 골격 캔버스(1254×1254, y 아래로 증가) 그대로이고 스프라이트 픽셀 좌표가 아니다.
// - 각도 규칙: 뼈 각 = atan2(to.y − from.y, to.x − from.x)(도). 기준 자세에서 계산한 값이 원본 attack 첫 프레임 rot_world 와
//   같다(몸통 −83.836°, 머리 −100.331° 등) — tests/pixel-studio.test.mjs 가 확인한다.
// - 자세(FK): 부모의 회전 변화(현재 각 − 기준 각)로 자식의 시작점을 강체 회전시키고, 자신은 자기 길이 × 원본 각도로 뻗는다.
//   프레임 데이터에 각이 없는 뼈(걷기·달리기의 머리·더듬이 뿌리)와 그 자손은 추정하지 않고 "값 없음"으로 둔다.
// - 루트 이동(root/rootCells)은 단위가 렌더러 내부 배율에 묶여 있어 좌표에 섞지 않고 수치로만 보여 준다.

const DEG = Math.PI / 180;
const angleOf = (from, to) => Math.atan2(to[1] - from[1], to[0] - from[0]) / DEG;

export function buildRig(skeleton) {
  const { joints } = skeleton;
  const byName = new Map(skeleton.bones.map((bone) => [bone.name, bone]));
  const ordered = [];
  const visit = (bone) => {
    if (ordered.includes(bone)) return;
    if (bone.parent) visit(byName.get(bone.parent));
    ordered.push(bone);
  };
  skeleton.bones.forEach(visit);
  const bones = ordered.map((bone) => {
    const from = joints[bone.from];
    const to = joints[bone.to];
    if (!from || !to) throw new Error(`골격 관절이 없습니다: ${bone.name}`);
    return Object.freeze({
      name: bone.name,
      ko: bone.ko,
      kind: bone.kind,
      parent: bone.parent,
      side: bone.side,
      from,
      to,
      length: Math.hypot(to[0] - from[0], to[1] - from[1]),
      restAngle: angleOf(from, to),
      attach: bone.attach ?? null,
    });
  });
  return Object.freeze({
    canvas: skeleton.canvas,
    units: skeleton.units,
    joints,
    bones,
    bonesByName: Object.fromEntries(bones.map((bone) => [bone.name, bone])),
    extraLayers: skeleton.extra_layers.map((layer) => ({ name: layer.name, ko: layer.ko, anchor: layer.anchor_bone, at: layer.at, follow: layer.follow ?? null })),
    layerOrder: skeleton.layer_order,
    layerOf: skeleton.layer_of,
  });
}

const rotateAbout = (point, pivot, radians) => {
  const c = Math.cos(radians);
  const s = Math.sin(radians);
  const dx = point[0] - pivot[0];
  const dy = point[1] - pivot[1];
  return [pivot[0] + dx * c - dy * s, pivot[1] + dx * s + dy * c];
};

// 한 프레임의 자세. 반환: name → { from, to, angle, delta, posed } (posed=false 면 from/to 는 null).
export function poseRig(rig, rotWorld) {
  const out = {};
  for (const bone of rig.bones) {
    const angle = rotWorld?.[bone.name];
    const parent = bone.parent ? out[bone.parent] : null;
    if (typeof angle !== "number" || (bone.parent && !parent.posed)) {
      out[bone.name] = { from: null, to: null, angle: typeof angle === "number" ? angle : null, delta: null, posed: false };
      continue;
    }
    let from = bone.from;
    if (parent) {
      // 부모 기준 자세의 시작점을 축으로 부모 회전 변화만큼 돌린 뒤, 부모의 새 시작점으로 옮긴다.
      const parentRest = rig.bonesByName[bone.parent];
      const rotated = rotateAbout(bone.from, parentRest.from, parent.delta * DEG);
      from = [rotated[0] - parentRest.from[0] + parent.from[0], rotated[1] - parentRest.from[1] + parent.from[1]];
    }
    const to = [from[0] + Math.cos(angle * DEG) * bone.length, from[1] + Math.sin(angle * DEG) * bone.length];
    out[bone.name] = { from, to, angle, delta: angle - bone.restAngle, posed: true };
  }
  return out;
}

// 접지 표시: 원본 plant 값(heel/toe/flat)에 따라 발 뼈에 붙은 원본 heel·toe 점을 자세로 옮긴다.
export function plantPoints(rig, pose, plant) {
  const points = [];
  for (const side of ["near", "far"]) {
    const kind = plant?.[side];
    const name = `${side}_foot`;
    const bone = rig.bonesByName[name];
    const posed = pose[name];
    if (!kind || !bone?.attach || !posed?.posed) continue;
    const keys = kind === "flat" ? ["heel", "toe"] : [kind];
    for (const key of keys) {
      const rest = bone.attach[key];
      if (!rest) continue;
      const rotated = rotateAbout(rest, bone.from, posed.delta * DEG);
      points.push({ side, kind: key, point: [rotated[0] - bone.from[0] + posed.from[0], rotated[1] - bone.from[1] + posed.from[1]] });
    }
  }
  return points;
}

// 프레임 수치 정리(화면 읽기용). motionRig = pixel-motion-rig.json.
export function frameRig(motionRig, motionId, step) {
  const frame = motionRig.motions[motionId]?.[step];
  if (!frame) return null;
  return { ms: frame.ms, root: frame.root, rootCells: frame.rootCells, headGrid: frame.headGrid, plant: frame.plant, rotWorld: frame.rot_world };
}
