import 'package:flutter/material.dart';
import 'package:mastprogs/elements/skill_box_icon.dart';
import 'package:mastprogs/elements/text_title.dart';

class RowSkillCard extends StatelessWidget {
  final String title;
  final double titleSize;
  final List<String> elemList;
  final List<String> descList;

  const RowSkillCard({
    super.key,
    required this.title,
    required this.titleSize,
    required this.elemList,
    required this.descList,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            border: Border.all(
              width: 2,
              color: Colors.grey.shade300,
            )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              TextTitle(msg: title, size: titleSize, useDivider: false),
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      for (String p in elemList) SkillBox(imgUrl: p),
                    ],
                  ),
                ),
              ),
              Container(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (String p in descList)
                        Column(
                          children: [Text(p), const SizedBox(height: 10)],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
