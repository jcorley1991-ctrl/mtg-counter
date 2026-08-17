import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../layout/table_layout_spec.dart';
import '../models/player_state.dart';
import '../widgets/player_panel.dart';
import '../widgets/utility_bar.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen>
    with WidgetsBindingObserver {
  static const _storageKey = 'mtg_counter_game_v2';
  static const _builtInCounters = <String>[
    'Energy',
    'Experience',
    'Rad',
    'Storm',
    'Treasure',
    'Food',
    'Clue',
    'Blood',
    'Charge',
  ];

  static const _themeNames = <String>[
    'Arcane',
    'Ember',
    'Verdant',
    'Void',
  ];

  static const _accents = <Color>[
    Color(0xFF4CB7FF),
    Color(0xFFE75B58),
    Color(0xFF58C989),
    Color(0xFFE1BC63),
    Color(0xFF9C72FF),
    Color(0xFF53D7D0),
  ];

  final Random _random = Random();
  final List<_GameSnapshot> _history = <_GameSnapshot>[];
  final List<_GameSnapshot> _redo = <_GameSnapshot>[];

  int _playerCount = 4;
  late List<PlayerState> _players;
  Map<String, int> _commanderDamage = <String, int>{};
  String? _monarchPlayerId;
  String? _initiativePlayerId;
  bool _isDay = true;
  int _themeIndex = 0;

  int _gameBaseSeconds = 0;
  int _turnBaseSeconds = 0;
  int? _timerStartedAtMs;
  Timer? _ticker;

  bool get _timerRunning => _timerStartedAtMs != null;

  int get _gameSeconds {
    if (_timerStartedAtMs == null) return _gameBaseSeconds;
    return _gameBaseSeconds +
        ((DateTime.now().millisecondsSinceEpoch - _timerStartedAtMs!) ~/ 1000);
  }

  int get _turnSeconds {
    if (_timerStartedAtMs == null) return _turnBaseSeconds;
    return _turnBaseSeconds +
        ((DateTime.now().millisecondsSinceEpoch - _timerStartedAtMs!) ~/ 1000);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _players = List<PlayerState>.generate(6, _newPlayer);
    unawaited(_loadState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_saveState());
    }
  }

  PlayerState _newPlayer(int index) => PlayerState(
        id: 'p${index + 1}',
        name: 'Player ${index + 1}',
        life: 40,
        startingLife: 40,
        poison: 0,
        commanderDamageSummary: 0,
        accent: _accents[index % _accents.length],
        commanderName: 'Commander ${index + 1}',
        counters: <String, int>{
          for (final name in _builtInCounters) name: 0,
        },
      );

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final restoredPlayers = <PlayerState>[];
      final rawPlayers = decoded['players'];
      if (rawPlayers is List) {
        for (final item in rawPlayers) {
          if (item is Map) {
            restoredPlayers.add(
              PlayerState.fromJson(Map<String, Object?>.from(item)),
            );
          }
        }
      }
      while (restoredPlayers.length < 6) {
        restoredPlayers.add(_newPlayer(restoredPlayers.length));
      }

      final damage = <String, int>{};
      final rawDamage = decoded['commanderDamage'];
      if (rawDamage is Map) {
        for (final entry in rawDamage.entries) {
          damage[entry.key.toString()] = (entry.value as num?)?.toInt() ?? 0;
        }
      }

      final savedAtMs = (decoded['savedAtMs'] as num?)?.toInt();
      final savedRunning = decoded['timerRunning'] as bool? ?? false;
      var gameSeconds = (decoded['gameSeconds'] as num?)?.toInt() ?? 0;
      var turnSeconds = (decoded['turnSeconds'] as num?)?.toInt() ?? 0;
      if (savedRunning && savedAtMs != null) {
        final away = max(
          0,
          (DateTime.now().millisecondsSinceEpoch - savedAtMs) ~/ 1000,
        );
        gameSeconds += away;
        turnSeconds += away;
      }

      if (!mounted) return;
      setState(() {
        _playerCount = ((decoded['playerCount'] as num?)?.toInt() ?? 4)
            .clamp(2, 6);
        _players = restoredPlayers.take(6).toList();
        _commanderDamage = damage;
        _monarchPlayerId = decoded['monarchPlayerId'] as String?;
        _initiativePlayerId = decoded['initiativePlayerId'] as String?;
        _isDay = decoded['isDay'] as bool? ?? true;
        _themeIndex = ((decoded['themeIndex'] as num?)?.toInt() ?? 0)
            .clamp(0, _themeNames.length - 1);
        _gameBaseSeconds = gameSeconds;
        _turnBaseSeconds = turnSeconds;
        _timerStartedAtMs = savedRunning
            ? DateTime.now().millisecondsSinceEpoch
            : null;
        _recalculateAllCommanderSummaries();
      });
      if (_timerRunning) _startTicker();
    } catch (_) {
      // A corrupt local snapshot must never prevent the counter from opening.
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final state = <String, Object?>{
      'playerCount': _playerCount,
      'players': _players.map((player) => player.toJson()).toList(),
      'commanderDamage': _commanderDamage,
      'monarchPlayerId': _monarchPlayerId,
      'initiativePlayerId': _initiativePlayerId,
      'isDay': _isDay,
      'themeIndex': _themeIndex,
      'gameSeconds': _gameSeconds,
      'turnSeconds': _turnSeconds,
      'timerRunning': _timerRunning,
      'savedAtMs': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_storageKey, jsonEncode(state));
  }

  _GameSnapshot _snapshot() => _GameSnapshot(
        playerCount: _playerCount,
        players: List<PlayerState>.of(_players),
        commanderDamage: Map<String, int>.of(_commanderDamage),
        monarchPlayerId: _monarchPlayerId,
        initiativePlayerId: _initiativePlayerId,
        isDay: _isDay,
        themeIndex: _themeIndex,
        gameSeconds: _gameSeconds,
        turnSeconds: _turnSeconds,
        timerRunning: _timerRunning,
      );

  void _checkpoint() {
    _history.add(_snapshot());
    if (_history.length > 50) _history.removeAt(0);
    _redo.clear();
  }

  void _commit(VoidCallback mutation) {
    _checkpoint();
    setState(mutation);
    unawaited(_saveState());
  }

  void _restoreSnapshot(_GameSnapshot snapshot) {
    _ticker?.cancel();
    _playerCount = snapshot.playerCount;
    _players = List<PlayerState>.of(snapshot.players);
    _commanderDamage = Map<String, int>.of(snapshot.commanderDamage);
    _monarchPlayerId = snapshot.monarchPlayerId;
    _initiativePlayerId = snapshot.initiativePlayerId;
    _isDay = snapshot.isDay;
    _themeIndex = snapshot.themeIndex;
    _gameBaseSeconds = snapshot.gameSeconds;
    _turnBaseSeconds = snapshot.turnSeconds;
    _timerStartedAtMs = snapshot.timerRunning
        ? DateTime.now().millisecondsSinceEpoch
        : null;
    if (_timerRunning) _startTicker();
  }

  void _undo() {
    if (_history.isEmpty) return;
    final previous = _history.removeLast();
    _redo.add(_snapshot());
    setState(() => _restoreSnapshot(previous));
    unawaited(_saveState());
  }

  void _redoAction() {
    if (_redo.isEmpty) return;
    final next = _redo.removeLast();
    _history.add(_snapshot());
    setState(() => _restoreSnapshot(next));
    unawaited(_saveState());
  }

  void _changeLife(int index, int delta) {
    _commit(() {
      _players[index] = _players[index].copyWith(
        life: _players[index].life + delta,
      );
    });
  }

  void _changePoison(int index, int delta) {
    final next = (_players[index].poison + delta).clamp(0, 999);
    if (next == _players[index].poison) return;
    _commit(() {
      _players[index] = _players[index].copyWith(poison: next);
    });
  }

  String _damageKey(int sourceIndex, int commanderSlot, int targetIndex) =>
      '${_players[sourceIndex].id}|$commanderSlot|${_players[targetIndex].id}';

  int _damageValue(int sourceIndex, int commanderSlot, int targetIndex) =>
      _commanderDamage[_damageKey(sourceIndex, commanderSlot, targetIndex)] ?? 0;

  void _changeCommanderDamage(
    int sourceIndex,
    int commanderSlot,
    int targetIndex,
    int delta,
  ) {
    final key = _damageKey(sourceIndex, commanderSlot, targetIndex);
    final current = _commanderDamage[key] ?? 0;
    final next = (current + delta).clamp(0, 999);
    if (next == current) return;

    _commit(() {
      if (next == 0) {
        _commanderDamage.remove(key);
      } else {
        _commanderDamage[key] = next;
      }
      _recalculateCommanderSummary(targetIndex);
    });
  }

  void _recalculateCommanderSummary(int targetIndex) {
    var highest = 0;
    for (var source = 0; source < _playerCount; source++) {
      if (source == targetIndex) continue;
      highest = max(highest, _damageValue(source, 0, targetIndex));
      if (_players[source].partnerCommanderName.trim().isNotEmpty) {
        highest = max(highest, _damageValue(source, 1, targetIndex));
      }
    }
    _players[targetIndex] = _players[targetIndex].copyWith(
      commanderDamageSummary: highest,
    );
  }

  void _recalculateAllCommanderSummaries() {
    for (var target = 0; target < _players.length; target++) {
      _recalculateCommanderSummary(target);
    }
  }

  void _changeCounter(int index, String name, int delta) {
    final values = Map<String, int>.of(_players[index].counters);
    final current = values[name] ?? 0;
    final next = (current + delta).clamp(0, 99999);
    if (current == next) return;
    _commit(() {
      values[name] = next;
      _players[index] = _players[index].copyWith(counters: values);
    });
  }

  void _changeToken(int index, String name, int delta) {
    final values = Map<String, int>.of(_players[index].tokens);
    final current = values[name] ?? 0;
    final next = (current + delta).clamp(0, 99999);
    if (current == next) return;
    _commit(() {
      values[name] = next;
      _players[index] = _players[index].copyWith(tokens: values);
    });
  }

  void _changeCommanderCasts(int index, bool partner, int delta) {
    final player = _players[index];
    final current = partner ? player.partnerCommanderCasts : player.commanderCasts;
    final next = (current + delta).clamp(0, 99);
    if (current == next) return;
    _commit(() {
      _players[index] = partner
          ? player.copyWith(partnerCommanderCasts: next)
          : player.copyWith(commanderCasts: next);
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
    if (selected == null || selected == _playerCount || !mounted) return;

    if (selected < _playerCount) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reduce player count?'),
          content: const Text(
            'Hidden players keep their names and counters so you can restore them later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    _commit(() {
      _playerCount = selected;
      if (_monarchPlayerId != null &&
          !_players.take(selected).any((p) => p.id == _monarchPlayerId)) {
        _monarchPlayerId = null;
      }
      if (_initiativePlayerId != null &&
          !_players.take(selected).any((p) => p.id == _initiativePlayerId)) {
        _initiativePlayerId = null;
      }
      _recalculateAllCommanderSummaries();
    });
  }

  Future<void> _showPoisonControls(int index) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111116),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
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
                  _SheetHandle(),
                  const SizedBox(height: 18),
                  Text(
                    '${player.name.toUpperCase()} — POISON',
                    style: TextStyle(
                      color: lethal
                          ? const Color(0xFFFF5C5C)
                          : const Color(0xFFC47AFF),
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
                        child: _LargeAdjustButton(
                          label: '−',
                          onPressed: player.poison > 0 ? () => change(-1) : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _LargeAdjustButton(
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
                              _commit(() {
                                _players[index] =
                                    _players[index].copyWith(poison: 0);
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
      ),
    );
  }

  Future<void> _showCommanderDamageControls(int targetIndex) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111116),
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final rows = <Widget>[];
            for (var source = 0; source < _playerCount; source++) {
              if (source == targetIndex) continue;
              final sourcePlayer = _players[source];
              rows.add(
                _CommanderDamageRow(
                  playerName: sourcePlayer.name,
                  commanderName: sourcePlayer.commanderName,
                  imageUrl: sourcePlayer.commanderImageUrl,
                  damage: _damageValue(source, 0, targetIndex),
                  onMinus: () {
                    _changeCommanderDamage(source, 0, targetIndex, -1);
                    setSheetState(() {});
                  },
                  onPlus: () {
                    _changeCommanderDamage(source, 0, targetIndex, 1);
                    setSheetState(() {});
                  },
                ),
              );
              if (sourcePlayer.partnerCommanderName.trim().isNotEmpty) {
                rows.add(
                  _CommanderDamageRow(
                    playerName: sourcePlayer.name,
                    commanderName: sourcePlayer.partnerCommanderName,
                    imageUrl: sourcePlayer.partnerImageUrl,
                    damage: _damageValue(source, 1, targetIndex),
                    onMinus: () {
                      _changeCommanderDamage(source, 1, targetIndex, -1);
                      setSheetState(() {});
                    },
                    onPlus: () {
                      _changeCommanderDamage(source, 1, targetIndex, 1);
                      setSheetState(() {});
                    },
                  ),
                );
              }
            }

            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _SheetHandle(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'COMMANDER DAMAGE → ${_players[targetIndex].name.toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showCommanderMatrix(),
                          icon: const Icon(Icons.grid_on_outlined),
                          label: const Text('MATRIX'),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      '21 combat damage from one commander is lethal. Partner commanders are tracked separately.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 22),
                      children: rows,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showCommanderMatrix() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111116),
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.88,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              _SheetHandle(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'COMMANDER DAMAGE MATRIX',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('SOURCE')),
                        for (var target = 0; target < _playerCount; target++)
                          DataColumn(label: Text(_players[target].name)),
                      ],
                      rows: [
                        for (var source = 0; source < _playerCount; source++)
                          ..._matrixRowsForSource(source),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DataRow> _matrixRowsForSource(int sourceIndex) {
    final source = _players[sourceIndex];
    final slots = <int>[0];
    if (source.partnerCommanderName.trim().isNotEmpty) slots.add(1);
    return [
      for (final slot in slots)
        DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: 150,
                child: Text(
                  '${source.name}\n${slot == 0 ? source.commanderName : source.partnerCommanderName}',
                ),
              ),
            ),
            for (var target = 0; target < _playerCount; target++)
              DataCell(
                Text(
                  target == sourceIndex
                      ? '—'
                      : '${_damageValue(sourceIndex, slot, target)}',
                  style: TextStyle(
                    color: target != sourceIndex &&
                            _damageValue(sourceIndex, slot, target) >= 21
                        ? const Color(0xFFFF5C5C)
                        : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: target == sourceIndex
                    ? null
                    : () {
                        Navigator.pop(context);
                        _showCommanderDamageControls(target);
                      },
              ),
          ],
        ),
    ];
  }

  Future<void> _showPlayerSettings(int index) async {
    final nameController = TextEditingController(text: _players[index].name);
    final commanderController =
        TextEditingController(text: _players[index].commanderName);
    final partnerController =
        TextEditingController(text: _players[index].partnerCommanderName);
    final commanderImageController =
        TextEditingController(text: _players[index].commanderImageUrl);
    final partnerImageController =
        TextEditingController(text: _players[index].partnerImageUrl);
    final backgroundController =
        TextEditingController(text: _players[index].backgroundImageUrl);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E0E13),
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.94,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final player = _players[index];

            void refresh() => setSheetState(() {});

            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _SheetHandle(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                    child: Row(
                      children: [
                        _CommanderAvatar(
                          imageUrl: player.commanderImageUrl,
                          accent: player.accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.name.toUpperCase(),
                                style: TextStyle(
                                  color: player.accent,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                '${player.commanderName} • Tax ${player.commanderTax}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        18,
                        8,
                        18,
                        28 + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      children: [
                        _SectionTitle('IDENTITY & ART'),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Player name'),
                        ),
                        TextField(
                          controller: commanderController,
                          decoration:
                              const InputDecoration(labelText: 'Commander name'),
                        ),
                        TextField(
                          controller: partnerController,
                          decoration: const InputDecoration(
                            labelText: 'Partner commander (optional)',
                          ),
                        ),
                        TextField(
                          controller: commanderImageController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Commander portrait image URL (optional)',
                          ),
                        ),
                        TextField(
                          controller: partnerImageController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Partner portrait image URL (optional)',
                          ),
                        ),
                        TextField(
                          controller: backgroundController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Panel fantasy artwork URL (optional)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              _commit(() {
                                _players[index] = player.copyWith(
                                  name: nameController.text.trim().isEmpty
                                      ? player.name
                                      : nameController.text.trim(),
                                  commanderName:
                                      commanderController.text.trim().isEmpty
                                          ? 'Commander'
                                          : commanderController.text.trim(),
                                  partnerCommanderName:
                                      partnerController.text.trim(),
                                  commanderImageUrl:
                                      commanderImageController.text.trim(),
                                  partnerImageUrl:
                                      partnerImageController.text.trim(),
                                  backgroundImageUrl:
                                      backgroundController.text.trim(),
                                );
                                _recalculateAllCommanderSummaries();
                              });
                              refresh();
                            },
                            child: const Text('SAVE IDENTITY & ART'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionTitle('STARTING LIFE'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final value in const [20, 30, 40])
                              ChoiceChip(
                                label: Text('$value'),
                                selected: player.startingLife == value,
                                onSelected: (_) {
                                  _setStartingLife(index, value);
                                  refresh();
                                },
                              ),
                            ActionChip(
                              label: Text('Custom: ${player.startingLife}'),
                              onPressed: () async {
                                await _showCustomStartingLife(index);
                                refresh();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SectionTitle('PLAYER COLOR'),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final color in _accents)
                              InkWell(
                                onTap: () {
                                  _commit(() {
                                    _players[index] =
                                        player.copyWith(accent: color);
                                  });
                                  refresh();
                                },
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: player.accent == color
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SectionTitle('COMMANDER TAX'),
                        _ValueRow(
                          label: player.commanderName,
                          subtitle:
                              '${player.commanderCasts} command-zone casts • Tax ${player.commanderTax}',
                          value: player.commanderTax,
                          onMinus: () {
                            _changeCommanderCasts(index, false, -1);
                            refresh();
                          },
                          onPlus: () {
                            _changeCommanderCasts(index, false, 1);
                            refresh();
                          },
                        ),
                        if (player.partnerCommanderName.trim().isNotEmpty)
                          _ValueRow(
                            label: player.partnerCommanderName,
                            subtitle:
                                '${player.partnerCommanderCasts} command-zone casts • Tax ${player.partnerCommanderTax}',
                            value: player.partnerCommanderTax,
                            onMinus: () {
                              _changeCommanderCasts(index, true, -1);
                              refresh();
                            },
                            onPlus: () {
                              _changeCommanderCasts(index, true, 1);
                              refresh();
                            },
                          ),
                        const SizedBox(height: 18),
                        _SectionTitle('COUNTERS'),
                        for (final name in _orderedCounterNames(player))
                          _ValueRow(
                            label: name,
                            value: player.counters[name] ?? 0,
                            onMinus: () {
                              _changeCounter(index, name, -1);
                              refresh();
                            },
                            onPlus: () {
                              _changeCounter(index, name, 1);
                              refresh();
                            },
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              final name = await _askForName('Custom counter name');
                              if (name == null || name.isEmpty) return;
                              final counters =
                                  Map<String, int>.of(_players[index].counters);
                              if (counters.containsKey(name)) return;
                              _commit(() {
                                counters[name] = 0;
                                _players[index] =
                                    _players[index].copyWith(counters: counters);
                              });
                              refresh();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('ADD CUSTOM COUNTER'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionTitle('TOKENS'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              label: const Text('Hare Apparent → Rabbit'),
                              onPressed: () {
                                _ensureToken(index, 'Rabbit');
                                refresh();
                              },
                            ),
                            ActionChip(
                              label: const Text('Preston → Illusion'),
                              onPressed: () {
                                _ensureToken(index, 'Illusion');
                                refresh();
                              },
                            ),
                            ActionChip(
                              label: const Text('+ Named token'),
                              onPressed: () async {
                                final name = await _askForName('Token name');
                                if (name == null || name.isEmpty) return;
                                _ensureToken(index, name);
                                refresh();
                              },
                            ),
                          ],
                        ),
                        if (player.tokens.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No named tokens yet.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        for (final name in player.tokens.keys.toList()..sort())
                          _ValueRow(
                            label: name,
                            value: player.tokens[name] ?? 0,
                            onMinus: () {
                              _changeToken(index, name, -1);
                              refresh();
                            },
                            onPlus: () {
                              _changeToken(index, name, 1);
                              refresh();
                            },
                          ),
                        const SizedBox(height: 18),
                        _SectionTitle('PLAYER STATE'),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("City's Blessing"),
                          subtitle: const Text(
                            'This state is tracked independently for each player.',
                          ),
                          value: player.cityBlessing,
                          onChanged: (value) {
                            _commit(() {
                              _players[index] =
                                  player.copyWith(cityBlessing: value);
                            });
                            refresh();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    nameController.dispose();
    commanderController.dispose();
    partnerController.dispose();
    commanderImageController.dispose();
    partnerImageController.dispose();
    backgroundController.dispose();
  }

  List<String> _orderedCounterNames(PlayerState player) {
    final custom = player.counters.keys
        .where((name) => !_builtInCounters.contains(name))
        .toList()
      ..sort();
    return <String>[..._builtInCounters, ...custom];
  }

  void _setStartingLife(int index, int value) {
    _commit(() {
      _players[index] = _players[index].copyWith(
        startingLife: value,
        life: value,
      );
    });
  }

  Future<void> _showCustomStartingLife(int index) async {
    final controller =
        TextEditingController(text: '${_players[index].startingLife}');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom starting life'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Starting life'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              int.tryParse(controller.text.trim()),
            ),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    _setStartingLife(index, value.clamp(1, 999));
  }

  Future<String?> _askForName(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _ensureToken(int index, String name) {
    if (_players[index].tokens.containsKey(name)) return;
    final tokens = Map<String, int>.of(_players[index].tokens)..[name] = 0;
    _commit(() {
      _players[index] = _players[index].copyWith(tokens: tokens);
    });
  }

  Future<void> _showHistory() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111116),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetHandle(),
                const SizedBox(height: 16),
                const Text(
                  'HISTORY',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_history.length} undo state(s) • ${_redo.length} redo state(s)',
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _history.isEmpty
                            ? null
                            : () {
                                _undo();
                                setSheetState(() {});
                              },
                        icon: const Icon(Icons.undo),
                        label: const Text('UNDO'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _redo.isEmpty
                            ? null
                            : () {
                                _redoAction();
                                setSheetState(() {});
                              },
                        icon: const Icon(Icons.redo),
                        label: const Text('REDO'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTableAndTheme() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E0E13),
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.88,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            void refresh() => setSheetState(() {});

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Center(child: _SheetHandle()),
                  const SizedBox(height: 16),
                  const Text(
                    'TABLE STATE & THEME',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('FANTASY THEME'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _themeNames.length; i++)
                        ChoiceChip(
                          label: Text(_themeNames[i]),
                          selected: _themeIndex == i,
                          onSelected: (_) {
                            if (_themeIndex == i) return;
                            _commit(() => _themeIndex = i);
                            refresh();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle('MONARCH'),
                  _PlayerOwnerSelector(
                    value: _monarchPlayerId,
                    players: _players.take(_playerCount).toList(),
                    onChanged: (value) {
                      if (value == _monarchPlayerId) return;
                      _commit(() => _monarchPlayerId = value);
                      refresh();
                    },
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle('INITIATIVE'),
                  _PlayerOwnerSelector(
                    value: _initiativePlayerId,
                    players: _players.take(_playerCount).toList(),
                    onChanged: (value) {
                      if (value == _initiativePlayerId) return;
                      _commit(() => _initiativePlayerId = value);
                      refresh();
                    },
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle('DAY / NIGHT'),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        avatar: const Icon(Icons.light_mode_outlined, size: 17),
                        label: const Text('DAY'),
                        selected: _isDay,
                        onSelected: (_) {
                          if (_isDay) return;
                          _commit(() => _isDay = true);
                          refresh();
                        },
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.dark_mode_outlined, size: 17),
                        label: const Text('NIGHT'),
                        selected: !_isDay,
                        onSelected: (_) {
                          if (!_isDay) return;
                          _commit(() => _isDay = false);
                          refresh();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle('GAME / TURN TIMER'),
                  _LiveTimerPanel(
                    gameSeconds: () => _gameSeconds,
                    turnSeconds: () => _turnSeconds,
                    isRunning: () => _timerRunning,
                    onToggle: _toggleTimer,
                    onNextTurn: _nextTurnTimer,
                    onReset: _resetTimer,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showDiceAndRandomizer() async {
    var result = 'Choose a die, flip a coin, or pick the first player.';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111116),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          void roll(int sides) {
            setSheetState(() {
              result = 'D$sides → ${1 + _random.nextInt(sides)}';
            });
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHandle(),
                  const SizedBox(height: 16),
                  Text(
                    result,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final sides in const [4, 6, 8, 10, 12, 20])
                        FilledButton.tonal(
                          onPressed: () => roll(sides),
                          child: Text('D$sides'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setSheetState(() {
                              result = _random.nextBool() ? 'HEADS' : 'TAILS';
                            });
                          },
                          icon: const Icon(Icons.paid_outlined),
                          label: const Text('COIN FLIP'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final player = _players[_random.nextInt(_playerCount)];
                            setSheetState(() {
                              result = '${player.name.toUpperCase()} STARTS';
                            });
                          },
                          icon: const Icon(Icons.shuffle),
                          label: const Text('RANDOM START'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _toggleTimer() {
    _checkpoint();
    setState(() {
      if (_timerRunning) {
        _gameBaseSeconds = _gameSeconds;
        _turnBaseSeconds = _turnSeconds;
        _timerStartedAtMs = null;
        _ticker?.cancel();
      } else {
        _timerStartedAtMs = DateTime.now().millisecondsSinceEpoch;
        _startTicker();
      }
    });
    unawaited(_saveState());
  }

  void _nextTurnTimer() {
    _checkpoint();
    setState(() {
      _turnBaseSeconds = 0;
      if (_timerRunning) {
        _timerStartedAtMs = DateTime.now().millisecondsSinceEpoch;
        _gameBaseSeconds = _gameSeconds;
      }
    });
    unawaited(_saveState());
  }

  void _resetTimer() {
    _checkpoint();
    setState(() {
      _gameBaseSeconds = 0;
      _turnBaseSeconds = 0;
      _timerStartedAtMs = _timerRunning
          ? DateTime.now().millisecondsSinceEpoch
          : null;
    });
    unawaited(_saveState());
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset game?'),
        content: const Text(
          'Resets gameplay totals and table states. Player names, commanders, colors, artwork, and named token/counter definitions stay configured.',
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
        final player = _players[i];
        _players[i] = player.copyWith(
          life: player.startingLife,
          poison: 0,
          commanderDamageSummary: 0,
          commanderCasts: 0,
          partnerCommanderCasts: 0,
          counters: player.counters.map((key, _) => MapEntry(key, 0)),
          tokens: player.tokens.map((key, _) => MapEntry(key, 0)),
          cityBlessing: false,
        );
      }
      _commanderDamage.clear();
      _monarchPlayerId = null;
      _initiativePlayerId = null;
      _isDay = true;
      _gameBaseSeconds = 0;
      _turnBaseSeconds = 0;
      _timerStartedAtMs = null;
      _ticker?.cancel();
    });
    unawaited(_saveState());
  }

  @override
  Widget build(BuildContext context) {
    final seats = TableLayoutSpec.forPlayerCount(_playerCount);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              bottom: 74,
              child: ColoredBox(
                color: Colors.black,
                child: LayoutBuilder(
                  builder: (context, tableConstraints) => Stack(
                    children: [
                      for (var i = 0; i < seats.length; i++)
                        _positionedSeat(tableConstraints.biggest, seats[i], i),
                    ],
                  ),
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
                  onHistory: _showHistory,
                  onTheme: _showTableAndTheme,
                  onDice: _showDiceAndRandomizer,
                ),
              ),
            ),
          ],
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
          themeIndex: _themeIndex,
          isMonarch: _monarchPlayerId == _players[index].id,
          hasInitiative: _initiativePlayerId == _players[index].id,
          onDecreaseLife: () => _changeLife(index, -1),
          onIncreaseLife: () => _changeLife(index, 1),
          onPoisonTap: () => _showPoisonControls(index),
          onCommanderDamageTap: () => _showCommanderDamageControls(index),
          onSettingsTap: () => _showPlayerSettings(index),
        ),
      ),
    );
  }
}

class _GameSnapshot {
  const _GameSnapshot({
    required this.playerCount,
    required this.players,
    required this.commanderDamage,
    required this.monarchPlayerId,
    required this.initiativePlayerId,
    required this.isDay,
    required this.themeIndex,
    required this.gameSeconds,
    required this.turnSeconds,
    required this.timerRunning,
  });

  final int playerCount;
  final List<PlayerState> players;
  final Map<String, int> commanderDamage;
  final String? monarchPlayerId;
  final String? initiativePlayerId;
  final bool isDay;
  final int themeIndex;
  final int gameSeconds;
  final int turnSeconds;
  final bool timerRunning;
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(999),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFE2C477),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _LargeAdjustButton extends StatelessWidget {
  const _LargeAdjustButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
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

class _CommanderAvatar extends StatelessWidget {
  const _CommanderAvatar({required this.imageUrl, required this.accent});

  final String imageUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final valid = imageUrl.trim().startsWith('http');
    return CircleAvatar(
      radius: 24,
      backgroundColor: accent.withValues(alpha: 0.22),
      foregroundImage: valid ? NetworkImage(imageUrl.trim()) : null,
      child: valid ? null : const Icon(Icons.person_outline),
    );
  }
}

class _CommanderDamageRow extends StatelessWidget {
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

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF17171D),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                  ],
                ),
              ),
              IconButton(onPressed: value > 0 ? onMinus : null, icon: const Icon(Icons.remove)),
              SizedBox(
                width: 42,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(onPressed: onPlus, icon: const Icon(Icons.add)),
            ],
          ),
        ),
      );
}

class _PlayerOwnerSelector extends StatelessWidget {
  const _PlayerOwnerSelector({
    required this.value,
    required this.players,
    required this.onChanged,
  });

  final String? value;
  final List<PlayerState> players;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value ?? '__none__';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF17171D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: selected,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: [
          const DropdownMenuItem(value: '__none__', child: Text('None')),
          for (final player in players)
            DropdownMenuItem(value: player.id, child: Text(player.name)),
        ],
        onChanged: (next) => onChanged(next == '__none__' ? null : next),
      ),
    );
  }
}

