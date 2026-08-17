import 'package:flutter/material.dart';

class UtilityBar extends StatelessWidget {
  const UtilityBar({
    super.key,
    required this.playerCount,
    required this.onReset,
    required this.onPlayerCount,
    required this.onUndo,
    required this.onTheme,
    required this.onDice,
  });

  final int playerCount;
  final VoidCallback onReset;
  final VoidCallback onPlayerCount;
  final VoidCallback onUndo;
  final VoidCallback onTheme;
  final VoidCallback onDice;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE8111116),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UtilityButton(icon: Icons.refresh, label: 'RESET', onTap: onReset),
            _UtilityButton(
              icon: Icons.groups_2_outlined,
              label: '$playerCount',
              onTap: onPlayerCount,
            ),
            _UtilityButton(icon: Icons.undo, label: 'UNDO', onTap: onUndo),
            _UtilityButton(icon: Icons.palette_outlined, label: 'THEME', onTap: onTheme),
            _UtilityButton(icon: Icons.casino_outlined, label: 'DICE', onTap: onDice),
          ],
        ),
      ),
    );
  }
}

class _UtilityButton extends StatelessWidget {
  const _UtilityButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
