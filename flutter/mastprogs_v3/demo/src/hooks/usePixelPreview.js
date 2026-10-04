import { useCallback, useEffect, useLayoutEffect, useMemo, useReducer, useRef, useState } from "react";
import { ONION_DEFAULT_OPACITY, PIXEL_PRESETS } from "../content/pixelStudio.js";
import { debugWarn } from "../lib/debug.js";
import { trimOwnedTimings } from "../lib/devTimings.js";
import { prefersReducedMotion } from "../lib/motion.js";
import { createLruCache } from "../pixel/cache.js";
import { compositeFrame, indicesToRgba, isolateLayer, toggleLayer, visibilityKey } from "../pixel/layers.js";
import { buildPaletteMap, extractPalette, hexToRgb, paletteKey } from "../pixel/palette.js";
import { colorShares } from "../pixel/paletteSets.js";
import { processFrame } from "../pixel/pipeline.js";
import { createShuffleBag, showcaseFor } from "../pixel/playback.js";
import { frameRig } from "../pixel/rig.js";
import { INITIAL_STYLE, effectiveOutlineColor, planTick, resolvePaletteSet, styleReducer } from "../pixel/studio.js";
import { ONION_TINT, composeOver, guideCoordinates, isLooping, onionNeighbors, recenterByBounds, stepFrame, tintPixels } from "../pixel/timeline.js";
import { useTheme } from "../theme/ThemeContext.jsx";

const FRAME_CACHE_LIMIT = 96;
const MAP_CACHE_LIMIT = 12;
const NEAREST_CACHE_LIMIT = 10;
const NEAREST_ENTRY_LIMIT = 4096;
const PRESET_IDS = PIXEL_PRESETS.map((preset) => preset.id);
// 개발 모드 타이밍 항목 상한을 확인할 주기(프레임 수)와 이 화면이 소유한 컴포넌트 이름.
const TIMING_CHECK_EVERY = 64;
export const STUDIO_TIMING_COMPONENTS = Object.freeze(["PixelStudioPreview", "PixelCanvas", "LayerTimeline", "StudioInspector", "PaletteSetRow", "RigPanel", "Switch", "GuideMarks"]);

const putImage = (canvas, image) => {
  const context = canvas?.getContext("2d");
  if (context && image) context.putImageData(new ImageData(image.data, image.width, image.height), 0, 0);
};

