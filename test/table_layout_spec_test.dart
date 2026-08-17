import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_counter_app/layout/table_layout_spec.dart';

void main() {
  test('supports exactly 2 through 6 players', () {
    for (var count = 2; count <= 6; count++) {
      expect(TableLayoutSpec.forPlayerCount(count), hasLength(count));
    }
  });

  test('every normalized seat remains inside the screen bounds', () {
    for (var count = 2; count <= 6; count++) {
      for (final seat in TableLayoutSpec.forPlayerCount(count)) {
        expect(seat.rect.left, greaterThanOrEqualTo(0));
        expect(seat.rect.top, greaterThanOrEqualTo(0));
        expect(seat.rect.right, lessThanOrEqualTo(1));
        expect(seat.rect.bottom, lessThanOrEqualTo(1));
      }
    }
  });
}
