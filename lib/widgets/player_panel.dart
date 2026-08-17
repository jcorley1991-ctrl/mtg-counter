import 'dart:math' as math;

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
        final compact = constraints.maxWidth < 225 || constraints.maxHeight < 210;
        final veryCompact = constraints.maxWidth < 175 || constraints.maxHeight < 155;
        final lifeSize = veryCompact ? 45.0 : compact ? 58.0 : 86.0;
        final radius = compact ? 18.0 : 24.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                color: const Color(0xFF050609),
                image: hasArtwork
                    ? DecorationImage(
                        image: NetworkImage(player.backgroundImageUrl.trim()),
                        fit: BoxFit.cover,
                        colorFilter: const ColorFilter.mode(
                          Color(0x99000000),
                          BlendMode.darken,
                        ),
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.24),
                    blurRadius: compact ? 12 : 22,
                    spreadRadius: compact ? 0 : 1,
                  ),
                  const BoxShadow(
                    color: Colors.black,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: CustomPaint(
                painter: _ArcanePanelPainter(
                  accent: accent,
                  themeIndex: themeIndex,
                  compact: compact,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 15,
                compact ? 9 : 13,
                compact ? 10 : 15,
                compact ? 10 : 14,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: compact ? 29 : 38,
                    child: Row(
                      children: [
                        const SizedBox(width: 34),
                        Expanded(
                          child: InkWell(
                            onTap: onSettingsTap,
                            borderRadius: BorderRadius.circular(10),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      player.name.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color.lerp(accent, Colors.white, 0.22),
                                        fontFamily: 'serif',
                                        fontSize: veryCompact ? 10 : compact ? 12 : 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: compact ? 1.1 : 1.8,
                                        shadows: [
                                          Shadow(
                                            color: accent.withValues(alpha: 0.60),
                                            blurRadius: 8,
                                          ),
                                          const Shadow(color: Colors.black, blurRadius: 5),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!veryCompact && isMonarch) ...[
                                    const SizedBox(width: 5),
                                    const Icon(Icons.workspace_premium, size: 15),
                                  ],
                                  if (!veryCompact && hasInitiative) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.flag_outlined, size: 14),
                                  ],
                                  if (!veryCompact && player.cityBlessing) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.auto_awesome, size: 14),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        _GearButton(
                          accent: accent,
                          compact: compact,
                          onTap: onSettingsTap,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _LifeButton(
                          symbol: '−',
                          accent: accent,
                          onTap: onDecreaseLife,
                          compact: compact,
                          veryCompact: veryCompact,
                        ),
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${player.life}',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: lifeSize,
                                  height: 0.88,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: accent.withValues(alpha: 0.78),
                                      blurRadius: compact ? 8 : 16,
                                    ),
                                    const Shadow(
                                      color: Colors.black,
                                      blurRadius: 7,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        _LifeButton(
                          symbol: '+',
                          accent: accent,
                          onTap: onIncreaseLife,
                          compact: compact,
                          veryCompact: veryCompact,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: compact ? 36 : 46,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _CounterSeal(
                            icon: Icons.coronavirus_outlined,
                            title: veryCompact ? '' : 'POISON',
                            value: '${player.poison}${poisonLethal ? '!' : ''}',
                            color: poisonLethal
                                ? const Color(0xFFFF5C5C)
                                : const Color(0xFFC978FF),
                            compact: compact,
                            onTap: onPoisonTap,
                          ),
                        ),
                        SizedBox(width: compact ? 6 : 10),
                        Flexible(
                          child: _CounterSeal(
                            icon: Icons.shield_outlined,
                            title: 'CMD',
                            value:
                                '${player.commanderDamageSummary}${commanderLethal ? '!' : ''}',
                            color: commanderLethal
                                ? const Color(0xFFFF5C5C)
                                : const Color(0xFFE7C56D),
                            compact: compact,
                            onTap: onCommanderDamageTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GearButton extends StatelessWidget {
  const _GearButton({
    required this.accent,
    required this.compact,
    required this.onTap,
  });

  final Color accent;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 36.0;
    return SizedBox.square(
      dimension: size,
      child: Material(
        color: const Color(0xD80A0A0D),
        shape: CircleBorder(
          side: BorderSide(color: const Color(0xFF9A7B43), width: compact ? 1 : 1.3),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(
            Icons.settings_outlined,
            size: compact ? 18 : 21,
            color: Color.lerp(Colors.white, accent, 0.16),
          ),
        ),
      ),
    );
  }
}

class _LifeButton extends StatelessWidget {
  const _LifeButton({
    required this.symbol,
    required this.accent,
    required this.onTap,
    required this.compact,
    required this.veryCompact,
  });

  final String symbol;
  final Color accent;
  final VoidCallback onTap;
  final bool compact;
  final bool veryCompact;

  @override
  Widget build(BuildContext context) {
    final size = veryCompact ? 35.0 : compact ? 43.0 : 58.0;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              accent.withValues(alpha: 0.18),
              const Color(0xF20A0A0D),
            ],
          ),
          border: Border.all(
            color: Color.lerp(const Color(0xFF806B42), accent, 0.45)!,
            width: compact ? 1.1 : 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.25),
              blurRadius: compact ? 5 : 9,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: veryCompact ? 24 : compact ? 28 : 36,
                  height: 1,
                  fontWeight: FontWeight.w300,
                  color: Color.lerp(Colors.white, accent, 0.12),
                  shadows: [
                    Shadow(color: accent.withValues(alpha: 0.48), blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterSeal extends StatelessWidget {
  const _CounterSeal({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xEC08080B),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 10,
            vertical: compact ? 5 : 7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Color.lerp(const Color(0xFF826E47), color, 0.22)!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 6),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: compact ? 14 : 17),
              SizedBox(width: compact ? 4 : 6),
              if (title.isNotEmpty)
                Text(
                  title,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: compact ? 9 : 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: color,
                  ),
                ),
              if (title.isNotEmpty) SizedBox(width: compact ? 3 : 5),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: compact ? 10 : 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcanePanelPainter extends CustomPainter {
  _ArcanePanelPainter({
    required this.accent,
    required this.themeIndex,
    required this.compact,
  });

  final Color accent;
  final int themeIndex;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = compact ? 18.0 : 24.0;
    final rrect = RRect.fromRectAndRadius(rect.deflate(0.7), Radius.circular(radius));

    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.05, -0.05),
        radius: 1.05,
        colors: [
          accent.withValues(alpha: 0.20),
          const Color(0xF20B0B10),
          const Color(0xFF020204),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, bgPaint);

    final vignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.025),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.36),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, vignette);

    final rune = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 0.8 : 1.15
      ..color = accent.withValues(alpha: compact ? 0.24 : 0.31);

    final center = Offset(size.width * 0.50, size.height * 0.50);
    final baseRadius = math.min(size.width, size.height) * (compact ? 0.22 : 0.235);

    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(center, baseRadius * (0.58 + 0.17 * i), rune);
    }

    final ticks = compact ? 16 : 28;
    for (var i = 0; i < ticks; i++) {
      final a = (math.pi * 2 * i / ticks) + (themeIndex * 0.11);
      final inner = baseRadius * 0.89;
      final outer = baseRadius * (i % 4 == 0 ? 1.02 : 0.97);
      canvas.drawLine(
        Offset(center.dx + math.cos(a) * inner, center.dy + math.sin(a) * inner),
        Offset(center.dx + math.cos(a) * outer, center.dy + math.sin(a) * outer),
        rune,
      );
    }

    final axis = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 0.8 : 1.1
      ..color = accent.withValues(alpha: 0.24);
    canvas.drawLine(
      Offset(center.dx - baseRadius * 1.18, center.dy),
      Offset(center.dx + baseRadius * 1.18, center.dy),
      axis,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - baseRadius * 1.18),
      Offset(center.dx, center.dy + baseRadius * 1.18),
      axis,
    );

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.3 : 1.8
      ..color = Color.lerp(accent, const Color(0xFFC9A96D), 0.18)!
          .withValues(alpha: 0.90);
    canvas.drawRRect(rrect.deflate(1.2), border);

    final innerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = const Color(0xFFC0A06A).withValues(alpha: 0.28);
    canvas.drawRRect(rrect.deflate(compact ? 4.0 : 5.0), innerBorder);

    _drawCorners(canvas, size, accent, compact);
    _drawCrystal(canvas, Offset(size.width / 2, compact ? 5 : 7), accent, compact);
    _drawCrystal(
      canvas,
      Offset(size.width / 2, size.height - (compact ? 5 : 7)),
      accent,
      compact,
    );
  }

  void _drawCorners(Canvas canvas, Size size, Color color, bool compact) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.0 : 1.35
      ..color = color.withValues(alpha: 0.64);
    final d = compact ? 14.0 : 21.0;
    final inset = compact ? 4.0 : 5.0;

    final corners = <Offset>[
      Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ];
    for (final c in corners) {
      final sx = c.dx < size.width / 2 ? 1.0 : -1.0;
      final sy = c.dy < size.height / 2 ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(c.dx, c.dy + sy * d)
        ..quadraticBezierTo(
          c.dx + sx * d * 0.18,
          c.dy + sy * d * 0.30,
          c.dx + sx * d,
          c.dy,
        )
        ..moveTo(c.dx + sx * 4, c.dy + sy * d * 0.68)
        ..quadraticBezierTo(
          c.dx + sx * d * 0.42,
          c.dy + sy * d * 0.42,
          c.dx + sx * d * 0.68,
          c.dy + sy * 4,
        );
      canvas.drawPath(path, p);
    }
  }

  void _drawCrystal(
    Canvas canvas,
    Offset center,
    Color color,
    bool compact,
  ) {
    final h = compact ? 8.0 : 12.0;
    final w = compact ? 4.0 : 6.0;
    final path = Path()
      ..moveTo(center.dx, center.dy - h)
      ..lineTo(center.dx + w, center.dy)
      ..lineTo(center.dx, center.dy + h)
      ..lineTo(center.dx - w, center.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, color, color.withValues(alpha: 0.30)],
        ).createShader(Rect.fromCenter(center: center, width: w * 2, height: h * 2)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _ArcanePanelPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.themeIndex != themeIndex ||
      oldDelegate.compact != compact;
}
