// 테스트용 수동 타이머: 컨트롤러가 건 타이머의 길이·취소를 기록하고, 테스트가 직접 실행한다.
import 'dart:async';

class FakeTimer implements Timer {
  FakeTimer(this.duration, this._callback);

  final Duration duration;
  final void Function() _callback;
  bool _active = true;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;

  @override
  void cancel() => _active = false;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }
}

class FakeTimers {
  final List<FakeTimer> created = [];

  Timer call(Duration duration, void Function() callback) {
    final timer = FakeTimer(duration, callback);
    created.add(timer);
    return timer;
  }

  Iterable<FakeTimer> get active => created.where((timer) => timer.isActive);

  /// 지금 걸려 있는 타이머 하나(없거나 둘 이상이면 실패).
  FakeTimer get single {
    final list = active.toList();
    if (list.length != 1) throw StateError('expected one active timer, found ${list.length}');
    return list.single;
  }

  void fireActive() => single.fire();
}
