// Hero Pixel Studio 미리보기의 상태·타이머·프레임 가공(React usePixelPreview.js 이식).
// AI-NOTE: 원본 레이어 셀(pixel-layers.json)을 원본 규칙으로 합성해 그린다. PNG/GIF 는 비교용 이미지로만 쓰고 가공하지 않는다(네트워크·저장 없음).
// - 재생 상태 playback({ motion, frame, loop, turn }) 하나가 유일한 프레임 커서다. 큰 캔버스·어니언·선택 레이어·중심 비교·타임라인·골격 수치가
//   모두 이 값에서 나온다. 프레임을 직접 고르면(칸·이전/다음·슬라이더) 재생을 멈춘다.
// - 타이머는 하나뿐이고 재생 중 + 화면 안(isIntersecting) + 탭 보임 세 조건이 모두 참일 때만 돈다. 간격은 원본 프레임 길이(ms) 그대로다.
//   주머니 꺼냄은 상태 갱신 밖(planTick)에서 한 번만 하고, 오래된 타이머(그 사이 커서가 바뀐 경우)는 아무것도 하지 않는다.
// - 사용자가 이 예시에 한해 명시적으로 요청한 연속 재생이다. 동작 줄이기 설정이면 멈춘 채 시작하고 재생 버튼으로만 움직인다.
// - 팔레트·외곽선·세트·비율을 직접 고르면 자동 연출을 멈추고 그 설정을 유지한다. 재생은 멈추지 않는다(styleReducer 는 playing 을 모른다).
//   레이어 표시·어니언·기준선은 화면 보기 설정이라 자동 연출과 무관하다. 사람이 멈춘 뒤 색을 바꿔도 멈춘 상태가 유지된다.
// - 가공 프레임·대응표·최근접 표·그림(ui.Image)은 크기 제한 캐시에 둔다(96·12·10, 최근접 표 4096 항목 넘으면 새로). 버려지는 그림은 dispose 한다.
//   큰 RGBA 배열은 위젯 속성으로 넘기지 않고, 위젯은 짧은 frameKey 문자열이 바뀔 때만 이 컨트롤러에서 그림을 받아 간다.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../../content/content_repository.dart';
import '../model/lru_cache.dart';
import '../model/pixel_layers.dart';
import '../model/pixel_outline.dart';
import '../model/pixel_palette.dart';
import '../model/pixel_palette_sets.dart';
import '../model/pixel_pipeline.dart';
import '../model/pixel_playback.dart';
import '../model/pixel_rig.dart';
import '../model/pixel_studio.dart';
import '../model/pixel_studio_content.dart';
import '../model/pixel_timeline.dart';
import '../model/sprite_meta.dart';

const int frameCacheLimit = 96;
const int mapCacheLimit = 12;
const int nearestCacheLimit = 10;
const int nearestEntryLimit = 4096;
// AI-NOTE: 올린 그림(ui.Image) 캐시 한도는 "재생이 실제로 거치는 서로 다른 그림 수"로 정한다(LRU 가 순환 접근에서 적중 0 이 되지 않게).
// 예전 한도 32 는 한 스타일의 작업 묶음(그림 종류 4 × 원본 28프레임 = 112)보다 작아 프레임마다 새 CanvasKit 그림을 3~4개 만들고 지웠다
// (decodeImageFromPixels → canvaskit/image.dart skiaDecodeImageFromPixels 의 canvasKit.MakeImage: wasm 힙에 픽셀 복사 + SkImage,
// 첫 그리기 때 GPU 텍스처). Dart 쪽 핸들은 모두 dispose 되어 개수는 일정했지만(테스트로 확인) 네이티브 생성·삭제가 끝없이 이어졌고,
// 브라우저 soak 99분 뒤 CanvasKit 힙 할당(PictureRecorder·MakeImage)이 실패했다. 네이티브 쪽에 무엇이 남는지는 소스로 증명하지 못했으므로
// 재생 중 새 네이티브 그림 생성 자체를 없앤다.
// - 자동 연출 중: 연출이 한 주기에 거치는 서로 다른 스타일 수(showcaseStyleCount, 현재 테마의 자동 외곽선 색 포함) × 작업 묶음 + 여유.
// - 사람이 색을 고른 뒤(touched, 되돌아가지 않음): 한 스타일 작업 묶음 + 여유로 줄인다(넘치는 그림은 즉시 dispose).
// - 어떤 내용이어도 imageCacheHardLimit 을 넘지 않는다. 그림 한 장 = (84+2) × (89+2) × 4 = 31,304 바이트.
const int imageCacheHeadroom = 16;
const int imageCacheHardLimit = 1536;

