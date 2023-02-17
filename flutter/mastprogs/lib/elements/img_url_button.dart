import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ImgButtonUrl extends StatelessWidget {
  final String url;
  final String imgPath;
  final double imgSize;

  const ImgButtonUrl(
      {super.key,
      required this.imgPath,
      required this.url,
      required this.imgSize});

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
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
        padding: const EdgeInsets.all(10),
        child: InkWell(
          onTap: () {
            _GoUrl(url);
          },
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: Image.asset(
            imgPath,
            width: imgSize,
          ),
        ),
      ),
    );
  }
}
