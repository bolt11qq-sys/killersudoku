import '../common/bitmask.dart';
import '../common/board.dart';
import 'combos.dart';
import 'puzzle.dart';

/// One digit set for a cage in the cage panel (TZ §3.3).
class ComboOption {
  const ComboOption(this.mask, {required this.dead});

  final int mask;

  /// Contradicts digits already on the board (shown struck out, disabled).
  final bool dead;

  List<int> get digits => digitsOf(mask);
}

/// All digit sets that sum to the cage total, each marked dead when it can
/// no longer fit: it must contain every digit already placed in the cage,
/// and its remaining digits must be assignable to the empty cells without
/// clashing with their rows, columns and blocks (port of `comboFeasible`).
List<ComboOption> cageCombos(Cage cage, List<int> values) {
  var placed = 0;
  for (final c in cage.cells) {
    if (values[c] != 0) placed |= bit(values[c]);
  }
  final empty = [
    for (final c in cage.cells)
      if (values[c] == 0) c,
  ];
  final houseMasks = [for (final c in empty) _houseMask(c, values)];
  return [
    for (final m in combosFor(cage.size, cage.sum))
      ComboOption(
        m,
        dead: (m & placed) != placed || !_feasible(m & ~placed, houseMasks),
      ),
  ];
}

int _houseMask(int cell, List<int> values) {
  var m = 0;
  for (final p in peers[cell]) {
    if (values[p] != 0) m |= bit(values[p]);
  }
  return m;
}

bool _feasible(int rem, List<int> houseMasks) {
  if (pop[rem] != houseMasks.length) return false;
  final allowed = [for (final h in houseMasks) ~h & rem];
  bool rec(int j, int left) {
    if (j == allowed.length) return true;
    var a = allowed[j] & left;
    while (a != 0) {
      final b = a & -a;
      a ^= b;
      if (rec(j + 1, left ^ b)) return true;
    }
    return false;
  }

  return rec(0, rem);
}
