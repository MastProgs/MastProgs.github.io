// 02 학력·역량(React SkillsSection.jsx)과 04 회사 경력(CareerSection.jsx).
// AI-NOTE: 숙련도 막대·별점·백분율 같은 자기 평가 수치는 쓰지 않는다. 이력서의 "활용 가능 기술" 분류를 그대로 옮긴다.
// 회사 경력은 최신순 세로 색인이며 회사·기간·역할·업무를 모두 펼쳐 둔다(접기 없음). 기간이 겹치는 항목도 원문 그대로다.
// 경력 연결선 기하(사용자 지시): 점은 각 행 가로선 한가운데, 세로선은 가로선 중심에서 다음 가로선 중심까지(첫 점 위·마지막 점 아래 없음).
// 모두 같은 토큰(점 11, 선 1)에서 계산한다(글자 위치로 눈대중하지 않음). 진행 중인 항목만 주황 점이다.
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/layout.dart';
import '../../../app/theme/palette.dart';
import '../../../app/theme/typography.dart';
import '../../../widgets/controls.dart';
import '../../../widgets/k_text.dart';
import '../../../widgets/reveal.dart';
import '../portfolio_content.dart';
import 'portfolio_scope.dart';
import 'portfolio_widgets.dart';

class SkillsSection extends StatelessWidget {
  const SkillsSection({super.key, required this.site, required this.resume});

  final SiteContent site;
  final ResumeContent resume;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final scope = PortfolioScope.of(context);
    final skills = resume.skills;
    final education = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlockTitle(skills['educationHeading']!),
        for (final (i, item) in resume.education.indexed)
          StaggerReveal(
            index: i,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(PhosphorIconsRegular.graduationCap, size: 20, color: palette.ink3),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 76,
                    child: Text(
                      item.date,
                      style: textStyle(size: 15, weight: FontWeight.w600, color: palette.ink2, height: 22 / 15, tabular: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KText(
                          item.school,
                          style: textStyle(size: 16, weight: FontWeight.w600, color: palette.ink, height: 22 / 16, em: -0.02),
                        ),
                        const SizedBox(height: 2),
                        KText('${item.major} · ${item.degree}', style: textStyle(size: 14.5, color: palette.ink2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    final stack = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlockTitle(skills['skillsHeading']!),
        for (final (i, group) in resume.skillGroups.indexed)
          StaggerReveal(
            index: i,
            child: _SkillRow(group: group, stacked: metrics.mobile),
          ),
      ],
    );
    return RevealOnce(
      enabled: scope.revealEnabled,
      animateSelf: false,
      child: ResumeSection(
        anchorId: site.section('skills'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHead(
              title: SectionTitle(index: skills['index']!, title: skills['heading']!),
            ),
            const SizedBox(height: 28),
            if (metrics.atMost(Breakpoints.desktop))
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [education, const SizedBox(height: 36), stack])
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: education),
                  const SizedBox(width: 56),
                  Expanded(flex: 7, child: stack),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SkillRow extends StatefulWidget {
  const _SkillRow({required this.group, required this.stacked});

  final SkillGroup group;
  final bool stacked;

  @override
  State<_SkillRow> createState() => _SkillRowState();
}

class _SkillRowState extends State<_SkillRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = AnimatedDefaultTextStyle(
      duration: motionDuration(context, Motion.fast),
      style: textStyle(size: 14.5, weight: FontWeight.w600, color: _hover ? palette.ink : palette.ink2, height: 28 / 14.5),
      child: KText(widget.group.label),
    );
    final chips = Wrap(spacing: 6, runSpacing: 6, children: [for (final item in widget.group.items) TagChip(item, lineHeight: 20)]);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.line)),
        ),
        child: widget.stacked
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [label, const SizedBox(height: 4), chips])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 112, child: label),
                  const SizedBox(width: 12),
                  Expanded(child: chips),
                ],
              ),
      ),
    );
  }
}

class CareerSection extends StatelessWidget {
  const CareerSection({super.key, required this.site, required this.resume});

  final SiteContent site;
  final ResumeContent resume;

