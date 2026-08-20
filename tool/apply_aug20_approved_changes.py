from pathlib import Path

path = Path('lib/screens/table_screen.dart')
text = path.read_text()


def replace_once(old: str, new: str, label: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: expected exactly 1 match, found {count}')
    text = text.replace(old, new, 1)


def replace_between(start: str, end: str, replacement: str, label: str) -> None:
    global text
    start_index = text.find(start)
    if start_index < 0:
        raise RuntimeError(f'{label}: start marker not found')
    end_index = text.find(end, start_index)
    if end_index < 0:
        raise RuntimeError(f'{label}: end marker not found')
    text = text[:start_index] + replacement + text[end_index:]


# MASTER TRUTH: 23 preset player colors plus a custom color picker.
replace_once(
    """  static const _accents = <Color>[\n    Color(0xFF4CB7FF),\n    Color(0xFFE75B58),\n    Color(0xFF58C989),\n    Color(0xFFE1BC63),\n    Color(0xFF9C72FF),\n    Color(0xFF53D7D0),\n    Color(0xFFEE8A3D),\n    Color(0xFFE95FA6),\n    Color(0xFFA6E65A),\n    Color(0xFF5B6EE1),\n    Color(0xFFB8C0CC),\n  ];""",
    """  static const _accents = <Color>[\n    Color(0xFF4CB7FF),\n    Color(0xFFE75B58),\n    Color(0xFF58C989),\n    Color(0xFFE1BC63),\n    Color(0xFF9C72FF),\n    Color(0xFF53D7D0),\n    Color(0xFFEE8A3D),\n    Color(0xFFE95FA6),\n    Color(0xFFA6E65A),\n    Color(0xFF5B6EE1),\n    Color(0xFFB8C0CC),\n    Color(0xFF008C8C),\n    Color(0xFF00D4FF),\n    Color(0xFFF4C542),\n    Color(0xFFFFAB00),\n    Color(0xFF6F42C1),\n    Color(0xFFFF2DAA),\n    Color(0xFF8B5A2B),\n    Color(0xFF800020),\n    Color(0xFF1F3A5F),\n    Color(0xFF98FFCC),\n    Color(0xFFC4A7FF),\n    Color(0xFF7A7F87),\n  ];""",
    '23-color player palette',
)

# Persist source-specific poison without disturbing existing aggregate poison saves.
replace_once(
    """  Map<String, int> _commanderDamage = <String, int>{};\n  String? _monarchPlayerId;""",
    """  Map<String, int> _commanderDamage = <String, int>{};\n  Map<String, int> _poisonBySource = <String, int>{};\n  String? _monarchPlayerId;""",
    'poison source state',
)

replace_once(
    """      final savedAtMs = (decoded['savedAtMs'] as num?)?.toInt();""",
    """      final poisonBySource = <String, int>{};\n      final rawPoisonBySource = decoded['poisonBySource'];\n      if (rawPoisonBySource is Map) {\n        for (final entry in rawPoisonBySource.entries) {\n          poisonBySource[entry.key.toString()] =\n              (entry.value as num?)?.toInt() ?? 0;\n        }\n      }\n\n      final savedAtMs = (decoded['savedAtMs'] as num?)?.toInt();""",
    'load poison source map',
)

replace_once(
    """        _commanderDamage = damage;\n        _monarchPlayerId = decoded['monarchPlayerId'] as String?;""",
    """        _commanderDamage = damage;\n        _poisonBySource = poisonBySource;\n        _monarchPlayerId = decoded['monarchPlayerId'] as String?;""",
    'restore poison source map',
)

replace_once(
    """      'commanderDamage': _commanderDamage,\n      'monarchPlayerId': _monarchPlayerId,""",
    """      'commanderDamage': _commanderDamage,\n      'poisonBySource': _poisonBySource,\n      'monarchPlayerId': _monarchPlayerId,""",
    'save poison source map',
)

replace_once(
    """        commanderDamage: Map<String, int>.of(_commanderDamage),\n        monarchPlayerId: _monarchPlayerId,""",
    """        commanderDamage: Map<String, int>.of(_commanderDamage),\n        poisonBySource: Map<String, int>.of(_poisonBySource),\n        monarchPlayerId: _monarchPlayerId,""",
    'snapshot poison source map',
)

replace_once(
    """    _commanderDamage = Map<String, int>.of(snapshot.commanderDamage);\n    _monarchPlayerId = snapshot.monarchPlayerId;""",
    """    _commanderDamage = Map<String, int>.of(snapshot.commanderDamage);\n    _poisonBySource = Map<String, int>.of(snapshot.poisonBySource);\n    _monarchPlayerId = snapshot.monarchPlayerId;""",
    'undo restore poison source map',
)

# Poison is now source-specific. Positive poison also lowers life by the same amount.
# Negative corrections reduce poison only and never restore life.
replace_between(
    "  void _changePoison(int index, int delta) {\n",
    "  String _damageKey(int sourceIndex, int commanderSlot, int targetIndex) =>\n",
    """  String _poisonKey(int sourceIndex, int targetIndex) =>\n      '${_players[sourceIndex].id}|${_players[targetIndex].id}';\n\n  int _poisonSourceValue(int sourceIndex, int targetIndex) =>\n      _poisonBySource[_poisonKey(sourceIndex, targetIndex)] ?? 0;\n\n  int _attributedPoisonTotal(int targetIndex) {\n    final targetId = _players[targetIndex].id;\n    var total = 0;\n    for (final entry in _poisonBySource.entries) {\n      if (entry.key.endsWith('|$targetId')) total += entry.value;\n    }\n    return total;\n  }\n\n  int _unattributedPoison(int targetIndex) => max(\n        0,\n        _players[targetIndex].poison - _attributedPoisonTotal(targetIndex),\n      );\n\n  void _changePoisonFromSource(\n    int sourceIndex,\n    int targetIndex,\n    int delta,\n  ) {\n    final key = _poisonKey(sourceIndex, targetIndex);\n    final current = _poisonBySource[key] ?? 0;\n    final player = _players[targetIndex];\n    var next = (current + delta).clamp(0, 999);\n    var applied = next - current;\n    if (applied > 0) {\n      applied = min(applied, 999 - player.poison);\n      next = current + applied;\n    } else if (applied < 0) {\n      applied = max(applied, -player.poison);\n      next = current + applied;\n    }\n    if (applied == 0) return;\n\n    _commit(() {\n      if (next == 0) {\n        _poisonBySource.remove(key);\n      } else {\n        _poisonBySource[key] = next;\n      }\n      final currentPlayer = _players[targetIndex];\n      _players[targetIndex] = currentPlayer.copyWith(\n        poison: (currentPlayer.poison + applied).clamp(0, 999),\n        life: applied > 0 ? currentPlayer.life - applied : currentPlayer.life,\n      );\n    });\n  }\n\n  void _reduceUnattributedPoison(int targetIndex) {\n    if (_unattributedPoison(targetIndex) <= 0) return;\n    _commit(() {\n      final player = _players[targetIndex];\n      _players[targetIndex] = player.copyWith(\n        poison: max(0, player.poison - 1),\n      );\n    });\n  }\n\n  void _clearPoison(int targetIndex) {\n    if (_players[targetIndex].poison == 0) return;\n    final targetId = _players[targetIndex].id;\n    _commit(() {\n      _poisonBySource.removeWhere(\n        (key, _) => key.endsWith('|$targetId'),\n      );\n      _players[targetIndex] = _players[targetIndex].copyWith(poison: 0);\n    });\n  }\n\n  String _damageKey(int sourceIndex, int commanderSlot, int targetIndex) =>\n""",
    'source-specific poison logic',
)

# Commander damage positive increments also lower the target player's life.
# Correcting commander damage downward never restores life.
replace_between(
    "  void _changeCommanderDamage(\n",
    "  void _recalculateCommanderSummary(int targetIndex) {\n",
    """  void _changeCommanderDamage(\n    int sourceIndex,\n    int commanderSlot,\n    int targetIndex,\n    int delta,\n  ) {\n    final key = _damageKey(sourceIndex, commanderSlot, targetIndex);\n    final current = _commanderDamage[key] ?? 0;\n    final next = (current + delta).clamp(0, 999);\n    final applied = next - current;\n    if (applied == 0) return;\n\n    _commit(() {\n      if (next == 0) {\n        _commanderDamage.remove(key);\n      } else {\n        _commanderDamage[key] = next;\n      }\n      if (applied > 0) {\n        final target = _players[targetIndex];\n        _players[targetIndex] = target.copyWith(\n          life: target.life - applied,\n        );\n      }\n      _recalculateCommanderSummary(targetIndex);\n    });\n  }\n\n  void _recalculateCommanderSummary(int targetIndex) {\n""",
    'commander damage linked life',
)

# Replace the old single poison +/- popup with source-colored rows.
replace_between(
    "  Future<void> _showPoisonControls(int index) async {\n",
    "  Future<void> _showCommanderDamageControls(int targetIndex) async {\n",
    """  Future<void> _showPoisonControls(int index) async {\n    await showModalBottomSheet<void>(\n      context: context,\n      backgroundColor: const Color(0xFF111116),\n      isScrollControlled: true,\n      builder: (context) => FractionallySizedBox(\n        heightFactor: 0.82,\n        child: StatefulBuilder(\n          builder: (context, setSheetState) {\n            final player = _players[index];\n            final lethal = player.poison >= 10;\n            final rows = <Widget>[];\n\n            for (var source = 0; source < _playerCount; source++) {\n              if (source == index) continue;\n              final sourcePlayer = _players[source];\n              final value = _poisonSourceValue(source, index);\n              rows.add(\n                _PoisonSourceRow(\n                  accent: sourcePlayer.accent,\n                  playerName: sourcePlayer.name,\n                  poison: value,\n                  onMinus: value > 0\n                      ? () {\n                          _changePoisonFromSource(source, index, -1);\n                          setSheetState(() {});\n                        }\n                      : null,\n                  onPlus: () {\n                    _changePoisonFromSource(source, index, 1);\n                    setSheetState(() {});\n                  },\n                ),\n              );\n            }\n\n            final unattributed = _unattributedPoison(index);\n            if (unattributed > 0) {\n              rows.add(\n                _PoisonSourceRow(\n                  accent: const Color(0xFF8A8A92),\n                  playerName: 'OTHER / LEGACY',\n                  poison: unattributed,\n                  onMinus: () {\n                    _reduceUnattributedPoison(index);\n                    setSheetState(() {});\n                  },\n                  onPlus: null,\n                ),\n              );\n            }\n\n            return SafeArea(\n              child: Column(\n                children: [\n                  const SizedBox(height: 12),\n                  _SheetHandle(),\n                  Padding(\n                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),\n                    child: Text(\n                      '${player.name.toUpperCase()} — POISON',\n                      style: TextStyle(\n                        color: lethal\n                            ? const Color(0xFFFF5C5C)\n                            : const Color(0xFFC47AFF),\n                        fontWeight: FontWeight.w900,\n                        letterSpacing: 1.1,\n                      ),\n                    ),\n                  ),\n                  Text(\n                    '${player.poison}',\n                    style: TextStyle(\n                      fontSize: 58,\n                      height: 1,\n                      fontWeight: FontWeight.w900,\n                      color: lethal ? const Color(0xFFFF5C5C) : Colors.white,\n                    ),\n                  ),\n                  const SizedBox(height: 4),\n                  Text(\n                    lethal\n                        ? 'POISON LETHAL — 10+'\n                        : 'Choose the player dealing poison. Their color identifies the source.',\n                    textAlign: TextAlign.center,\n                    style: TextStyle(\n                      color: lethal ? const Color(0xFFFF8A8A) : Colors.white54,\n                      fontWeight: lethal ? FontWeight.w800 : FontWeight.w500,\n                      fontSize: 12,\n                    ),\n                  ),\n                  const SizedBox(height: 8),\n                  Expanded(\n                    child: ListView(\n                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),\n                      children: rows,\n                    ),\n                  ),\n                  Padding(\n                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),\n                    child: SizedBox(\n                      width: double.infinity,\n                      child: OutlinedButton(\n                        onPressed: player.poison == 0\n                            ? null\n                            : () {\n                                _clearPoison(index);\n                                setSheetState(() {});\n                              },\n                        child: const Text('CLEAR POISON'),\n                      ),\n                    ),\n                  ),\n                ],\n              ),\n            );\n          },\n        ),\n      ),\n    );\n  }\n\n  Future<void> _showCommanderDamageControls(int targetIndex) async {\n""",
    'source-colored poison popup',
)

# Add Custom to the player color area without touching any other settings section.
replace_between(
    "                        _SectionTitle('PLAYER COLOR'),\n",
    "                        _SectionTitle('COMMANDER TAX'),\n",
    """                        _SectionTitle('PLAYER COLOR'),\n                        Wrap(\n                          spacing: 10,\n                          runSpacing: 10,\n                          crossAxisAlignment: WrapCrossAlignment.center,\n                          children: [\n                            for (final color in _accents)\n                              InkWell(\n                                onTap: () {\n                                  _commit(() {\n                                    _players[index] =\n                                        player.copyWith(accent: color);\n                                  });\n                                  refresh();\n                                },\n                                customBorder: const CircleBorder(),\n                                child: Container(\n                                  width: 38,\n                                  height: 38,\n                                  decoration: BoxDecoration(\n                                    color: color,\n                                    shape: BoxShape.circle,\n                                    border: Border.all(\n                                      color: player.accent == color\n                                          ? Colors.white\n                                          : Colors.transparent,\n                                      width: 3,\n                                    ),\n                                  ),\n                                ),\n                              ),\n                            ActionChip(\n                              avatar: CircleAvatar(\n                                radius: 9,\n                                backgroundColor: player.accent,\n                              ),\n                              label: const Text('CUSTOM'),\n                              onPressed: () async {\n                                final color = await _showCustomColorPicker(\n                                  _players[index].accent,\n                                );\n                                if (color == null) return;\n                                _commit(() {\n                                  _players[index] =\n                                      _players[index].copyWith(accent: color);\n                                });\n                                refresh();\n                              },\n                            ),\n                          ],\n                        ),\n                        const SizedBox(height: 18),\n                        _SectionTitle('COMMANDER TAX'),\n""",
    'player color selector with custom color',
)

# Add an HSV custom picker. It changes only the player's accent color.
replace_once(
    """  List<String> _orderedCounterNames(PlayerState player) {""",
    """  Future<Color?> _showCustomColorPicker(Color initialColor) async {\n    var hsv = HSVColor.fromColor(initialColor);\n    return showDialog<Color>(\n      context: context,\n      builder: (context) => StatefulBuilder(\n        builder: (context, setDialogState) {\n          final preview = hsv.toColor();\n          return AlertDialog(\n            title: const Text('Custom player color'),\n            content: Column(\n              mainAxisSize: MainAxisSize.min,\n              children: [\n                Container(\n                  height: 58,\n                  decoration: BoxDecoration(\n                    color: preview,\n                    borderRadius: BorderRadius.circular(12),\n                    border: Border.all(color: Colors.white38),\n                  ),\n                ),\n                const SizedBox(height: 14),\n                const Align(\n                  alignment: Alignment.centerLeft,\n                  child: Text('Hue'),\n                ),\n                Slider(\n                  min: 0,\n                  max: 360,\n                  value: hsv.hue,\n                  activeColor: preview,\n                  onChanged: (value) {\n                    setDialogState(() => hsv = hsv.withHue(value));\n                  },\n                ),\n                const Align(\n                  alignment: Alignment.centerLeft,\n                  child: Text('Saturation'),\n                ),\n                Slider(\n                  min: 0,\n                  max: 1,\n                  value: hsv.saturation,\n                  activeColor: preview,\n                  onChanged: (value) {\n                    setDialogState(() => hsv = hsv.withSaturation(value));\n                  },\n                ),\n                const Align(\n                  alignment: Alignment.centerLeft,\n                  child: Text('Brightness'),\n                ),\n                Slider(\n                  min: 0,\n                  max: 1,\n                  value: hsv.value,\n                  activeColor: preview,\n                  onChanged: (value) {\n                    setDialogState(() => hsv = hsv.withValue(value));\n                  },\n                ),\n              ],\n            ),\n            actions: [\n              TextButton(\n                onPressed: () => Navigator.pop(context),\n                child: const Text('Cancel'),\n              ),\n              FilledButton(\n                onPressed: () => Navigator.pop(context, preview),\n                child: const Text('Use color'),\n              ),\n            ],\n          );\n        },\n      ),\n    );\n  }\n\n  List<String> _orderedCounterNames(PlayerState player) {""",
    'custom color picker',
)

# Reset poison source attribution together with the already-reset aggregate poison.
replace_once(
    """      _commanderDamage.clear();\n      _monarchPlayerId = null;""",
    """      _commanderDamage.clear();\n      _poisonBySource.clear();\n      _monarchPlayerId = null;""",
    'reset poison source map',
)

# Add poison attribution to undo/redo snapshots.
replace_once(
    """    required this.commanderDamage,\n    required this.monarchPlayerId,""",
    """    required this.commanderDamage,\n    required this.poisonBySource,\n    required this.monarchPlayerId,""",
    'snapshot constructor poison map',
)

replace_once(
    """  final Map<String, int> commanderDamage;\n  final String? monarchPlayerId;""",
    """  final Map<String, int> commanderDamage;\n  final Map<String, int> poisonBySource;\n  final String? monarchPlayerId;""",
    'snapshot field poison map',
)

# Source-colored poison row. Commander source rows remain handled by the locked prior transform.
replace_once(
    """class _CommanderDamageRow extends StatelessWidget {""",
    """class _PoisonSourceRow extends StatelessWidget {\n  const _PoisonSourceRow({\n    required this.accent,\n    required this.playerName,\n    required this.poison,\n    required this.onMinus,\n    required this.onPlus,\n  });\n\n  final Color accent;\n  final String playerName;\n  final int poison;\n  final VoidCallback? onMinus;\n  final VoidCallback? onPlus;\n\n  @override\n  Widget build(BuildContext context) {\n    return Card(\n      color: Color.lerp(const Color(0xFF18181F), accent, 0.16),\n      shape: RoundedRectangleBorder(\n        borderRadius: BorderRadius.circular(12),\n        side: BorderSide(color: accent.withValues(alpha: 0.72), width: 1.2),\n      ),\n      child: Padding(\n        padding: const EdgeInsets.all(12),\n        child: Row(\n          children: [\n            CircleAvatar(\n              radius: 22,\n              backgroundColor: accent.withValues(alpha: 0.22),\n              child: Icon(Icons.coronavirus_outlined, color: accent),\n            ),\n            const SizedBox(width: 12),\n            Expanded(\n              child: Column(\n                crossAxisAlignment: CrossAxisAlignment.start,\n                children: [\n                  Text(\n                    playerName.toUpperCase(),\n                    overflow: TextOverflow.ellipsis,\n                    style: TextStyle(\n                      fontWeight: FontWeight.w900,\n                      color: accent,\n                    ),\n                  ),\n                  Text(\n                    'POISON SOURCE',\n                    style: TextStyle(\n                      fontSize: 11,\n                      color: accent.withValues(alpha: 0.88),\n                      fontWeight: FontWeight.w700,\n                    ),\n                  ),\n                ],\n              ),\n            ),\n            IconButton(\n              onPressed: onMinus,\n              icon: Icon(Icons.remove, color: accent),\n            ),\n            SizedBox(\n              width: 38,\n              child: Text(\n                '$poison',\n                textAlign: TextAlign.center,\n                style: TextStyle(\n                  fontSize: 22,\n                  fontWeight: FontWeight.w900,\n                  color: accent,\n                ),\n              ),\n            ),\n            IconButton(\n              onPressed: onPlus,\n              icon: Icon(Icons.add, color: accent),\n            ),\n          ],\n        ),\n      ),\n    );\n  }\n}\n\nclass _CommanderDamageRow extends StatelessWidget {""",
    'poison source row widget',
)

# Perfection gate: verify every authorized change exists after transformation.
required_fragments = [
    'Color(0xFF7A7F87)',
    "label: const Text('CUSTOM')",
    'Map<String, int> _poisonBySource',
    'void _changePoisonFromSource(',
    'life: applied > 0 ? currentPlayer.life - applied : currentPlayer.life',
    'life: target.life - applied',
    'class _PoisonSourceRow extends StatelessWidget',
    'accent: sourcePlayer.accent',
]
for fragment in required_fragments:
    if fragment not in text:
        raise RuntimeError(f'approved-change verification failed: {fragment}')

path.write_text(text)
print('Applied Aug 20 approved changes: 23+Custom colors, linked commander life, linked source-colored poison.')
