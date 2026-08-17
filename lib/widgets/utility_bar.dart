import 'dart:math' as math;

import 'package:flutter/material.dart';

class UtilityBar extends StatelessWidget {
  const UtilityBar({
    super.key,
    required this.playerCount,
    required this.onReset,
    required this.onPlayerCount,
    required this.onHistory,
    required this.onTheme,
    required this.onDice,
  });

  final int playerCount;
  final VoidCallback onReset;
  final VoidCallback onPlayerCount;
  final VoidCallback onHistory;
  final VoidCallback onTheme;
  final VoidCallback onDice;

  @override
  Widget build(BuildContext context) {
    final buttons = <_UtilitySpec>[
      _UtilitySpec(Icons.refresh, 'RESET', onReset),
      _UtilitySpec(Icons.groups_2_outlined, '$playerCount\nPLAYERS', onPlayerCount),
      _UtilitySpec(Icons.history_outlined, 'HISTORY', onHistory),
      _UtilitySpec(Icons.local_fire_department_outlined, 'THEME', onTheme),
      _UtilitySpec(Icons.casino_outlined, 'DICE', onDice),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = math.min(constraints.maxWidth - 18, 510.0);
        return SizedBox(
          width: maxWidth,
          height: 68,
          child: CustomPaint(
            painter: _ArtifactBarPainter(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  for (var i = 0; i < buttons.length; i++)
                    Expanded(
                      child: _UtilityButton(
                        icon: buttons[i].icon,
                        label: buttons[i].label,
                        onTap: buttons[i].onTap,
                        emphasized: i == 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UtilitySpec {
  const _UtilitySpec(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _UtilityButton extends StatelessWidget {
  const _UtilityButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.emphasized,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 30,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: emphasized ? 38 : 34,
            height: emphasized ? 38 : 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  emphasized
                      ? const Color(0xFF173E57)
                      : const Color(0xFF24201A),
                  const Color(0xFF09090C),
                ],
              ),
              border: Border.all(
                color: emphasized
                    ? const Color(0xFF53BFF4)
                    : const Color(0xFF9D7B43),
                width: 1.1,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black, blurRadius: 5, offset: Offset(0, 2)),
              ],
            ),
            child: Icon(
              icon,
              size: emphasized ? 21 : 19,
              color: emphasized
                  ? const Color(0xFF68D0FF)
                  : const Color(0xFFE8C878),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 7.5,
              height: 0.95,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
              color: Color(0xFFF0E2C5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtifactBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 1, size.width, size.height - 2);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF242329), Color(0xFF101014), Color(0xFF060608)],
        ).createShader(rect),
    );

    canvas.drawRRect(
      rrect.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF9E7C49),
    );
    canvas.drawRRect(
      rrect.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.65
        ..color = const Color(0xFFDEC18B).withValues(alpha: 0.26),
    );

    final topGem = Offset(size.width / 2, 2);
    final bottomGem = Offset(size.width / 2, size.height - 2);
    _gem(canvas, topGem, const Color(0xFFB13A38));
    _gem(canvas, bottomGem, const Color(0xFF3EB8F3));
    _gem(canvas, const Offset(5, 34), const Color(0xFF3EB8F3));
    _gem(canvas, Offset(size.width - 5, 34), const Color(0xFF3EB8F3));

    final ornament = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF8D7046).withValues(alpha: 0.7);
    canvas.drawLine(const Offset(14, 9), Offset(size.width - 14, 9), ornament);
    canvas.drawLine(
      Offset(14, size.height - 9),
      Offset(size.width - 14, size.height - 9),
      ornament,
    );
  }

  void _gem(Canvas canvas, Offset center, Color color) {
    const h = 6.0;
    const w = 4.0;
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
          colors: [Colors.white, color, color.withValues(alpha: 0.3)],
        ).createShader(Rect.fromCenter(center: center, width: w * 2, height: h * 2)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
