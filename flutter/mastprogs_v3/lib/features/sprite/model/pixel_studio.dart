// /sprite 작업 화면의 색 설정·재생 한 칸 전환(React src/pixel/studio.js 이식, 순수 함수).
// AI-NOTE: PixelStudioController 가 이 모듈만으로 색 설정 상태를 바꾼다. 여기 있는 어떤 전환도 재생(playing)을 건드리지 않는다:
// 사용자 지시로 팔레트·외곽선·세트·비율을 바꿔도 재생은 계속되고, 멈추는 것은 프레임 직접 선택과 재생 버튼뿐이다.
import '../../../core/js_compat.dart';
import 'pixel_palette.dart';
import 'pixel_palette_sets.dart';
import 'pixel_playback.dart';
import 'pixel_studio_content.dart';

// ── 외곽선 색 ─────────────────────────────────────────────
// mode "auto": 테마·프리셋에서 고른다(어두운 테마 = 기존 outline, 밝은 테마 = outlineLight 어두운 색).
// mode "manual": 사용자가 고른 색을 그대로 쓴다. 프리셋을 바꾸거나 테마를 바꿔도 덮지 않는다.
const List<String> outlineModes = ['auto', 'manual'];

String autoOutlineColor(PixelStudioContent content, String presetId, String theme) {
  final preset = content.preset(presetId);
  return theme == 'light' ? preset.outlineLight : preset.outline;
}

class StudioStyle {
  const StudioStyle({
    required this.presetId,
    required this.customAccent,
    required this.outlineOn,
    required this.outlineMode,
    required this.outlineManual,
    required this.setId,
    required this.ratio,
    required this.touched,
  });

  factory StudioStyle.initial(PixelStudioContent content) => StudioStyle(
    presetId: 'original',
    customAccent: null,
    outlineOn: false,
    outlineMode: 'auto',
    outlineManual: null,
    setId: content.defaultSetId,
    ratio: content.defaultPaletteRatio,
    touched: false,
  );

  final String presetId;
  final String? customAccent;
  final bool outlineOn;
  final String outlineMode;
  final String? outlineManual;
  final String setId;
  final int ratio;

  /// 사람이 색을 직접 고르면 참. 자동 연출(showcase)은 이 값이 거짓일 때만 돈다.
  final bool touched;

  StudioStyle copyWith({
    String? presetId,
    String? customAccent,
    bool? outlineOn,
    String? outlineMode,
    String? outlineManual,
    String? setId,
    int? ratio,
    bool? touched,
  }) => StudioStyle(
    presetId: presetId ?? this.presetId,
    customAccent: customAccent ?? this.customAccent,
    outlineOn: outlineOn ?? this.outlineOn,
    outlineMode: outlineMode ?? this.outlineMode,
    outlineManual: outlineManual ?? this.outlineManual,
    setId: setId ?? this.setId,
    ratio: ratio ?? this.ratio,
    touched: touched ?? this.touched,
  );
}

// 캔버스·색 입력·캐시 키가 모두 이 값 하나를 쓴다(표시된 색과 그려진 색이 어긋나지 않게).
String effectiveOutlineColor(PixelStudioContent content, StudioStyle style, String theme) {
  final manual = style.outlineManual;
  if (style.outlineMode == 'manual' && manual != null && hexToRgb(manual) != null) return manual.toLowerCase();
  return autoOutlineColor(content, style.presetId, theme);
}

class ResolvedPaletteSet {
  const ResolvedPaletteSet({required this.mode, required this.set});

  /// source | set
  final String mode;
  final PaletteSet? set;
}

// ── 팔레트 세트 ───────────────────────────────────────────
// '원본 색상'(SOURCE_SET_ID)은 매핑 단계를 건너뛴다(set = null). 알 수 없는 id 만 첫 세트로 돌아가며,
// 원본 색상을 고른 상태를 AAP-64 로 바꾸지 않는다.
ResolvedPaletteSet resolvePaletteSet(PixelStudioContent content, List<PaletteSet> sets, String setId) {
  if (setId == content.sourceSetId) return const ResolvedPaletteSet(mode: 'source', set: null);
  return ResolvedPaletteSet(mode: 'set', set: sets.where((item) => item.id == setId).firstOrNull ?? sets.first);
}

bool isKnownSetId(PixelStudioContent content, List<PaletteSet> sets, Object? id) => id == content.sourceSetId || sets.any((item) => item.id == id);

sealed class StyleAction {
  const StyleAction();
}

class PresetStyle extends StyleAction {
  const PresetStyle(this.id);

  final Object? id;
}

class AccentStyle extends StyleAction {
  const AccentStyle(this.hex);

  final Object? hex;
}

class ToggleOutlineStyle extends StyleAction {
  const ToggleOutlineStyle();
}

class OutlineColorStyle extends StyleAction {
  const OutlineColorStyle(this.hex);

  final Object? hex;
}

class OutlineAutoStyle extends StyleAction {
  const OutlineAutoStyle();
}

