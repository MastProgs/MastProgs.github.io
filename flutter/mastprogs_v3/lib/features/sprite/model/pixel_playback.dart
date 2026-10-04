// 모션 재생 순서 도우미(React src/pixel/playback.js 이식, 순수 함수).
// AI-NOTE: 걷기·달리기·공격을 "섞은 주머니(shuffle bag)"에서 하나씩 꺼낸다. 한 주머니에 세 모션이 모두 한 번씩 들어 있어
// 모두 나오고, 주머니가 바뀌는 경계에서도 같은 모션이 연달아 나오지 않게 첫 항목을 바꾼다. 모션 전환은 항상 한 사이클이
// 끝난 뒤(마지막 프레임 다음)에만 일어난다 — 중간 프레임에서 끊지 않는다. 난수는 주입해 테스트에서 고정한다.
import 'dart:math' as math;

typedef Rng = double Function();

final math.Random _random = math.Random();

double defaultRng() => _random.nextDouble();

List<T> shuffle<T>(List<T> items, [Rng rng = defaultRng]) {
  final out = [...items];
  for (var i = out.length - 1; i > 0; i -= 1) {
    final j = (rng() * (i + 1)).floor();
    final swap = out[i];
    out[i] = out[j];
    out[j] = swap;
  }
  return out;
}

class ShuffleBag<T> {
  ShuffleBag(List<T> items, [Rng rng = defaultRng]) : _items = List.unmodifiable(items), _rng = rng {
    if (items.isEmpty) throw StateError('empty bag');
  }

  final List<T> _items;
  final Rng _rng;
  List<T> _bag = [];
  T? _last;

  T next() {
    if (_bag.isEmpty) {
      _bag = shuffle(_items, _rng);
      if (_items.length > 1 && _bag.first == _last) {
        final swap = 1 + (_rng() * (_bag.length - 1)).floor();
        final first = _bag[0];
        _bag[0] = _bag[swap];
        _bag[swap] = first;
      }
    }
    final value = _bag.removeAt(0);
    _last = value;
    return value;
  }

  // 직접 고른 모션(current)에서 다시 섞기를 시작할 때: 남은 주머니를 버리고 current 를 마지막으로 삼아
  // 다음 꺼냄이 지금 모션과 겹치지 않게 한다.
  void resumeFrom(T current) {
    _bag = [];
    _last = current;
  }
}

// 모션마다 한 차례에 도는 사이클 수. 짧은 걷기·달리기는 두 번, 공격은 한 번(자연스러운 한 동작).
const Map<String, int> turnCycles = {'walk': 2, 'run': 2, 'attack': 1};

int cyclesFor(String motionId) => turnCycles[motionId] ?? 1;

/// 재생 상태 { motion, frame, loop, turn }. 큰 캔버스·어니언·타임라인·골격 수치가 모두 이 값 하나를 따른다.
class PlaybackState {
  const PlaybackState({required this.motion, required this.frame, required this.loop, required this.turn});

  final String motion;
  final int frame;
  final int loop;
  final int turn;

  PlaybackState copyWith({String? motion, int? frame, int? loop, int? turn}) =>
      PlaybackState(motion: motion ?? this.motion, frame: frame ?? this.frame, loop: loop ?? this.loop, turn: turn ?? this.turn);

  @override
  bool operator ==(Object other) => other is PlaybackState && other.motion == motion && other.frame == frame && other.loop == loop && other.turn == turn;

  @override
  int get hashCode => Object.hash(motion, frame, loop, turn);

  @override
  String toString() => 'PlaybackState($motion, frame $frame, loop $loop, turn $turn)';
}

/// 모션별 프레임 길이(ms). 원본 pixel-assets.json 의 값 그대로(균일 간격으로 바꾸지 않음).
typedef MotionFrameMs = Map<String, List<int>>;

// 재생 상태를 한 프레임 앞으로. 마지막 사이클이 끝나면 pickNext() 로 다음 모션. hold 가 참이면(무작위 섞기 끔) 같은 모션을 계속 돈다.
PlaybackState stepPlayback(PlaybackState state, MotionFrameMs motions, {required String Function() pickNext, bool hold = false}) {
  final length = motions[state.motion]!.length;
  final frame = state.frame + 1;
  if (frame < length) return state.copyWith(frame: frame);
  final loop = state.loop + 1;
  if (hold || loop < cyclesFor(state.motion)) return state.copyWith(frame: 0, loop: hold ? 0 : loop);
  return PlaybackState(motion: pickNext(), frame: 0, loop: 0, turn: state.turn + 1);
}

class Showcase {
  const Showcase({required this.presetId, required this.outline});

  final String presetId;
  final bool outline;
}

// 자동 연출(사람이 팔레트·외곽선을 직접 고르기 전까지만): 차례마다 프리셋을 돌리고 외곽선은 두 차례마다 켠다.
Showcase showcaseFor(int turn, List<String> presetIds) {
  final ids = presetIds.isNotEmpty ? presetIds : const ['original'];
  return Showcase(presetId: ids[turn % ids.length], outline: (turn ~/ 2) % 2 == 1);
}
