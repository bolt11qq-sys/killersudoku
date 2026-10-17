import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/data/game_record.dart';
import 'package:killer_sudoku/data/game_repository.dart';
import 'package:killer_sudoku/engine/killer/level.dart';
import 'package:killer_sudoku/features/game/board/board_view.dart';
import 'package:killer_sudoku/features/game/game_state.dart';
import 'package:killer_sudoku/l10n/strings.dart';

import '../helpers.dart';

int sol(int i) => testPuzzle.solution[i];
int wrong(int i) => sol(i) % 9 + 1;

Future<void> startNewGame(WidgetTester tester) async {
  await tester.tap(find.text(S.newGame));
  await settle(tester);
  await tester.tap(find.text(S.level(KillerLevel.medium)));
  await settle(tester);
}

Future<void> tapCell(WidgetTester tester, int i) async {
  final rect = tester.getRect(find.byType(BoardView));
  final cell = rect.width / 9;
  await tester.tapAt(rect.topLeft +
      Offset((i % 9 + 0.5) * cell, (i ~/ 9 + 0.5) * cell));
  await tester.pump();
}

/// Taps the number-pad button for digit [d] (the pad's big digit text).
Future<void> tapDigit(WidgetTester tester, int d) async {
  final buttons = find.descendant(
    of: find.byType(InkWell),
    matching: find.text('$d'),
  );
  await tester.tap(buttons.last);
  await tester.pump();
}

/// A saved game with every cell solved except [open].
MemoryGameRepository repoWithAlmostSolved(List<int> open) {
  final values = [...testPuzzle.solution];
  for (final i in open) {
    values[i] = 0;
  }
  final s = GameState.start(testPuzzle).copyWith(
    values: List.unmodifiable(values),
    selected: open.first,
    elapsed: 90,
  );
  return MemoryGameRepository()..current = jsonEncode(s.toJson());
}

void main() {
  testWidgets('new game: sheet lists five levels and opens the board',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text(S.newGame));
    await settle(tester);
    for (final l in KillerLevel.values) {
      expect(find.text(S.level(l)), findsOneWidget);
    }
    await tester.tap(find.text(S.level(KillerLevel.medium)));
    await settle(tester);

    expect(find.byType(BoardView), findsOneWidget);
    expect(find.text(S.score(0)), findsOneWidget);
    expect(find.text(S.mistakes(0, 3)), findsOneWidget);
    expect(find.text('0/81'), findsOneWidget);
    expect(find.text(S.toolFastPencil), findsOneWidget);
  });

  testWidgets('entering the right digit scores and is saved', (tester) async {
    final repo = await pumpApp(tester);
    await startNewGame(tester);

    await tapCell(tester, 0);
    await tapDigit(tester, sol(0));
    expect(find.text(S.score(30)), findsOneWidget);
    expect(find.text('1/81'), findsOneWidget);
    expect(repo.current, isNotNull);
    final saved = GameState.fromJson(
      (jsonDecode(repo.current!) as Map<Object?, Object?>)
          .cast<String, Object?>(),
    );
    expect(saved.values[0], sol(0));
  });

  testWidgets('wrong digits count mistakes; the third one loses',
      (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);

    for (final i in [0, 1]) {
      await tapCell(tester, i);
      await tapDigit(tester, wrong(i));
    }
    expect(find.text(S.mistakes(2, 3)), findsOneWidget);
    await tapCell(tester, 2);
    await tapDigit(tester, wrong(2));
    await settle(tester);
    expect(find.text(S.lossTitle), findsOneWidget);

    await tester.tap(find.text(S.lossContinue));
    await settle(tester);
    expect(find.text(S.lossTitle), findsNothing);
    expect(find.text(S.mistakes(0, null)), findsOneWidget);
  });

  testWidgets('pause hides the board and resumes', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);

    await tester.tap(find.byTooltip(S.pause));
    await settle(tester);
    expect(find.text(S.resume), findsOneWidget);
    await tester.tap(find.text(S.resume));
    await settle(tester);
    expect(find.text(S.resume), findsNothing);
  });

  testWidgets('pencil mode writes notes instead of digits', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);

    await tester.tap(find.text(S.toolPencil));
    await tester.pump();
    expect(find.text(S.pencilOn), findsOneWidget);
    await tapCell(tester, 0);
    await tapDigit(tester, 5);
    expect(find.text(S.score(0)), findsOneWidget);
    expect(find.text('0/81'), findsOneWidget);
  });

  testWidgets('cage panel lists combos for the selected cage',
      (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);

    await tapCell(tester, 0);
    final cage = testPuzzle.cages[testPuzzle.cageOf[0]];
    expect(find.textContaining('Σ ${cage.sum} · ${cage.size} katak'),
        findsOneWidget);
  });

  testWidgets('saved game offers "Davom etish" and restores paused',
      (tester) async {
    await pumpApp(tester, repo: repoWithAlmostSolved([0, 1]));
    expect(find.text(S.continueGame), findsOneWidget);

    await tester.tap(find.text(S.continueGame));
    await settle(tester);
    expect(find.text(S.resume), findsOneWidget, reason: 'restored paused');
  });

  testWidgets('placing the last digit wins and records history',
      (tester) async {
    final repo = await pumpApp(tester, repo: repoWithAlmostSolved([0]));
    await tester.tap(find.text(S.continueGame));
    await settle(tester);
    await tester.tap(find.text(S.resume));
    await settle(tester);

    await tapCell(tester, 0);
    await tapDigit(tester, sol(0));
    await settle(tester);
    expect(find.text(S.winTitle), findsOneWidget);
    expect(find.text(S.newRecord), findsOneWidget, reason: 'first win');
    expect(repo.records.single.result, GameResult.won);
    expect(repo.current, isNull);

    await tester.tap(find.text(S.goHome));
    await settle(tester);
    expect(find.text(S.modeTitle), findsOneWidget);
    expect(find.text(S.continueGame), findsNothing);
  });

  testWidgets('a new game over an unfinished one records it as abandoned',
      (tester) async {
    final repo = await pumpApp(tester, repo: repoWithAlmostSolved([0, 1]));
    await tester.tap(find.text(S.newGame));
    await settle(tester);
    await tester.tap(find.text(S.level(KillerLevel.medium)));
    await settle(tester);
    expect(repo.records.single.result, GameResult.abandoned);
  });
}
