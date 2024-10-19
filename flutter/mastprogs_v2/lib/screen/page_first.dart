import 'package:flutter/material.dart';
import 'package:mastprogs_v2/screen/body/page_company.dart';
import 'package:mastprogs_v2/screen/body/page_introduce.dart';
import 'package:mastprogs_v2/screen/body/page_project.dart';
import 'package:mastprogs_v2/screen/body/page_work.dart';
import 'package:mastprogs_v2/screen/sub/app_bar.dart';
import 'package:mastprogs_v2/screen/sub/menu_list.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  int _selectedIndex = 0;
  final List<int> _pageHistory = [0];

  final List<Widget> _pages = [
    const WorkScreen(),
    const IntroduceScreen(),
    const CompanyScreen(),
    const ProjectScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _pageHistory.add(index);
        _selectedIndex = index;
      });
    }
  }

  void _handlePopInvokedWithResult(bool didPop, dynamic result) {
    if (didPop) return;

    if (_pageHistory.length > 1) {
      setState(() {
        _pageHistory.removeLast();
        _selectedIndex = _pageHistory.last;
      });
    } else {
      // 앱 종료 로직
      //SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePopInvokedWithResult,
      child: Scaffold(
        appBar: const FrontAppBar(),
        drawer: buildDrawer(context, _selectedIndex, _onItemTapped),
        body: _pages[_selectedIndex],
      ),
    );
  }
}
