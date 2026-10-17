import 'dart:typed_data';

import '../common/bitmask.dart';

/// Precomputed cage-sum tables (port of `COMBOS` / `ACH` in killer_engine.js).
///
/// Index layout: `size * 46 + sum`, size 0..9, sum 0..45.
int comboIndex(int size, int sum) => size * 46 + sum;

/// All digit masks with [size] digits that sum to [sum], ascending by mask.
List<int> combosFor(int size, int sum) {
  if (size < 0 || size > 9 || sum < 0 || sum > 45) return const [];
  return _combos[comboIndex(size, sum)];
}

final List<List<int>> _combos = _buildCombos();

List<List<int>> _buildCombos() {
  final c = List<List<int>>.generate(460, (_) => <int>[]);
  for (var m = 1; m < 512; m++) {
    c[comboIndex(pop[m], digitSum[m])].add(m);
  }
  return List.unmodifiable([for (final l in c) List<int>.unmodifiable(l)]);
}

/// True if some [size]-digit subset of [avail] sums to [sum].
bool achievable(int avail, int size, int sum) {
  if (size < 0 || size > 9 || sum < 0 || sum > 45) return false;
  return _ach[avail * 460 + comboIndex(size, sum)] == 1;
}

final Uint8List _ach = _buildAch();

Uint8List _buildAch() {
  final ach = Uint8List(512 * 460);
  for (var a = 0; a < 512; a++) {
    var sub = a;
    while (true) {
      ach[a * 460 + comboIndex(pop[sub], digitSum[sub])] = 1;
      if (sub == 0) break;
      sub = (sub - 1) & a;
    }
  }
  return ach;
}
