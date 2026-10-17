// Generator properties over 50 seeds per level (TZ §4.3).
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/engine/common/bitmask.dart';
import 'package:killer_sudoku/engine/common/board.dart';
import 'package:killer_sudoku/engine/killer/generator.dart';
import 'package:killer_sudoku/engine/killer/level.dart';
import 'package:killer_sudoku/engine/killer/puzzle.dart';
import 'package:killer_sudoku/engine/killer/solver.dart';

const int kSeedsPerLevel = 50;
const int kFirstSeed = 1000;
const int kWorkers = 4;

/// Generates puzzles for [seeds] spread over [kWorkers] isolates.
Future<List<KillerPuzzle>> generateMany(KillerLevel level, List<int> seeds) async {
  final chunks = List.generate(kWorkers, (w) => [
        for (var i = w; i < seeds.length; i += kWorkers) seeds[i],
      ]);
  final parts = await Future.wait([
    for (final chunk in chunks)
      Isolate.run(() => [for (final s in chunk) generate(level, s)]),
  ]);
  return [for (final p in parts) ...p];
}

void expectValidSolution(List<int> sol) {
  for (final h in houses) {
    var m = 0;
    for (final c in h) {
      m |= bit(sol[c]);
    }
    expect(m, kAllDigits, reason: 'house $h is not 1..9');
  }
}

bool isConnected(List<int> cells) {
  final set = cells.toSet();
  final seen = {cells.first};
  final stack = [cells.first];
  while (stack.isNotEmpty) {
    final c = stack.removeLast();
    for (final n in neighbours[c]) {
      if (set.contains(n) && seen.add(n)) stack.add(n);
    }
  }
  return seen.length == set.length;
}

void checkPuzzle(KillerPuzzle p) {
  final level = p.level;
  final why = '${level.id} seed ${p.seed}';
  expectValidSolution(p.solution);

  // Every cell belongs to exactly one cage, consistent with cageOf.
  final owner = List<int>.filled(81, -1);
  for (var k = 0; k < p.cages.length; k++) {
    for (final c in p.cages[k].cells) {
      expect(owner[c], -1, reason: '$why: cell $c in two cages');
      owner[c] = k;
    }
  }
  expect(owner, p.cageOf, reason: why);

  var singles = 0;
  for (final cage in p.cages) {
    final digits = [for (final c in cage.cells) p.solution[c]];
    expect(digits.toSet().length, digits.length,
        reason: '$why: repeated digit in $cage');
    expect(digits.fold<int>(0, (a, b) => a + b), cage.sum, reason: why);
    expect(isConnected(cage.cells), isTrue, reason: '$why: split $cage');
    expect(cage.size, inInclusiveRange(1, level.maxCage + 1), reason: why);
    if (cage.size == 1) singles++;
  }
  expect(singles, lessThanOrEqualTo(level.maxSingles), reason: why);

  // Unique solution, proven without a node limit.
  final r = solve(p.cages, p.cageOf, limit: 2);
  expect(r.isUnique, isTrue, reason: '$why: not unique');
  expect(r.first, p.solution, reason: why);

  // Givens: count, one per block at most, equal to the solution.
  final given = [
    for (var i = 0; i < 81; i++)
      if (p.givens[i] != 0) i,
  ];
  expect(given.length, level.givens, reason: why);
  expect(given.map((i) => blockOf[i]).toSet().length, given.length,
      reason: '$why: two givens in one block');
  for (final i in given) {
    expect(p.givens[i], p.solution[i], reason: why);
  }
}

void main() {
  for (final level in KillerLevel.values) {
    test(
      '${level.id}: $kSeedsPerLevel seeds are valid and unique',
      () async {
        final seeds = List.generate(kSeedsPerLevel, (i) => kFirstSeed + i);
        final puzzles = await generateMany(level, seeds);
        expect(puzzles, hasLength(kSeedsPerLevel));
        puzzles.forEach(checkPuzzle);
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  }

  test('same seed gives the same puzzle', () {
    final a = generate(KillerLevel.medium, 20261017);
    final b = generate(KillerLevel.medium, 20261017);
    expect(a.toJson(), b.toJson());
  });

  test('puzzle survives a JSON round trip', () {
    final p = generate(KillerLevel.easy, 7);
    final q = KillerPuzzle.fromJson(p.toJson());
    expect(q.toJson(), p.toJson());
    expect(q.cageOf, p.cageOf);
    expect(q.level, KillerLevel.easy);
  });
}
