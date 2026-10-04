import { useEffect, useMemo, useRef } from "react";
import { PIXEL_COPY, PLANT_LABELS } from "../../../content/pixelStudio.js";
import { plantPoints, poseRig } from "../../../pixel/rig.js";
import { useTheme } from "../../../theme/ThemeContext.jsx";

// 원본 골격 캔버스(1254) 중 그릴 범위와 캔버스 픽셀 배율. 공격의 검 끝까지 들어가도록 잡았다.
const VIEW = Object.freeze({ x: 150, y: 80, w: 1000, h: 1120 });
const SCALE = 0.4;
const fmt = (value) => (value === null || value === undefined ? PIXEL_COPY.rigMissing : `${value.toFixed(1)}°`);
const fmtDelta = (value) => (value === null || value === undefined ? "" : `${value >= 0 ? "+" : ""}${value.toFixed(1)}°`);
const plantText = (kind) => (kind ? PLANT_LABELS[kind] ?? kind : "—");
const cssVar = (style, name) => style.getPropertyValue(name).trim() || "#888";

function drawRig(canvas, rig, pose, plants) {
  const context = canvas.getContext("2d");
  if (!context) return;
  const style = getComputedStyle(canvas);
  const colors = {
    rest: cssVar(style, "--rig-rest"),
    near: cssVar(style, "--rig-near"),
    far: cssVar(style, "--rig-far"),
    center: cssVar(style, "--rig-center"),
    guide: cssVar(style, "--rig-guide"),
    plant: cssVar(style, "--rig-plant"),
  };
  const px = (p) => [(p[0] - VIEW.x) * SCALE, (p[1] - VIEW.y) * SCALE];
  const line = (a, b, color, width, dash = []) => {
    const [ax, ay] = px(a);
    const [bx, by] = px(b);
    context.strokeStyle = color;
    context.lineWidth = width;
    context.setLineDash(dash);
    context.beginPath();
    context.moveTo(ax, ay);
    context.lineTo(bx, by);
    context.stroke();
  };
  context.clearRect(0, 0, canvas.width, canvas.height);
  // 원본 단위의 바닥(ground_y)·정수리(crown_y) 줄.
  line([VIEW.x, rig.units.ground_y], [VIEW.x + VIEW.w, rig.units.ground_y], colors.guide, 1.5);
  line([VIEW.x, rig.units.crown_y], [VIEW.x + VIEW.w, rig.units.crown_y], colors.guide, 1, [4, 4]);
  // 기준 자세(원본 관절 좌표 그대로).
  for (const bone of rig.bones) line(bone.from, bone.to, colors.rest, 3);
  // 현재 프레임 각도로 계산한 자세. 뒤쪽 → 가운데 → 앞쪽 순서로 겹친다.
  for (const side of ["far", "back", "center", "near"]) {
    for (const bone of rig.bones) {
      if (bone.side !== side) continue;
      const posed = pose[bone.name];
      if (!posed.posed) continue;
      const color = side === "near" ? colors.near : side === "far" ? colors.far : colors.center;
      line(posed.from, posed.to, color, 4);
      const [jx, jy] = px(posed.from);
      context.fillStyle = color;
      context.beginPath();
      context.arc(jx, jy, 3, 0, Math.PI * 2);
      context.fill();
    }
  }
  context.setLineDash([]);
  for (const { point } of plants) {
    const [x, y] = px(point);
    context.fillStyle = colors.plant;
    context.fillRect(x - 4, y - 4, 8, 8);
  }
}

