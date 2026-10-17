import 'level.dart';

/// A cage: its cells (sorted ascending) and their required sum.
class Cage {
  const Cage(this.cells, this.sum);

  final List<int> cells;
  final int sum;

  int get size => cells.length;

  Map<String, Object> toJson() => {'cells': cells, 'sum': sum};

  factory Cage.fromJson(Map<String, Object?> j) =>
      Cage(List<int>.unmodifiable(j['cells']! as List<Object?>), j['sum']! as int);

  @override
  bool operator ==(Object other) =>
      other is Cage &&
      other.sum == sum &&
      other.cells.length == cells.length &&
      Iterable<int>.generate(cells.length)
          .every((i) => other.cells[i] == cells[i]);

  @override
  int get hashCode => Object.hash(sum, Object.hashAll(cells));

  @override
  String toString() => 'Cage($sum: $cells)';
}

/// A generated Killer Sudoku puzzle with its unique solution.
class KillerPuzzle {
  const KillerPuzzle({
    required this.level,
    required this.seed,
    required this.solution,
    required this.cages,
    required this.cageOf,
    required this.givens,
    this.nodes = 0,
  });

  final KillerLevel level;

  /// Seed that produced this puzzle (after any retries).
  final int seed;

  /// 81 digits 1..9.
  final List<int> solution;
  final List<Cage> cages;

  /// Index into [cages] for every cell.
  final List<int> cageOf;

  /// 81 entries; a digit for a given (pre-filled) cell, 0 otherwise.
  final List<int> givens;

  /// Solver nodes needed by the uniqueness check (rough difficulty signal).
  final int nodes;

  Map<String, Object> toJson() => {
        'level': level.id,
        'seed': seed,
        'solution': solution,
        'cages': [for (final c in cages) c.toJson()],
        'givens': givens,
        'nodes': nodes,
      };

  factory KillerPuzzle.fromJson(Map<String, Object?> j) {
    final cages = [
      for (final c in j['cages']! as List<Object?>)
        Cage.fromJson((c! as Map<Object?, Object?>).cast<String, Object?>()),
    ];
    return KillerPuzzle(
      level: KillerLevel.fromId(j['level']! as String),
      seed: j['seed']! as int,
      solution: List<int>.unmodifiable(j['solution']! as List<Object?>),
      cages: List.unmodifiable(cages),
      cageOf: cageOfFromCages(cages),
      givens: List<int>.unmodifiable(j['givens']! as List<Object?>),
      nodes: (j['nodes'] as int?) ?? 0,
    );
  }
}

/// Rebuilds the cell → cage index table.
List<int> cageOfFromCages(List<Cage> cages) {
  final out = List<int>.filled(81, -1);
  for (var k = 0; k < cages.length; k++) {
    for (final c in cages[k].cells) {
      out[c] = k;
    }
  }
  return List.unmodifiable(out);
}
