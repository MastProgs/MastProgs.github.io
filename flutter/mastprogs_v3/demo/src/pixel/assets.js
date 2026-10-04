// 원본 용사(v8, 파란 머리) 프레임 메타데이터. public/pixel/hero 의 GIF·PNG 는 원본 그대로이며 새로 만들지 않는다.
// AI-NOTE: 네트워크 API 로 받지 않고 번들에 import 한다(개인정보 검사가 fetch 를 금지). 이미지는 <img>/Image 로만 읽는다.
// 레이어·팔레트 세트·골격 JSON 은 원본 v8 프로젝트에서 뽑은 작은 데이터다(64 해상도 레이어 셀, PALETTE_DEFS, 내장 팔레트 10종,
// hero-side.skeleton.json, engine-motion rot_world). 화면은 이 데이터를 그대로 합성·표시한다.
import meta from "../content/pixel-assets.json";
import layersJson from "../content/pixel-layers.json";
import motionRigJson from "../content/pixel-motion-rig.json";
import paletteSetsJson from "../content/pixel-palette-sets.json";
import rigJson from "../content/pixel-rig.json";
import sourceColors from "../content/pixel-source-colors.json";
import { buildLayerModel, sourceColorTable } from "./layers.js";
import { buildPaletteSets } from "./paletteSets.js";
import { buildRig } from "./rig.js";
import { buildSpriteModel } from "./sprite.js";

export const HERO_SPRITE = buildSpriteModel(meta);
export const HERO_LAYERS = buildLayerModel(layersJson);
export const HERO_COLOR_TABLE = sourceColorTable(sourceColors);
export const PALETTE_SETS = buildPaletteSets(paletteSetsJson);
export const HERO_RIG = buildRig(rigJson);
export const HERO_MOTION_RIG = motionRigJson;
