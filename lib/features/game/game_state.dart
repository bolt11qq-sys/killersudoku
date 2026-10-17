import 'package:flutter/foundation.dart';

import '../../engine/killer/puzzle.dart';

enum GameStatus { playing, paused, won, lost }

/// Board contents restored by "Orqaga" (undo).
@immutable
class Snapshot {
  const Snapshot(this.values, this.notes);

  final List<int> values;
  final List<int> notes;

  Map<String, Object> toJson() => {'v': values, 'n': notes};

  factory Snapshot.fromJson(Map<String, Object?> j) => Snapshot(
        List<int>.unmodifiable(j['v']! as List<Object?>),
        List<int>.unmodifiable(j['n']! as List<Object?>),
      );
}

/// Full state of one game (TZ §7.1 `current_game`). Immutable; every move
/// produces a new instance through `GameLogic`.
@immutable
class GameState {
  const GameState({
    required this.puzzle,
    required this.values,
    required this.notes,
    this.crossed = const {},
    this.history = const [],
    this.scoredCells = const {},
    this.scoredUnits = const {},
    this.selected = -1,
    this.notesMode = false,
    this.pickedDigit = 0,
    this.mistakes = 0,
    this.unlimited = false,
    this.score = 0,
    this.elapsed = 0,
    this.lastCorrectAt = -1000,
    this.hintsUsed = 0,
    this.fastPencilUsed = 0,
    this.status = GameStatus.playing,
    this.saved = false,
    this.daily = false,
  });

  /// A fresh game: givens pre-filled, centre cell selected.
  factory GameState.start(KillerPuzzle puzzle, {bool daily = false}) =>
      GameState(
        puzzle: puzzle,
        values: List<int>.unmodifiable(puzzle.givens),
        notes: List<int>.unmodifiable(List<int>.filled(81, 0)),
        selected: 40,
        daily: daily,
      );

  final KillerPuzzle puzzle;

  /// 81 digits, 0 = empty. Includes givens.
  final List<int> values;

  /// 81 pencil-mark masks.
  final List<int> notes;

  /// Cage index → combo masks the player crossed out in the cage panel.
  final Map<int, Set<int>> crossed;
  final List<Snapshot> history;

  /// Cells and units (`kind * 100 + index`) that already earned points, so
  /// undo + re-entry cannot farm score.
  final Set<int> scoredCells;
  final Set<int> scoredUnits;
  final int selected;
  final bool notesMode;

  /// Digit chosen in number-first mode (0 = none).
  final int pickedDigit;
  final int mistakes;

  /// The player continued after reaching the mistake limit.
  final bool unlimited;
  final int score;

  /// Play time in seconds.
  final int elapsed;

  /// [elapsed] at the last correct digit, for the speed bonus.
  final int lastCorrectAt;
  final int hintsUsed;
  final int fastPencilUsed;
  final GameStatus status;

  /// Starred by the player (TZ §3.3).
  final bool saved;
  final bool daily;

  bool get isOver => status == GameStatus.won || status == GameStatus.lost;

  bool isGiven(int i) => puzzle.givens[i] != 0;

  bool isWrong(int i) => values[i] != 0 && values[i] != puzzle.solution[i];

  /// Cells the player has to fill.
  int get toFill => 81 - puzzle.givens.where((g) => g != 0).length;

  /// Correctly filled non-given cells.
  int get filledCorrect {
    var n = 0;
    for (var i = 0; i < 81; i++) {
      if (!isGiven(i) && values[i] != 0 && values[i] == puzzle.solution[i]) {
        n++;
      }
    }
    return n;
  }

  /// Correct placements of digit [d] on the board (givens included).
  int placedCorrect(int d) {
    var n = 0;
    for (var i = 0; i < 81; i++) {
      if (values[i] == d && puzzle.solution[i] == d) n++;
    }
    return n;
  }

