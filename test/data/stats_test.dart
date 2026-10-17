import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/data/game_record.dart';
import 'package:killer_sudoku/data/progress.dart';
import 'package:killer_sudoku/data/stats.dart';
import 'package:killer_sudoku/engine/killer/level.dart';

final now = DateTime(2026, 10, 17, 12);

GameRecord rec({
  int daysAgo = 0,
  KillerLevel level = KillerLevel.medium,
  GameResult result = GameResult.won,
  int seconds = 600,
  int mistakes = 0,
  int hints = 0,
}) =>
    GameRecord(
      date: now.subtract(Duration(days: daysAgo)),
      level: level,
      result: result,
      seconds: seconds,
      mistakes: mistakes,
      hints: hints,
      score: 0,
    );

void main() {
  group('stars (TZ §5.5)', () {
    Stars stars(int seconds, {int mistakes = 0, int hints = 0, bool unlimited = false, List<GameRecord> h = const []}) =>
        Stats.starsFor(
          level: KillerLevel.medium,
          seconds: seconds,
          mistakes: mistakes,
          hints: hints,
          unlimited: unlimited,
          history: h,
        );

    test('1 to 3 stars', () {
      expect(stars(13 * 60, mistakes: 1).count, 1);
      expect(stars(13 * 60).count, 2, reason: 'clean, slower than 12 min');
      expect(stars(11 * 60).count, 3);
      expect(stars(11 * 60, hints: 1).count, 2);
      expect(stars(11 * 60, unlimited: true).count, 2);
    });

    test('speed star uses the median once 5 wins exist', () {
      final h = [for (var k = 0; k < 5; k++) rec(seconds: 300)];
      expect(Stats.fastThreshold(KillerLevel.medium, h), 300);
      expect(stars(400, h: h).fast, isFalse);
      expect(stars(250, h: h).fast, isTrue);
      expect(Stats.fastThreshold(KillerLevel.medium, h.take(4).toList()), 720);
    });
  });

  test('level progress carries overflow into the next Lv', () {
    var p = const LevelProgress(lv: 2, stars: 99);
    p = p.add(3);
    expect(p.lv, 3);
    expect(p.stars, 2);
    expect(p.total, 3);
    expect(p.isNew, isTrue);
    expect(p.seen().isNew, isFalse);
  });

  test('weekly win rate counts the last 7 days', () {
    final h = [
      rec(daysAgo: 1),
      rec(daysAgo: 2, result: GameResult.lost),
      rec(daysAgo: 3, result: GameResult.abandoned),
      rec(daysAgo: 10),
    ];
    expect(Stats.weeklyWinRate(h, now), 33);
    expect(Stats.weeklyWinRate(const [], now), isNull);
  });

  test('streak ends today or yesterday', () {
    expect(Stats.streak([rec(), rec(daysAgo: 1), rec(daysAgo: 2)], now), 3);
    expect(Stats.streak([rec(daysAgo: 1), rec(daysAgo: 2)], now), 2);
    expect(Stats.streak([rec(daysAgo: 2)], now), 0);
    expect(Stats.wonToday([rec(daysAgo: 1)], now), isFalse);
  });

  test('rating is 0..100 and rewards harder, cleaner games', () {
    expect(Stats.rating(const []), 0);
    final easy = [for (var k = 0; k < 5; k++) rec(level: KillerLevel.easy, mistakes: 2)];
    final devil = [for (var k = 0; k < 5; k++) rec(level: KillerLevel.devil, seconds: 1200)];
    expect(Stats.rating(devil), greaterThan(Stats.rating(easy)));
    expect(Stats.rating(devil), inInclusiveRange(0, 100));
    final withLosses = [...devil, for (var k = 0; k < 3; k++) rec(result: GameResult.lost)];
    expect(Stats.rating(withLosses), Stats.rating(devil) - 6);
  });

  test('level statistics', () {
    final h = [
      rec(seconds: 500),
      rec(seconds: 700, mistakes: 1),
      rec(result: GameResult.lost),
      rec(seconds: 300),
      rec(level: KillerLevel.devil),
    ];
    final s = Stats.levelStats(h, KillerLevel.medium);
    expect(s.played, 4);
    expect(s.won, 3);
    expect(s.winRate, 75);
    expect(s.bestSeconds, 300);
    expect(s.avgSeconds, 500);
    expect(s.flawless, 2);
    expect(s.currentStreak, 1);
    expect(s.longestStreak, 2);
  });

  test('daily times: 30 days, oldest first, averaged per day', () {
    final t = Stats.dailyTimes(
      [rec(seconds: 100), rec(seconds: 300), rec(daysAgo: 29, seconds: 50)],
      KillerLevel.medium,
      now,
    );
    expect(t, hasLength(30));
    expect(t.last, 200);
    expect(t.first, 50);
    expect(t[10], isNull);
  });

  test('daily challenge seed and weekday levels (TZ §4.2)', () {
    expect(Daily.seed(DateTime(2026, 10, 17)), 20261017);
    expect(Daily.key(DateTime(2026, 1, 5)), '2026-01-05');
    final monday = DateTime(2026, 10, 12);
    final levels = [for (var d = 0; d < 7; d++) Daily.level(monday.add(Duration(days: d)))];
    expect(levels, [
      KillerLevel.medium,
      KillerLevel.medium,
      KillerLevel.hard,
      KillerLevel.hard,
      KillerLevel.expert,
      KillerLevel.expert,
      KillerLevel.devil,
    ]);
  });
}
