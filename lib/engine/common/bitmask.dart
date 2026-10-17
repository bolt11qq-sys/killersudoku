import 'dart:typed_data';

/// Digit sets are 9-bit masks: bit (d-1) set means digit d is present.
const int kAllDigits = 511;

/// Mask for a single digit 1..9.
int bit(int d) => 1 << (d - 1);

/// Number of digits in each mask 0..511.
final Uint8List pop = _buildPop();

/// Sum of the digits in each mask 0..511.
final Uint8List digitSum = _buildSum();

Uint8List _buildPop() {
  final p = Uint8List(512);
  for (var m = 0; m < 512; m++) {
    var n = 0;
    for (var d = 1; d <= 9; d++) {
      if ((m >> (d - 1)) & 1 == 1) n++;
    }
    p[m] = n;
  }
  return p;
}

Uint8List _buildSum() {
  final s = Uint8List(512);
  for (var m = 0; m < 512; m++) {
    var n = 0;
    for (var d = 1; d <= 9; d++) {
      if ((m >> (d - 1)) & 1 == 1) n += d;
    }
    s[m] = n;
  }
  return s;
}

/// Digits of [mask] in ascending order.
List<int> digitsOf(int mask) => [
      for (var d = 1; d <= 9; d++)
        if (mask & bit(d) != 0) d,
    ];

/// Lowest digit of a single-digit mask.
int digitOf(int mask) {
  for (var d = 1; d <= 9; d++) {
    if (mask & bit(d) != 0) return d;
  }
  return 0;
}
