import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/data/backup.dart';
import 'package:killer_sudoku/data/game_record.dart';
import 'package:killer_sudoku/data/game_repository.dart';
import 'package:killer_sudoku/data/kv_store.dart';
import 'package:killer_sudoku/data/progress.dart';
import 'package:killer_sudoku/data/puzzle_cache.dart';
import 'package:killer_sudoku/data/settings.dart';
import 'package:killer_sudoku/engine/killer/level.dart';
import 'package:killer_sudoku/features/game/game_state.dart';

import '../helpers.dart';

void main() {
  group('puzzle cache', () {
    late MemoryKvStore kv;
    late List<(KillerLevel, int)> calls;
    late PuzzleCache cache;
    var seed = 0;

    setUp(() {
      kv = MemoryKvStore();
      calls = [];
      cache = PuzzleCache(kv, (level, s) async {
        calls.add((level, s));
        return puzzleFor(level, s);
      }, () => ++seed);
    });

    test('refill tops every level up to two', () async {
      await cache.refill();
      for (final l in KillerLevel.values) {
        expect(cache.count(l), PuzzleCache.perLevel);
      }
      expect(calls, hasLength(10));
      expect(calls.first.$1, KillerLevel.medium, reason: 'quick levels first');
    });

    test('next serves from the cache and refills', () async {
      await cache.refill();
      calls.clear();
      final p = await cache.next(KillerLevel.devil);
      expect(p.level, KillerLevel.devil);
      // next() already started the background refill.
      await cache.refill();
      expect(cache.count(KillerLevel.devil), 2);
      expect(calls, hasLength(1));
    });

    test('next generates when the cache is empty', () async {
      final p = await cache.next(KillerLevel.easy);
      expect(p.level, KillerLevel.easy);
      expect(calls.first.$1, KillerLevel.easy);
    });

    test('daily puzzle is generated once with the date seed', () async {
      final a = await cache.daily(KillerLevel.expert, 20261017);
      final b = await cache.daily(KillerLevel.expert, 20261017);
      expect(a.seed, 20261017);
      expect(b.toJson(), a.toJson());
      expect(calls.where((c) => c.$2 == 20261017), hasLength(1));
    });
  });

  test('progress repository stores levels, last level and dailies', () async {
    final repo = ProgressRepository(MemoryKvStore());
    expect(repo.level(KillerLevel.hard).lv, 1);
    await repo.setLevel(KillerLevel.hard, const LevelProgress().add(150));
    expect(repo.level(KillerLevel.hard).lv, 2);
    expect(repo.level(KillerLevel.hard).stars, 50);
    await repo.setLastLevel(KillerLevel.devil);
    expect(repo.lastLevel, KillerLevel.devil);
    await repo.addDailySolved('2026-10-17');
    await repo.addDailySolved('2026-10-16');
    expect(repo.dailySolved, {'2026-10-16', '2026-10-17'});
  });

  test('backup export → import restores everything', () async {
    final games = MemoryGameRepository();
    final kv = MemoryKvStore();
    final progress = ProgressRepository(kv);
    await games.saveCurrent(GameState.start(testPuzzle).copyWith(elapsed: 42));
    await games.addRecord(GameRecord(
      date: DateTime(2026, 10, 1),
      level: KillerLevel.hard,
      result: GameResult.won,
      seconds: 900,
      mistakes: 0,
      hints: 1,
      score: 1234,
      stars: 2,
    ));
    await games.setSaved(testPuzzle, saved: true);
    await progress.setLevel(KillerLevel.hard, const LevelProgress(lv: 3, stars: 7));
    const settings = AppSettings(sound: false, themeMode: ThemeMode.dark);

    final json = Backup.export(games: games, kv: kv, settings: settings);

    final games2 = MemoryGameRepository();
    final kv2 = MemoryKvStore();
    final restored = await Backup.import(json, games: games2, kv: kv2);
    expect(restored.sound, isFalse);
    expect(restored.themeMode, ThemeMode.dark);
    expect(games2.loadCurrent()!.elapsed, 42);
    expect(games2.history().single.score, 1234);
    expect(games2.history().single.stars, 2);
    expect(games2.savedPuzzles().single.toJson(), testPuzzle.toJson());
    expect(ProgressRepository(kv2).level(KillerLevel.hard).lv, 3);
  });

  test('import rejects foreign files without changing data', () async {
    final games = MemoryGameRepository();
    await games.addRecord(GameRecord(
      date: DateTime(2026),
      level: KillerLevel.easy,
      result: GameResult.won,
      seconds: 1,
      mistakes: 0,
      hints: 0,
      score: 0,
    ));
    for (final bad in ['not json', '{"app": "other"}', '{"app": "killer_sudoku"}']) {
      await expectLater(
        Backup.import(bad, games: games, kv: MemoryKvStore()),
        throwsFormatException,
      );
    }
    expect(games.history(), hasLength(1));
  });
}
