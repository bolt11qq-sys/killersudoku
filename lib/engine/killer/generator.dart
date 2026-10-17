import 'dart:typed_data';

import '../common/bitmask.dart';
import '../common/board.dart';
import '../common/rng.dart';
import 'level.dart';
import 'puzzle.dart';
import 'solver.dart';

/// Search-node budget for the uniqueness check while generating (TZ §4.1).
const int kGenNodeLimit = 700;

/// How many seeds [generate] tries via [nextSeed] before giving up.
/// The web worker used 6; the extra headroom only matters for rare seeds.
const int kMaxSeedAttempts = 64;

/// Generates a puzzle for [level], deterministic in [seed].
///
/// Mirrors the web worker: try [generateOnce] with [seed], and on failure
/// move on with [nextSeed]. The returned puzzle records the seed that
/// actually produced it.
KillerPuzzle generate(KillerLevel level, int seed) {
  var s = seed & 0xFFFFFFFF;
  for (var t = 0; t < kMaxSeedAttempts; t++) {
    final p = generateOnce(level, s);
    if (p != null) return p;
    s = nextSeed(s);
  }
  throw StateError('No ${level.id} puzzle after $kMaxSeedAttempts seeds');
}

/// Statistics of one [generateOnce] run, for comparison with the JS engine.
class GenStats {
  int tries = 0;
  int solves = 0;
}

/// One run of the JS `generate(level, seed)`; null if 30 fresh grids
/// (each with up to 40 cage repairs) did not give a unique puzzle.
KillerPuzzle? generateOnce(KillerLevel level, int seed, [GenStats? stats]) {
  final rnd = Mulberry32(seed);
  final st = stats ?? GenStats();
  while (st.tries < 30) {
    st.tries++;
    final sol = _fullGrid(rnd);
    final raw = <_RawCage?>[];
    final cageOf = Int32List(81)..fillRange(0, 81, -1);
    _growRegion(
      List<int>.generate(81, (i) => i),
      sol,
      level,
      rnd,
      raw,
      cageOf,
    );
    for (var fix = 0; fix < 40; fix++) {
      final p = _finalize(raw, cageOf, sol);
      final r = solve(p.cages, p.cageOf, limit: 2, nodeLimit: kGenNodeLimit);
      st.solves++;
      if (r.isUnique) {
        final singles = p.cages.where((c) => c.size == 1).length;
        if (singles <= level.maxSingles) {
          return KillerPuzzle(
            level: level,
            seed: seed,
            solution: List.unmodifiable(sol),
            cages: p.cages,
            cageOf: p.cageOf,
            givens: _pickGivens(level, seed, sol),
            nodes: r.nodes,
          );
        }
        break;
      }
      // Dissolve the cage of a cell where two solutions differ (or a random
      // cell) plus one neighbouring cage, then regrow that region.
      int x;
      if (r.aborted || r.solutions.length < 2) {
        x = rnd.nextInt(81);
      } else {
        final s1 = r.solutions[0], s2 = r.solutions[1];
        final diff = [
          for (var i = 0; i < 81; i++)
            if (s1[i] != s2[i]) i,
        ];
        x = diff[rnd.nextInt(diff.length)];
      }
      final k = cageOf[x];
      // Set literals keep insertion order, like the JS `Set`.
      final nbK = rnd.shuffle(<int>{
        for (final c in raw[k]!.cells)
          for (final n in neighbours[c])
            if (cageOf[n] != k) cageOf[n],
      }.toList());
      final region = [...raw[k]!.cells];
      raw[k] = null;
      if (nbK.isNotEmpty) {
        final q = nbK[0];
        region.addAll(raw[q]!.cells);
        raw[q] = null;
      }
      for (final c in region) {
        cageOf[c] = -1;
      }
      _growRegion(region, sol, level, rnd, raw, cageOf);
    }
  }
  return null;
}

class _RawCage {
  _RawCage(this.cells, this.mask);
  final List<int> cells;
  int mask;
}

