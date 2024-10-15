import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/provider.dart';
import 'package:mastprogs_v2/screen/page_first.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider(context)),
        // 필요한 만큼 프로바이더를 추가할 수 있습니다
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: '서버 프로그래머 김형준',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            fontFamily: 'NotoSans',
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            fontFamily: 'NotoSans',
          ),
          themeMode: themeProvider.themeMode,
          home: const FirstPage(),
        );
      },
    );
  }
}
