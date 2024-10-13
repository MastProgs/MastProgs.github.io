import 'package:flutter/material.dart';

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
          child: const Text('Drawer Header'),
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
