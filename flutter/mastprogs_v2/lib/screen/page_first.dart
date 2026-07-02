import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mastprogs_v2/service/resume_pdf_service.dart';
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
  static const ResumePdfService _resumePdfService = ResumePdfService();

  int _selectedIndex = 0;
  bool _isExportingPdf = false;
  final List<int> _pageHistory = [0];

  final List<Widget> _pages = [
    const IntroduceScreen(),
    const CompanyScreen(),
    const WorkScreen(),
    ProjectScreen(),
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

  Future<void> _exportResumePdf() async {
    if (_isExportingPdf) {
      return;
    }

    setState(() {
      _isExportingPdf = true;
    });

    try {
      await _resumePdfService.exportResumePdf();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('PDF export failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF 출력 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isExportingPdf ? null : _exportResumePdf,
          icon: _isExportingPdf
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf),
          label: Text(_isExportingPdf ? 'PDF 생성 중' : 'PDF로 출력하기'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
