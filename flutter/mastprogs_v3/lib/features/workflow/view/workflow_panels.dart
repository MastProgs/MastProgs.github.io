// /workflow 패널: 사람 ↔ Master AI 대화(ConversationPanel.jsx), 직접 처리 흐름(DirectPanel.jsx), 로컬 실행 기록(RecordsExplorer.jsx).
// AI-NOTE: 대화는 사람의 답 중 범위·권한 결정만 표시를 붙인다(단계마다 승인하는 구조가 아님). 메시지마다 msg:<이벤트 id> 프레임 id 를 단다.
// 기록은 cursor 에서 매번 파생된다(records). 처음으로 누르면 목록이 비고 선택도 풀린다. 선택하지 않았으면 마지막 단계가 만든 파일을 따라가고,
// 파일을 누르면 그 파일에 고정된다(그 파일이 있는 동안). 고정한 파일이 지금 cursor 에 없으면 최신 파일을 보인다.
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../widgets/dashed.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/pressable.dart';
import '../model/workflow_content.dart';
import '../model/workflow_records.dart';
import '../model/workflow_scenario.dart';
import 'frame_scope.dart';

/// .wfd-block__title
class BlockHeading extends StatelessWidget {
  const BlockHeading(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    // 원본 <h2 className="wfd-block__title">(대화·직접·기록).
    headingLevel: 2,
    child: KText(
      text,
      style: textStyle(size: 18, weight: FontWeight.w700, em: -0.02, color: color ?? context.palette.stageInk),
    ),
  );
}

const Map<String, String> _decisionTag = {'scope': '범위 결정', 'permission': '권한 결정'};

class ConversationPanel extends StatelessWidget {
  const ConversationPanel({super.key, required this.content, required this.messages});

  final WorkflowContent content;
  final List<ConversationMessage> messages;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final copy = content.copy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlockHeading(copy['conversationHeading']!),
          const SizedBox(height: 12),
          if (messages.isEmpty)
            KText(copy['conversationEmpty']!, style: textStyle(size: 16, color: palette.stageInk3))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, message) in messages.indexed) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _Message(key: ValueKey(message.id), content: content, message: message),
                ],
              ],
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(PhosphorIconsRegular.userFocus, size: 16, color: AppPalette.chatNoteIcon),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KText(copy['humanNote']!, style: textStyle(size: 14, color: palette.stageInk2, height: 1.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 새 메시지는 한 번만 아래에서 떠오른다(280ms, 동작 줄이기면 즉시).
class _Message extends StatelessWidget {
  const _Message({super.key, required this.content, required this.message});

  final WorkflowContent content;
  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    final master = message.actor == 'master';
    final tag = _decisionTag[message.decision];
    final avatar = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: master ? palette.stageInk : AppPalette.white),
      child: Icon(master ? PhosphorIconsRegular.robot : PhosphorIconsRegular.user, size: 18, color: master ? palette.orange : palette.stageInk),
    );
    final body = Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: master ? palette.panel : AppPalette.msgHumanBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: master ? Colors.transparent : palette.stageLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                content.actorLabel[message.actor]!,
                style: textStyle(size: 13, weight: FontWeight.w700, color: master ? palette.ink : palette.stageInk),
              ),
              Text(message.time, style: textStyle(size: 13, color: master ? palette.ink3 : palette.stageInk3, tabular: true)),
              if (tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(color: AppPalette.decisionTagBg, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.userFocus, size: 14, color: AppPalette.decisionTagInk),
                      const SizedBox(width: 4),
                      Text(
                        tag,
                        style: textStyle(size: 13, weight: FontWeight.w600, color: AppPalette.decisionTagInk),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          KText(message.text, style: textStyle(size: 15.5, height: 1.55, color: master ? palette.ink : palette.stageInk)),
        ],
      ),
    );
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: master ? TextDirection.rtl : TextDirection.ltr,
      children: [
        ExcludeSemantics(child: avatar),
        const SizedBox(width: 12),
        Flexible(child: body),
      ],
    );
    return Align(
      alignment: master ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: mobile ? double.infinity : 760),
        child: _RiseIn(
          child: FrameNode(id: 'msg:${message.id}', radius: 14, child: row),
        ),
      ),
    );
  }
}

/// 처음 그릴 때 한 번만 아래(6px)에서 떠오르는 등장(원본 wfd-rise 280ms).
class _RiseIn extends StatefulWidget {
  const _RiseIn({required this.child});

  final Widget child;

  @override
  State<_RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<_RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ReducedMotion.of(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final t = Motion.easeOut.transform(_controller.value);
      return Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child),
      );
    },
    child: widget.child,
  );
}

