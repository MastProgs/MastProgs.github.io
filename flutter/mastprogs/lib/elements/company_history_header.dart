import 'package:flutter/cupertino.dart';
import 'package:mastprogs/elements/text_title.dart';

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
              fit: BoxFit.cover,
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
