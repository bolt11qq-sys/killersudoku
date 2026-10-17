import '../common/bitmask.dart';
import '../common/board.dart';
import 'candidates.dart';
import 'puzzle.dart';

/// Kinds of smart hints, in the order they are tried (web version order,
/// TZ §5.3).
enum HintKind {
  /// Wrong digits on the board; applying removes them.
  wrongDigits,

  /// 45 rule: the only innie of a region is determined.
  innie,

  /// 45 rule: the only outie of a region is determined.
  outie,

  /// One candidate left in a cell (houses + cage sum).
  nakedSingle,

  /// A digit fits only one cell of a house.
  hiddenSingle,

  /// 45 rule: two innies with a known sum restrict their candidates.
  pairSum,

  /// No simple step: the cell with fewest candidates; applying reveals it.
  lastResort,
}

enum RegionKind { row, column, block, rows, columns }

/// A house or a band of 2–3 adjacent rows / columns.
class Region {
  const Region(this.kind, this.start, [this.count = 1]);

  final RegionKind kind;

  /// 0-based first row / column / block.
  final int start;
  final int count;

  List<int> get cells => switch (kind) {
        RegionKind.row => houses[start],
        RegionKind.column => houses[9 + start],
        RegionKind.block => houses[18 + start],
        RegionKind.rows => [
            for (var r = start; r < start + count; r++) ...houses[r],
          ],
        RegionKind.columns => [
            for (var c = start; c < start + count; c++) ...houses[9 + c],
          ],
      };
}

/// A hint with everything the three steps (where / why / apply) need.
class Hint {
  const Hint({
    required this.kind,
    this.region,
    this.focus = const [],
    this.target,
    this.digit,
    this.allowed = const {},
    this.total = 0,
    this.inside = 0,
    this.crossing = 0,
    this.houseMask = 0,
    this.cageMask = 0,
    this.cageSum = 0,
  });

  final HintKind kind;

  /// Area to look at (step 1). Null for single-cell hints.
  final Region? region;

  /// Cells explained in step 2.
  final List<int> focus;

  /// Cell to fill and its digit, when applying places a digit.
  final int? target;
  final int? digit;

  /// Cell → candidate mask to keep, when applying narrows pencil marks.
  final Map<int, int> allowed;

  /// 45-rule numbers: region total, cages fully inside, crossing cages.
  final int total;
  final int inside;
  final int crossing;

  /// Single-cell details: digits used in the houses, digits the cage allows.
  final int houseMask;
  final int cageMask;
  final int cageSum;

  /// Cells to highlight at [step] (0 = where, 1 = why, 2 = result).
  List<int> cellsForStep(int step) {
    if (step == 0) return region?.cells ?? focus;
    return focus;
  }
}

/// Finds the next hint for [values] (0 = empty), or null when solved.
/// [notes] narrow candidates the player has already reduced.
Hint? findHint(KillerPuzzle p, List<int> values, List<int> notes) {
  final sol = p.solution;
  final wrong = [
    for (var i = 0; i < 81; i++)
      if (values[i] != 0 && values[i] != sol[i]) i,
  ];
  if (wrong.isNotEmpty) {
    return Hint(
      kind: HintKind.wrongDigits,
      region: Region(RegionKind.row, rowOf[wrong.first]),
      focus: wrong,
    );
  }
  if (!values.contains(0)) return null;

  final singles = [
    for (var r = 0; r < 9; r++) Region(RegionKind.row, r),
    for (var c = 0; c < 9; c++) Region(RegionKind.column, c),
    for (var b = 0; b < 9; b++) Region(RegionKind.block, b),
  ];
  final bands = [
    for (var n = 2; n <= 3; n++)
      for (var r = 0; r + n <= 9; r++) ...[
        Region(RegionKind.rows, r, n),
        Region(RegionKind.columns, r, n),
      ],
  ];
  for (final region in [...singles, ...bands]) {
    final h = _rule45(p, values, region);
    if (h != null) return h;
  }

  final cd = candidates(p.cages, p.cageOf, values);
  for (var i = 0; i < 81; i++) {
    if (values[i] != 0 || pop[cd.cand[i]] != 1) continue;
    final d = digitOf(cd.cand[i]);
    if (d != sol[i]) continue;
    return Hint(
      kind: HintKind.nakedSingle,
      focus: [i],
      target: i,
      digit: d,
      houseMask: cd.houseMask[i],
      cageMask: cd.cageMask[i],
      cageSum: p.cages[p.cageOf[i]].sum,
    );
  }

  for (var h = 0; h < 27; h++) {
    final house = houses[h];
    var placed = 0;
    for (final x in house) {
      if (values[x] != 0) placed |= bit(values[x]);
    }
    for (var d = 1; d <= 9; d++) {
      if (placed & bit(d) != 0) continue;
      final spots = [
        for (final x in house)
          if (values[x] == 0 && cd.cand[x] & bit(d) != 0) x,
      ];
      if (spots.length == 1 && sol[spots.first] == d) {
        return Hint(
          kind: HintKind.hiddenSingle,
          region: singles[h],
          focus: spots,
          target: spots.first,
          digit: d,
        );
      }
    }
  }

  for (final region in singles) {
    final h = _pairSum(p, values, notes, cd, region);
    if (h != null) return h;
  }

  var best = -1, bn = 10;
  for (var i = 0; i < 81; i++) {
    if (values[i] == 0 && pop[cd.cand[i]] < bn) {
      bn = pop[cd.cand[i]];
      best = i;
    }
  }
  return Hint(
    kind: HintKind.lastResort,
    focus: [best],
    target: best,
    digit: sol[best],
    houseMask: cd.cand[best],
  );
}