/// 위젯 공용 등장 효과(대화·되돌림·명세·fork 표시가 같이 쓴다).
class RiseIn extends StatelessWidget {
  const RiseIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => _RiseIn(child: child);
}

class DirectPanel extends StatelessWidget {
  const DirectPanel({super.key, required this.content, required this.nodes});

  final WorkflowContent content;
  final List<DirectNodeState> nodes;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mobile = ScreenMetrics.of(context).mobile;
    final cells = [
      for (final node in nodes)
        FrameNode(
          id: 'direct:${node.step}',
          radius: 14,
          child: Semantics(
            selected: node.isActive,
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: palette.tile,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: node.isActive ? palette.line5 : palette.tileLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    node.status == 'done'
                        ? PhosphorIconsFill.checkCircle
                        : node.isActive
                        ? PhosphorIconsBold.circleNotch
                        : PhosphorIconsBold.circleDashed,
                    size: 18,
                    color: node.status == 'done' ? palette.ink : palette.inkSoft,
                  ),
                  const SizedBox(height: 6),
                  KText(
                    node.label,
                    style: textStyle(size: 16, weight: FontWeight.w600, color: node.status == 'done' ? palette.ink : palette.inkSoft),
                  ),
                  if (node.id == 'direct') ...[
                    const SizedBox(height: 6),
                    Text(content.directWorkOwns, style: textStyle(size: 12.5, mono: true, color: node.status == 'done' ? palette.ink : palette.inkSoft)),
                  ],
                ],
              ),
            ),
          ),
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: palette.panel, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlockHeading(content.copy['directHeading']!, color: palette.ink),
          const SizedBox(height: 12),
          if (mobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, cell) in cells.indexed) ...[if (i > 0) const SizedBox(height: 10), cell],
              ],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, cell) in cells.indexed) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: cell)],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TreeRow {
  const _TreeRow.dir(this.name, this.depth) : file = null;
  const _TreeRow.file(this.name, this.depth, this.file);

  final String name;
  final int depth;
  final RecordFile? file;
}

// 경로 목록을 폴더 머리글 + 파일 행으로 펼친다. 폴더는 처음 나올 때 한 번만 넣는다.
List<_TreeRow> _toRows(List<RecordFile> files) {
  final rows = <_TreeRow>[];
  final seen = <String>{};
  for (final file in files) {
    final parts = file.path.split('/');
    for (var depth = 1; depth < parts.length; depth += 1) {
      final dir = parts.sublist(0, depth).join('/');
      if (seen.add(dir)) rows.add(_TreeRow.dir(parts[depth - 1], depth - 1));
    }
    rows.add(_TreeRow.file(parts.last, parts.length - 1, file));
  }
  return rows;
}

const Map<String, String> _changeText = {'new': '새 파일', 'updated': '갱신'};

class RecordsExplorer extends StatelessWidget {
  const RecordsExplorer({
    super.key,
    required this.content,
    required this.records,
    required this.changes,
    required this.selectedPath,
    required this.onSelect,
    required this.onFollow,
  });

  final WorkflowContent content;
  final WorkflowRecords records;
  final Map<String, String> changes;
  final String? selectedPath;
  final ValueChanged<String> onSelect;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final narrow = ScreenMetrics.of(context).atMost(Breakpoints.narrow);
    final copy = content.copy;
    final files = records.files;
    final pinned = selectedPath != null && files.any((file) => file.path == selectedPath);
    final activePath = pinned ? selectedPath : records.latestPath;
    final active = records.fileAt(activePath);

    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockHeading(copy['recordsHeading']!),
        const SizedBox(height: 4),
        KText(copy['recordsLead']!, style: textStyle(size: 14.5, color: palette.stageInk2)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(PhosphorIconsRegular.folder, size: 16, color: palette.stageInk),
            Text('${records.root}/', style: textStyle(size: 13, mono: true, color: palette.stageInk)),
            Text('파일 ${files.length}개', style: textStyle(size: 13, color: palette.stageInk3)),
          ],
        ),
      ],
    );

    if (files.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            head,
            const SizedBox(height: 12),
            DashedBox(
              color: palette.stageLine,
              radius: 14,
              padding: const EdgeInsets.all(18),
              child: KText(copy['recordsEmpty']!, style: textStyle(size: 16, color: palette.stageInk3)),
            ),
          ],
        ),
      );
    }

    final rows = _toRows(files);
    final tree = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: narrow ? 300 : 460),
      child: Semantics(
        container: true,
        label: '기록 파일',
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          children: [
            for (final row in rows)
              _TreeRowView(row: row, activePath: activePath, change: row.file == null ? null : changes[row.file!.path], onSelect: onSelect),
          ],
        ),
      ),
    );

    final viewer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: palette.line)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(active?.path ?? '', style: textStyle(size: 13, mono: true, color: palette.orangeText)),
              if (pinned)
                Pressable(
                  onPressed: onFollow,
                  semanticLabel: copy['recordsFollow'],
                  excludeChildSemantics: true,
                  radius: BorderRadius.circular(6),
                  builder: (context, state) => Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        copy['recordsFollow']!,
                        style: textStyle(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: palette.ink,
                          decoration: TextDecoration.underline,
                          decorationColor: palette.ink,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _FileContent(path: active?.path ?? '', content: active == null || active.content.isEmpty ? '(비어 있음)' : active.content),
      ],
    );

    final body = Container(
      decoration: BoxDecoration(color: palette.panel, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: palette.line)),
                  ),
                  child: tree,
                ),
                viewer,
              ],
            )
          : Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 340, child: tree),
                    Expanded(child: viewer),
                  ],
                ),
                // 목록 오른쪽 경계선은 두 칸 중 높은 쪽까지 이어진다(원본 grid 행 높이).
                Positioned(left: 339, top: 0, bottom: 0, width: 1, child: ColoredBox(color: palette.line)),
              ],
            ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [head, const SizedBox(height: 12), body]),
    );
  }
}

