import 'dart:typed_data';

import '../common/bitmask.dart';
import '../common/board.dart';
import 'combos.dart';
import 'puzzle.dart';

/// Per-cell candidate masks for the current board (port of `candidates`).
class Candidates {
  const Candidates(this.cand, this.houseMask, this.cageMask);

  /// Digits still possible in each empty cell (0 for filled cells).
  final Int32List cand;

  /// Digits already used in the cell's row, column and block.
  final Int32List houseMask;

  /// Digits the cell's cage sum still allows.
  final Int32List cageMask;
}

/// Candidates from houses plus cage arithmetic: a digit is allowed if the
/// rest of the cage can still reach its sum with unused digits.
Candidates candidates(List<Cage> cages, List<int> cageOf, List<int> vals) {
  final rm = Int32List(9), cm = Int32List(9), bm = Int32List(9);
  final nc = cages.length;
  final cu = Int32List(nc), cs = Int32List(nc), cc = Int32List(nc);
  for (var k = 0; k < nc; k++) {
    cs[k] = cages[k].sum;
    cc[k] = cages[k].size;
  }
  for (var i = 0; i < 81; i++) {
    if (vals[i] != 0) {
      final b = bit(vals[i]), k = cageOf[i];
      rm[rowOf[i]] |= b;
      cm[colOf[i]] |= b;
      bm[blockOf[i]] |= b;
      cu[k] |= b;
      cs[k] -= vals[i];
      cc[k]--;
    }
  }
  final out = Int32List(81), houseMask = Int32List(81), cageMask = Int32List(81);
  for (var i = 0; i < 81; i++) {
    if (vals[i] != 0) continue;
    final k = cageOf[i], used = cu[k];
    houseMask[i] = rm[rowOf[i]] | cm[colOf[i]] | bm[blockOf[i]];
    final avail = kAllDigits & ~used;
    var cmask = 0;
    for (var d = 1; d <= 9; d++) {
      final b = bit(d);
      if (used & b != 0) continue;
      final rs = cs[k] - d;
      if (rs < 0 || cc[k] < 1) continue;
      if (achievable(avail & ~b, cc[k] - 1, rs)) cmask |= b;
    }
    cageMask[i] = cmask;
    out[i] = cmask & ~houseMask[i] & kAllDigits;
  }
  return Candidates(out, houseMask, cageMask);
}
