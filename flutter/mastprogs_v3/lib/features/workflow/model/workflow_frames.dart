// /workflow 재생기의 "프레임" 도우미(React src/workflow-detail/frames.js 이식). 순수 함수만 둔다.
// AI-NOTE: 프레임 i = 단계 i-1 이 막 적용된 화면(cursor = i). 강조는 방금 바뀐 곳을 가리킨다.
// 레인의 isActive(다음에 실행될 단계)와 다르다 — 아직 실행되지 않은 이벤트를 프레임 강조로 쓰지 않는다.
// 화면 노드는 frame id 로 찾는다(문구 검색 금지). id 규칙:
//   msg:<eventId> · spec · task:<split|review|freeze>(병렬 전체 Task Planning) · master(지시 배정)
//   lane:<laneId>(Seed 준비) · stage:<laneId>:<stage> · integration:<stage> · gate(조립 병합) · direct:<step>(직접 처리 흐름 노드)
import 'workflow_scenario.dart';

// 1배 속도에서 한 프레임 머무는 시간. 한 단계에 여러 레인 변화가 겹치므로 메인보다 조금 길다.
const int detailStepMs = 1500;
const List<double> speeds = [0.5, 1, 2];
const double defaultSpeed = 1;

double normalizeSpeed(num? value) => speeds.contains(value) ? value!.toDouble() : defaultSpeed;

/// round(DETAIL_STEP_MS / speed): 0.5배 = 3000ms, 1배 = 1500ms, 2배 = 750ms.
int frameDelay(num? speed) => (detailStepMs / normalizeSpeed(speed)).round();

// 주 강조(스크롤 기준) 우선순위: 반려·QA 실패 → Master·WORK SPEC·Task Planning·Seed → 레인 진행 → 통합 → 대화.
abstract final class FrameTier {
  static const int fault = 0;
  static const int master = 1;
  static const int lane = 2;
  static const int integration = 3;
  static const int conversation = 4;
}

// task-split → task:split (TaskPlanPanel 의 같은 frame id).
String taskFrameId(String stage) => 'task:${stage.replaceFirst(RegExp(r'^task-'), '')}';

class _Target {
  const _Target(this.id, this.tier, [this.event, this.order = 0]);

  final String id;
  final int tier;
  final WorkflowEvent? event;
  final int order;
}

List<_Target> _targetsForEvent(WorkflowEvent event, bool direct) {
  if (direct) {
    return [_Target('direct:${event.step}', FrameTier.master), if (event.type == 'message') _Target('msg:${event.id}', FrameTier.conversation)];
  }
  if (event.type == 'message') {
    return [_Target('msg:${event.id}', FrameTier.conversation), if (event.decision == 'dispatch') const _Target('master', FrameTier.master)];
  }
  if (event.type == 'spec') return const [_Target('spec', FrameTier.master)];
  if (event.type == 'task') return [_Target(taskFrameId(event.stage!), FrameTier.master)];
  if (event.type == 'seed') return [_Target('lane:${event.lane}', FrameTier.master)];
  if (event.type == 'integration') {
    return [_Target('integration:${event.stage}', FrameTier.integration), if (event.stage == 'merge') const _Target('gate', FrameTier.integration)];
  }
  if (event.lane != null && event.stage != null) {
    return [_Target('stage:${event.lane}:${event.stage}', event.isFault ? FrameTier.fault : FrameTier.lane)];
  }
  return const [];
}

// cursor 의 프레임에서 바뀐 노드 전부와 주 강조 하나. 같은 등급이면 이벤트 순서(seq)대로라 항상 같은 결과다.
List<_Target> _sortedTargets(WorkflowScenario scenario, int at) {
  final direct = scenario.isDirect;
  final byId = <String, _Target>{};
  for (final (order, event) in scenario.steps[at - 1].events.indexed) {
    for (final target in _targetsForEvent(event, direct)) {
      final found = byId[target.id];
      if (found == null || target.tier < found.tier) {
        byId[target.id] = _Target(target.id, target.tier, event, found != null ? found.order : order);
      }
    }
  }
  final list = byId.values.toList();
  // 원본: [...byId.values()].sort((a, b) => a.tier - b.tier || a.order - b.order) — 같은 값은 넣은 순서(안정 정렬).
  final indexed = [for (final (index, target) in list.indexed) (index, target)];
  indexed.sort((a, b) {
    final byTier = a.$2.tier - b.$2.tier;
    if (byTier != 0) return byTier;
    final byOrder = a.$2.order - b.$2.order;
    return byOrder != 0 ? byOrder : a.$1 - b.$1;
  });
  return [for (final entry in indexed) entry.$2];
}

class FrameTargets {
  const FrameTargets({required this.frame, required this.ids, required this.primary});

  final int frame;
  final List<String> ids;
  final String? primary;

  bool has(String id) => ids.contains(id);

  Map<String, Object?> toJson() => {
    'frame': frame,
    'ids': [...ids],
    'primary': primary,
  };
}

FrameTargets deriveFrameTargets(WorkflowScenario scenario, num cursor) {
  final at = scenario.clamp(cursor);
  if (at == 0) return const FrameTargets(frame: 0, ids: [], primary: null);
  final sorted = _sortedTargets(scenario, at);
  return FrameTargets(frame: at, ids: [for (final target in sorted) target.id], primary: sorted.firstOrNull?.id);
}

// 재생기의 현재 프레임 제목. 주 강조와 같은 이벤트를 설명한다(병렬 반려 프레임은 다음 재기획이 아니라 그 반려).
String frameTitle(WorkflowScenario scenario, num cursor) {
  final at = scenario.clamp(cursor);
  final event = at == 0 ? null : _sortedTargets(scenario, at).firstOrNull?.event;
  return event != null ? scenario.describeEvent(event) : scenario.describeStep(at);
}

// 따라가기 스크롤 양(px, 음수 = 위로). 노드가 고정 재생 막대 아래 보이는 영역에 이미 다 있으면 null(움직이지 않음).
// 노드가 보이는 영역보다 크면 윗변을 막대 바로 아래에 맞춘다.
double? followScrollDelta({required double top, required double bottom, required double safeTop, required double viewportHeight, double margin = 16}) {
  final visibleTop = safeTop + margin;
  final visibleBottom = viewportHeight - margin;
  if (top >= visibleTop && bottom <= visibleBottom) return null;
  if (top < visibleTop || bottom - top > visibleBottom - visibleTop) return (top - visibleTop).roundToDouble();
  return (bottom - visibleBottom).roundToDouble();
}
