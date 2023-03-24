import 'package:flutter/material.dart';
import 'package:mastprogs/elements/text_title.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivateProject extends StatelessWidget {
  const PrivateProject({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: 1000,
          child: Column(
            children: [
              const SizedBox(height: 50),
              BigButton(
                headTitle: '분류 모델 AI 차트 분석',
                headSize: 64,
                headTitleColor: Colors.white,
                backColor: Colors.amber,
                icon: Icons.book,
                iconColor: Colors.purple.shade900,
                iconSize: 102,
                url:
                    'http://ggram.ipdisk.co.kr:80/dl/93a3b6d36baf60b15236875e27d4301a/63f1b2b7/657465726e616c3b706c61796578706f/tBHKe7Cvei0A1zqgXvsi0hfjH0Bgkim/%EC%A1%B8%EC%97%85_%EB%B0%9C%ED%91%9C%EC%9E%90%EB%A3%8C.pdf',
              ),
              const SizedBox(height: 20),
              BigButton(
                headTitle: '애니메이션 추천 시스템',
                headSize: 64,
                headTitleColor: Colors.white,
                backColor: Colors.deepOrange.shade900,
                icon: Icons.recommend,
                iconColor: Colors.lightGreen,
                iconSize: 102,
                url: 'https://naver.me/51YeJXCy',
              ),
              const SizedBox(height: 20),
              Container(
                width: 1000,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
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
                child: Image.asset(
                  'assets/images/auto_trading.png',
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              const SizedBox(height: 20),
              BigButton(
                headTitle: '자동 트레이딩 시스템',
                headSize: 64,
                headTitleColor: Colors.white,
                backColor: Colors.blue.shade900,
                icon: Icons.equalizer_rounded,
                iconColor: Colors.cyan,
                iconSize: 102,
                url: 'https://naver.me/GKoLX1eX',
              ),
              const SizedBox(height: 20),
              BigButton(
                headTitle: '쿠팡 파트너스 자동 포스팅',
                headSize: 64,
                headTitleColor: Colors.white,
                backColor: Colors.green.shade900,
                icon: Icons.edit,
                iconColor: Colors.lime,
                iconSize: 102,
                url: 'https://naver.me/Fx40a9ii',
              ),
              const SizedBox(height: 500),
            ],
          ),
        ),
      ),
    );
  }
}

class BigButton extends StatelessWidget {
  final String headTitle, url;
  final Color headTitleColor, backColor, iconColor;
  final double headSize, iconSize;
  final IconData icon;

  const BigButton({
    super.key,
    required this.headTitle,
    required this.headSize,
    required this.headTitleColor,
    required this.backColor,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.url,
  });

  void _GoUrl(String url) async {
    var uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _GoUrl(url);
      },
      child: Container(
        width: 1000,
        height: 300,
        decoration: BoxDecoration(
          color: backColor,
          borderRadius: const BorderRadius.all(Radius.circular(15)),
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
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextTitle(
                msg: headTitle,
                size: headSize,
                useDivider: false,
                color: headTitleColor,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
