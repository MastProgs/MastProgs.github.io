// /workflow 상세 페이지(React WorkflowDetailPage.jsx + WorkflowPlayer.jsx + useFrameFollow 이식).
// AI-NOTE: 독립 병렬이 기본 화면이다. 경로 선택(직접 처리 / 순차 / 독립 병렬)은 재생기 안에 한 번만 있고, 세 경로가 같은 음악 재생기형 프레임 조작을 쓴다.
// 순서: 경로 선택·옵션 → 고정 재생기 → 사람↔Master 대화 → (직접 처리) 직접 처리 흐름 | (순차·병렬) WORK SPEC·(병렬) Task Planning·Seed·레인 보드·
// 병합 게이트·통합 → 기록 예시. 경로·옵션을 바꾸면 리듀서가 cursor·기록·선택을 처음으로 돌리고 타이머가 정리된다.
// 재생기는 CSS position: sticky 처럼 실행 판(.wfd-run) 안에서만 위 8px(모바일 4px)에 붙는다(하나의 위젯이 그대로 붙어 키보드 포커스가 유지된다).
// 현재 프레임 따라가기: 주 강조 노드가 고정 재생기 아래 보이는 영역 밖에 있을 때만 그 위치로 옮긴다(이미 보이면 움직이지 않음).
// 첫 렌더·처음으로·경로/옵션 변경에서는 움직이지 않고, 포커스는 건드리지 않는다. 자동 재생 중 사람이 휠·터치로 읽기 시작하면
// 다음 수동 조작(이전·다음·위치·재생)까지 자동 재생 따라가기를 멈춘다. 따라가기를 껐다 켜면 일시정지 중이어도 바로 옮긴다.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../content/content_repository.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/measure_size.dart';
import '../../../widgets/page_frame.dart';
import '../../../widgets/pressable.dart';
import '../controller/workflow_player_controller.dart';
import '../model/workflow_frames.dart';
import 'detail_transport.dart';
import 'frame_scope.dart';
import 'lane_board.dart';
import 'route_controls.dart';
import 'workflow_panels.dart';

class WorkflowPage extends StatefulWidget {
  const WorkflowPage({super.key});

  @override
  State<WorkflowPage> createState() => _WorkflowPageState();
}

class _WorkflowPageState extends State<WorkflowPage> {
  late final Future<WorkflowPageData> _data = AppServices.of(context).content.workflow();

  @override
  Widget build(BuildContext context) => FutureBuilder<WorkflowPageData>(
    future: _data,
    builder: (context, snapshot) => snapshot.hasData ? WorkflowDetailView(data: snapshot.data!) : const SizedBox.expand(),
  );
}

class WorkflowDetailView extends StatefulWidget {
  const WorkflowDetailView({super.key, required this.data});

  final WorkflowPageData data;

  @override
  State<WorkflowDetailView> createState() => _WorkflowDetailViewState();
}

const Set<String> _frameActions = {'tick', 'next', 'prev', 'seek'};
const Set<String> _manualActions = {'next', 'prev', 'seek', 'play'};

class _WorkflowDetailViewState extends State<WorkflowDetailView> {
  late final WorkflowPlayerController _controller = WorkflowPlayerController(content: widget.data.content, pageHidden: PageVisibility.notifierOf(context));
  final ScrollController _scroll = ScrollController();
  final FrameKeys _frameKeys = FrameKeys();
  final GlobalKey _runKey = GlobalKey(debugLabel: 'wfd-run');
  final ValueNotifier<double> _barShift = ValueNotifier(0);
  double _headHeight = 0;
  double _barHeight = 0;

