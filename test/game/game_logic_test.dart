import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/data/settings.dart';
import 'package:killer_sudoku/engine/common/bitmask.dart';
import 'package:killer_sudoku/engine/common/board.dart';
import 'package:killer_sudoku/engine/killer/generator.dart';
import 'package:killer_sudoku/engine/killer/level.dart';
import 'package:killer_sudoku/engine/killer/puzzle.dart';
import 'package:killer_sudoku/features/game/game_logic.dart';
import 'package:killer_sudoku/features/game/game_state.dart';

void main() {
  late KillerPuzzle puzzle;
  const rules = AppSettings();

  setUpAll(() => puzzle = generate(KillerLevel.medium, 11));

  GameState fresh() => GameState.start(puzzle);
  int sol(int i) => puzzle.solution[i];
  int wrong(int i) => sol(i) % 9 + 1;
  GameState at(GameState s, int i) => GameLogic.select(s, i);
  GameState put(GameState s, int i, int d) =>
      GameLogic.input(at(s, i), d, rules).state;

  group('input', () {
    test('correct digit scores base × coefficient', () {
      final s = put(fresh(), 0, sol(0));
      expect(s.values[0], sol(0));
      // Medium coefficient 3; first digit is not within 10 s of a previous one.
      expect(s.score, 30);
      expect(s.mistakes, 0);
      expect(s.history, hasLength(1));
    });

    test('speed bonus within 10 seconds of the previous correct digit', () {
      var s = put(fresh(), 0, sol(0));
      for (var t = 0; t < 5; t++) {
        s = GameLogic.tick(s);
      }
      s = put(s, 1, sol(1));
      expect(s.score, 30 + 45);
      for (var t = 0; t < 10; t++) {
        s = GameLogic.tick(s);
      }
      s = put(s, 2, sol(2));
      expect(s.score, 30 + 45 + 30);
    });

    test('wrong digit counts a mistake, costs 20, never below 0', () {
      final r = GameLogic.input(at(fresh(), 0), wrong(0), rules);
      expect(r.mistake, isTrue);
      expect(r.state.mistakes, 1);
      expect(r.state.score, 0);
      final s = put(put(fresh(), 1, sol(1)), 0, wrong(0));
      expect(s.score, 10);
    });

    test('third mistake loses when the limit is on', () {
      var s = fresh();
      for (final i in [0, 1, 2]) {
        s = put(s, i, wrong(i));
      }
      expect(s.status, GameStatus.lost);
      expect(put(s, 3, sol(3)), same(s), reason: 'no moves after loss');
    });

    test('no loss with the limit off', () {
      const noLimit = AppSettings(mistakeLimit: false);
      var s = fresh();
      for (final i in [0, 1, 2, 3]) {
        s = GameLogic.input(at(s, i), wrong(i), noLimit).state;
      }
      expect(s.mistakes, 4);
      expect(s.status, GameStatus.playing);
    });

    test('continue after loss resets mistakes and removes the limit', () {
      var s = fresh();
      for (final i in [0, 1, 2]) {
        s = put(s, i, wrong(i));
      }
      s = GameLogic.continueAfterLoss(s);
      expect(s.status, GameStatus.playing);
      expect(s.mistakes, 0);
      expect(s.unlimited, isTrue);
      for (final i in [3, 4, 5]) {
        s = put(s, i, wrong(i));
      }
      expect(s.status, GameStatus.playing);
    });

    test('correct digits are locked when errors are shown', () {
      final s = put(fresh(), 0, sol(0));
      expect(put(s, 0, wrong(0)), same(s));
      expect(GameLogic.erase(s, rules), same(s));
      // With errors hidden the player may change anything.
      const hidden = AppSettings(showErrors: false);
      final r = GameLogic.input(s, wrong(0), hidden).state;
      expect(r.values[0], wrong(0));
      expect(r.mistakes, 0);
    });

    test('givens cannot be changed', () {
      final easy = generate(KillerLevel.easy, 3);
      final g = easy.givens.indexWhere((v) => v != 0);
      final s = GameState.start(easy);
      expect(s.values[g], easy.solution[g]);
      expect(GameLogic.input(at(s, g), wrong(g), rules).state.values[g],
          easy.solution[g]);
      expect(s.toFill, 81 - KillerLevel.easy.givens);
    });

    test('placing a digit removes it from peer and cage notes', () {
      var s = fresh();
      s = GameLogic.toggleNotesMode(s);
      final d = sol(0);
      final peer = peers[0].firstWhere((p) => sol(p) != d);
      s = GameLogic.input(at(s, peer), d, rules).state;
      expect(s.notes[peer], bit(d));
      s = GameLogic.toggleNotesMode(s);
      s = put(s, 0, d);
      expect(s.notes[peer], 0);
    });

    test('a known-wrong digit keeps the notes', () {
      var s = GameLogic.toggleNotesMode(fresh());
      final d = wrong(0);
      final peer = peers[0].firstWhere((p) => sol(p) != d);
      s = GameLogic.input(at(s, peer), d, rules).state;
      s = put(GameLogic.toggleNotesMode(s), 0, d);
      expect(s.notes[peer], bit(d));
    });
  });

  group('units and win', () {
    test('completing a row adds 50 × coefficient once', () {
      var s = fresh();
      for (var c = 0; c < 8; c++) {
        s = put(s, c, sol(c));
      }
      final before = s.score;
      final r = GameLogic.input(at(s, 8), sol(8), rules);
      final row = r.completed.where((u) => u.kind == UnitKind.row).toList();
      expect(row, hasLength(1));
      expect(row.single.cells, houses[0]);
      // Cell points (30 or 45) plus 150 per completed unit.
      final cellPoints = r.state.score - before - 150 * r.completed.length;
      expect(cellPoints, anyOf(30, 45));
      expect(r.state.scoredUnits, contains(UnitKind.row.index * 100 + 0));
    });

    test('undo and re-entry do not earn points twice', () {
      var s = put(fresh(), 0, sol(0));
      final score = s.score;
      s = GameLogic.undo(s);
      expect(s.values[0], 0);
      s = put(s, 0, sol(0));
      expect(s.score, score);
    });

    test('filling the solution wins', () {
      var s = fresh();
      for (var i = 0; i < 81; i++) {
        s = put(s, i, sol(i));
      }
      expect(s.status, GameStatus.won);
      expect(s.filledCorrect, s.toFill);
    });
  });

  group('tools', () {
    test('undo restores values and notes but not mistakes', () {
      var s = put(fresh(), 0, wrong(0));
      s = GameLogic.undo(s);
      expect(s.values[0], 0);
      expect(s.mistakes, 1);
      expect(s.history, isEmpty);
      expect(GameLogic.undo(s), same(s));
    });

    test('erase clears the digit, then the notes', () {
      var s = put(fresh(), 0, wrong(0));
      s = GameLogic.erase(s, rules);
      expect(s.values[0], 0);
      s = GameLogic.toggleNotesMode(s);
      s = GameLogic.input(s, 4, rules).state;
      s = GameLogic.erase(s, rules);
      expect(s.notes[0], 0);
    });

    test('fast pencil fills candidates in empty cells only', () {
      var s = put(fresh(), 0, sol(0));
      s = GameLogic.fastPencil(s);
      expect(s.notes[0], 0);
      expect(s.fastPencilUsed, 1);
      for (var i = 1; i < 81; i++) {
        expect(s.notes[i] & bit(sol(i)), isNot(0),
            reason: 'cell $i must keep its solution digit');
      }
    });

    test('combo toggling crosses out and restores', () {
      var s = GameLogic.toggleCombo(fresh(), 2, 0x7);
      expect(s.crossed[2], {0x7});
      s = GameLogic.toggleCombo(s, 2, 0x7);
      expect(s.crossed[2], isEmpty);
    });

    test('paused game ignores input and the timer', () {
      var s = GameLogic.pause(fresh());
      expect(GameLogic.tick(s).elapsed, 0);
      expect(GameLogic.input(s, sol(40), rules).state, same(s));
      s = GameLogic.resume(s);
      expect(GameLogic.tick(s).elapsed, 1);
    });

    test('number-first pick toggles', () {
      var s = GameLogic.pickDigit(fresh(), 5);
      expect(s.pickedDigit, 5);
      s = GameLogic.pickDigit(s, 5);
      expect(s.pickedDigit, 0);
    });
  });

  test('state survives a JSON round trip and restores paused', () {
    var s = put(fresh(), 0, sol(0));
    s = GameLogic.toggleCombo(GameLogic.tick(s), 3, 0x11);
    final r = GameState.fromJson(s.toJson());
    expect(r.values, s.values);
    expect(r.notes, s.notes);
    expect(r.score, s.score);
    expect(r.elapsed, 1);
    expect(r.crossed, {3: {0x11}});
    expect(r.history, hasLength(1));
    expect(r.scoredCells, s.scoredCells);
    expect(r.status, GameStatus.paused);
    expect(r.puzzle.cages, puzzle.cages);
  });
}
