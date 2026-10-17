import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/app/theme.dart';

/// WCAG relative-luminance contrast ratio.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, c) in [
    ('light', AppColors.light),
    ('dark', AppColors.dark),
  ]) {
    group('$name theme tokens', () {
      test('main text is readable on backgrounds (≥ 4.5:1)', () {
        for (final bg in [c.bg, c.surface, c.highlight, c.selected]) {
          expect(contrast(c.textPrimary, bg), greaterThanOrEqualTo(4.5));
        }
      });

      test('player digits and errors are distinguishable on cells (≥ 3:1)',
          () {
        for (final bg in [c.surface, c.highlight, c.selected, c.sameNumber]) {
          expect(contrast(c.primary, bg), greaterThanOrEqualTo(3));
          expect(contrast(c.error, bg), greaterThanOrEqualTo(3));
        }
      });

      test('cage sums are readable on cells and selected cage (≥ 4.5:1)', () {
        for (final bg in [c.surface, c.cageFill]) {
          expect(contrast(c.cage, bg), greaterThanOrEqualTo(4.5));
        }
      });
    });
  }

  test('number button width follows TZ §6.3', () {
    // Xiaomi 12T logical width ≈ 393 dp.
    expect(AppDims.numberButtonWidth(393), closeTo((393 - 32 - 40) / 9, 1e-9));
  });
}
