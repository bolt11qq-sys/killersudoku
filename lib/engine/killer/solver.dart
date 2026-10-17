import 'dart:typed_data';

import '../common/bitmask.dart';
import '../common/board.dart';
import 'combos.dart';
import 'puzzle.dart';

/// Result of [solve].
class SolveResult {
  const SolveResult({
    required this.count,
    required this.aborted,
    required this.nodes,
    required this.solutions,
  });

  /// Solutions found (stops at the requested limit).
  final int count;

  /// True when the node limit was hit; [count] is then a lower bound.
  final bool aborted;
  final int nodes;
  final List<List<int>> solutions;

  List<int>? get first => solutions.isEmpty ? null : solutions.first;

  /// Exactly one solution, proven (search finished).
  bool get isUnique => !aborted && count == 1;
}

/// "45 rule" cages: for every house, the cells not covered by cages lying
/// fully inside it form a virtual cage with sum 45 − (inside cage sums).
/// Only regions of 1..6 cells are kept, as in the web version.
List<Cage> virtualCages(List<Cage> cages, List<int> cageOf) {
  final out = <Cage>[];
  for (final h in houses) {
    final inH = h.toSet();
    var inside = 0;
    final covered = <int>{};
    // Insertion-ordered like the JS `Set`.
    for (final k in {for (final c in h) cageOf[c]}) {
      if (cages[k].cells.every(inH.contains)) {
        inside += cages[k].sum;
        covered.addAll(cages[k].cells);
      }
    }
    final inn = [
      for (final c in h)
        if (!covered.contains(c)) c,
    ];
    if (inn.isNotEmpty && inn.length <= 6) out.add(Cage(inn, 45 - inside));
  }
  return out;
}

/// True if the cells `j ∉ idx ∪ {skip}` can each take a distinct digit of
/// [rem] from their allowed masks [al].
bool _canMatch(List<int> al, int idx, int n, int skip, int rem) {
  var best = -1, bc = 99;
  for (var j = 0; j < n; j++) {
    if (j == skip || (idx >> j) & 1 == 1) continue;
    final c = pop[al[j] & rem];
    if (c == 0) return false;
    if (c < bc) {
      bc = c;
      best = j;
    }
  }
  if (best < 0) return true;
  var a = al[best] & rem;
  final nidx = idx | (1 << best);
  while (a != 0) {
    final b = a & -a;
    a ^= b;
    if (_canMatch(al, nidx, n, skip, rem ^ b)) return true;
  }
  return false;
}

/// Full cage consistency for the empty cells of a cage. [al] holds each
/// empty cell's allowed digits, [used] the digits already placed in the
/// cage and [rs] the remaining sum. Returns, per cell, the digits that occur
/// in some valid completion, or null when there is none.
Int32List? cageMasks(List<int> al, int used, int rs) {
  final n = al.length;
  if (rs > 45) return null;
  final out = Int32List(n);
  var any = false;
  for (final m in combosFor(n, rs)) {
    if (m & used != 0) continue;
    var un = 0;
    var ok = true;
    for (var j = 0; j < n; j++) {
      final a = al[j] & m;
      if (a == 0) {
        ok = false;
        break;
      }
      un |= a;
    }
    if (!ok || un != m) continue;
    for (var j = 0; j < n; j++) {
      var a = al[j] & m & ~out[j];
      while (a != 0) {
        final b = a & -a;
        a ^= b;
        if (_canMatch(al, 0, n, j, m ^ b)) {
          out[j] |= b;
          any = true;
        }
      }
    }
  }
  return any ? out : null;
}

