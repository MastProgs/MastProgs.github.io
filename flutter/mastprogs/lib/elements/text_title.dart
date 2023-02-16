import 'package:flutter/material.dart';

class TextTitle extends StatelessWidget {
  final String msg;
  final double size;

  const TextTitle({super.key, required this.msg, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msg,
            style: TextStyle(
              fontFamily: 'NanumMyeongjo',
              fontSize: size,
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(
            decoration: const BoxDecoration(color: Colors.black),
            child: const SizedBox(
              height: 10,
            ),
          )
        ],
      ),
    );
  }
}
