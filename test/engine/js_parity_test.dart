// Compares the Dart engine with the JS reference (TZ §4.3).
// Fixtures come from `node tool/gen_golden.js`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/engine/common/rng.dart';
import 'package:killer_sudoku/engine/killer/candidates.dart';
import 'package:killer_sudoku/engine/killer/generator.dart';
import 'package:killer_sudoku/engine/killer/level.dart';
import 'package:killer_sudoku/engine/killer/puzzle.dart';
import 'package:killer_sudoku/engine/killer/solver.dart';

typedef Json = Map<String, Object?>;

List<int> ints(Object? v) => (v! as List<Object?>).cast<int>();

List<Cage> cagesOf(Object? v) => [
      for (final c in v! as List<Object?>)
        Cage(ints((c! as Json)['cells']), (c as Json)['sum']! as int),
    ];

void main() {
  final golden = jsonDecode(
    File('test/engine/fixtures/js_golden.json').readAsStringSync(),
  ) as Json;
  List<Json> section(String k) =>
      (golden[k]! as List<Object?>).cast<Json>();

  test('mulberry32 matches JS values exactly', () {
    for (final r in section('rng')) {
      final rng = Mulberry32(r['seed']! as int);
      for (final v in (r['values']! as List<Object?>).cast<num>()) {
        expect(rng.next(), v.toDouble());
      }
    }
  });

  test('reseed matches JS double arithmetic', () {
    for (final r in section('reseed')) {
      expect(nextSeed(r['s']! as int), r['next'], reason: 's=${r['s']}');
    }
  });

  group('generateOnce matches JS generate', () {
    for (final g in section('generate')) {
      final level = KillerLevel.fromId(g['level']! as String);
      final seed = g['seed']! as int;
      test('${level.id} seed $seed', () {
        final stats = GenStats();
        final p = generateOnce(level, seed, stats);
        if (g['none'] == true) {
          expect(p, isNull);
          return;
        }
        expect(p, isNotNull);
        expect(p!.solution, ints(g['sol']));
        expect(p.cages, cagesOf(g['cages']));
        expect(p.cageOf, ints(g['cageOf']));
        expect(p.nodes, g['nodes']);
        expect(stats.tries, g['tries']);
        expect(stats.solves, g['solves']);
      });
    }
  });

  test('generate retry loop matches the web worker', () {
    for (final r in section('retry')) {
      final level = KillerLevel.fromId(r['level']! as String);
      final p = generate(level, r['seed']! as int);
      expect(p.solution, ints(r['sol']));
    }
  });

  test('candidates match JS', () {
    final gens = {
      for (final g in section('generate'))
        if (g['none'] != true) '${g['level']}/${g['seed']}': g,
    };
    for (final c in section('candidates')) {
      final g = gens['${c['level']}/${c['seed']}']!;
      final cages = cagesOf(g['cages']);
      final res = candidates(cages, ints(g['cageOf']), ints(c['vals']));
      expect(res.cand, ints(c['cand']));
      expect(res.houseMask, ints(c['houseMask']));
      expect(res.cageMask, ints(c['cageMask']));
    }
  });

  test('solver count and node totals match JS', () {
    final gens = {
      for (final g in section('generate'))
        if (g['none'] != true) '${g['level']}/${g['seed']}': g,
    };
    for (final s in section('solve')) {
      final g = gens['${s['level']}/${s['seed']}']!;
      final r = solve(
        cagesOf(g['cages']),
        ints(g['cageOf']),
        limit: 2,
        nodeLimit: 100000,
      );
      expect(r.count, s['count']);
      expect(r.nodes, s['nodes']);
      expect(r.aborted, s['aborted']);
    }
  });
}
