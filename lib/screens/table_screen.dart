import 'package:flutter/material.dart';

import '../layout/table_layout_spec.dart';
import '../models/player_state.dart';
import '../widgets/player_panel.dart';
import '../widgets/utility_bar.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  int _playerCount = 4;
  late List<PlayerState> _players;
  final List<_GameSnapshot> _history = [];

  static const _accents = <Color>[
    Color(0xFF4CB7FF),
    Color(0xFFE75B58),
    Color(0xFF58C989),
    Color(0xFFE1BC63),
    Color(0xFF9C72FF),
    Color(0xFF53D7D0),
  ];

  @override
  void initState() {
    super.initState();
    _players = List.generate(
      6,
      (index) => PlayerState(
        id: 'p${index + 1}',
        name: 'Player ${index + 1}',
        life: 40,
        poison: 0,
        commanderDamageSummary: 0,
        accent: _accents[index],
      ),
    );
  }

  void _checkpoint() {
    _history.add(
      _GameSnapshot(
        playerCount: _playerCount,
        players: List<PlayerState>.of(_players),
      ),
    );
    if (_history.length > 30) _history.removeAt(0);
  }

  void _changeLife(int index, int delta) {
    _checkpoint();
    setState(() {
      _players[index] = _players[index].copyWith(
        life: _players[index].life + delta,
      );
    });
  }

  void _changePoison(int index, int delta) {
    final next = (_players[index].poison + delta).clamp(0, 999);
    if (next == _players[index].poison) return;

    _checkpoint();
    setState(() {
      _players[index] = _players[index].copyWith(poison: next);
    });
  }

  void _undo() {
    if (_history.isEmpty) return;
    final snapshot = _history.removeLast();
    setState(() {
      _playerCount = snapshot.playerCount;
      _players = List<PlayerState>.of(snapshot.players);
    });
  }

  Future<void> _choosePlayerCount() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF111116),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var value = 2; value <= 6; value++)
                ChoiceChip(
                  selected: value == _playerCount,
                  label: Text('$value players'),
                  onSelected: (_) => Navigator.pop(context, value),
                ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && selected != _playerCount) {
      _checkpoint();
      setState(() => _playerCount = selected);
    }
  }

  Future<void> _showPoisonControls(int index) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111116),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final player = _players[index];
            final lethal = player.poison >= 10;

            void change(int delta) {
              _changePoison(index, delta);
              setSheetState(() {});
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${player.name.toUpperCase()} — POISON',
                      style: TextStyle(
                        color: lethal ? const Color(0xFFFF5C5C) : const Color(0xFFC47AFF),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${player.poison}',
                      style: TextStyle(
                        fontSize: 76,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: lethal ? const Color(0xFFFF5C5C) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lethal ? 'POISON LETHAL — 10+' : '10 poison counters is lethal',
                      style: TextStyle(
                        color: lethal ? const Color(0xFFFF8A8A) : Colors.white54,
                        fontWeight: lethal ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _PoisonButton(
                            label: '−',
                            onPressed: player.poison > 0 ? () => change(-1) : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _PoisonButton(
                            label: '+',
                            onPressed: () => change(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: player.poison == 0
                            ? null
                            : () {
                                _checkpoint();
                                setState(() {
                                  _players[index] = _players[index].copyWith(poison: 0);
                                });
                                setSheetState(() {});
                              },
                        child: const Text('CLEAR POISON'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStageNotice(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is reserved for its approved implementation stage.'),
      ),
    );
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset game?'),
        content: const Text(
          'This resets life, poison, and commander-damage summaries for all players.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    _checkpoint();
    setState(() {
      for (var i = 0; i < _players.length; i++) {
        _players[i] = _players[i].copyWith(
          life: 40,
          poison: 0,
          commanderDamageSummary: 0,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final seats = TableLayoutSpec.forPlayerCount(_playerCount);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  bottom: 74,
                  child: ColoredBox(
                    color: Colors.black,
                    child: LayoutBuilder(
                      builder: (context, tableConstraints) {
                        return Stack(
                          children: [
                            for (var i = 0; i < seats.length; i++)
                              _positionedSeat(
                                tableConstraints.biggest,
                                seats[i],
                                i,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Center(
                    child: UtilityBar(
                      playerCount: _playerCount,
                      onReset: _reset,
                      onPlayerCount: _choosePlayerCount,
                      onUndo: _undo,
                      onTheme: () => _showStageNotice('Theme and fantasy artwork'),
                      onDice: () => _showStageNotice('Dice and randomizer'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _positionedSeat(Size size, SeatSpec seat, int index) {
    final rect = Rect.fromLTWH(
      seat.rect.left * size.width,
      seat.rect.top * size.height,
      seat.rect.width * size.width,
      seat.rect.height * size.height,
    );

    return Positioned.fromRect(
      rect: rect,
      child: RotatedBox(
        quarterTurns: seat.quarterTurns,
        child: PlayerPanel(
          player: _players[index],
          onDecreaseLife: () => _changeLife(index, -1),
          onIncreaseLife: () => _changeLife(index, 1),
          onPoisonTap: () => _showPoisonControls(index),
          onCommanderDamageTap: () => _showStageNotice('Commander damage'),
          onSettingsTap: () => _showStageNotice('Player settings'),
        ),
      ),
    );
  }
}

class _GameSnapshot {
  const _GameSnapshot({required this.playerCount, required this.players});

  final int playerCount;
  final List<PlayerState> players;
}

class _PoisonButton extends StatelessWidget {
  const _PoisonButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