  // 따라가기 상태(useFrameFollow).
  bool _suspended = false;
  bool _wasEnabled = true;
  int? _lastCursor;
  String? _lastAction;
  String? _lastPrimary;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateSticky);
    _controller.addListener(_onPlayerChange);
    _lastCursor = _controller.state.cursor;
    _lastAction = _controller.state.lastAction;
    _lastPrimary = _controller.frame.targets.primary;
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerChange);
    _controller.dispose();
    _scroll.dispose();
    _barShift.dispose();
    super.dispose();
  }

  void _onPlayerChange() {
    final state = _controller.state;
    final primary = _controller.frame.targets.primary;
    final enabled = _controller.follow;
    final cursorOrActionChanged = state.cursor != _lastCursor || state.lastAction != _lastAction;
    if (cursorOrActionChanged && _manualActions.contains(state.lastAction)) _suspended = false;
    final reenabled = enabled && !_wasEnabled;
    final changed = cursorOrActionChanged || primary != _lastPrimary || enabled != _wasEnabled;
    _wasEnabled = enabled;
    _lastCursor = state.cursor;
    _lastAction = state.lastAction;
    _lastPrimary = primary;
    if (!changed) return;
    if (reenabled) _suspended = false;
    if (!enabled || primary == null) return;
    if (!reenabled && !_frameActions.contains(state.lastAction)) return;
    if (!reenabled && state.lastAction == 'tick' && _suspended) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow(primary));
  }

  void _follow(String primary) {
    if (!mounted || !_scroll.hasClients) return;
    final node = _frameKeys.contextOf(primary)?.findRenderObject() as RenderBox?;
    if (node == null || !node.attached || !node.hasSize) return;
    final top = node.localToGlobal(Offset.zero).dy;
    final delta = followScrollDelta(
      top: top,
      bottom: top + node.size.height,
      // 강조 노드는 모두 재생기보다 아래에 있으므로 스크롤 뒤 재생기가 위에 붙는다. 그 높이만큼을 가려지는 영역으로 본다.
      safeTop: _barHeight,
      viewportHeight: MediaQuery.sizeOf(context).height,
    );
    if (delta == null) return;
    final position = _scroll.position;
    final target = (position.pixels + delta).clamp(position.minScrollExtent, position.maxScrollExtent);
    if (ReducedMotion.read(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: const Duration(milliseconds: 420), curve: Curves.easeInOut);
    }
  }

  void _suspend() => _suspended = true;

  // CSS sticky: 재생기 자연 위치가 화면 위(top 8/4px)보다 올라가면 그만큼 아래로 옮기되 실행 판 아래 끝을 넘지 않는다.
  void _updateSticky() {
    final run = _runKey.currentContext?.findRenderObject() as RenderBox?;
    if (run == null || !run.attached || !run.hasSize) return;
    final stickTop = ScreenMetrics.of(context).mobile ? 4.0 : 8.0;
    final runTop = run.localToGlobal(Offset.zero).dy;
    final natural = runTop + _headHeight + 16;
    final maxShift = run.size.height - _headHeight - 16 - _barHeight;
    final shift = (stickTop - natural).clamp(0.0, maxShift < 0 ? 0.0 : maxShift);
    if (shift != _barShift.value) _barShift.value = shift;
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.data.content;
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSticky());
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) _suspend();
      },
      child: NotificationListener<ScrollStartNotification>(
        onNotification: (notification) {
          if (notification.dragDetails != null) _suspend();
          return false;
        },
        child: Scrollbar(
          controller: _scroll,
          child: SingleChildScrollView(
            controller: _scroll,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShellWidth(child: DetailTopBar(backLabel: content.copy['backLabel']!)),
                  ShellWidth(
                    child: DetailIntro(eyebrow: content.copy['eyebrow']!, title: content.copy['title']!, paragraphs: content.intro),
                  ),
                  const SizedBox(height: 20),
                  ShellWidth(
                    child: ListenableBuilder(listenable: _controller, builder: (context, _) => _buildRun(context)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRun(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final content = widget.data.content;
    final controller = _controller;
    final frame = controller.frame;
    final scenario = controller.scenario;
    final barOutset = metrics.mobile ? 6.0 : 8.0;

    final head = MeasureSize(
      onChange: (size) {
        _headHeight = size.height;
        _updateSticky();
      },
      child: Padding(
        padding: EdgeInsets.only(top: metrics.mobile ? 14 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RouteRow(value: scenario.options.route, hint: content.copy['routeHint']!, onChanged: controller.setRoute),
            ScenarioOptionsView(content: content, options: scenario.options, onChanged: controller.setOption),
          ],
        ),
      ),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        head,
        const SizedBox(height: 16),
        SizedBox(height: _barHeight),
        const SizedBox(height: 16),
        ConversationPanel(content: content, messages: frame.messages),
        const SizedBox(height: 16),
        if (scenario.isDirect)
          DirectPanel(content: content, nodes: frame.direct)
        else
          LaneBoard(content: content, frame: frame, showSeed: scenario.options.seed),
        const SizedBox(height: 16),
        RecordsExplorer(
          content: content,
          records: frame.records,
          changes: frame.changes,
          selectedPath: controller.state.selectedPath,
          onSelect: controller.selectFile,
          onFollow: controller.followFiles,
        ),
        ScreenReaderOnly(controller.announcement, liveRegion: true),
      ],
    );

    return FocusRingColor(
      color: palette.orangeDeep,
      child: FrameScope(
        targets: frame.targets,
        keys: _frameKeys,
        child: Container(
          padding: metrics.mobile ? const EdgeInsets.fromLTRB(12, 0, 12, 18) : const EdgeInsets.fromLTRB(24, 0, 24, 26),
          decoration: BoxDecoration(color: palette.stage, borderRadius: BorderRadius.circular(22)),
          child: Stack(
            key: _runKey,
            clipBehavior: Clip.none,
            children: [
              body,
              ValueListenableBuilder<double>(
                valueListenable: _barShift,
                builder: (context, shift, child) => Positioned(top: _headHeight + 16 + shift, left: -barOutset, right: -barOutset, child: child!),
                child: MeasureSize(
                  onChange: (size) {
                    if (size.height == _barHeight) return;
                    setState(() => _barHeight = size.height);
                  },
                  child: DetailTransport(controller: controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