  GameState copyWith({
    List<int>? values,
    List<int>? notes,
    Map<int, Set<int>>? crossed,
    List<Snapshot>? history,
    Set<int>? scoredCells,
    Set<int>? scoredUnits,
    int? selected,
    bool? notesMode,
    int? pickedDigit,
    int? mistakes,
    bool? unlimited,
    int? score,
    int? elapsed,
    int? lastCorrectAt,
    int? hintsUsed,
    int? fastPencilUsed,
    GameStatus? status,
    bool? saved,
  }) {
    return GameState(
      puzzle: puzzle,
      values: values ?? this.values,
      notes: notes ?? this.notes,
      crossed: crossed ?? this.crossed,
      history: history ?? this.history,
      scoredCells: scoredCells ?? this.scoredCells,
      scoredUnits: scoredUnits ?? this.scoredUnits,
      selected: selected ?? this.selected,
      notesMode: notesMode ?? this.notesMode,
      pickedDigit: pickedDigit ?? this.pickedDigit,
      mistakes: mistakes ?? this.mistakes,
      unlimited: unlimited ?? this.unlimited,
      score: score ?? this.score,
      elapsed: elapsed ?? this.elapsed,
      lastCorrectAt: lastCorrectAt ?? this.lastCorrectAt,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      fastPencilUsed: fastPencilUsed ?? this.fastPencilUsed,
      status: status ?? this.status,
      saved: saved ?? this.saved,
      daily: daily,
    );
  }

  Map<String, Object> toJson() => {
        'v': 1,
        'puzzle': puzzle.toJson(),
        'values': values,
        'notes': notes,
        'crossed': {
          for (final e in crossed.entries) '${e.key}': e.value.toList(),
        },
        'history': [for (final s in history) s.toJson()],
        'scoredCells': scoredCells.toList(),
        'scoredUnits': scoredUnits.toList(),
        'selected': selected,
        'notesMode': notesMode,
        'pickedDigit': pickedDigit,
        'mistakes': mistakes,
        'unlimited': unlimited,
        'score': score,
        'elapsed': elapsed,
        'lastCorrectAt': lastCorrectAt,
        'hintsUsed': hintsUsed,
        'fastPencilUsed': fastPencilUsed,
        // A running game is always restored paused.
        'status': (status == GameStatus.playing ? GameStatus.paused : status)
            .name,
        'saved': saved,
        'daily': daily,
      };

  factory GameState.fromJson(Map<String, Object?> j) {
    List<int> ints(String k) =>
        List<int>.unmodifiable(j[k]! as List<Object?>);
    Map<String, Object?> obj(Object? o) =>
        (o! as Map<Object?, Object?>).cast<String, Object?>();
    return GameState(
      puzzle: KillerPuzzle.fromJson(obj(j['puzzle'])),
      values: ints('values'),
      notes: ints('notes'),
      crossed: {
        for (final e in obj(j['crossed']).entries)
          int.parse(e.key): (e.value! as List<Object?>).cast<int>().toSet(),
      },
      history: [
        for (final s in j['history']! as List<Object?>) Snapshot.fromJson(obj(s)),
      ],
      scoredCells: {...?(j['scoredCells'] as List<Object?>?)?.cast<int>()},
      scoredUnits: {...?(j['scoredUnits'] as List<Object?>?)?.cast<int>()},
      selected: j['selected']! as int,
      notesMode: j['notesMode']! as bool,
      pickedDigit: (j['pickedDigit'] as int?) ?? 0,
      mistakes: j['mistakes']! as int,
      unlimited: j['unlimited']! as bool,
      score: j['score']! as int,
      elapsed: j['elapsed']! as int,
      lastCorrectAt: j['lastCorrectAt']! as int,
      hintsUsed: j['hintsUsed']! as int,
      fastPencilUsed: j['fastPencilUsed']! as int,
      status: GameStatus.values.byName(j['status']! as String),
      saved: (j['saved'] as bool?) ?? false,
      daily: (j['daily'] as bool?) ?? false,
    );
  }
}