/// 한 스타일의 재생 작업 묶음(그림 종류 × 프레임) + 여유.
int styleImageBudget(int frameCount) => math.min(imageCacheHardLimit, PixelImageKind.values.length * frameCount + imageCacheHeadroom);

/// 자동 연출 중 한도: 서로 다른 연출 스타일 × 작업 묶음 + 여유(상한 적용).
int showcaseImageBudget(int styleCount, int frameCount) =>
    math.min(imageCacheHardLimit, styleCount * PixelImageKind.values.length * frameCount + imageCacheHeadroom);

/// 자동 연출이 한 주기(프리셋 수 × 4 차례: 프리셋 = turn % 수, 외곽선 = (turn ~/ 2) % 2)에 실제로 거치는 서로 다른 그림 스타일 수.
/// 프리셋 강조색과 외곽선 색(켤 때만, 테마별 자동 색)이 같으면 같은 픽셀이므로 하나로 센다(styleKey 와 같은 기준, 세트·비율은 연출이 바꾸지 않음).
int showcaseStyleCount(PixelStudioContent content, String theme) {
  final ids = content.presetIds;
  final period = math.max(1, ids.length) * 4;
  final keys = <String>{};
  for (var turn = 0; turn < period; turn += 1) {
    final show = showcaseFor(turn, ids);
    final outline = show.outline ? autoOutlineColor(content, show.presetId, theme) : null;
    keys.add('${paletteKey(content.preset(show.presetId).accent)}|${outline != null && hexToRgb(outline) != null ? outline : 'none'}');
  }
  return keys.length;
}

/// loading → ready(원본 데이터로 다시 그림) | fallback(원본 GIF 로 대신).
enum StudioReady { loading, ready, fallback }

/// 큰 캔버스·작은 캔버스 종류.
enum PixelImageKind { stage, current, layer, centered }

typedef StudioTimerFactory = Timer Function(Duration duration, void Function() callback);

class PixelStudioController extends ChangeNotifier {
  PixelStudioController({
    required this.page,
    required String theme,
    required bool reducedMotion,
    ValueListenable<bool>? pageHidden,
    Rng rng = defaultRng,
    StudioTimerFactory? timerFactory,
  }) : _theme = theme,
       _pageHidden = pageHidden,
       _timerFactory = timerFactory ?? Timer.new,
       _playing = !reducedMotion,
       _pageVisible = !(pageHidden?.value ?? false),
       _style = StudioStyle.initial(page.content) {
    // 주머니와 첫 모션은 처음 한 번만 만든다.
    _bag = ShuffleBag([for (final motion in page.sprite.motions) motion.id], rng);
    _playback = PlaybackState(motion: _bag.next(), frame: 0, loop: 0, turn: 0);
    _pageHidden?.addListener(_onVisibility);
  }

  final SpritePageData page;
  final ValueListenable<bool>? _pageHidden;
  final StudioTimerFactory _timerFactory;
  late final ShuffleBag<String> _bag;

  SpriteStudioData? _studio;
  StudioReady _ready = StudioReady.loading;
  bool _playing;
  bool _shuffleOn = true;
  late PlaybackState _playback;
  StudioStyle _style;
  List<bool> _visibility = const [];
  int _selectedLayer = 0;
  bool _isolated = false;
  bool _onionOn = true;
  late double _onionOpacity = page.content.onionDefaultOpacity;
  bool _guidesOn = true;
  bool _inView = false;
  bool _pageVisible;
  String _theme;
  Timer? _timer;
  bool _disposed = false;

  final LruCache<String, PixelImage> _frameCache = LruCache(frameCacheLimit);
  final LruCache<String, Map<int, Rgb>> _mapCache = LruCache(mapCacheLimit);
  final LruCache<String, Map<int, Rgb>> _nearestCaches = LruCache(nearestCacheLimit);
  // 한도는 데이터를 붙일 때·테마·스타일이 바뀔 때 _applyImageBudget 이 정한다(그 전에는 쓰이지 않음).
  late final LruCache<String, ui.Image> imageCache = LruCache(imageCacheHardLimit, onEvict: (image) => image.dispose());

  /// 지금 올린 그림 캐시 한도(자동 연출 중이면 연출 전체, 사람이 고른 뒤면 한 스타일).
  int get imageBudget => imageCache.limit;

  void _applyImageBudget() {
    final studio = _studio;
    if (studio == null) return;
    final frames = studio.layers.frames.length;
    final budget = _style.touched ? styleImageBudget(frames) : showcaseImageBudget(showcaseStyleCount(page.content, _theme), frames);
    if (budget != imageCache.limit) imageCache.resize(budget);
  }