class SetStyle extends StyleAction {
  const SetStyle(this.id);

  final Object? id;
}

class RatioStyle extends StyleAction {
  const RatioStyle(this.value);

  final Object? value;
}

class ShowcaseStyle extends StyleAction {
  const ShowcaseStyle({required this.presetId, required this.outline});

  final String presetId;
  final bool outline;
}

/// Math.round(Number(value)) 를 0..100 으로. 유한한 수가 아니면 null.
int? _clampRatio100(Object? value) {
  final n = jsNumber(value);
  if (!n.isFinite) return null;
  final rounded = (n + 0.5).floor();
  return rounded < 0 ? 0 : (rounded > 100 ? 100 : rounded);
}

/// 유효하지 않은 입력이면 같은 객체를 그대로 돌려준다(다시 그리지 않음). 재생 필드는 결과에 절대 없다.
StudioStyle styleReducer(PixelStudioContent content, List<PaletteSet> sets, StudioStyle state, StyleAction action) {
  switch (action) {
    case PresetStyle(:final id):
      if (!content.presets.any((item) => item.id == id)) return state;
      // 외곽선이 자동이면 effectiveOutlineColor 가 새 프리셋 색을 고른다. 직접 고른 색은 그대로 둔다.
      return state.copyWith(presetId: '$id', touched: true);
    case AccentStyle(:final hex):
      if (hexToRgb(hex) == null) return state;
      return state.copyWith(customAccent: '$hex', presetId: 'custom', touched: true);
    case ToggleOutlineStyle():
      return state.copyWith(outlineOn: !state.outlineOn, touched: true);
    case OutlineColorStyle(:final hex):
      if (hexToRgb(hex) == null) return state;
      return state.copyWith(outlineMode: 'manual', outlineManual: '$hex'.toLowerCase(), outlineOn: true, touched: true);
    case OutlineAutoStyle():
      // 마지막으로 고른 색은 남겨 둔다(다시 직접 고르면 그 색에서 시작).
      return state.outlineMode == 'auto' ? state : state.copyWith(outlineMode: 'auto', touched: true);
    case SetStyle(:final id):
      if (!isKnownSetId(content, sets, id)) return state;
      return state.copyWith(setId: '$id', touched: true);
    case RatioStyle(:final value):
      final ratio = _clampRatio100(value);
      if (ratio == null) return state;
      return state.copyWith(ratio: ratio, touched: true);
    case ShowcaseStyle(:final presetId, :final outline):
      // 자동 연출: 손대기 전까지만 프리셋·외곽선 켬/끔을 돌린다. 외곽선 색은 자동 모드라 따로 정하지 않는다.
      if (state.touched) return state;
      return state.copyWith(presetId: presetId, outlineOn: outline);
  }
}

// ── 재생 한 칸 ────────────────────────────────────────────
// 이 칸에서 다음 모션을 꺼내야 하는지(마지막 사이클의 마지막 프레임 다음). 꺼냄(주머니 변경)은 이 판단 뒤 상태 갱신 "밖"에서 한 번만 한다.
bool needsNextMotion(PlaybackState state, MotionFrameMs motions, {bool hold = false}) {
  final length = motions[state.motion]!.length;
  if (state.frame + 1 < length) return false;
  return !hold && state.loop + 1 >= cyclesFor(state.motion);
}

// 순수 전환: nextMotion 은 needsNextMotion 이 참일 때 미리 꺼내 둔 값이다.
PlaybackState advancePlayback(PlaybackState state, MotionFrameMs motions, {String? nextMotion, bool hold = false}) {
  final length = motions[state.motion]!.length;
  final frame = state.frame + 1;
  if (frame < length) return state.copyWith(frame: frame);
  final loop = state.loop + 1;
  if (hold || loop < cyclesFor(state.motion)) return state.copyWith(frame: 0, loop: hold ? 0 : loop);
  if (nextMotion == null) return state.copyWith(frame: 0, loop: 0);
  return PlaybackState(motion: nextMotion, frame: 0, loop: 0, turn: state.turn + 1);
}

// 타이머 한 번의 처리: 최신 상태(latest)가 타이머를 건 때의 상태(snapshot)와 다르면 아무것도 꺼내지 않는다(오래된 타이머).
// 같으면 필요할 때만 주머니에서 한 번 꺼내고, 갱신 함수는 snapshot 과 같을 때만 전환하는 순수 함수다.
PlaybackState Function(PlaybackState state)? planTick({
  required PlaybackState snapshot,
  required PlaybackState latest,
  required MotionFrameMs motions,
  required bool hold,
  required String Function() draw,
}) {
  // 원본처럼 객체 동일성으로 비교한다(값이 같아도 새로 만든 상태면 그 사이 다른 조작이 있었던 것).
  if (!identical(latest, snapshot)) return null;
  final nextMotion = needsNextMotion(snapshot, motions, hold: hold) ? draw() : null;
  return (state) => identical(state, snapshot) ? advancePlayback(state, motions, nextMotion: nextMotion, hold: hold) : state;
}