class _LiveTimerPanel extends StatefulWidget {
  const _LiveTimerPanel({
    required this.gameSeconds,
    required this.turnSeconds,
    required this.isRunning,
    required this.onToggle,
    required this.onNextTurn,
    required this.onReset,
  });

  final int Function() gameSeconds;
  final int Function() turnSeconds;
  final bool Function() isRunning;
  final VoidCallback onToggle;
  final VoidCallback onNextTurn;
  final VoidCallback onReset;

  @override
  State<_LiveTimerPanel> createState() => _LiveTimerPanelState();
}

class _LiveTimerPanelState extends State<_LiveTimerPanel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF17171D),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TimerReadout(
                      label: 'GAME',
                      value: _format(widget.gameSeconds()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimerReadout(
                      label: 'TURN',
                      value: _format(widget.turnSeconds()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {
                      widget.onToggle();
                      setState(() {});
                    },
                    icon: Icon(widget.isRunning() ? Icons.pause : Icons.play_arrow),
                    label: Text(widget.isRunning() ? 'PAUSE' : 'START'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      widget.onNextTurn();
                      setState(() {});
                    },
                    icon: const Icon(Icons.skip_next),
                    label: const Text('NEXT TURN'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      widget.onReset();
                      setState(() {});
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('RESET'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _TimerReadout extends StatelessWidget {
  const _TimerReadout({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
}