class _Split {
  _Split(this.total);
  final int total;
  int inside = 0;
  int crossing = 0;
  final innies = <int>[];
  final outies = <int>[];
}

_Split _analyse(KillerPuzzle p, Region region) {
  final cells = region.cells;
  final inSet = cells.toSet();
  final s = _Split(45 * region.count);
  for (final k in {for (final c in cells) p.cageOf[c]}) {
    final cage = p.cages[k];
    if (cage.cells.every(inSet.contains)) {
      s.inside += cage.sum;
    } else {
      s.crossing += cage.sum;
      for (final c in cage.cells) {
        (inSet.contains(c) ? s.innies : s.outies).add(c);
      }
    }
  }
  return s;
}

Hint? _rule45(KillerPuzzle p, List<int> values, Region region) {
  final a = _analyse(p, region);
  if (a.innies.length == 1 && values[a.innies.first] == 0) {
    final x = a.innies.first;
    final d = a.total - a.inside;
    if (d == p.solution[x]) {
      return Hint(
        kind: HintKind.innie,
        region: region,
        focus: [x],
        target: x,
        digit: d,
        total: a.total,
        inside: a.inside,
      );
    }
  }
  if (a.outies.length == 1 && values[a.outies.first] == 0) {
    final x = a.outies.first;
    final d = a.crossing - (a.total - a.inside);
    if (d == p.solution[x]) {
      return Hint(
        kind: HintKind.outie,
        region: region,
        focus: [x],
        target: x,
        digit: d,
        total: a.total,
        inside: a.inside,
        crossing: a.crossing,
      );
    }
  }
  return null;
}

Hint? _pairSum(
  KillerPuzzle p,
  List<int> values,
  List<int> notes,
  Candidates cd,
  Region region,
) {
  final a = _analyse(p, region);
  if (a.innies.length != 2) return null;
  final x = a.innies[0], y = a.innies[1];
  if (values[x] != 0 || values[y] != 0) return null;
  final sum = a.total - a.inside;
  // Current candidates, narrowed by the player's own notes if any.
  int eff(int i) => notes[i] != 0 ? notes[i] & cd.cand[i] : cd.cand[i];
  final ex = eff(x), ey = eff(y);
  var mx = 0, my = 0;
  for (var d = 1; d <= 9; d++) {
    final e = sum - d;
    if (e < 1 || e > 9 || e == d) continue;
    if (ex & bit(d) != 0 && ey & bit(e) != 0) {
      mx |= bit(d);
      my |= bit(e);
    }
  }
  // Useful only if it narrows something and keeps the solution.
  if (mx == ex && my == ey) return null;
  if (mx & bit(p.solution[x]) == 0 || my & bit(p.solution[y]) == 0) {
    return null;
  }
  return Hint(
    kind: HintKind.pairSum,
    region: region,
    focus: [x, y],
    allowed: {x: mx, y: my},
    total: a.total,
    inside: a.inside,
  );
}
