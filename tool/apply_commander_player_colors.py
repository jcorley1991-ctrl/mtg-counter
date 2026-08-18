from pathlib import Path
import re

path = Path('lib/screens/table_screen.dart')
text = path.read_text()


def replace_once(old: str, new: str, label: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: expected exactly 1 match, found {count}')
    text = text.replace(old, new, 1)


replace_once(
    """  static const _accents = <Color>[\n    Color(0xFF4CB7FF),\n    Color(0xFFE75B58),\n    Color(0xFF58C989),\n    Color(0xFFE1BC63),\n    Color(0xFF9C72FF),\n    Color(0xFF53D7D0),\n  ];""",
    """  static const _accents = <Color>[\n    Color(0xFF4CB7FF),\n    Color(0xFFE75B58),\n    Color(0xFF58C989),\n    Color(0xFFE1BC63),\n    Color(0xFF9C72FF),\n    Color(0xFF53D7D0),\n    Color(0xFFEE8A3D),\n    Color(0xFFE95FA6),\n    Color(0xFFA6E65A),\n    Color(0xFF5B6EE1),\n    Color(0xFFB8C0CC),\n  ];""",
    'player accent palette',
)

pattern = re.compile(
    r"(_CommanderDamageRow\(\n)(\s+)(playerName: sourcePlayer\.name,)",
)
text, row_call_count = pattern.subn(
    lambda m: f"{m.group(1)}{m.group(2)}accent: sourcePlayer.accent,\n{m.group(2)}{m.group(3)}",
    text,
)
if row_call_count != 2:
    raise RuntimeError(
        f'commander row call sites: expected 2 matches, found {row_call_count}'
    )

replace_once(
    """  const _CommanderDamageRow({\n    required this.playerName,""",
    """  const _CommanderDamageRow({\n    required this.accent,\n    required this.playerName,""",
    'commander row constructor accent',
)

replace_once(
    """  final String playerName;\n  final String commanderName;""",
    """  final Color accent;\n  final String playerName;\n  final String commanderName;""",
    'commander row accent field',
)

replace_once(
    """    return Card(\n      color: lethal ? const Color(0xFF351114) : const Color(0xFF18181F),""",
    """    return Card(\n      color: lethal\n          ? Color.lerp(const Color(0xFF351114), accent, 0.18)\n          : Color.lerp(const Color(0xFF18181F), accent, 0.16),\n      shape: RoundedRectangleBorder(\n        borderRadius: BorderRadius.circular(12),\n        side: BorderSide(\n          color: lethal\n              ? Color.lerp(accent, const Color(0xFFFF5C5C), 0.58)!\n              : accent.withValues(alpha: 0.72),\n          width: 1.2,\n        ),\n      ),""",
    'commander row card color',
)

replace_once(
    """              accent: lethal ? const Color(0xFFFF5C5C) : const Color(0xFFE2C477),""",
    """              accent: lethal\n                  ? Color.lerp(accent, const Color(0xFFFF5C5C), 0.48)!\n                  : accent,""",
    'commander avatar player color',
)

replace_once(
    """                    style: const TextStyle(fontWeight: FontWeight.w900),""",
    """                    style: TextStyle(\n                      fontWeight: FontWeight.w900,\n                      color: accent,\n                    ),""",
    'commander name player color',
)

replace_once(
    """                  Text(\n                    'SOURCE: $playerName${lethal ? ' • LETHAL' : ''}',\n                    style: TextStyle(\n                      fontSize: 11,\n                      color: lethal ? const Color(0xFFFF8A8A) : Colors.white54,\n                      fontWeight: FontWeight.w700,\n                    ),\n                  ),""",
    """                  Text(\n                    'SOURCE: $playerName${lethal ? ' • LETHAL' : ''}',\n                    style: TextStyle(\n                      fontSize: 11,\n                      color: lethal\n                          ? const Color(0xFFFF8A8A)\n                          : accent.withValues(alpha: 0.88),\n                      fontWeight: FontWeight.w700,\n                    ),\n                  ),""",
    'commander source player color',
)

replace_once(
    """            IconButton(onPressed: damage > 0 ? onMinus : null, icon: const Icon(Icons.remove)),""",
    """            IconButton(\n              onPressed: damage > 0 ? onMinus : null,\n              icon: Icon(Icons.remove, color: accent),\n            ),""",
    'commander minus color',
)

replace_once(
    """                  color: lethal ? const Color(0xFFFF5C5C) : Colors.white,""",
    """                  color: lethal ? const Color(0xFFFF5C5C) : accent,""",
    'commander damage player color',
)

replace_once(
    """            IconButton(onPressed: onPlus, icon: const Icon(Icons.add)),""",
    """            IconButton(\n              onPressed: onPlus,\n              icon: Icon(Icons.add, color: accent),\n            ),""",
    'commander plus color',
)

replace_once(
    """                child: Text(\n                  '${source.name}\\n${slot == 0 ? source.commanderName : source.partnerCommanderName}',\n                ),""",
    """                child: Text(\n                  '${source.name}\\n${slot == 0 ? source.commanderName : source.partnerCommanderName}',\n                  style: TextStyle(\n                    color: source.accent,\n                    fontWeight: FontWeight.w700,\n                  ),\n                ),""",
    'commander matrix source color',
)

path.write_text(text)
print('Applied commander player colors and expanded player palette.')
