import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/font_style.dart';

class SkillsSection extends StatelessWidget {
  final List<Skill> allSkills;
  const SkillsSection({super.key, required this.allSkills});

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
            itemCount: allSkills.length,
            itemBuilder: (context, index) {
              return _buildSkillCard(allSkills[index], context);
            },
          ),
        );
      },
    );
  }

  Widget _buildSkillCard(Skill skill, BuildContext context) {
    return GestureDetector(
      onTap: () => _showSkillDialog(context, skill),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: skill.imageAssets.map((asset) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                ElevatedButton(
                  onPressed: () {
                    // 외부 URL로 연결하는 로직 추가
                  },
                  child: const Text('Learn More'),
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

class Skill {
  final String name;
  final int proficiency;
  final String description;
  final List<String> imageAssets;

  Skill(this.name, this.proficiency, this.description, this.imageAssets);
}
