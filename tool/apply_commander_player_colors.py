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

old_row = """class _CommanderDamageRow extends StatelessWidget {
  const _CommanderDamageRow({
    required this.playerName,
    required this.commanderName,
    required this.imageUrl,
    required this.damage,
    required this.onMinus,
    required this.onPlus,
  });

  final String playerName;
  final String commanderName;
  final String imageUrl;
  final int damage;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final lethal = damage >= 21;
    return Card(
      color: lethal ? const Color(0xFF351114) : const Color(0xFF18181F),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _CommanderAvatar(
              imageUrl: imageUrl,
              accent: lethal ? const Color(0xFFFF5C5C) : const Color(0xFFE2C477),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commanderName.isEmpty ? 'Commander' : commanderName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'SOURCE: $playerName${lethal ? ' • LETHAL' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: lethal ? const Color(0xFFFF8A8A) : Colors.white54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(onPressed: damage > 0 ? onMinus : null, icon: const Icon(Icons.remove)),
            SizedBox(
              width: 38,
              child: Text(
                '$damage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: lethal ? const Color(0xFFFF5C5C) : Colors.white,
                ),
              ),
            ),
            IconButton(onPressed: onPlus, icon: const Icon(Icons.add)),
          ],
        ),
      ),
    );
  }
}
"""

new_row = """class _CommanderDamageRow extends StatelessWidget {
  const _CommanderDamageRow({
    required this.accent,
    required this.playerName,
    required this.commanderName,
    required this.imageUrl,
    required this.damage,
    required this.onMinus,
    required this.onPlus,
  });

  final Color accent;
  final String playerName;
  final String commanderName;
  final String imageUrl;
  final int damage;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final lethal = damage >= 21;
    return Card(
      color: lethal
          ? Color.lerp(const Color(0xFF351114), accent, 0.18)
          : Color.lerp(const Color(0xFF18181F), accent, 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: lethal
              ? Color.lerp(accent, const Color(0xFFFF5C5C), 0.58)!
              : accent.withValues(alpha: 0.72),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _CommanderAvatar(
              imageUrl: imageUrl,
              accent: lethal
                  ? Color.lerp(accent, const Color(0xFFFF5C5C), 0.48)!
                  : accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commanderName.isEmpty ? 'Commander' : commanderName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  Text(
                    'SOURCE: $playerName${lethal ? ' • LETHAL' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: lethal
                          ? const Color(0xFFFF8A8A)
                          : accent.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: damage > 0 ? onMinus : null,
              icon: Icon(Icons.remove, color: accent),
            ),
            SizedBox(
              width: 38,
              child: Text(
                '$damage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: lethal ? const Color(0xFFFF5C5C) : accent,
                ),
              ),
            ),
            IconButton(
              onPressed: onPlus,
              icon: Icon(Icons.add, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
"""

replace_once(old_row, new_row, 'commander damage row')

replace_once(
    """                child: Text(\n                  '${source.name}\\n${slot == 0 ? source.commanderName : source.partnerCommanderName}',\n                ),""",
    """                child: Text(\n                  '${source.name}\\n${slot == 0 ? source.commanderName : source.partnerCommanderName}',\n                  style: TextStyle(\n                    color: source.accent,\n                    fontWeight: FontWeight.w700,\n                  ),\n                ),""",
    'commander matrix source color',
)

path.write_text(text)
print('Applied commander player colors and expanded player palette.')