  @override
  Widget build(BuildContext context) {
    final scope = PortfolioScope.of(context);
    final career = resume.career;
    final entries = resume.careerEntries;
    return RevealOnce(
      enabled: scope.revealEnabled,
      animateSelf: false,
      child: ResumeSection(
        anchorId: site.section('career'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHead(
              title: SectionTitle(index: career['index']!, title: career['heading']!),
              lede: career['lede'],
            ),
            const SizedBox(height: 28),
            for (final (i, entry) in entries.indexed)
              StaggerReveal(
                index: i,
                delay: const Duration(milliseconds: 60),
                child: _CareerItem(resume: resume, entry: entry, last: i == entries.length - 1),
              ),
          ],
        ),
      ),
    );
  }
}

class _CareerItem extends StatefulWidget {
  const _CareerItem({required this.resume, required this.entry, required this.last});

  final ResumeContent resume;
  final CareerEntry entry;
  final bool last;

  @override
  State<_CareerItem> createState() => _CareerItemState();
}

class _CareerItemState extends State<_CareerItem> {
  bool _hover = false;

  static const double _dot = 11;
  static const double _rule = 1;
  static const double _line = 1;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final metrics = ScreenMetrics.of(context);
    final entry = widget.entry;
    final current = entry.isCurrent;
    final indent = metrics.mobile ? 28.0 : 36.0;
    final duration = motionDuration(context, Motion.fast);

    final period = Semantics(
      label: '${entry.start} 부터 ${entry.end ?? widget.resume.presentLabel}${current ? ', ${widget.resume.career['currentBadge']}' : ''}',
      excludeSemantics: true,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AnimatedDefaultTextStyle(
            duration: duration,
            style: textStyle(size: 15, weight: FontWeight.w600, color: _hover ? palette.ink : palette.ink2, height: 22 / 15, tabular: true),
            child: Text('${entry.start} – ${entry.end ?? widget.resume.presentLabel}'),
          ),
          if (current)
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: palette.orange),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.resume.career['currentBadge']!,
                style: textStyle(size: 12, weight: FontWeight.w600, color: palette.orangeText),
              ),
            ),
        ],
      ),
    );
    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          headingLevel: 3,
          child: KText(
            entry.company,
            style: textStyle(size: 22, weight: FontWeight.w700, em: -0.03, color: palette.ink, height: 1.2),
          ),
        ),
        const SizedBox(height: 6),
        KText(
          entry.role,
          style: textStyle(size: 15, weight: FontWeight.w500, color: palette.ink),
        ),
        if (entry.note.isNotEmpty) ...[const SizedBox(height: 4), KText(entry.note, style: textStyle(size: 14, color: palette.ink3))],
      ],
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final duty in entry.duties)
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -14,
                  top: 15 * 0.8,
                  child: Container(width: 5, height: 1, color: palette.ink3),
                ),
                KText(duty, style: textStyle(size: 15, color: palette.ink2, height: 1.7)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Semantics(
          label: '${entry.company} 관련 기술·영역',
          container: true,
          child: Wrap(spacing: 6, runSpacing: 6, children: [for (final tag in entry.tags) TagChip(tag)]),
        ),
      ],
    );

    final Widget grid;
    if (metrics.mobile) {
      grid = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [period, const SizedBox(height: 8), head, const SizedBox(height: 12), body]);
    } else if (metrics.atMost(Breakpoints.desktop)) {
      grid = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 180, child: period),
              const SizedBox(width: 32),
              Expanded(child: head),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 212),
              Expanded(child: body),
            ],
          ),
        ],
      );
    } else {
      grid = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 196, child: period),
          const SizedBox(width: 32),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: SizedBox(width: 300, child: head),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(child: body),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(indent, 26, 0, 26),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: palette.line, width: _rule),
              ),
            ),
            child: grid,
          ),
          // 세로선: 자기 가로선 중심에서 다음 가로선 중심까지(마지막 행 없음).
          if (!widget.last)
            Positioned(
              top: _rule / 2,
              bottom: -_rule / 2,
              left: (_dot - _line) / 2,
              child: Container(width: _line, color: palette.tileLine),
            ),
          // 점: 가로선 중심에 맞춘다(top = 선 중심 − 점/2).
          Positioned(
            top: _rule / 2 - _dot / 2,
            left: 0,
            child: AnimatedContainer(
              duration: duration,
              width: _dot,
              height: _dot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: current ? palette.orange : palette.bg,
                // 원본 CSS 순서상 가리킴(ink)이 진행 중(주황) 테두리보다 뒤에 있어 가리키면 모두 ink 테두리다.
                border: Border.all(color: _hover ? palette.ink : (current ? palette.orange : palette.line4), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