  List<PaletteEntry>? _sourcePalette;

  // ── 읽기 ────────────────────────────────────────────────
  SpriteMeta get sprite => page.sprite;
  StudioReady get ready => _ready;
  SpriteStudioData? get studio => _studio;
  bool get playing => _playing;
  bool get shuffleOn => _shuffleOn;
  PlaybackState get playback => _playback;
  StudioStyle get style => _style;
  bool get inView => _inView;
  bool get pageVisible => _pageVisible;
  bool get active => _playing && _inView && _pageVisible;
  bool get showcase => !_style.touched;
  List<bool> get visibility => _visibility;
  int get selectedLayer => _selectedLayer;
  bool get isolated => _isolated;
  bool get onionOn => _onionOn;
  double get onionOpacity => _onionOpacity;
  bool get guidesOn => _guidesOn;
  String get theme => _theme;
  bool get hasPendingTimer => _timer?.isActive ?? false;

  SpriteMotion get motion => sprite.motion(_playback.motion);
  bool get loop => isLooping(_playback.motion);
  PixelLayerModel get model => _studio!.layers;
  List<int> get steps => model.motions[_playback.motion]!;
  int get frameIndex => steps[_playback.frame];
  String? get accent => _style.presetId == 'custom' ? _style.customAccent : page.content.preset(_style.presetId).accent;
  String get outlineColor => effectiveOutlineColor(page.content, _style, _theme);
  ResolvedPaletteSet get palette => resolvePaletteSet(page.content, _studio?.sets ?? const [], _style.setId);
  List<bool> get effectiveVisibility => _isolated ? isolateLayer(model, _selectedLayer) : _visibility;
  OnionNeighbors get neighbors => onionNeighbors(steps.length, _playback.frame, loop);
  GuideCoordinates get guides => guideCoordinates(model, sprite.pad);
  FrameRigDetail? get rig => frameRig(_studio!.motionRig, _playback.motion, _playback.frame);

  // ── 데이터 준비 ─────────────────────────────────────────
  /// 원본 데이터 모델을 붙인다. 만들거나 첫 프레임을 그리지 못하면 원본 GIF 대체 화면으로 남는다.
  void attachStudio(SpriteStudioData studio) {
    if (_disposed) return;
    try {
      _studio = studio;
      _visibility = [...studio.layers.defaultVisibility];
      final sword = studio.layers.layers.indexWhere((layer) => layer.name == 'sword');
      _selectedLayer = sword < 0 ? 0 : sword;
      _render(frameIndex, effectiveVisibility, visibilityKey(effectiveVisibility));
      _applyImageBudget();
      _ready = StudioReady.ready;
    } catch (error) {
      if (kDebugMode) debugPrint('[portfolio] pixel preview: original data unavailable, using GIF fallback: $error');
      _studio = null;
      _ready = StudioReady.fallback;
    }
    notifyListeners();
  }

  void markFallback(Object error) {
    if (_disposed) return;
    if (kDebugMode) debugPrint('[portfolio] pixel preview: original data unavailable, using GIF fallback: $error');
    _ready = StudioReady.fallback;
    notifyListeners();
  }

  // ── 환경 ────────────────────────────────────────────────
  void setTheme(String theme) {
    if (theme == _theme) return;
    _theme = theme;
    _applyImageBudget();
    notifyListeners();
  }

  /// 화면 안 여부(IntersectionObserver 의 isIntersecting). 조금이라도 보이면 참, 완전히 밖이면 거짓.
  void setInView(bool value) {
    if (value == _inView) return;
    _inView = value;
    _reschedule();
    notifyListeners();
  }

  void _onVisibility() {
    final visible = !(_pageHidden?.value ?? false);
    if (visible == _pageVisible) return;
    _pageVisible = visible;
    _reschedule();
    notifyListeners();
  }

  // ── 재생 ────────────────────────────────────────────────
  void _setPlayback(PlaybackState next) {
    if (identical(next, _playback)) return;
    final previousTurn = _playback.turn;
    _playback = next;
    // 자동 연출: 새 차례마다 프리셋·외곽선 켬/끔을 바꾼다. 사람이 직접 고른 뒤에는 하지 않는다(styleReducer 가 무시).
    if (next.turn != previousTurn && next.turn != 0 && !_style.touched) {
      final show = showcaseFor(next.turn, page.content.presetIds);
      _dispatchStyle(ShowcaseStyle(presetId: show.presetId, outline: show.outline), notify: false);
    }
    _reschedule();
    notifyListeners();
  }