// AI-NOTE: Hero Pixel Studio 미리보기의 상태·타이머·프레임 가공을 한곳에서 맡는다(화면은 PixelStudioPreview 와 cases/pixel/*).
// - 원본 레이어 셀(src/content/pixel-layers.json)을 원본 규칙으로 합성해 그린다. PNG 를 다시 읽지 않는다(네트워크·저장 없음).
//   원본 GIF·첫 PNG 는 비교용 <img> 로만 쓰며 어떤 가공도 하지 않는다.
// - 재생 상태 playback({ motion, frame, loop, turn }) 하나가 유일한 프레임 커서다. 큰 캔버스·어니언·선택 레이어·중심 비교·
//   타임라인·골격 수치가 모두 이 값에서 나온다. 프레임을 직접 고르면(칸·이전/다음·슬라이더) 재생을 멈춘다.
// - 가공 프레임·대응표·최근접 표는 크기 제한 캐시에 둔다. 타이머는 setTimeout 하나뿐이고 재생 중 + 화면 안 + 탭 보임일 때만 돈다.
// - 사용자가 이 예시에 한해 명시적으로 요청한 연속 재생이다(다른 곳의 "멈추지 않는 자동 재생 금지" 규칙은 그대로).
//   동작 줄이기 설정이면 멈춘 정지 화면으로 시작하고, 재생 버튼으로만 움직인다.
// - 팔레트·외곽선·팔레트 세트를 직접 고르면 자동 연출을 멈추고 그 설정을 유지한다. 재생은 멈추지 않는다(styleReducer 는 playing 을 모른다).
//   레이어 표시·어니언·기준선은 화면 보기 설정이라 자동 연출과 무관하다.
// AI-NOTE: (장시간 재생 멈춤 수정) 큰 RGBA 배열(Uint8ClampedArray)과 이 훅의 반환 객체 전체는 절대 컴포넌트 props 로 넘기지 않는다.
// React 19.2 개발 빌드는 바뀐 props 를 3단계까지 펼쳐 프레임마다 performance measure 에 복제했고, 몇 분 뒤
// "DataCloneError … out of memory" 로 커밋이 멈췄다. 이제 가공 이미지는 이 훅 안 메모에만 있고, 작은 캔버스는
// 문자열 frameKey 가 바뀔 때 paint 효과에서 안정된 접근자(paintImage)로 읽어 그린다. 접근자가 읽는 ref 는 레이아웃 효과에서만 쓴다
// (렌더 중 ref 읽기/쓰기 없음, 모든 효과보다 먼저 같은 렌더의 이미지로 맞춰짐).
export function usePixelPreview(sprite, studio) {
  const { layers: model, colorTable, sets, motionRig } = studio;
  const { theme } = useTheme();
  const rootRef = useRef(null);
  const canvasRef = useRef(null);
  const frameCache = useMemo(() => createLruCache(FRAME_CACHE_LIMIT), []);
  const mapCache = useMemo(() => createLruCache(MAP_CACHE_LIMIT), []);
  const nearestCaches = useMemo(() => createLruCache(NEAREST_CACHE_LIMIT), []);
  // 주머니와 첫 모션은 ref 초기화 때 한 번만 만든다(StrictMode 가 state 초기화 함수를 두 번 불러도 주머니를 더 꺼내지 않게).
  const bagRef = useRef(null);
  const firstMotionRef = useRef(null);
  if (!bagRef.current) {
    bagRef.current = createShuffleBag(sprite.motions.map((motion) => motion.id));
    firstMotionRef.current = bagRef.current.next();
  }

  const [ready, setReady] = useState("loading");
  const [playing, setPlaying] = useState(() => !prefersReducedMotion());
  const [shuffleOn, setShuffleOn] = useState(true);
  const [playback, setPlayback] = useState(() => ({ motion: firstMotionRef.current, frame: 0, loop: 0, turn: 0 }));
  const [style, dispatchStyle] = useReducer(styleReducer, INITIAL_STYLE);
  const [visibility, setVisibility] = useState(() => [...model.defaultVisibility]);
  const [selectedLayer, setSelectedLayer] = useState(() => Math.max(0, model.layers.findIndex((layer) => layer.name === "sword")));
  const [isolated, setIsolated] = useState(false);
  const [onionOn, setOnionOn] = useState(true);
  const [onionOpacity, setOnionOpacity] = useState(ONION_DEFAULT_OPACITY);
  const [guidesOn, setGuidesOn] = useState(true);
  const [inView, setInView] = useState(false);
  const [pageVisible, setPageVisible] = useState(() => typeof document === "undefined" || !document.hidden);

  const { presetId, customAccent, outlineOn, outlineMode, setId, ratio } = style;
  const preset = PIXEL_PRESETS.find((item) => item.id === presetId) ?? PIXEL_PRESETS[0];
  const accent = presetId === "custom" ? customAccent : preset.accent;
  const outlineColor = effectiveOutlineColor(style, theme);
  const active = playing && inView && pageVisible;

  const motion = sprite.motionsById[playback.motion];
  const steps = model.motions[playback.motion];
  const frameIndex = steps[playback.frame];
  const loop = isLooping(playback.motion);
  const { mode: paletteMode, set } = resolvePaletteSet(sets, setId);
  const effectiveVisibility = useMemo(() => (isolated ? isolateLayer(model, selectedLayer) : visibility), [isolated, model, selectedLayer, visibility]);
  const visKey = visibilityKey(effectiveVisibility);
  const guides = useMemo(() => guideCoordinates(model, sprite.pad), [model, sprite.pad]);
  const imageSize = useMemo(() => ({ width: sprite.canvasWidth, height: sprite.canvasHeight }), [sprite.canvasWidth, sprite.canvasHeight]);

  // 포인트 색 무리를 찾을 원본 색 목록: 모든 프레임을 원본 표시값으로 합성한 결과(한 번).
  const sourcePalette = useMemo(
    () => extractPalette(model.frames.map((frame) => indicesToRgba(compositeFrame(model, frame.index).indices, colorTable))),
    [model, colorTable],
  );

  // 캔버스를 쓸 수 있는지 한 번 확인한다. 못 쓰면 원본 GIF 로 대신한다.
  useEffect(() => {
    const context = canvasRef.current?.getContext("2d");
    if (context) {
      setReady("ready");
    } else {
      debugWarn("pixel preview: canvas 2d context unavailable, using GIF fallback");
      setReady("fallback");
    }
    return () => {
      frameCache.clear();
      mapCache.clear();
      nearestCaches.clear();
    };
  }, [frameCache, mapCache, nearestCaches]);

  // 화면 안에 있을 때만 재생(IntersectionObserver), 탭이 가려지면 멈춤.
  useEffect(() => {
    const node = rootRef.current;
    if (!node || typeof IntersectionObserver !== "function") {
      setInView(true);
      return undefined;
    }
    const observer = new IntersectionObserver(([entry]) => setInView(entry.isIntersecting), { threshold: 0.2 });
    observer.observe(node);
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    const handle = () => setPageVisible(!document.hidden);
    document.addEventListener("visibilitychange", handle);
    return () => document.removeEventListener("visibilitychange", handle);
  }, []);

  // 타이머가 오래된 커서로 전환하지 않도록, 마지막으로 커밋된 커서를 효과에서만 기록한다(렌더 중에는 읽지 않음).
  const committedPlaybackRef = useRef(playback);
  useLayoutEffect(() => {
    committedPlaybackRef.current = playback;
  }, [playback]);

  // 프레임 타이머: 원본 프레임 길이(ms) 그대로. 사이클이 끝날 때만 다음 모션으로 넘어간다.
  // 주머니 꺼냄은 상태 갱신 함수 밖(planTick)에서 한 번만 하고, 갱신 함수는 순수하다(StrictMode 이중 호출에도 같은 결과).
  useEffect(() => {
    if (!active) return undefined;
    const snapshot = playback;
    const timer = window.setTimeout(() => {
      const update = planTick({
        snapshot,
        latest: committedPlaybackRef.current,
        motionsById: sprite.motionsById,
        hold: !shuffleOn,
        draw: () => bagRef.current.next(),
      });
      if (update) setPlayback(update);
    }, sprite.motionsById[snapshot.motion].frames[snapshot.frame].ms);
    return () => window.clearTimeout(timer);
  }, [active, playback, shuffleOn, sprite]);

  // 자동 연출: 새 차례마다 프리셋·외곽선 켬/끔을 바꾼다. 사람이 직접 고른 뒤에는 하지 않는다(styleReducer 가 무시).
  useEffect(() => {
    if (style.touched || playback.turn === 0) return;
    const next = showcaseFor(playback.turn, PRESET_IDS);
    dispatchStyle({ type: "showcase", presetId: next.presetId, outline: next.outline });
  }, [playback.turn, style.touched]);

  // 개발 모드 전용: 이 화면이 소유한 컴포넌트의 React 타이밍 항목만 상한 안으로(lib/devTimings.js).
  const tickCount = useRef(0);
  useEffect(() => {
    if (!import.meta.env?.DEV || typeof performance === "undefined") return;
    tickCount.current += 1;
    if (tickCount.current % TIMING_CHECK_EVERY === 0) trimOwnedTimings(performance, STUDIO_TIMING_COMPONENTS);
  }, [playback]);

  // 같은 설정이면 캐시에서 다시 쓴다. 대응표·최근접 표도 크기 제한 캐시.
  const pKey = paletteKey(accent);
  const outlineKey = outlineOn && hexToRgb(outlineColor) ? outlineColor : "none";
  const setKey = set ? set.id : "source";
  const ratioValue = ratio / 100;
  const styleKey = `${pKey}|${outlineKey}|${setKey}|${set ? ratio : "-"}`;
  const render = useCallback(
    (index, vis, vKey) => {
      const key = `${index}|${vKey}|${styleKey}`;
      let image = frameCache.get(key);
      if (image) return image;
      let accentMap = mapCache.get(pKey);
      if (!accentMap) {
        accentMap = buildPaletteMap(sourcePalette, accent);
        mapCache.set(pKey, accentMap);
      }
      let nearestCache = null;
      if (set) {
        nearestCache = nearestCaches.get(set.id);
        if (!nearestCache || nearestCache.size > NEAREST_ENTRY_LIMIT) {
          nearestCache = new Map();
          nearestCaches.set(set.id, nearestCache);
        }
      }
      image = processFrame({
        model,
        table: colorTable,
        frameIndex: index,
        visibility: vis,
        pad: sprite.pad,
        accentMap,
        outlineRgb: outlineKey === "none" ? null : hexToRgb(outlineKey),
        set,
        ratio: set ? ratioValue : 0,
        nearestCache: nearestCache ?? undefined,
      });
      frameCache.set(key, image);
      return image;
    },
    [styleKey, pKey, outlineKey, set, ratioValue, accent, sourcePalette, model, colorTable, sprite.pad, frameCache, mapCache, nearestCaches],
  );

  // ── 큰 RGBA 배열: 이 아래 메모들은 훅 안에만 머문다(반환하지 않음) ──
  const current = useMemo(() => render(frameIndex, effectiveVisibility, visKey), [render, frameIndex, effectiveVisibility, visKey]);
  const neighbors = useMemo(() => onionNeighbors(steps.length, playback.frame, loop), [steps.length, playback.frame, loop]);
  const stage = useMemo(() => {
    if (!onionOn) return current;
    const ghost = (step, tint) => (step === null ? null : tintPixels(render(steps[step], effectiveVisibility, visKey).data, tint, onionOpacity));
    const data = composeOver([ghost(neighbors.prev, ONION_TINT.prev), ghost(neighbors.next, ONION_TINT.next), current.data], current.data.length);
    return { ...current, data };
  }, [onionOn, current, render, steps, neighbors, effectiveVisibility, visKey, onionOpacity]);

  const layerView = useMemo(() => {
    const vis = isolateLayer(model, selectedLayer);
    return render(frameIndex, vis, visibilityKey(vis));
  }, [model, selectedLayer, render, frameIndex]);

  const centering = useMemo(() => recenterByBounds(current.data, current.width, current.height, guides), [current, guides]);
  const centered = useMemo(() => ({ data: centering.data, width: current.width, height: current.height }), [centering, current]);

  // ── 화면으로 내보내는 작은 값 ──
  // 점유율은 색 수십 개의 작은 목록, 중심 이동량은 숫자 두 개다.
  const shares = useMemo(() => colorShares(current.data, set), [current, set]);
  const centerShift = useMemo(() => ({ dx: centering.dx, dy: centering.dy }), [centering.dx, centering.dy]);
  const rig = useMemo(() => frameRig(motionRig, playback.motion, playback.frame), [motionRig, playback.motion, playback.frame]);
  const frameKeys = useMemo(
    () => ({
      current: `${frameIndex}|${visKey}|${styleKey}`,
      layer: `${frameIndex}|L${selectedLayer}|${styleKey}`,
    }),
    [frameIndex, visKey, styleKey, selectedLayer],
  );

  // 작은 캔버스용 이미지 표: 레이아웃 효과에서만 갱신(모든 paint 효과보다 먼저, 같은 렌더의 값).
  const imagesRef = useRef({ current: null, layer: null, centered: null });
  useLayoutEffect(() => {
    imagesRef.current = { current, layer: layerView, centered };
  }, [current, layerView, centered]);
  // 안정된 접근자: PixelCanvas 가 frameKey 가 바뀐 효과 안에서만 부른다.
  const paintImage = useCallback((kind, canvas) => putImage(canvas, imagesRef.current[kind]), []);

  // 큰 캔버스 그리기(현재 프레임 + 아래에 깔린 어니언).
  useEffect(() => {
    if (ready !== "ready") return;
    putImage(canvasRef.current, stage);
  }, [ready, stage]);

  // 재생 상태를 바꾸는 동작은 프레임 직접 선택(멈춤)과 재생 버튼뿐이다. 색 설정 동작은 dispatchStyle 만 부른다.
  const actions = useMemo(() => {
    const pauseAt = (frame) => {
      setPlaying(false);
      setPlayback((state) => ({ ...state, frame: Math.min(model.motions[state.motion].length - 1, Math.max(0, frame)) }));
    };
    return {
      togglePlay: () => setPlaying((value) => !value),
      toggleShuffle: () => {
        // 다시 켤 때 다음 꺼냄이 지금 모션을 반복하지 않게 한다(이벤트 처리 중이라 마지막 커밋 커서를 읽어도 된다).
        if (!shuffleOn) bagRef.current.resumeFrom(committedPlaybackRef.current.motion);
        setShuffleOn(!shuffleOn);
      },
      selectMotion: (id) => {
        bagRef.current.resumeFrom(id);
        setShuffleOn(false);
        setPlayback((state) => (state.motion === id ? state : { ...state, motion: id, frame: 0, loop: 0 }));
      },
      selectPreset: (id) => dispatchStyle({ type: "preset", id }),
      setAccent: (hex) => dispatchStyle({ type: "accent", hex }),
      toggleOutline: () => dispatchStyle({ type: "toggleOutline" }),
      setOutlineColor: (hex) => dispatchStyle({ type: "outlineColor", hex }),
      setOutlineAuto: () => dispatchStyle({ type: "outlineAuto" }),
      selectSet: (id) => dispatchStyle({ type: "set", id, sets }),
      setRatio: (value) => dispatchStyle({ type: "ratio", value }),
      // 프레임 직접 선택: 모두 멈춘 뒤 같은 커서를 옮긴다.
      selectFrame: pauseAt,
      stepFrame: (delta) => {
        setPlaying(false);
        setPlayback((state) => {
          const length = model.motions[state.motion].length;
          return { ...state, frame: stepFrame(length, state.frame, delta, isLooping(state.motion)) };
        });
      },
      selectCell: (layerIndex, frame) => {
        setSelectedLayer(layerIndex);
        pauseAt(frame);
      },
      selectLayer: (layerIndex) => setSelectedLayer(layerIndex),
      toggleLayer: (layerIndex) => setVisibility((value) => toggleLayer(value, layerIndex)),
      toggleIsolate: () => setIsolated((value) => !value),
      resetLayers: () => {
        setVisibility([...model.defaultVisibility]);
        setIsolated(false);
      },
      toggleOnion: () => setOnionOn((value) => !value),
      setOnionOpacity: (value) => {
        const n = Number(value);
        if (Number.isFinite(n)) setOnionOpacity(Math.min(1, Math.max(0.1, n)));
      },
      toggleGuides: () => setGuidesOn((value) => !value),
    };
  }, [model, sets, shuffleOn]);

  // AI-NOTE: 반환값에는 큰 배열이 없다. 화면은 이 객체를 통째로 자식에게 넘기지 않고 필요한 작은 값만 골라 넘긴다.
  return {
    rootRef,
    canvasRef,
    paintImage,
    frameKeys,
    imageSize,
    ready,
    playing,
    active,
    inView,
    shuffleOn,
    playback,
    motion,
    presetId,
    accent,
    customAccent,
    outlineOn,
    outlineColor,
    outlineMode,
    showcase: !style.touched,
    // 2행 팔레트 세트('원본 색상'이면 set = null)
    paletteMode,
    set,
    ratio,
    shares,
    // 작업 화면(모두 같은 커서에서 나옴)
    model,
    steps,
    frameIndex,
    loop,
    neighbors,
    visibility,
    effectiveVisibility,
    selectedLayer,
    isolated,
    onionOn,
    onionOpacity,
    guidesOn,
    guides,
    centerShift,
    rig,
    actions,
  };
}
