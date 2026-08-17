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
          SeatSpec(rect: Rect.fromLTWH(0.004, 0.004, 0.992, 0.486), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.004, 0.510, 0.992, 0.486), quarterTurns: 0),
        ];
      case 3:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.004, 0.004, 0.992, 0.432), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.004, 0.448, 0.490, 0.548), quarterTurns: 0),
          SeatSpec(rect: Rect.fromLTWH(0.506, 0.448, 0.490, 0.548), quarterTurns: 0),
        ];
      case 4:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.004, 0.004, 0.490, 0.490), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.506, 0.004, 0.490, 0.490), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.004, 0.506, 0.490, 0.490), quarterTurns: 0),
          SeatSpec(rect: Rect.fromLTWH(0.506, 0.506, 0.490, 0.490), quarterTurns: 0),
        ];
      case 5:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.004, 0.004, 0.490, 0.316), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.506, 0.004, 0.490, 0.316), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.004, 0.332, 0.474, 0.352), quarterTurns: 3),
          SeatSpec(rect: Rect.fromLTWH(0.522, 0.332, 0.474, 0.352), quarterTurns: 1),
          SeatSpec(rect: Rect.fromLTWH(0.050, 0.696, 0.900, 0.300), quarterTurns: 0),
        ];
      case 6:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.020, 0.004, 0.960, 0.230), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.004, 0.244, 0.482, 0.246), quarterTurns: 1),
          SeatSpec(rect: Rect.fromLTWH(0.514, 0.244, 0.482, 0.246), quarterTurns: 3),
          SeatSpec(rect: Rect.fromLTWH(0.004, 0.502, 0.482, 0.246), quarterTurns: 1),
          SeatSpec(rect: Rect.fromLTWH(0.514, 0.502, 0.482, 0.246), quarterTurns: 3),
          SeatSpec(rect: Rect.fromLTWH(0.020, 0.758, 0.960, 0.238), quarterTurns: 0),
        ];
      default:
        throw ArgumentError.value(count, 'count', 'Supported range is 2–6');
    }
  }
}
