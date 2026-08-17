import 'package:flutter/foundation.dart';

@immutable
class CommanderDamage {
  const CommanderDamage({
    required this.sourcePlayerId,
    required this.sourceCommanderId,
    required this.targetPlayerId,
    required this.damage,
  });

  final String sourcePlayerId;
  final String sourceCommanderId;
  final String targetPlayerId;
  final int damage;
}
