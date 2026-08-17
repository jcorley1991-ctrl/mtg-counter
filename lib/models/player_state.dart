import 'package:flutter/material.dart';

@immutable
class PlayerState {
  const PlayerState({
    required this.id,
    required this.name,
    required this.life,
    required this.startingLife,
    required this.poison,
    required this.commanderDamageSummary,
    required this.accent,
    this.commanderName = 'Commander',
    this.partnerCommanderName = '',
    this.commanderImageUrl = '',
    this.partnerImageUrl = '',
    this.backgroundImageUrl = '',
    this.commanderCasts = 0,
    this.partnerCommanderCasts = 0,
    this.counters = const <String, int>{},
    this.tokens = const <String, int>{},
    this.cityBlessing = false,
  });

  final String id;
  final String name;
  final int life;
  final int startingLife;
  final int poison;
  final int commanderDamageSummary;
  final Color accent;
  final String commanderName;
  final String partnerCommanderName;
  final String commanderImageUrl;
  final String partnerImageUrl;
  final String backgroundImageUrl;
  final int commanderCasts;
  final int partnerCommanderCasts;
  final Map<String, int> counters;
  final Map<String, int> tokens;
  final bool cityBlessing;

  int get commanderTax => commanderCasts * 2;
  int get partnerCommanderTax => partnerCommanderCasts * 2;

  PlayerState copyWith({
    String? id,
    String? name,
    int? life,
    int? startingLife,
    int? poison,
    int? commanderDamageSummary,
    Color? accent,
    String? commanderName,
    String? partnerCommanderName,
    String? commanderImageUrl,
    String? partnerImageUrl,
    String? backgroundImageUrl,
    int? commanderCasts,
    int? partnerCommanderCasts,
    Map<String, int>? counters,
    Map<String, int>? tokens,
    bool? cityBlessing,
  }) {
    return PlayerState(
      id: id ?? this.id,
      name: name ?? this.name,
      life: life ?? this.life,
      startingLife: startingLife ?? this.startingLife,
      poison: poison ?? this.poison,
      commanderDamageSummary:
          commanderDamageSummary ?? this.commanderDamageSummary,
      accent: accent ?? this.accent,
      commanderName: commanderName ?? this.commanderName,
      partnerCommanderName:
          partnerCommanderName ?? this.partnerCommanderName,
      commanderImageUrl: commanderImageUrl ?? this.commanderImageUrl,
      partnerImageUrl: partnerImageUrl ?? this.partnerImageUrl,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      commanderCasts: commanderCasts ?? this.commanderCasts,
      partnerCommanderCasts:
          partnerCommanderCasts ?? this.partnerCommanderCasts,
      counters: counters ?? this.counters,
      tokens: tokens ?? this.tokens,
      cityBlessing: cityBlessing ?? this.cityBlessing,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'life': life,
        'startingLife': startingLife,
        'poison': poison,
        'commanderDamageSummary': commanderDamageSummary,
        'accent': accent.toARGB32(),
        'commanderName': commanderName,
        'partnerCommanderName': partnerCommanderName,
        'commanderImageUrl': commanderImageUrl,
        'partnerImageUrl': partnerImageUrl,
        'backgroundImageUrl': backgroundImageUrl,
        'commanderCasts': commanderCasts,
        'partnerCommanderCasts': partnerCommanderCasts,
        'counters': counters,
        'tokens': tokens,
        'cityBlessing': cityBlessing,
      };

  factory PlayerState.fromJson(Map<String, Object?> json) {
    Map<String, int> readIntMap(Object? value) {
      if (value is! Map) return <String, int>{};
      return value.map<String, int>(
        (key, item) => MapEntry(key.toString(), (item as num?)?.toInt() ?? 0),
      );
    }

    return PlayerState(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Player',
      life: (json['life'] as num?)?.toInt() ?? 40,
      startingLife: (json['startingLife'] as num?)?.toInt() ?? 40,
      poison: (json['poison'] as num?)?.toInt() ?? 0,
      commanderDamageSummary:
          (json['commanderDamageSummary'] as num?)?.toInt() ?? 0,
      accent: Color((json['accent'] as num?)?.toInt() ?? 0xFF4CB7FF),
      commanderName: json['commanderName'] as String? ?? 'Commander',
      partnerCommanderName: json['partnerCommanderName'] as String? ?? '',
      commanderImageUrl: json['commanderImageUrl'] as String? ?? '',
      partnerImageUrl: json['partnerImageUrl'] as String? ?? '',
      backgroundImageUrl: json['backgroundImageUrl'] as String? ?? '',
      commanderCasts: (json['commanderCasts'] as num?)?.toInt() ?? 0,
      partnerCommanderCasts:
          (json['partnerCommanderCasts'] as num?)?.toInt() ?? 0,
      counters: readIntMap(json['counters']),
      tokens: readIntMap(json['tokens']),
      cityBlessing: json['cityBlessing'] as bool? ?? false,
    );
  }
}
