import 'package:flutter/material.dart';

class TextTitle extends StatelessWidget {
  final String msg;
  final double size;
  final bool useDivider;
  final Color color;
  final bool makeSpace;

  const TextTitle({
    super.key,
    required this.msg,
    required this.size,
    required this.useDivider,
    this.color = Colors.black,
    this.makeSpace = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          msg,
          style: TextStyle(
              fontFamily: 'NanumMyeongjo',
              fontSize: size,
              fontWeight: FontWeight.w600,
              color: color),
        ),
        if (useDivider == true)
          const Padding(
            padding: EdgeInsets.all(5),
            child: Divider(color: Colors.black, thickness: 1),
          ),
        if (makeSpace)
          const SizedBox(
            height: 10,
          ),
      ],
    );
  }
}
