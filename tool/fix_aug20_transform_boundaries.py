from pathlib import Path

path = Path('lib/screens/table_screen.dart')
text = path.read_text()


def collapse_once(line: str, label: str) -> None:
    global text
    doubled = f'{line}\n{line}\n'
    count = text.count(doubled)
    if count != 1:
        raise RuntimeError(f'{label}: expected exactly 1 doubled boundary, found {count}')
    text = text.replace(doubled, f'{line}\n', 1)


collapse_once(
    '  String _damageKey(int sourceIndex, int commanderSlot, int targetIndex) =>',
    'damage key boundary',
)
collapse_once(
    '  void _recalculateCommanderSummary(int targetIndex) {',
    'commander summary boundary',
)
collapse_once(
    '  Future<void> _showCommanderDamageControls(int targetIndex) async {',
    'commander popup boundary',
)
collapse_once(
    "                        _SectionTitle('COMMANDER TAX'),",
    'commander tax section boundary',
)

for line in [
    '  String _damageKey(int sourceIndex, int commanderSlot, int targetIndex) =>',
    '  void _recalculateCommanderSummary(int targetIndex) {',
    '  Future<void> _showCommanderDamageControls(int targetIndex) async {',
]:
    if text.count(line) != 1:
        raise RuntimeError(f'boundary verification failed: {line}')

path.write_text(text)
print('Collapsed Aug 20 transform boundary duplicates.')
