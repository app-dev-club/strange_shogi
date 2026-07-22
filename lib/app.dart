import 'package:flutter/material.dart';

import 'screens/game_flow_screen.dart';

class StrangeShogiApp extends StatelessWidget {
  const StrangeShogiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff7c3925),
      brightness: Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ヘンな将棋',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff8f1e5),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      home: const GameFlowScreen(),
    );
  }
}
