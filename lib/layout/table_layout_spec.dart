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
          SeatSpec(rect: Rect.fromLTWH(0.008, 0.008, 0.984, 0.478), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.008, 0.514, 0.984, 0.478), quarterTurns: 0),
        ];
      case 3:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.008, 0.008, 0.984, 0.425), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.008, 0.447, 0.484, 0.545), quarterTurns: 0),
          SeatSpec(rect: Rect.fromLTWH(0.508, 0.447, 0.484, 0.545), quarterTurns: 0),
        ];
      case 4:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.008, 0.008, 0.484, 0.482), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.508, 0.008, 0.484, 0.482), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.008, 0.510, 0.484, 0.482), quarterTurns: 0),
          SeatSpec(rect: Rect.fromLTWH(0.508, 0.510, 0.484, 0.482), quarterTurns: 0),
        ];
      case 5:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.008, 0.008, 0.484, 0.310), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.508, 0.008, 0.484, 0.310), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.008, 0.330, 0.452, 0.354), quarterTurns: 3),
          SeatSpec(rect: Rect.fromLTWH(0.540, 0.330, 0.452, 0.354), quarterTurns: 1),
          SeatSpec(rect: Rect.fromLTWH(0.105, 0.696, 0.790, 0.296), quarterTurns: 0),
        ];
      case 6:
        return const [
          SeatSpec(rect: Rect.fromLTWH(0.100, 0.006, 0.800, 0.224), quarterTurns: 2),
          SeatSpec(rect: Rect.fromLTWH(0.006, 0.238, 0.444, 0.252), quarterTurns: 3),
          SeatSpec(rect: Rect.fromLTWH(0.550, 0.238, 0.444, 0.252), quarterTurns: 1),
          SeatSpec(rect: Rect.fromLTWH(0.006, 0.500, 0.444, 0.252), quarterTurns: 3),
          SeatSpec(rect: Rect.fromLTWH(0.550, 0.500, 0.444, 0.252), quarterTurns: 1),
          SeatSpec(rect: Rect.fromLTWH(0.100, 0.762, 0.800, 0.230), quarterTurns: 0),
        ];
      default:
        throw ArgumentError.value(count, 'count', 'Supported range is 2–6');
    }
  }
}
