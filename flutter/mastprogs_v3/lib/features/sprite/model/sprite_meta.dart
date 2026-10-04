// 용사 스프라이트 메타데이터 정리(React src/pixel/sprite.js 이식, 순수 함수). 입력은 assets/data/pixel-assets.json 하나뿐이다.
// AI-NOTE: 원본 프레임은 모두 같은 84×89 공통 캔버스·같은 기준점(pivotX, soleRow)을 쓴다. 여기서는 위치를 다시 계산하지 않고
// 외곽선 여백(pad)만큼 모든 프레임을 똑같이 옮긴 화면 기하만 만든다(프레임별 재정렬·흔들림 없음).
// 메인 SpriteBrief 도 이 가벼운 모델만 쓴다(레이어·팔레트·골격 데이터를 읽지 않음).
// 원본 경로(/pixel/hero/...)는 Flutter 자산 키(assets/media/pixel/hero/...)로 바꿔 쓴다(파일 바이트는 원본 그대로, core/public_assets.dart 사용).
import '../../../core/json.dart';
import 'pixel_outline.dart';

const Map<String, String> motionLabel = {'walk': '걷기', 'run': '달리기', 'attack': '공격'};

class SpriteFrameMeta {
  const SpriteFrameMeta({required this.src, required this.ms});

  /// 원본 웹 경로(예: /pixel/hero/frames/walk-00.png).
  final String src;
  final int ms;
}

class SpriteMotion {
  const SpriteMotion({required this.id, required this.label, required this.gif, required this.frames});

  final String id;
  final String label;
  final String gif;
  final List<SpriteFrameMeta> frames;
}

class SpriteMeta {
  const SpriteMeta({required this.width, required this.height, required this.pad, required this.pivotX, required this.soleRow, required this.motions});

  factory SpriteMeta.fromJson(Json meta, {int pad = outlinePad}) {
    final motions = [
      for (final motion in meta.objs('motions'))
        SpriteMotion(
          id: motion.str('id'),
          label: motionLabel[motion.str('id')] ?? motion.str('id'),
          gif: motion.str('gif'),
          frames: [for (final frame in motion.objs('frames')) SpriteFrameMeta(src: frame.str('src'), ms: frame.integer('ms'))],
        ),
    ];
    return SpriteMeta(
      width: meta.integer('width'),
      height: meta.integer('height'),
      pad: pad,
      pivotX: meta.integer('pivotX') + pad,
      soleRow: meta.integer('soleRow') + pad,
      motions: List.unmodifiable(motions),
    );
  }

  final int width;
  final int height;
  final int pad;

  /// 여백을 더한 공통 캔버스 기준.
  final int pivotX;
  final int soleRow;
  final List<SpriteMotion> motions;

  int get canvasWidth => width + pad * 2;
  int get canvasHeight => height + pad * 2;
  int get frameCount => motions.fold(0, (sum, motion) => sum + motion.frames.length);

  SpriteMotion motion(String id) => motions.firstWhere((motion) => motion.id == id);

  /// 모션별 프레임 길이(ms) 표(재생 타이머가 그대로 쓴다).
  Map<String, List<int>> get frameMs => {
    for (final motion in motions) motion.id: [for (final frame in motion.frames) frame.ms],
  };
}
