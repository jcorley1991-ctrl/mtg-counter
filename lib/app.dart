import 'package:flutter/material.dart';

import 'screens/table_screen.dart';

class MtgCounterApp extends StatelessWidget {
  const MtgCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '13 Spells Life Counter',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF101014),
          primary: Color(0xFFE2C477),
        ),
        useMaterial3: true,
      ),
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _entered = false;

  @override
  Widget build(BuildContext context) {
    if (_entered) return const TableScreen();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _entered = true),
        child: SizedBox.expand(
          child: Image.asset(
            'assets/branding/startup.jpg',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