class _TreeRowView extends StatelessWidget {
  const _TreeRowView({required this.row, required this.activePath, required this.change, required this.onSelect});

  final _TreeRow row;
  final String? activePath;
  final String? change;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final indent = row.depth * 14.0;
    final file = row.file;
    if (file == null) {
      return ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.only(left: indent),
          child: Container(
            constraints: const BoxConstraints(minHeight: 28),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.folder, size: 15, color: palette.ink3),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('${row.name}/', style: textStyle(size: 12.5, color: palette.ink3)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final selected = file.path == activePath;
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Pressable(
        onPressed: () => onSelect(file.path),
        toggled: selected,
        semanticLabel: '${row.name} (${file.path})${change != null ? ', ${_changeText[change]}' : ''}',
        excludeChildSemantics: true,
        radius: BorderRadius.circular(8),
        builder: (context, state) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: motionDuration(context, Motion.fast),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? palette.orangeTint : (state.hovered ? palette.surface3 : Colors.transparent),
              // 선택 표시: 왼쪽 안쪽 2px 주황(box-shadow: inset 2px 0 0).
              border: selected ? Border(left: BorderSide(color: palette.orange, width: 2)) : null,
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.fileText, size: 15, color: palette.ink3),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(row.name, style: textStyle(size: 13.5, color: palette.ink)),
                ),
                if (change != null) _ChangeBadge(key: ValueKey('${file.path}-$change'), change: change!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "새 파일"/"갱신" 표시. 나타날 때 한 번 튀어 오른다(220ms, 동작 줄이기면 즉시).
class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({super.key, required this.change});

  final String change;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fresh = change == 'new';
    final badge = Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: fresh ? palette.orange : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: fresh ? null : Border.all(color: palette.line4),
      ),
      child: Text(
        _changeText[change]!,
        style: textStyle(size: 11.5, weight: FontWeight.w700, color: fresh ? palette.orangeInk : palette.ink2),
      ),
    );
    return BadgePop(child: badge);
  }
}

/// badge-pop: 투명·0.6배에서 한 번 튀어 오른다(cubic-bezier(0.3, 1.4, 0.5, 1)).
class BadgePop extends StatelessWidget {
  const BadgePop({super.key, required this.child, this.duration = const Duration(milliseconds: 220)});

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (ReducedMotion.of(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: const Cubic(0.3, 1.4, 0.5, 1),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: child,
    );
  }
}

/// 파일 내용(고정폭, 줄바꿈 유지, 자체 스크롤). 키보드로 포커스해 화살표로 스크롤할 수 있다.
class _FileContent extends StatefulWidget {
  const _FileContent({required this.path, required this.content});

  final String path;
  final String content;

  @override
  State<_FileContent> createState() => _FileContentState();
}

class _FileContentState extends State<_FileContent> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // 원본 <pre tabIndex={0} aria-label="{path} 내용">: 역할 없는 포커스 칸 + 이름·내용을 가진 읽기 노드 하나.
    return Pressable(
      plain: true,
      semanticLabel: '${widget.path} 내용',
      semanticValue: widget.content,
      excludeChildSemantics: true,
      radius: BorderRadius.zero,
      focusOffset: -2,
      builder: (context, state) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 240, maxHeight: 408),
        child: Scrollbar(
          controller: _scroll,
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: SizedBox(
              width: double.infinity,
              child: SelectableText(widget.content, style: textStyle(size: 13, mono: true, color: palette.inkHi, height: 1.6)),
            ),
          ),
        ),
      ),
    );
  }
}
