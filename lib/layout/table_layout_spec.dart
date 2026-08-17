import 'package:flutter/widgets.dart';

@immutable
class SeatSpec {
  const SeatSpec({required this.rect, required this.quarterTurns});

  final Rect rect;
  final int quarterTurns;
}

class TableLayoutSpec {
  static List<SeatSpec> forPlayerCount(int count) {
    switch (count) {
      case 2:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.02, 0.03, 0.96, 0.43), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.02, 0.54, 0.96, 0.43), quarterTurns: 0),
        ];
      case 3:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.02, 0.03, 0.96, 0.38), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.02, 0.49, 0.47, 0.48), quarterTurns: 0),
          SeatSpec(rect: Rect.fromLTWH(0.51, 0.49, 0.47, 0.48), quarterTurns: 0),
        ];
      case 4:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.02, 0.03, 0.47, 0.44), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.51, 0.03, 0.47, 0.44), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.02, 0.53, 0.47, 0.44), quarterTurns: 0),
          SeatSpec(rect: Rect.fromLTWH(0.51, 0.53, 0.47, 0.44), quarterTurns: 0),
        ];
      case 5:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.13, 0.02, 0.36, 0.29), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.51, 0.02, 0.36, 0.29), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.02, 0.33, 0.35, 0.34), quarterTurns: 3),
          SeatSpec(rect: Rect.fromLTWH(0.63, 0.33, 0.35, 0.34), quarterTurns: 1),
          SeatSpec(rect: Rect.fromLTWH(0.20, 0.69, 0.60, 0.29), quarterTurns: 0),
        ];
      case 6:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.16, 0.015, 0.68, 0.215), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.015, 0.235, 0.385, 0.255), quarterTurns: 3),
          SeatSpec(rect: Rect.fromLTWH(0.600, 0.235, 0.385, 0.255), quarterTurns: 1),
          SeatSpec(rect: Rect.fromLTWH(0.015, 0.505, 0.385, 0.255), quarterTurns: 3),
          SeatSpec(rect: Rect.fromLTWH(0.600, 0.505, 0.385, 0.255), quarterTurns: 1),
          SeatSpec(rect: Rect.fromLTWH(0.16, 0.775, 0.68, 0.215), quarterTurns: 0),
        ];
      default:
        throw ArgumentError.value(count, 'count', 'Supported range is 2–6');
    }
  }
}
