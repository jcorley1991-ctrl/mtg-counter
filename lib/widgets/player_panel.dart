import 'package:flutter/material.dart';

import '../models/player_state.dart';

class PlayerPanel extends StatelessWidget {
  const PlayerPanel({
    super.key,
    required this.player,
    required this.onDecreaseLife,
    required this.onIncreaseLife,
    required this.onPoisonTap,
    required this.onCommanderDamageTap,
    required this.onSettingsTap,
  });

  final PlayerState player;
  final VoidCallback onDecreaseLife;
  final VoidCallback onIncreaseLife;
  final VoidCallback onPoisonTap;
  final VoidCallback onCommanderDamageTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final accent = player.accent;
    final poisonLethal = player.poison >= 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 220 || constraints.maxHeight < 200;
        final lifeSize = compact ? 48.0 : 72.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.82), width: 1.4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.30),
                const Color(0xFF111116),
                Colors.black,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.15),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Stage 1 placeholder. Approved fantasy full-art treatment is locked;
                // final artwork/theme integration is implemented in Stage 8.
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.22,
                      child: CustomPaint(painter: _FantasyPlaceholderPainter(accent)),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(compact ? 10 : 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              player.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                fontSize: compact ? 11 : 13,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Player settings',
                            onPressed: onSettingsTap,
                            visualDensity: VisualDensity.compact,
                            iconSize: compact ? 18 : 22,
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _LifeButton(symbol: '−', onTap: onDecreaseLife, compact: compact),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${player.life}',
                                  style: TextStyle(
                                    fontSize: lifeSize,
                                    height: 0.9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(color: Colors.black, blurRadius: 10),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            _LifeButton(symbol: '+', onTap: onIncreaseLife, compact: compact),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CounterChip(
                            icon: Icons.coronavirus_outlined,
                            label: compact
                                ? '${player.poison}${poisonLethal ? '!' : ''}'
                                : 'POISON ${player.poison}${poisonLethal ? '!' : ''}',
                            color: poisonLethal
                                ? const Color(0xFFFF5C5C)
                                : const Color(0xFFC47AFF),
                            onTap: onPoisonTap,
                          ),
                          _CounterChip(
                            icon: Icons.shield_outlined,
                            label: 'CMD ${player.commanderDamageSummary}',
                            color: const Color(0xFFE2C477),
                            onTap: onCommanderDamageTap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LifeButton extends StatelessWidget {
  const _LifeButton({required this.symbol, required this.onTap, required this.compact});

  final String symbol;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 54.0;
    return SizedBox.square(
      dimension: size,
      child: Material(
        color: Colors.black.withValues(alpha: 0.42),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Text(
              symbol,
              style: TextStyle(
                fontSize: compact ? 28 : 34,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.52),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FantasyPlaceholderPainter extends CustomPainter {
  _FantasyPlaceholderPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent;

    final center = Offset(size.width * 0.55, size.height * 0.42);
    final radius = size.shortestSide * 0.18;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.72, paint);
    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.85),
      Offset(size.width * 0.95, size.height * 0.25),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FantasyPlaceholderPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
