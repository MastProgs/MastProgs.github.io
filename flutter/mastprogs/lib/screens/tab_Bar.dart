import 'package:flutter/material.dart';

class TopTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 탭의 수
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Tab Bar'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tab 1'),
              Tab(text: 'Tab 2'),
              Tab(text: 'Tab 3'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(
              child: Text('This is Tab 1'),
            ),
            Center(
              child: Text('This is Tab 2'),
            ),
            Center(
              child: Text('This is Tab 3'),
            ),
          ],
        ),
      ),
    );
  }
}
