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

            // border: Border.all(color: Colors.grey.shade500, width: 1),

            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                offset: const Offset(2, 2),
                blurRadius: 2.0,
                spreadRadius: 1,
              ),
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-2, -2),
                blurRadius: 2.0,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              imgUrl,
              height: 40,
            ),
          ),
        ),
        const SizedBox(
          width: 12,
        ),
      ],
    );
  }
}
