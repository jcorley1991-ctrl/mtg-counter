from pathlib import Path

path = Path('lib/screens/table_screen.dart')
text = path.read_text()
start = 'class _LargeAdjustButton extends StatelessWidget {\n'
end = 'class _CommanderAvatar extends StatelessWidget {\n'
start_index = text.find(start)
end_index = text.find(end, start_index)
if start_index < 0 or end_index < 0:
    raise RuntimeError('obsolete poison helper boundaries not found')
if text.count(start) != 1:
    raise RuntimeError('expected exactly one obsolete poison helper')
text = text[:start_index] + text[end_index:]
if '_LargeAdjustButton' in text:
    raise RuntimeError('obsolete poison helper still referenced after removal')
path.write_text(text)
print('Removed obsolete aggregate-poison adjust helper.')
