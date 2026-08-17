import 'package:flutter/material.dart';

import '../models/player_state.dart';

class PlayerPanel extends StatelessWidget {
  const PlayerPanel({
    super.key,
    required this.player,
    required this.themeIndex,
    required this.isMonarch,
    required this.hasInitiative,
    required this.onDecreaseLife,
    required this.onIncreaseLife,
    required this.onPoisonTap,
    required this.onCommanderDamageTap,
    required this.onSettingsTap,
  });

  final PlayerState player;
  final int themeIndex;
  final bool isMonarch;
  final bool hasInitiative;
  final VoidCallback onDecreaseLife;
  final VoidCallback onIncreaseLife;
  final VoidCallback onPoisonTap;
  final VoidCallback onCommanderDamageTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final accent = player.accent;
    final poisonLethal = player.poison >= 10;
    final commanderLethal = player.commanderDamageSummary >= 21;
    final hasArtwork = player.backgroundImageUrl.trim().startsWith('http');

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
              colors: _themeGradient(accent, themeIndex),
            ),
            image: hasArtwork
                ? DecorationImage(
                    image: NetworkImage(player.backgroundImageUrl.trim()),
                    fit: BoxFit.cover,
                    colorFilter: const ColorFilter.mode(
                      Color(0x77000000),
                      BlendMode.darken,
                    ),
                  )
                : null,
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
                if (!hasArtwork)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.25,
                        child: CustomPaint(
                          painter: _FantasyPatternPainter(accent, themeIndex),
                        ),
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
                            child: InkWell(
                              onTap: onSettingsTap,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        player.name.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: accent,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.1,
                                          fontSize: compact ? 11 : 13,
                                          shadows: const [
                                            Shadow(color: Colors.black, blurRadius: 7),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isMonarch) ...[
                                      const SizedBox(width: 5),
                                      const Icon(Icons.workspace_premium, size: 15),
                                    ],
                                    if (hasInitiative) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.flag_outlined, size: 14),
                                    ],
                                    if (player.cityBlessing) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.auto_awesome, size: 14),
                                    ],
                                  ],
                                ),
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
                            _LifeButton(
                              symbol: '−',
                              onTap: onDecreaseLife,
                              compact: compact,
                            ),
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
                            _LifeButton(
                              symbol: '+',
                              onTap: onIncreaseLife,
                              compact: compact,
                            ),
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
                            label:
                                'CMD ${player.commanderDamageSummary}${commanderLethal ? '!' : ''}',
                            color: commanderLethal
                                ? const Color(0xFFFF5C5C)
                                : const Color(0xFFE2C477),
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

  static List<Color> _themeGradient(Color accent, int themeIndex) {
    switch (themeIndex % 4) {
      case 1:
        return [
          const Color(0xFF41170C),
          accent.withValues(alpha: 0.22),
          const Color(0xFF080405),
        ];
      case 2:
        return [
          const Color(0xFF0B3025),
          accent.withValues(alpha: 0.20),
          const Color(0xFF030807),
        ];
      case 3:
        return [
          const Color(0xFF21103D),
          accent.withValues(alpha: 0.25),
          const Color(0xFF040306),
        ];
      default:
        return [
          accent.withValues(alpha: 0.30),
          const Color(0xFF111116),
          Colors.black,
        ];
    }
  }
}

class _LifeButton extends StatelessWidget {
  const _LifeButton({
    required this.symbol,
    required this.onTap,
    required this.compact,
  });

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
      color: Colors.black.withValues(alpha: 0.58),
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

class _FantasyPatternPainter extends CustomPainter {
  _FantasyPatternPainter(this.accent, this.themeIndex);

  final Color accent;
  final int themeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent;

    final center = Offset(size.width * 0.55, size.height * 0.45);
    final radius = size.shortestSide * 0.18;

    switch (themeIndex % 4) {
      case 1:
        final path = Path()
          ..moveTo(size.width * 0.08, size.height * 0.80)
          ..quadraticBezierTo(
            size.width * 0.45,
            size.height * 0.08,
            size.width * 0.92,
            size.height * 0.62,
          )
          ..quadraticBezierTo(
            size.width * 0.55,
            size.height * 0.92,
            size.width * 0.18,
            size.height * 0.30,
          );
        canvas.drawPath(path, paint);
        canvas.drawCircle(center, radius * 0.65, paint);
        break;
      case 2:
        for (var i = 0; i < 4; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: radius * (0.55 + i * 0.28)),
            0.4 + i * 0.3,
            2.1,
            false,
            paint,
          );
        }
        break;
      case 3:
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(center, radius * 0.58, paint);
        canvas.drawLine(
          Offset(center.dx - radius * 1.5, center.dy),
          Offset(center.dx + radius * 1.5, center.dy),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - radius * 1.5),
          Offset(center.dx, center.dy + radius * 1.5),
          paint,
        );
        break;
      default:
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(center, radius * 0.72, paint);
        canvas.drawLine(
          Offset(size.width * 0.05, size.height * 0.85),
          Offset(size.width * 0.95, size.height * 0.25),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _FantasyPatternPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.themeIndex != themeIndex;
}
