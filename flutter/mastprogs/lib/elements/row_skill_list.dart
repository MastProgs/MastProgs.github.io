import 'package:flutter/material.dart';
import 'package:mastprogs/elements/skill_box_icon.dart';
import 'package:mastprogs/elements/text_title.dart';

class RowSkillCard extends StatelessWidget {
  final String title;
  final double titleSize;
  final List<String> elemList;

  const RowSkillCard({
    super.key,
    required this.title,
    required this.titleSize,
    required this.elemList,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            border: Border.all(
              width: 2,
              color: Colors.grey.shade300,
            )),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextTitle(msg: title, size: titleSize),
            Container(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (String p in elemList) SkillBox(imgUrl: p),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
