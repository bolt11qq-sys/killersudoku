/// Killer difficulty levels (TZ §4.1).
///
/// [id] matches the level keys of the web version (`hard`, `expert`, `devil`)
/// so fixtures and saved data stay compatible.
enum KillerLevel {
  easy(id: 'easy', minCage: 2, maxCage: 3, maxSingles: 1, givens: 6),
  medium(id: 'medium', minCage: 2, maxCage: 3, maxSingles: 1, givens: 0),
  hard(id: 'hard', minCage: 2, maxCage: 4, maxSingles: 1, givens: 0),
  expert(id: 'expert', minCage: 2, maxCage: 5, maxSingles: 0, givens: 0),
  devil(id: 'devil', minCage: 2, maxCage: 6, maxSingles: 0, givens: 0);

  const KillerLevel({
    required this.id,
    required this.minCage,
    required this.maxCage,
    required this.maxSingles,
    required this.givens,
  });

  final String id;

  /// Target cage size range used while growing cages.
  final int minCage;
  final int maxCage;

  /// How many 1-cell cages the final puzzle may keep.
  final int maxSingles;

  /// Solution digits revealed at the start (one per block at most).
  final int givens;

  static KillerLevel fromId(String id) =>
      values.firstWhere((l) => l.id == id, orElse: () => expert);
}
