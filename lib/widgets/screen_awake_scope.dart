import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ScreenAwakeScope extends StatefulWidget {
  const ScreenAwakeScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ScreenAwakeScope> createState() => _ScreenAwakeScopeState();
}

class _ScreenAwakeScopeState extends State<ScreenAwakeScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_setScreenAwake(true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(_setScreenAwake(state == AppLifecycleState.resumed));
  }

  Future<void> _setScreenAwake(bool enabled) async {
    try {
      if (enabled) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // A wake-lock failure must never interrupt the life counter itself.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_setScreenAwake(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
