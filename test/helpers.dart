import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/data/game_repository.dart';
import 'package:killer_sudoku/data/kv_store.dart';
import 'package:killer_sudoku/data/settings.dart';
import 'package:killer_sudoku/engine/killer/generator.dart';
import 'package:killer_sudoku/engine/killer/level.dart';
import 'package:killer_sudoku/engine/killer/puzzle.dart';
import 'package:killer_sudoku/features/game/feedback.dart';
import 'package:killer_sudoku/features/game/game_controller.dart';
import 'package:killer_sudoku/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One fixed puzzle for all widget tests (generated once, ~50 ms).
final KillerPuzzle testPuzzle = generate(KillerLevel.medium, 11);

/// [testPuzzle] relabelled to [level], so every level is instant in tests.
KillerPuzzle puzzleFor(KillerLevel level, [int seed = 11]) => KillerPuzzle(
      level: level,
      seed: seed,
      solution: testPuzzle.solution,
      cages: testPuzzle.cages,
      cageOf: testPuzzle.cageOf,
      givens: testPuzzle.givens,
    );

/// A fixed "now": Saturday 17 October 2026 (daily level Ekspert).
final DateTime testNow = DateTime(2026, 10, 17, 12);

/// Pumps the whole app with in-memory storage and instant puzzles.
Future<MemoryGameRepository> pumpApp(
  WidgetTester tester, {
  MemoryGameRepository? repo,
  MemoryKvStore? kv,
  Map<String, Object> prefs = const {},
  DateTime? now,
}) async {
  // Xiaomi 12T-like logical size.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final r = repo ?? MemoryGameRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(r),
        kvStoreProvider.overrideWithValue(kv ?? MemoryKvStore()),
        sharedPreferencesProvider.overrideWithValue(sp),
        feedbackProvider.overrideWithValue(SilentFeedback()),
        clockProvider.overrideWithValue(() => now ?? testNow),
        puzzleGeneratorProvider.overrideWithValue(
          (level, seed) async => puzzleFor(level, seed),
        ),
      ],
      child: const KillerSudokuApp(),
    ),
  );
  await tester.pump();
  return r;
}

/// Settles animations without waiting on the 1-second game timer forever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
