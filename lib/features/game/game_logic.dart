import 'dart:math' as math;

import '../../data/settings.dart';
import '../../engine/common/bitmask.dart';
import '../../engine/common/board.dart';
import '../../engine/killer/candidates.dart';
import '../../engine/killer/hints.dart';
import '../../engine/killer/level.dart';
import 'game_state.dart';

/// A row, column, block or cage that became completely and correctly filled.
enum UnitKind { row, column, block, cage }

class Unit {
  const Unit(this.kind, this.index, this.cells);

  final UnitKind kind;
  final int index;
  final List<int> cells;
}

/// Outcome of a move: the new state plus events for feedback (haptics,
/// line wave animation, dialogs).
class MoveResult {
  const MoveResult(this.state, {this.mistake = false, this.completed = const []});

  final GameState state;
  final bool mistake;
  final List<Unit> completed;
}

/// Pure game rules (TZ §5.1, §5.2, §5.4). No Flutter, no I/O.
abstract final class GameLogic {
  static const int basePoints = 10;
  static const int unitBonus = 50;
  static const int mistakePenalty = 20;
  static const int fastWindowSeconds = 10;
  static const double fastMultiplier = 1.5;

  /// Score coefficient per level (TZ §5.4).
  static double coefficient(KillerLevel l) => switch (l) {
        KillerLevel.easy => 2,
        KillerLevel.medium => 3,
        KillerLevel.hard => 4,
        KillerLevel.expert => 5.5,
        KillerLevel.devil => 7,
      };

  /// Givens, and correct digits when errors are shown, cannot be changed.
  static bool isLocked(GameState s, int i, AppSettings rules) =>
      s.isGiven(i) ||
      (rules.showErrors && s.values[i] != 0 && !s.isWrong(i));

  static bool _canPlay(GameState s) => s.status == GameStatus.playing;

  static GameState select(GameState s, int i) =>
      _canPlay(s) && s.selected != i ? s.copyWith(selected: i) : s;

  static GameState toggleNotesMode(GameState s) =>
      s.copyWith(notesMode: !s.notesMode);

  /// Number-first mode: pick a digit (tapping it again clears the pick).
  static GameState pickDigit(GameState s, int d) =>
      s.copyWith(pickedDigit: s.pickedDigit == d ? 0 : d);

  static Snapshot _snap(GameState s) => Snapshot(s.values, s.notes);

  static List<Snapshot> _pushed(GameState s) => [...s.history, _snap(s)];

  /// Enters digit [d] (or toggles the pencil mark in notes mode) in the
  /// selected cell.
  static MoveResult input(GameState s, int d, AppSettings rules) {
    final i = s.selected;
    if (!_canPlay(s) || i < 0 || d < 1 || d > 9) return MoveResult(s);

    if (s.notesMode) {
      if (s.values[i] != 0) return MoveResult(s);
      final notes = [...s.notes];
      notes[i] ^= bit(d);
      return MoveResult(s.copyWith(
        notes: List.unmodifiable(notes),
        history: _pushed(s),
      ));
    }

    if (isLocked(s, i, rules) || s.values[i] == d) return MoveResult(s);

    final values = [...s.values]..[i] = d;
    final notes = [...s.notes]..[i] = 0;
    final correct = d == s.puzzle.solution[i];
    final level = s.puzzle.level;
    final k = coefficient(level);
    var score = s.score;
    var mistakes = s.mistakes;
    var lastCorrectAt = s.lastCorrectAt;
    var status = s.status;
    var mistake = false;
    var completed = const <Unit>[];
    var scoredCells = s.scoredCells;
    var scoredUnits = s.scoredUnits;

    if (correct) {
      completed = _completedUnits(s, values, i);
      // Points only the first time a cell / unit is solved.
      if (!scoredCells.contains(i)) {
        final fast = s.elapsed - s.lastCorrectAt < fastWindowSeconds;
        score += (basePoints * k * (fast ? fastMultiplier : 1)).round();
        lastCorrectAt = s.elapsed;
        scoredCells = {...scoredCells, i};
      }
      for (final u in completed) {
        final key = u.kind.index * 100 + u.index;
        if (!scoredUnits.contains(key)) {
          score += (unitBonus * k).round();
          scoredUnits = {...scoredUnits, key};
        }
      }
    } else if (rules.showErrors) {
      mistake = true;
      mistakes++;
      score = math.max(0, score - mistakePenalty);
      if (rules.mistakeLimit &&
          !s.unlimited &&
          mistakes >= AppSettings.maxMistakes) {
        status = GameStatus.lost;
      }
    }

    // A digit the player knows is wrong should not wipe their notes.
    if (rules.autoRemoveNotes && (correct || !rules.showErrors)) {
      final b = bit(d);
      for (final p in peers[i]) {
        notes[p] &= ~b;
      }
      for (final c in s.puzzle.cages[s.puzzle.cageOf[i]].cells) {
        notes[c] &= ~b;
      }
    }

    if (_solved(s, values)) status = GameStatus.won;

    return MoveResult(
      s.copyWith(
        values: List.unmodifiable(values),
        notes: List.unmodifiable(notes),
        history: _pushed(s),
        scoredCells: scoredCells,
        scoredUnits: scoredUnits,
        score: score,
        mistakes: mistakes,
        lastCorrectAt: lastCorrectAt,
        status: status,
      ),
      mistake: mistake,
      completed: completed,
    );
  }

