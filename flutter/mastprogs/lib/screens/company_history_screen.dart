import 'package:flutter/material.dart';

import '../elements/text_title.dart';

class CompanyHistoryScreen extends StatelessWidget {
  const CompanyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: 1000,
          child: Column(
            children: [
              const SizedBox(height: 50),
              Container(
                width: 1000,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  border: Border.all(
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
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
                child: Column(
                  children: [
                    HistoryHeader(
                      imgPath: 'assets/images/wemade.png',
                      backColor: Colors.black87.withOpacity(0.85),
                      msg: '위메이드 플러스',
                      msgColor: Colors.white,
                    ),
                    const Text('data'),
                    const Text('data'),
                    const Text('data'),
                    const Text('data'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryHeader extends StatelessWidget {
  final String imgPath, msg;
  final Color backColor, msgColor;

  const HistoryHeader({
    super.key,
    required this.imgPath,
    required this.backColor,
    required this.msg,
    required this.msgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imgPath, //'assets/images/wemade.png',
              height: 50,
              width: 50,
              fit: BoxFit.fill,
            ),
          ),
          const SizedBox(width: 15),
          Container(
            decoration: BoxDecoration(
              color: backColor, //Colors.lightGreenAccent,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            width: 890,
            height: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10),
                    TextTitle(
                      msg: msg, //'위메이드 플러스',
                      size: 25,
                      useDivider: false,
                      color: msgColor, //Colors.black,
                      makeSpace: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
