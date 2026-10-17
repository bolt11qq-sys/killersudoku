import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../engine/killer/puzzle.dart';
import '../features/game/game_state.dart';
import 'game_record.dart';

/// Persistence for games (TZ §7.1). Values are stored as JSON strings so no
/// Hive type adapters are needed and the export (stage 7) is trivial.
abstract class GameRepository {
  GameState? loadCurrent();
  Future<void> saveCurrent(GameState s);
  Future<void> clearCurrent();

  List<GameRecord> history();
  Future<void> addRecord(GameRecord r);

  bool isSaved(KillerPuzzle p);
  Future<void> setSaved(KillerPuzzle p, {required bool saved});
}

/// Overridden in `main()` (Hive) and in tests ([MemoryGameRepository]).
final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => throw UnimplementedError('GameRepository not provided'),
);

String _savedKey(KillerPuzzle p) => '${p.level.id}:${p.seed}';

class HiveGameRepository implements GameRepository {
  HiveGameRepository(this._current, this._history, this._saved);

  static const currentBox = 'current_game';
  static const historyBox = 'history';
  static const savedBox = 'saved';
  static const _currentKey = 'game';

  /// Opens all boxes; call after `Hive.initFlutter()`.
  static Future<HiveGameRepository> open() async => HiveGameRepository(
        await Hive.openBox<String>(currentBox),
        await Hive.openBox<String>(historyBox),
        await Hive.openBox<String>(savedBox),
      );

  final Box<String> _current;
  final Box<String> _history;
  final Box<String> _saved;

  Map<String, Object?> _decode(String s) =>
      (jsonDecode(s) as Map<Object?, Object?>).cast<String, Object?>();

  @override
  GameState? loadCurrent() {
    final raw = _current.get(_currentKey);
    if (raw == null) return null;
    try {
      return GameState.fromJson(_decode(raw));
    } on Object {
      // A corrupt or outdated save must never block the app.
      return null;
    }
  }

  @override
  Future<void> saveCurrent(GameState s) =>
      _current.put(_currentKey, jsonEncode(s.toJson()));

  @override
  Future<void> clearCurrent() => _current.delete(_currentKey);

  @override
  List<GameRecord> history() => [
        for (final raw in _history.values) GameRecord.fromJson(_decode(raw)),
      ];

  @override
  Future<void> addRecord(GameRecord r) async {
    await _history.add(jsonEncode(r.toJson()));
  }

  @override
  bool isSaved(KillerPuzzle p) => _saved.containsKey(_savedKey(p));

  @override
  Future<void> setSaved(KillerPuzzle p, {required bool saved}) => saved
      ? _saved.put(_savedKey(p), jsonEncode(p.toJson()))
      : _saved.delete(_savedKey(p));
}

/// In-memory repository for tests.
class MemoryGameRepository implements GameRepository {
  String? current;
  final List<GameRecord> records = [];
  final Map<String, KillerPuzzle> saved = {};

  @override
  GameState? loadCurrent() => current == null
      ? null
      : GameState.fromJson(
          (jsonDecode(current!) as Map<Object?, Object?>).cast<String, Object?>(),
        );

  @override
  Future<void> saveCurrent(GameState s) async =>
      current = jsonEncode(s.toJson());

  @override
  Future<void> clearCurrent() async => current = null;

  @override
  List<GameRecord> history() => List.of(records);

  @override
  Future<void> addRecord(GameRecord r) async => records.add(r);

  @override
  bool isSaved(KillerPuzzle p) => saved.containsKey(_savedKey(p));

  @override
  Future<void> setSaved(KillerPuzzle p, {required bool saved}) async {
    if (saved) {
      this.saved[_savedKey(p)] = p;
    } else {
      this.saved.remove(_savedKey(p));
    }
  }
}
