import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/font_style.dart';

Drawer buildDrawer(
    BuildContext context, int selectedIndex, Function(int) onIndexChanged) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Column(
            children: [
              Text(
                '서버 프로그래머',
                style: FontStyleYouandiModernTR.getStyle(
                  context: context,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '김형준',
                style: FontStyleYouandiModernTR.getStyle(
                    context: context, fontSize: 36),
              ),
            ],
          ),
        ),
        ListTile(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.person),
              SizedBox(width: 10),
              Text('자기 소개'),
            ],
          ),
          selected: selectedIndex == 0,
          onTap: () {
            Navigator.pop(context);
            onIndexChanged(0);
          },
        ),
        ListTile(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.business),
              SizedBox(width: 10),
              Text('회사 경력'),
            ],
          ),
          selected: selectedIndex == 1,
          onTap: () {
            Navigator.pop(context);
            onIndexChanged(1);
          },
        ),
        ListTile(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.handyman),
              SizedBox(width: 10),
              Text('작업 내역'),
            ],
          ),
          selected: selectedIndex == 2,
          onTap: () {
            Navigator.pop(context);
            onIndexChanged(2);
          },
        ),
        ListTile(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.polyline_sharp),
              SizedBox(width: 10),
              Text('개인 프로젝트'),
            ],
          ),
          selected: selectedIndex == 3,
          onTap: () {
            Navigator.pop(context);
            onIndexChanged(3);
          },
        ),
      ],
    ),
  );
}
