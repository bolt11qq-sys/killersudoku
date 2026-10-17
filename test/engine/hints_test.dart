import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/data/settings.dart';
import 'package:killer_sudoku/engine/common/bitmask.dart';
import 'package:killer_sudoku/engine/killer/generator.dart';
import 'package:killer_sudoku/engine/killer/hints.dart';
import 'package:killer_sudoku/engine/killer/level.dart';
import 'package:killer_sudoku/features/game/game_logic.dart';
import 'package:killer_sudoku/features/game/game_state.dart';
import 'package:killer_sudoku/l10n/strings.dart';

void main() {
  const rules = AppSettings();

  test('wrong digits are reported first and removed by applying', () {
    final p = generate(KillerLevel.medium, 5);
    final values = List<int>.filled(81, 0)..[0] = p.solution[0] % 9 + 1;
    final h = findHint(p, values, List.filled(81, 0))!;
    expect(h.kind, HintKind.wrongDigits);
    expect(h.focus, [0]);
    final s = GameLogic.applyHint(
      GameState.start(p).copyWith(values: values),
      h,
      rules,
    );
    expect(s.values[0], 0);
  });

  test('a solved board has no hint', () {
    final p = generate(KillerLevel.easy, 2);
    expect(findHint(p, p.solution, List.filled(81, 0)), isNull);
  });

  // The strongest check: following hints alone always finishes the
  // puzzle, every placed digit is correct and no step repeats forever.
  for (final level in KillerLevel.values) {
    test('${level.id}: applying hints solves the puzzle', () {
      for (final seed in [21, 22, 23]) {
        final p = generate(level, seed);
        var s = GameState.start(p);
        final kinds = <HintKind>{};
        for (var step = 0; step < 400 && s.status != GameStatus.won; step++) {
          final h = findHint(p, s.values, s.notes);
          expect(h, isNotNull, reason: 'stuck at step $step');
          kinds.add(h!.kind);
          // Texts exist for every step of every hint.
          for (var k = 0; k < 3; k++) {
            expect(S.hintText(h, k), isNotEmpty);
          }
          expect(S.hintTitle(h), isNotEmpty);
          if (h.target != null) {
            expect(h.digit, p.solution[h.target!], reason: '${h.kind}');
          }
          for (final e in h.allowed.entries) {
            expect(e.value & bit(p.solution[e.key]), isNot(0));
          }
          s = GameLogic.applyHint(s, h, rules);
        }
        expect(s.status, GameStatus.won, reason: '${level.id} seed $seed');
        expect(s.score, 0, reason: 'hint digits give no points');
        expect(kinds, isNot(contains(HintKind.wrongDigits)));
      }
    });
  }

  test('45 rule hint explains with the region totals', () {
    // Over many seeds at least one innie / outie hint appears first.
    var seen = false;
    for (var seed = 1; seed <= 20 && !seen; seed++) {
      final p = generate(KillerLevel.medium, seed);
      final h = findHint(p, p.givens, List.filled(81, 0))!;
      if (h.kind == HintKind.innie) {
        expect(h.total - h.inside, h.digit);
        seen = true;
      } else if (h.kind == HintKind.outie) {
        expect(h.crossing - (h.total - h.inside), h.digit);
        seen = true;
      }
    }
    expect(seen, isTrue);
  });
}
