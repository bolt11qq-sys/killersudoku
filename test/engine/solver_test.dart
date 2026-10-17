import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/engine/common/bitmask.dart';
import 'package:killer_sudoku/engine/killer/candidates.dart';
import 'package:killer_sudoku/engine/killer/combos.dart';
import 'package:killer_sudoku/engine/killer/puzzle.dart';
import 'package:killer_sudoku/engine/killer/solver.dart';

/// A valid solution grid used to build hand-made cage layouts.
const List<int> kGrid = [
  5, 3, 4, 6, 7, 8, 9, 1, 2, //
  6, 7, 2, 1, 9, 5, 3, 4, 8,
  1, 9, 8, 3, 4, 2, 5, 6, 7,
  8, 5, 9, 7, 6, 1, 4, 2, 3,
  4, 2, 6, 8, 5, 3, 7, 9, 1,
  7, 1, 3, 9, 2, 4, 8, 5, 6,
  9, 6, 1, 5, 3, 7, 2, 8, 4,
  2, 8, 7, 4, 1, 9, 6, 3, 5,
  3, 4, 5, 2, 8, 6, 1, 7, 9,
];

/// Horizontal domino cages over [kGrid] (last column as single cells).
List<Cage> dominoCages() {
  final cages = <Cage>[];
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 8; c += 2) {
      final a = r * 9 + c;
      cages.add(Cage([a, a + 1], kGrid[a] + kGrid[a + 1]));
    }
    final last = r * 9 + 8;
    cages.add(Cage([last], kGrid[last]));
  }
  return cages;
}

void main() {
  group('combos', () {
    test('known cage combinations', () {
      expect(combosFor(2, 3).map(digitsOf), [
        [1, 2],
      ]);
      expect(combosFor(2, 17).map(digitsOf), [
        [8, 9],
      ]);
      expect(combosFor(9, 45), hasLength(1));
      expect(combosFor(3, 15), hasLength(8));
      expect(combosFor(2, 2), isEmpty);
      expect(combosFor(10, 45), isEmpty);
    });

    test('achievable respects available digits', () {
      expect(achievable(kAllDigits, 2, 17), isTrue);
      expect(achievable(kAllDigits & ~bit(9), 2, 17), isFalse);
      expect(achievable(kAllDigits, 0, 0), isTrue);
    });
  });

  group('solver', () {
    test('detects a non-unique layout and returns valid solutions', () {
      // Dominoes can swap their two digits, so this layout is ambiguous.
      final cages = dominoCages();
      final r = solve(cages, cageOfFromCages(cages), limit: 2);
      expect(r.aborted, isFalse);
      expect(r.count, 2);
      expect(r.isUnique, isFalse);
      expect(r.solutions[0], isNot(equals(r.solutions[1])));
      for (final s in r.solutions) {
        for (final cage in cages) {
          final digits = [for (final c in cage.cells) s[c]];
          expect(digits.fold<int>(0, (a, b) => a + b), cage.sum);
          expect(digits.toSet(), hasLength(digits.length));
        }
      }
    });

    test('every cell as its own cage is trivially unique', () {
      final cages = [for (var i = 0; i < 81; i++) Cage([i], kGrid[i])];
      final r = solve(cages, cageOfFromCages(cages), limit: 2);
      expect(r.isUnique, isTrue);
      expect(r.first, kGrid);
    });

    test('a contradictory board has no solution', () {
      final cages = [for (var i = 0; i < 81; i++) Cage([i], kGrid[i])];
      final vals = List<int>.filled(81, 0)..[0] = kGrid[1];
      final r = solve(cages, cageOfFromCages(cages), vals: vals);
      expect(r.count, 0);
    });

    test('node limit aborts the search', () {
      final cages = dominoCages();
      final r = solve(cages, cageOfFromCages(cages), nodeLimit: 3);
      expect(r.aborted, isTrue);
      expect(r.nodes, 4);
    });

    test('virtual cages apply the 45 rule', () {
      // Row 0: dominoes cover columns 0..7, the single in column 8 is
      // its own cage, so no innies are left in row 0.
      final cages = dominoCages();
      final v = virtualCages(cages, cageOfFromCages(cages));
      for (final cage in v) {
        final expected = cage.cells.fold<int>(0, (a, c) => a + kGrid[c]);
        expect(cage.sum, expected, reason: '$cage');
      }
    });

    test('cageMasks keeps only digits of a feasible completion', () {
      // Two cells summing to 3 can only be {1, 2}.
      final res = cageMasks([kAllDigits, kAllDigits], 0, 3)!;
      expect(digitsOf(res[0]), [1, 2]);
      expect(digitsOf(res[1]), [1, 2]);
      // First cell already restricted to 1 → second must be 2.
      final res2 = cageMasks([bit(1), kAllDigits], 0, 3)!;
      expect(digitsOf(res2[1]), [2]);
      expect(cageMasks([bit(1), bit(1)], 0, 3), isNull);
    });
  });

  test('candidates combine houses and cage sums', () {
    final cages = dominoCages();
    final cageOf = cageOfFromCages(cages);
    final vals = List<int>.filled(81, 0)..[0] = kGrid[0];
    final c = candidates(cages, cageOf, vals);
    // Cell 1 shares the domino with cell 0 (5 + 3 = 8) → only 3 fits.
    expect(digitsOf(c.cand[1]), [3]);
    expect(c.cand[0], 0);
  });
}