  // 타이머: 활성일 때 지금 프레임의 원본 길이(ms)만큼 하나만 예약한다. 상태가 바뀔 때마다 새로 건다(useEffect 의존성과 같음).
  void _reschedule() {
    _timer?.cancel();
    _timer = null;
    if (!active || _disposed) return;
    final snapshot = _playback;
    final ms = sprite.motion(snapshot.motion).frames[snapshot.frame].ms;
    _timer = _timerFactory(Duration(milliseconds: ms), () {
      _timer = null;
      final update = planTick(snapshot: snapshot, latest: _playback, motions: sprite.frameMs, hold: !_shuffleOn, draw: _bag.next);
      if (update != null) _setPlayback(update(_playback));
    });
  }

  void togglePlay() {
    _playing = !_playing;
    _reschedule();
    notifyListeners();
  }

  void toggleShuffle() {
    // 다시 켤 때 다음 꺼냄이 지금 모션을 반복하지 않게 한다.
    if (!_shuffleOn) _bag.resumeFrom(_playback.motion);
    _shuffleOn = !_shuffleOn;
    _reschedule();
    notifyListeners();
  }

  /// 모션 직접 선택: 주머니를 이 모션에서 다시 시작하고 무작위 섞기를 끈다. 다른 모션이면 프레임·loop 를 0 으로(재생 상태는 그대로).
  void selectMotion(String id) {
    _bag.resumeFrom(id);
    final shuffleChanged = _shuffleOn;
    _shuffleOn = false;
    if (_playback.motion == id) {
      if (shuffleChanged) _reschedule();
      notifyListeners();
      return;
    }
    _setPlayback(_playback.copyWith(motion: id, frame: 0, loop: 0));
  }

  void _pauseAt(int frame) {
    _playing = false;
    final length = model.motions[_playback.motion]!.length;
    _setPlayback(_playback.copyWith(frame: frame < 0 ? 0 : (frame > length - 1 ? length - 1 : frame)));
  }

  /// 프레임 직접 선택(슬라이더·번호): 멈춘 뒤 같은 커서를 옮긴다.
  void selectFrame(int frame) => _pauseAt(frame);

  /// 이전/다음 프레임: 반복 모션은 돌고 공격은 처음·끝에서 멈춘다. 멈춘다.
  void stepFrameBy(int delta) {
    _playing = false;
    final length = model.motions[_playback.motion]!.length;
    _setPlayback(_playback.copyWith(frame: stepFrame(length, _playback.frame, delta, isLooping(_playback.motion))));
  }

  void selectCell(int layerIndex, int frame) {
    _selectedLayer = layerIndex;
    _pauseAt(frame);
  }

  // ── 색 설정(재생을 건드리지 않음) ─────────────────────────
  void _dispatchStyle(StyleAction action, {bool notify = true}) {
    final next = styleReducer(page.content, _studio?.sets ?? const [], _style, action);
    if (identical(next, _style)) return;
    _style = next;
    _applyImageBudget();
    if (notify) notifyListeners();
  }

  void selectPreset(String id) => _dispatchStyle(PresetStyle(id));
  void setAccent(String hex) => _dispatchStyle(AccentStyle(hex));
  void toggleOutline() => _dispatchStyle(const ToggleOutlineStyle());
  void setOutlineColor(String hex) => _dispatchStyle(OutlineColorStyle(hex));
  void setOutlineAuto() => _dispatchStyle(const OutlineAutoStyle());
  void selectSet(String id) => _dispatchStyle(SetStyle(id));
  void setRatio(Object? value) => _dispatchStyle(RatioStyle(value));

  // ── 보기 설정 ───────────────────────────────────────────
  void selectLayer(int index) {
    if (index == _selectedLayer) return;
    _selectedLayer = index;
    notifyListeners();
  }

  void toggleLayer(int index) {
    _visibility = toggleLayerVisibility(_visibility, index);
    notifyListeners();
  }

  void toggleIsolate() {
    _isolated = !_isolated;
    notifyListeners();
  }

  void resetLayers() {
    _visibility = [...model.defaultVisibility];
    _isolated = false;
    notifyListeners();
  }

  void toggleOnion() {
    _onionOn = !_onionOn;
    notifyListeners();
  }

  /// 유효한 수만 0.1..1 로 자른다(그 밖의 입력은 무시).
  void setOnionOpacity(Object? value) {
    final n = value is num ? value.toDouble() : double.tryParse('$value');
    if (n == null || !n.isFinite) return;
    final clamped = n < 0.1 ? 0.1 : (n > 1 ? 1.0 : n);
    if (clamped == _onionOpacity) return;
    _onionOpacity = clamped;
    notifyListeners();
  }

