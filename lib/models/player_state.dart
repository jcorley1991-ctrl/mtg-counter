import 'package:flutter/material.dart';

@immutable
class PlayerState {
  const PlayerState({
    required this.id,
    required this.name,
    required this.life,
    required this.poison,
    required this.commanderDamageSummary,
    required this.accent,
  });

  final String id;
  final String name;
  final int life;
  final int poison;
  final int commanderDamageSummary;
  final Color accent;

  PlayerState copyWith({
    String? id,
    String? name,
    int? life,
    int? poison,
    int? commanderDamageSummary,
    Color? accent,
  }) {
    return PlayerState(
      id: id ?? this.id,
      name: name ?? this.name,
      life: life ?? this.life,
      poison: poison ?? this.poison,
      commanderDamageSummary:
          commanderDamageSummary ?? this.commanderDamageSummary,
      accent: accent ?? this.accent,
    );
  }
}