// AI-NOTE: 골격 패널. 왼쪽 캔버스는 원본 골격 좌표(1254×1254)의 기준 자세(흐린 선)와, 현재 프레임의 원본 월드 각도로만 계산한
// 자세(FK, 진한 선)다. 스프라이트 픽셀 위에 겹치지 않는다(좌표계가 다르고, 원본 렌더러의 투영·머리 격자 맞춤을 흉내 내지 않음).
// 프레임 데이터에 각이 없는 뼈는 "값 없음"으로 두고 그리지 않는다. root·rootCells·headGrid·접지는 원본 값을 그대로 적는다.
export function RigPanel({ rig, frame }) {
  const canvasRef = useRef(null);
  const { theme } = useTheme();
  const pose = useMemo(() => poseRig(rig, frame?.rotWorld), [rig, frame]);
  const plants = useMemo(() => plantPoints(rig, pose, frame?.plant), [rig, pose, frame]);
  const nameKo = (name) => rig.bonesByName[name]?.ko ?? name;

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return undefined;
    // 테마 값은 상위 Provider 효과에서 바뀌므로 다음 그림 차례에 읽는다.
    const id = window.requestAnimationFrame(() => drawRig(canvas, rig, pose, plants));
    return () => window.cancelAnimationFrame(id);
  }, [rig, pose, plants, theme]);

  if (!frame) return null;
  return (
    <section className="pixel-rig" aria-label={PIXEL_COPY.rigTitle}>
      <p className="pixel-card__title">{PIXEL_COPY.rigTitle}</p>
      <div className="pixel-rig__body">
        <figure className="pixel-rig__figure">
          <canvas ref={canvasRef} className="pixel-rig__canvas" width={VIEW.w * SCALE} height={VIEW.h * SCALE} role="img" aria-label={PIXEL_COPY.rigCanvas} />
          <figcaption>
            <span className="pixel-rig__key is-rest" aria-hidden="true" />
            {PIXEL_COPY.rigRest}
            <span className="pixel-rig__key is-posed" aria-hidden="true" />
            {PIXEL_COPY.rigPosed}
          </figcaption>
        </figure>

        <div className="pixel-rig__data">
          <dl className="pixel-rig__facts">
            <div>
              <dt>{PIXEL_COPY.rigPlant}</dt>
              <dd>
                앞 {plantText(frame.plant?.near)} · 뒤 {plantText(frame.plant?.far)}
              </dd>
            </div>
            <div>
              <dt>{PIXEL_COPY.rigRoot}</dt>
              <dd>[{frame.root.join(", ")}]</dd>
            </div>
            <div>
              <dt>{PIXEL_COPY.rigRootCells}</dt>
              <dd>[{frame.rootCells.join(", ")}]</dd>
            </div>
            <div>
              <dt>{PIXEL_COPY.rigHeadGrid}</dt>
              <dd>[{frame.headGrid.join(", ")}]</dd>
            </div>
          </dl>
          <div className="pixel-rig__table-wrap" role="region" aria-label={PIXEL_COPY.rigTitle} tabIndex={0}>
            <table className="pixel-rig__table">
              <thead>
                <tr>
                  <th scope="col">{PIXEL_COPY.rigBone}</th>
                  <th scope="col">{PIXEL_COPY.rigParent}</th>
                  <th scope="col">{PIXEL_COPY.rigAngle}</th>
                  <th scope="col">{PIXEL_COPY.rigDelta}</th>
                </tr>
              </thead>
              <tbody>
                {rig.bones.map((bone) => {
                  const posed = pose[bone.name];
                  return (
                    <tr key={bone.name} className={posed.posed ? undefined : "is-missing"}>
                      <th scope="row">
                        {bone.ko}
                        <code>{bone.name}</code>
                      </th>
                      <td>{bone.parent ? nameKo(bone.parent) : "—"}</td>
                      <td>{fmt(posed.angle)}</td>
                      <td>{posed.posed ? fmtDelta(posed.delta) : ""}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <p className="pixel-card__meta">
            {PIXEL_COPY.extraLayers}: {rig.extraLayers.map((layer) => `${layer.ko} → ${nameKo(layer.anchor)}${layer.follow ? `(${nameKo(layer.follow.bone)} ${Math.round(layer.follow.ratio * 100)}%)` : ""}`).join(" · ")}
          </p>
        </div>
      </div>
    </section>
  );
}