  void toggleGuides() {
    _guidesOn = !_guidesOn;
    notifyListeners();
  }

  // ── 프레임 가공(같은 설정이면 캐시) ──────────────────────
  String get _pKey => paletteKey(accent);
  String get _outlineKey => _style.outlineOn && hexToRgb(outlineColor) != null ? outlineColor : 'none';

  String get styleKey {
    final set = palette.set;
    return '$_pKey|$_outlineKey|${set?.id ?? 'source'}|${set != null ? _style.ratio : '-'}';
  }

  List<PaletteEntry> get _palette =>
      _sourcePalette ??= extractPalette([for (final frame in model.frames) indicesToRgba(compositeFrame(model, frame.index).indices, _studio!.colorTable)]);

  PixelImage _render(int index, List<bool> vis, String vKey) {
    final key = '$index|$vKey|$styleKey';
    final cached = _frameCache.get(key);
    if (cached != null) return cached;
    final pKey = _pKey;
    var accentMap = _mapCache.get(pKey);
    if (accentMap == null) {
      accentMap = buildPaletteMap(_palette, accent);
      _mapCache.set(pKey, accentMap);
    }
    final set = palette.set;
    Map<int, Rgb>? nearest;
    if (set != null) {
      nearest = _nearestCaches.get(set.id);
      if (nearest == null || nearest.length > nearestEntryLimit) {
        nearest = <int, Rgb>{};
        _nearestCaches.set(set.id, nearest);
      }
    }
    final outlineKey = _outlineKey;
    final image = processFrame(
      model: model,
      table: _studio!.colorTable,
      frameIndex: index,
      visibility: vis,
      pad: sprite.pad,
      accentMap: accentMap,
      outlineRgb: outlineKey == 'none' ? null : hexToRgb(outlineKey),
      set: set,
      ratio: set != null ? _style.ratio / 100 : 0,
      nearestCache: nearest,
    );
    _frameCache.set(key, image);
    return image;
  }

  PixelImage get currentImage {
    final vis = effectiveVisibility;
    return _render(frameIndex, vis, visibilityKey(vis));
  }

  PixelImage get stageImage {
    final current = currentImage;
    if (!_onionOn) return current;
    final vis = effectiveVisibility;
    final vKey = visibilityKey(vis);
    final near = neighbors;
    Uint8List? ghost(int? step, Rgb tint) => step == null ? null : tintPixels(_render(steps[step], vis, vKey).data, tint, _onionOpacity);
    return PixelImage(
      data: composeOver([ghost(near.prev, onionTintPrev), ghost(near.next, onionTintNext), current.data], current.data.length),
      width: current.width,
      height: current.height,
    );
  }

  PixelImage get layerImage {
    final vis = isolateLayer(model, _selectedLayer);
    return _render(frameIndex, vis, visibilityKey(vis));
  }

  Recentered get centering => recenterByBounds(currentImage.data, currentImage.width, currentImage.height, guides);

  ColorShares get shares => colorShares(currentImage.data, palette.set);

  /// 그림 종류별 짧은 키(같으면 다시 그리지 않음).
  String frameKey(PixelImageKind kind) {
    final vis = effectiveVisibility;
    final current = '$frameIndex|${visibilityKey(vis)}|$styleKey';
    return switch (kind) {
      PixelImageKind.current => current,
      PixelImageKind.centered => '$current|c',
      PixelImageKind.layer => '$frameIndex|L$_selectedLayer|$styleKey',
      PixelImageKind.stage => _onionOn ? '$current|o${neighbors.prev}|${neighbors.next}|$_onionOpacity' : current,
    };
  }

  PixelImage imageFor(PixelImageKind kind) => switch (kind) {
    PixelImageKind.stage => stageImage,
    PixelImageKind.current => currentImage,
    PixelImageKind.layer => layerImage,
    PixelImageKind.centered => PixelImage(data: centering.data, width: currentImage.width, height: currentImage.height),
  };

  /// 캐시 크기(점검·테스트용).
  ({int frames, int maps, int nearest, int images}) get cacheSizes =>
      (frames: _frameCache.size, maps: _mapCache.size, nearest: _nearestCaches.size, images: imageCache.size);

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _pageHidden?.removeListener(_onVisibility);
    _frameCache.clear();
    _mapCache.clear();
    _nearestCaches.clear();
    imageCache.clear();
    super.dispose();
  }
}

/// 원본 toggleLayer(표시 상태 도우미)와 같은 규칙.
List<bool> toggleLayerVisibility(List<bool> visibility, int index) => toggleLayer(visibility, index);
