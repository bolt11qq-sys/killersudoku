import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/data/game_record.dart';
import 'package:killer_sudoku/data/game_repository.dart';
import 'package:killer_sudoku/data/kv_store.dart';
import 'package:killer_sudoku/data/progress.dart';
import 'package:killer_sudoku/data/stats.dart';
import 'package:killer_sudoku/engine/killer/level.dart';
import 'package:killer_sudoku/features/game/board/board_view.dart';
import 'package:killer_sudoku/features/game/game_state.dart';
import 'package:killer_sudoku/features/game/hint_panel.dart';
import 'package:killer_sudoku/l10n/strings.dart';

import 'game/game_screen_test.dart' show inSheet, startNewGame;
import 'helpers.dart';

GameRecord win(int daysAgo, {KillerLevel level = KillerLevel.medium}) =>
    GameRecord(
      date: testNow.subtract(Duration(days: daysAgo)),
      level: level,
      result: GameResult.won,
      seconds: 400,
      mistakes: 0,
      hints: 0,
      score: 500,
      stars: 2,
    );

void main() {
  testWidgets('home shows rating, streak, daily card and how-to-play',
      (tester) async {
    final repo = MemoryGameRepository()
      ..records.addAll([win(1), win(2), win(3)]);
    await pumpApp(tester, repo: repo);

    expect(find.text('${Stats.rating(repo.records)}'), findsOneWidget);
    expect(find.text('3'), findsOneWidget, reason: '3-day streak');
    expect(find.text(S.dailyDate(testNow)), findsOneWidget);
    expect(find.text(S.play), findsOneWidget);

    await tester.tap(find.text(S.howToPlay));
    await settle(tester);
    expect(find.text(S.rules.first.$2), findsOneWidget);
  });

  testWidgets('new game sheet shows weekly win rate and Lv badges',
      (tester) async {
    final kv = MemoryKvStore();
    await ProgressRepository(kv)
        .setLevel(KillerLevel.hard, const LevelProgress(lv: 2, stars: 39));
    await ProgressRepository(kv).setLastLevel(KillerLevel.hard);
    final repo = MemoryGameRepository()..records.addAll([win(1), win(2)]);
    await pumpApp(tester, repo: repo, kv: kv);

    await tester.tap(find.text(S.newGame));
    await settle(tester);
    expect(
      find.textContaining(S.weeklyWinRate(100), findRichText: true),
      findsOneWidget,
    );
    expect(inSheet(S.lv(2)), findsOneWidget);
    expect(inSheet(S.lv(1)), findsNWidgets(4));
    expect(inSheet(' ${S.starsProgress(39)}'), findsOneWidget);
  });

  testWidgets('daily card starts the daily challenge', (tester) async {
    final repo = await pumpApp(tester);
    await tester.tap(find.text(S.play));
    await settle(tester);
    expect(find.byType(BoardView), findsOneWidget);
    // Saturday → Ekspert.
    expect(find.text(S.level(KillerLevel.expert)), findsOneWidget);
    final saved = GameState.fromJson(
      (jsonDecode(repo.current!) as Map<Object?, Object?>)
          .cast<String, Object?>(),
    );
    expect(saved.dailyKey, Daily.key(testNow));
    expect(saved.puzzle.seed, Daily.seed(testNow));
  });

  testWidgets('smart hint opens in three steps and applies', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);

    await tester.tap(find.text(S.toolHint));
    await tester.pump();
    expect(find.byType(HintPanel), findsOneWidget);
    expect(find.text(S.hintNext), findsOneWidget);
    await tester.tap(find.text(S.hintNext));
    await tester.pump();
    await tester.tap(find.text(S.hintNext));
    await tester.pump();
    expect(find.text(S.hintApply), findsOneWidget);
    await tester.tap(find.text(S.hintApply));
    await tester.pump();
    expect(find.byType(HintPanel), findsNothing);
    // The hint digit counts as filled but gives no points.
    expect(find.text('1/81'), findsOneWidget);
    expect(find.text(S.score(0)), findsOneWidget);
  });

  testWidgets('winning shows stars and level progress', (tester) async {
    final values = [...testPuzzle.solution]..[0] = 0;
    final s = GameState.start(testPuzzle).copyWith(
      values: List.unmodifiable(values),
      selected: 0,
      elapsed: 60,
    );
    final repo = MemoryGameRepository()..current = jsonEncode(s.toJson());
    final kv = MemoryKvStore();
    await pumpApp(tester, repo: repo, kv: kv);
    await tester.tap(find.text(S.continueGame));
    await settle(tester);
    await tester.tap(find.text(S.resume));
    await settle(tester);
    final rect = tester.getRect(find.byType(BoardView));
    await tester.tapAt(rect.topLeft + Offset(rect.width / 18, rect.width / 18));
    await tester.pump();
    final digit = find.descendant(
      of: find.byType(InkWell),
      matching: find.text('${testPuzzle.solution[0]}'),
    );
    await tester.tap(digit.last);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(S.winTitle), findsOneWidget);
    expect(find.text(S.starWin), findsOneWidget);
    expect(find.text(S.starClean), findsOneWidget);
    expect(find.text(S.starFast), findsOneWidget);
    // Clean and fast: 3 stars on O'rta.
    expect(repo.records.single.stars, 3);
    expect(ProgressRepository(kv).level(KillerLevel.medium).stars, 3);
  });

  testWidgets('calendar marks solved days and plays a past day',
      (tester) async {
    final kv = MemoryKvStore();
    await ProgressRepository(kv).addDailySolved('2026-10-16');
    await pumpApp(tester, kv: kv);
    await tester.tap(find.byTooltip(S.streakTooltip));
    await settle(tester);
    expect(find.text('${S.monthName(10)} 2026'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    await tester.tap(find.text('5'));
    await settle(tester);
    expect(find.byType(BoardView), findsOneWidget);
  });

  testWidgets('Men shows statistics and saved puzzles', (tester) async {
    final repo = MemoryGameRepository()
      ..records.addAll([win(0), win(1)]);
    await repo.setSaved(testPuzzle, saved: true);
    await pumpApp(tester, repo: repo);
    await tester.tap(find.text(S.tabMe));
    await settle(tester);
    expect(find.text(S.statsTitle), findsOneWidget);
    expect(find.text(S.statPlayed), findsOneWidget);
    expect(find.text(S.chartTitle), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await settle(tester);
    expect(find.text(S.savedTitle), findsOneWidget);
    expect(find.text(S.level(KillerLevel.medium)), findsWidgets);
  });

  testWidgets('settings change the theme and survive', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text(S.tabMe));
    await settle(tester);
    await tester.tap(find.byTooltip(S.settingsTitle));
    await settle(tester);
    expect(find.text(S.setMistakeLimit), findsOneWidget);
    await tester.tap(find.text(S.themeDark));
    await settle(tester);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
