import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/element/gradient_painter.dart';
import 'package:mastprogs_v2/common/font_style.dart';
import 'package:mastprogs_v2/common/provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SkillsSection extends StatefulWidget {
  final List<Skill> allSkills;

  const SkillsSection({super.key, required this.allSkills});

  @override
  State<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection>
    with SingleTickerProviderStateMixin {
  List<bool> _isHovering = [];
  late AnimationController _controller;
  Offset? _mousePosition;

  @override
  void initState() {
    super.initState();
    _isHovering = List<bool>.filled(widget.allSkills.length, false);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(); // 애니메이션을 계속 반복
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth > 700) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 500) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: constraints.maxHeight,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1, // 비율 조정
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: widget.allSkills.length,
            itemBuilder: (context, index) {
              return _buildSkillCard(
                  widget.allSkills[index], context, index); // 인덱스 전달
            },
          ),
        );
      },
    );
  }

  Widget _buildSkillCard(Skill skill, BuildContext context, int index) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (event) {
        setState(() {
          _isHovering[index] = true;
          _mousePosition = event.localPosition;
        });
      },
      onHover: (event) {
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering[index] = false;
          _mousePosition = null;
        });
      },
      child: GestureDetector(
        onTap: () => _showSkillDialog(context, skill),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: GradientPainter(
                        isHovering: _isHovering[index],
                        mousePosition: _mousePosition,
                        animation: _controller,
                        isDarkMode: isDarkMode,
                      ),
                      child: const SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: skill.imageAssets.map((asset) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Image.asset(
                                  asset,
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            skill.name,
                            style: FontStyleNotoSans.getStyle(
                              context: context,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStarRating(skill.proficiency),
                              const SizedBox(width: 8),
                              Text(
                                _getProficiencyText(skill.proficiency),
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              skill.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: FontStyleNotoSans.getStyle(
                                context: context,
                                fontSize: 14,
                                lightColor: Colors.grey.shade600,
                                darkColor: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSkillDialog(BuildContext context, Skill skill) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(skill.name),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 600), // 최대 가로 폭 설정
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill.description),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, // 버튼 사이의 간격
                  runSpacing: 8, // 버튼 사이의 간격
                  children: skill.links.map((link) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.0), // 버튼 사이에 간격 추가
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                        ),
                        onPressed: () {
                          // 외부 URL로 연결하는 로직 추가
                          launchUrl(Uri.parse(link.url));
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // 버튼 크기를 내용에 맞게 조정
                          children: [
                            Icon(link.icon),
                            const SizedBox(width: 8),
                            Text(link.text),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStarRating(int proficiency) {
    return Row(
      children: List.generate(3, (index) {
        return Icon(
          index < proficiency ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  String _getProficiencyText(int proficiency) {
    switch (proficiency) {
      case 1:
        return '활용가능';
      case 2:
        return '익숙함';
      case 3:
        return '능숙함';
      default:
        return '';
    }
  }
}

class Link {
  final String url;
  final String text;
  IconData icon;

  Link({required this.url, required this.text, this.icon = Icons.link});
}

class Skill {
  final String name;
  final int proficiency;
  final String description;
  final List<String> imageAssets;
  List<Link> links; // Link 클래스를 사용

  Skill({
    required this.name,
    required this.proficiency,
    required this.description,
    required this.imageAssets,
    this.links = const [], // 기본값을 빈 리스트로 설정
  });
}
