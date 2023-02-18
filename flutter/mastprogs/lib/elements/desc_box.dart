import 'package:flutter/material.dart';
import 'package:mastprogs/elements/text_title.dart';

class DescriptionBox extends StatelessWidget {
  final String title, desc;
  final double titleSize;
  const DescriptionBox({
    Key? key,
    required this.title,
    required this.titleSize,
    required this.desc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextTitle(
            msg: title,
            size: titleSize,
            useDivider: false,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              // border: Border.all(
              //   width: 1,
              //   color: Colors.black,
              // ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(desc),
            ),
          ),
        ],
      ),
    );
  }
}