List<int> _fullGrid(Mulberry32 rnd) {
  final g = Int8List(81);
  final rm = Int32List(9), cm = Int32List(9), bm = Int32List(9);
  bool rec(int i) {
    if (i == 81) return true;
    final ds = rnd.shuffle([1, 2, 3, 4, 5, 6, 7, 8, 9]);
    for (final d in ds) {
      final b = bit(d);
      if ((rm[rowOf[i]] | cm[colOf[i]] | bm[blockOf[i]]) & b != 0) continue;
      g[i] = d;
      rm[rowOf[i]] |= b;
      cm[colOf[i]] |= b;
      bm[blockOf[i]] |= b;
      if (rec(i + 1)) return true;
      g[i] = 0;
      rm[rowOf[i]] &= ~b;
      cm[colOf[i]] &= ~b;
      bm[blockOf[i]] &= ~b;
    }
    return false;
  }

  rec(0);
  return List<int>.of(g);
}

/// Re-cages the cells of [region] (their `cageOf` must be -1), then merges
/// new 1-cell cages into a neighbouring cage where no digit would repeat.
void _growRegion(
  List<int> region,
  List<int> sol,
  KillerLevel level,
  Mulberry32 rnd,
  List<_RawCage?> cages,
  Int32List cageOf,
) {
  final inR = region.toSet();
  final order = rnd.shuffle([...region]);
  final made = <int>[];
  for (final start in order) {
    if (cageOf[start] >= 0) continue;
    final id = cages.length;
    final target =
        level.minCage + rnd.nextInt(level.maxCage - level.minCage + 1);
    final cells = [start];
    var used = bit(sol[start]);
    cageOf[start] = id;
    while (cells.length < target) {
      final fr = <int>[];
      for (final c in cells) {
        for (final n in neighbours[c]) {
          if (inR.contains(n) &&
              cageOf[n] < 0 &&
              used & bit(sol[n]) == 0 &&
              !fr.contains(n)) {
            fr.add(n);
          }
        }
      }
      if (fr.isEmpty) break;
      final n = fr[rnd.nextInt(fr.length)];
      cells.add(n);
      cageOf[n] = id;
      used |= bit(sol[n]);
    }
    cages.add(_RawCage(cells, used));
    made.add(id);
  }
  for (final id in made) {
    final cg = cages[id];
    if (cg == null || cg.cells.length != 1) continue;
    final c = cg.cells[0], b = bit(sol[c]);
    // Duplicates are kept on purpose: the JS shuffles the same list.
    final opts = rnd.shuffle([
      for (final n in neighbours[c])
        if (_canAbsorb(cages, cageOf[n], id, b, level.maxCage + 1)) cageOf[n],
    ]);
    if (opts.isNotEmpty) {
      final k = opts[0];
      cages[k]!.cells.add(c);
      cages[k]!.mask |= b;
      cageOf[c] = k;
      cages[id] = null;
    }
  }
}

bool _canAbsorb(List<_RawCage?> cages, int k, int id, int b, int sizeLimit) {
  if (k < 0 || k == id) return false;
  final cg = cages[k];
  return cg != null && cg.mask & b == 0 && cg.cells.length < sizeLimit;
}

({List<Cage> cages, List<int> cageOf}) _finalize(
  List<_RawCage?> raw,
  Int32List cageOf,
  List<int> sol,
) {
  final out = <Cage>[];
  final map = <int, int>{};
  for (var i = 0; i < raw.length; i++) {
    final cg = raw[i];
    if (cg == null) continue;
    map[i] = out.length;
    final cells = [...cg.cells]..sort();
    var sum = 0;
    for (final c in cells) {
      sum += sol[c];
    }
    out.add(Cage(List.unmodifiable(cells), sum));
  }
  return (
    cages: List.unmodifiable(out),
    cageOf: List.unmodifiable([for (final k in cageOf) map[k]!]),
  );
}

/// Revealed digits for easier levels: [KillerLevel.givens] cells, at most one
/// per block, drawn from a stream separate from the generator's so the
/// cage layout stays identical to the JS engine for the same seed.
List<int> _pickGivens(KillerLevel level, int seed, List<int> sol) {
  final out = List<int>.filled(81, 0);
  if (level.givens == 0) return List.unmodifiable(out);
  final rnd = Mulberry32(seed ^ 0x5EED6175);
  final blocks = rnd.shuffle(List<int>.generate(9, (i) => i));
  for (final b in blocks.take(level.givens)) {
    final cell = houses[18 + b][rnd.nextInt(9)];
    out[cell] = sol[cell];
  }
  return List.unmodifiable(out);
}
