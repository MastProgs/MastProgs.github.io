import 'package:flutter/material.dart';

class SkillBox extends StatelessWidget {
  final String imgUrl;

  const SkillBox({
    required this.imgUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade500,
                offset: const Offset(2, 2),
                blurRadius: 5.0,
                spreadRadius: 1,
              ),
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-2, -2),
                blurRadius: 5.0,
                spreadRadius: 1,
              ),
            ],
          ),
          width: 75,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              imgUrl,
              height: 61,
            ),
          ),
        ),
        const SizedBox(
          width: 25,
        ),
      ],
    );
  }
}
