/// Seeded PRNG (mulberry32), bit-for-bit identical to `rng()` in
/// `reference/killer_engine.js`, so the same seed yields the same puzzle in
/// both implementations.
///
/// All state is kept as an unsigned 32-bit value. Dart VM ints are 64-bit,
/// so every step is masked with [_m32]; the low 32 bits of a 64-bit product
/// equal `Math.imul`'s result modulo 2^32.
class Mulberry32 {
  Mulberry32(int seed) : _a = seed & _m32;

  static const int _m32 = 0xFFFFFFFF;
  int _a;

  static int _imul(int a, int b) => (a * b) & _m32;

  /// Next value in [0, 1).
  double next() {
    _a = (_a + 0x6D2B79F5) & _m32;
    var t = _a;
    t = _imul(t ^ (t >> 15), t | 1);
    t = (t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & _m32)) & _m32;
    return ((t ^ (t >> 14)) & _m32) / 4294967296.0;
  }

  /// `Math.floor(rnd() * n)`.
  int nextInt(int n) => (next() * n).floor();

  /// In-place Fisher–Yates, same draw order as the JS `shuffle`.
  List<T> shuffle<T>(List<T> a) {
    for (var i = a.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final t = a[i];
      a[i] = a[j];
      a[j] = t;
    }
    return a;
  }
}

/// The retry reseed from the web worker: `(s * 1103515245 + 12345) >>> 0`.
///
/// JS evaluates this in doubles, so the product loses precision once it
/// exceeds 2^53. Reproduce that exactly: multiply and add as doubles, then
/// take the result modulo 2^32.
int nextSeed(int s) {
  final d = s.toDouble() * 1103515245.0 + 12345.0;
  return d.toInt() & 0xFFFFFFFF;
}