/// Candidate masks for the empty cells of [g] after cage consistency and
/// hidden/naked single elimination, or null on a contradiction.
Int32List? propagate(List<Cage> cages, List<int> g) {
  final rm = Int32List(9), cm = Int32List(9), bm = Int32List(9);
  for (var i = 0; i < 81; i++) {
    if (g[i] != 0) {
      final b = bit(g[i]);
      rm[rowOf[i]] |= b;
      cm[colOf[i]] |= b;
      bm[blockOf[i]] |= b;
    }
  }
  final mask = Int32List(81);
  for (var i = 0; i < 81; i++) {
    if (g[i] == 0) {
      mask[i] = kAllDigits & ~(rm[rowOf[i]] | cm[colOf[i]] | bm[blockOf[i]]);
      if (mask[i] == 0) return null;
    }
  }
  for (var round = 0; round < 3; round++) {
    var changed = false;
    // Cage arithmetic.
    for (final cage in cages) {
      var used = 0, rs = cage.sum;
      final e = <int>[];
      for (final c in cage.cells) {
        if (g[c] != 0) {
          used |= bit(g[c]);
          rs -= g[c];
        } else {
          e.add(c);
        }
      }
      if (e.isEmpty) {
        if (rs != 0) return null;
        continue;
      }
      if (rs <= 0) return null;
      final al = [for (final c in e) mask[c] & ~used];
      final res = cageMasks(al, used, rs);
      if (res == null) return null;
      for (var j = 0; j < e.length; j++) {
        if (res[j] != mask[e[j]]) {
          mask[e[j]] = res[j];
          changed = true;
        }
      }
    }
    // Hidden singles.
    for (final h in houses) {
      var placed = 0;
      for (final x in h) {
        if (g[x] != 0) placed |= bit(g[x]);
      }
      for (var d = 1; d <= 9; d++) {
        final b = bit(d);
        if (placed & b != 0) continue;
        var n = 0, at = -1;
        for (final x in h) {
          if (g[x] == 0 && mask[x] & b != 0) {
            n++;
            at = x;
          }
        }
        if (n == 0) return null;
        if (n == 1 && mask[at] != b) {
          mask[at] = b;
          changed = true;
        }
      }
    }
    // Naked singles: remove from peers in each house.
    for (final h in houses) {
      for (final x in h) {
        if (g[x] != 0 || pop[mask[x]] != 1) continue;
        for (final y in h) {
          if (y != x && g[y] == 0 && mask[y] & mask[x] != 0) {
            mask[y] &= ~mask[x];
            if (mask[y] == 0) return null;
            changed = true;
          }
        }
      }
    }
    if (!changed) break;
  }
  return mask;
}

/// Backtracking solver with constraint propagation (port of `solve`).
///
/// Stops after [limit] solutions or [nodeLimit] search nodes. [vals] are
/// optional pre-filled digits (0 = empty).
SolveResult solve(
  List<Cage> cages,
  List<int> cageOf, {
  List<int>? vals,
  int limit = 2,
  int nodeLimit = 1 << 30,
}) {
  final s = _Search(
    [...cages, ...virtualCages(cages, cageOf)],
    limit,
    nodeLimit,
  );
  if (vals != null) {
    for (var i = 0; i < 81; i++) {
      s.g[i] = vals[i];
    }
  }
  s.rec();
  return SolveResult(
    count: s.count,
    aborted: s.aborted,
    nodes: s.nodes,
    solutions: s.sols,
  );
}

class _Search {
  _Search(this.cages, this.limit, this.nodeLimit);

  final List<Cage> cages;
  final int limit;
  final int nodeLimit;
  final Int8List g = Int8List(81);
  int count = 0;
  int nodes = 0;
  bool aborted = false;
  final List<List<int>> sols = [];

  /// Returns true to stop the whole search.
  bool rec() {
    if (++nodes > nodeLimit) {
      aborted = true;
      return true;
    }
    final mask = propagate(cages, g);
    if (mask == null) return false;
    var best = -1, bc = 0, bn = 10, empty = 0;
    for (var i = 0; i < 81; i++) {
      if (g[i] != 0) continue;
      empty++;
      final n = pop[mask[i]];
      if (n < bn) {
        bn = n;
        best = i;
        bc = mask[i];
      }
    }
    if (empty == 0) {
      count++;
      sols.add(List<int>.unmodifiable(g));
      return count >= limit;
    }
    if (bn > 1) {
      // Branch on a hidden single position if it has fewer options.
      var hb = 10, hd = 0;
      List<int>? hcells;
      for (final h in houses) {
        var placed = 0;
        for (final x in h) {
          if (g[x] != 0) placed |= bit(g[x]);
        }
        for (var d = 1; d <= 9; d++) {
          final b = bit(d);
          if (placed & b != 0) continue;
          var n = 0;
          for (final x in h) {
            if (g[x] == 0 && mask[x] & b != 0) n++;
          }
          if (n == 0) return false;
          if (n < hb) {
            hb = n;
            hd = d;
            hcells = h;
          }
        }
      }
      if (hb < bn) {
        final b = bit(hd);
        for (final x in hcells!) {
          if (g[x] != 0 || mask[x] & b == 0) continue;
          g[x] = hd;
          if (rec()) {
            g[x] = 0;
            return true;
          }
          g[x] = 0;
        }
        return false;
      }
    }
    for (var d = 1; d <= 9; d++) {
      if (bc & bit(d) == 0) continue;
      g[best] = d;
      if (rec()) {
        g[best] = 0;
        return true;
      }
      g[best] = 0;
    }
    return false;
  }
}
