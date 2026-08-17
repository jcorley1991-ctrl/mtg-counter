import 'package:flutter/material.dart';

import 'screens/table_screen.dart';

class MtgCounterApp extends StatelessWidget {
  const MtgCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MTG Counter',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF101014),
          primary: Color(0xFFE2C477),
        ),
        useMaterial3: true,
      ),
      home: const TableScreen(),
    );
  }
}
