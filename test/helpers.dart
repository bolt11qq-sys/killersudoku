import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/data/game_repository.dart';
import 'package:killer_sudoku/data/settings.dart';
import 'package:killer_sudoku/engine/killer/generator.dart';
import 'package:killer_sudoku/engine/killer/level.dart';
import 'package:killer_sudoku/engine/killer/puzzle.dart';
import 'package:killer_sudoku/features/game/game_controller.dart';
import 'package:killer_sudoku/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One fixed puzzle for all widget tests (generated once, ~50 ms).
final KillerPuzzle testPuzzle = generate(KillerLevel.medium, 11);

/// Pumps the whole app with in-memory storage and a fixed puzzle source.
Future<MemoryGameRepository> pumpApp(
  WidgetTester tester, {
  MemoryGameRepository? repo,
  Map<String, Object> prefs = const {},
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
        sharedPreferencesProvider.overrideWithValue(sp),
        puzzleSourceProvider.overrideWithValue(
          (level) async => level == testPuzzle.level
              ? testPuzzle
              : generate(level, 11),
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