  /// "Qo'llash" in the hint panel (TZ §5.3): removes wrong digits, places
  /// the hinted digit (no points, TZ §5.4) or narrows pencil marks.
  static GameState applyHint(GameState s, Hint h, AppSettings rules) {
    if (!_canPlay(s)) return s;
    final values = [...s.values];
    final notes = [...s.notes];
    var scoredCells = s.scoredCells;
    var scoredUnits = s.scoredUnits;
    var status = s.status;
    var selected = s.selected;
    switch (h.kind) {
      case HintKind.wrongDigits:
        for (final i in h.focus) {
          values[i] = 0;
        }
      case HintKind.pairSum:
        for (final e in h.allowed.entries) {
          notes[e.key] = e.value;
        }
      default:
        final i = h.target!, d = h.digit!;
        values[i] = d;
        notes[i] = 0;
        selected = i;
        if (rules.autoRemoveNotes) {
          for (final p in peers[i]) {
            notes[p] &= ~bit(d);
          }
          for (final c in s.puzzle.cages[s.puzzle.cageOf[i]].cells) {
            notes[c] &= ~bit(d);
          }
        }
        // Counted as solved so it can never earn points later.
        scoredCells = {...scoredCells, i};
        scoredUnits = {
          ...scoredUnits,
          for (final u in _completedUnits(s, values, i))
            u.kind.index * 100 + u.index,
        };
        if (_solved(s, values)) status = GameStatus.won;
    }
    return s.copyWith(
      values: List.unmodifiable(values),
      notes: List.unmodifiable(notes),
      history: _pushed(s),
      scoredCells: scoredCells,
      scoredUnits: scoredUnits,
      status: status,
      selected: selected,
    );
  }

  /// Clears the selected cell's digit, or its notes if it has no digit.
  static GameState erase(GameState s, AppSettings rules) {
    final i = s.selected;
    if (!_canPlay(s) || i < 0 || isLocked(s, i, rules)) return s;
    if (s.values[i] == 0 && s.notes[i] == 0) return s;
    final values = [...s.values];
    final notes = [...s.notes];
    if (values[i] != 0) {
      values[i] = 0;
    } else {
      notes[i] = 0;
    }
    return s.copyWith(
      values: List.unmodifiable(values),
      notes: List.unmodifiable(notes),
      history: _pushed(s),
    );
  }

  /// Restores the previous board. Mistakes and score are not refunded.
  static GameState undo(GameState s) {
    if (!_canPlay(s) || s.history.isEmpty) return s;
    final last = s.history.last;
    return s.copyWith(
      values: last.values,
      notes: last.notes,
      history: s.history.sublist(0, s.history.length - 1),
    );
  }

  /// Tez qoralama: fills every empty cell with its current candidates
  /// (houses and cage sums, TZ §5.2).
  static GameState fastPencil(GameState s) {
    if (!_canPlay(s)) return s;
    final c = candidates(s.puzzle.cages, s.puzzle.cageOf, s.values);
    final notes = [
      for (var i = 0; i < 81; i++) s.values[i] == 0 ? c.cand[i] : 0,
    ];
    return s.copyWith(
      notes: List.unmodifiable(notes),
      history: _pushed(s),
      fastPencilUsed: s.fastPencilUsed + 1,
    );
  }

  /// Crosses a combo out in the cage panel, or restores it.
  static GameState toggleCombo(GameState s, int cage, int mask) {
    final set = {...?s.crossed[cage]};
    if (!set.remove(mask)) set.add(mask);
    return s.copyWith(crossed: {...s.crossed, cage: set});
  }

  static GameState tick(GameState s) =>
      _canPlay(s) ? s.copyWith(elapsed: s.elapsed + 1) : s;

  static GameState pause(GameState s) =>
      s.status == GameStatus.playing ? s.copyWith(status: GameStatus.paused) : s;

  static GameState resume(GameState s) =>
      s.status == GameStatus.paused ? s.copyWith(status: GameStatus.playing) : s;

  /// "Davom etish" in the loss dialog: mistakes reset, no limit any more.
  static GameState continueAfterLoss(GameState s) => s.status == GameStatus.lost
      ? s.copyWith(mistakes: 0, unlimited: true, status: GameStatus.playing)
      : s;

  static bool _solved(GameState s, List<int> values) {
    for (var i = 0; i < 81; i++) {
      if (values[i] != s.puzzle.solution[i]) return false;
    }
    return true;
  }

  static List<Unit> _completedUnits(GameState s, List<int> values, int i) {
    final sol = s.puzzle.solution;
    bool full(List<int> cells) => cells.every((c) => values[c] == sol[c]);
    final cageIndex = s.puzzle.cageOf[i];
    final candidates = [
      Unit(UnitKind.row, rowOf[i], houses[rowOf[i]]),
      Unit(UnitKind.column, colOf[i], houses[9 + colOf[i]]),
      Unit(UnitKind.block, blockOf[i], houses[18 + blockOf[i]]),
      Unit(UnitKind.cage, cageIndex, s.puzzle.cages[cageIndex].cells),
    ];
    return [
      for (final u in candidates)
        if (full(u.cells)) u,
    ];
  }
}
