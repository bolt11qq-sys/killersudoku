import 'dart:math' as math;

import '../engine/killer/level.dart';
import 'game_record.dart';

/// Pure statistics over the game history (TZ §5.5, §3.5). Records are in
/// chronological order (oldest first).
abstract final class Stats {
  /// Reference solve times used for the "tezkor" star until a level has
  /// [minWinsForMedian] wins (TZ §5.5).
  static int referenceSeconds(KillerLevel l) => switch (l) {
        KillerLevel.easy => 8 * 60,
        KillerLevel.medium => 12 * 60,
        KillerLevel.hard => 18 * 60,
        KillerLevel.expert => 25 * 60,
        KillerLevel.devil => 35 * 60,
      };

  static const int minWinsForMedian = 5;
  static const int recentWins = 20;

  static List<GameRecord> wins(List<GameRecord> h, [KillerLevel? level]) => [
        for (final r in h)
          if (r.result == GameResult.won && (level == null || r.level == level))
            r,
      ];

  static int median(List<int> xs) {
    final s = [...xs]..sort();
    final n = s.length;
    return n.isOdd ? s[n ~/ 2] : ((s[n ~/ 2 - 1] + s[n ~/ 2]) / 2).round();
  }

  /// Time to beat for the speed star on [level].
  static int fastThreshold(KillerLevel level, List<GameRecord> history) {
    final w = wins(history, level);
    if (w.length < minWinsForMedian) return referenceSeconds(level);
    final recent = w.sublist(math.max(0, w.length - recentWins));
    return median([for (final r in recent) r.seconds]);
  }

  /// Stars for a win (TZ §5.5): 1 for winning, +1 clean (no mistakes, no
  /// hints, never continued after a loss), +1 faster than the threshold.
  static Stars starsFor({
    required KillerLevel level,
    required int seconds,
    required int mistakes,
    required int hints,
    required bool unlimited,
    required List<GameRecord> history,
  }) {
    final clean = mistakes == 0 && hints == 0 && !unlimited;
    final fast = seconds < fastThreshold(level, history);
    return Stars(clean: clean, fast: fast);
  }

  /// Share of games started in the last 7 days that were won (0..100), or
  /// null when no game was played.
  static int? weeklyWinRate(List<GameRecord> h, DateTime now) {
    final from = now.subtract(const Duration(days: 7));
    final week = [for (final r in h) if (r.date.isAfter(from)) r];
    if (week.isEmpty) return null;
    final won = week.where((r) => r.result == GameResult.won).length;
    return (100 * won / week.length).round();
  }

  static double _levelWeight(KillerLevel l) => switch (l) {
        KillerLevel.easy => 0.2,
        KillerLevel.medium => 0.4,
        KillerLevel.hard => 0.6,
        KillerLevel.expert => 0.8,
        KillerLevel.devil => 1.0,
      };

  /// Brain rating 0..100 (TZ §5.5) from the last 20 wins: level weight
  /// (60 %), speed against the level's typical time (25 %) and a clean
  /// game (15 %). Each loss or abandoned game among the last 20 games
  /// costs 2 points.
  static int rating(List<GameRecord> h) {
    final w = wins(h);
    if (w.isEmpty) return 0;
    final recent = w.sublist(math.max(0, w.length - recentWins));
    var sum = 0.0;
    for (final r in recent) {
      final typical = fastThreshold(r.level, h);
      final speed = (typical / math.max(1, r.seconds) - 0.5).clamp(0.0, 1.0);
      final clean = r.mistakes == 0 && r.hints == 0 && !r.unlimited ? 1 : 0;
      sum += 100 * (0.6 * _levelWeight(r.level) + 0.25 * speed + 0.15 * clean);
    }
    final lastGames = h.sublist(math.max(0, h.length - recentWins));
    final lost = lastGames.where((r) => r.result != GameResult.won).length;
    return (sum / recent.length - 2 * lost).round().clamp(0, 100);
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Days with at least one win.
  static Set<DateTime> winDays(List<GameRecord> h) =>
      {for (final r in wins(h)) _day(r.date)};

  /// Consecutive days with a win, ending today, or yesterday when today
  /// has no win yet (TZ §5.5).
  static int streak(List<GameRecord> h, DateTime now) {
    final days = winDays(h);
    var d = _day(now);
    if (!days.contains(d)) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(d)) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  static bool wonToday(List<GameRecord> h, DateTime now) =>
      winDays(h).contains(_day(now));

  /// Per-level numbers for the "Men" screen (TZ §3.5).
  static LevelStats levelStats(List<GameRecord> h, KillerLevel level) {
    final games = [for (final r in h) if (r.level == level) r];
    final w = wins(games);
    var current = 0, longest = 0, run = 0;
    for (final r in games) {
      if (r.result == GameResult.won) {
        run++;
        longest = math.max(longest, run);
      } else {
        run = 0;
      }
    }
    current = run;
    return LevelStats(
      played: games.length,
      won: w.length,
      bestSeconds: w.isEmpty ? null : w.map((r) => r.seconds).reduce(math.min),
      avgSeconds: w.isEmpty
          ? null
          : (w.map((r) => r.seconds).reduce((a, b) => a + b) / w.length)
              .round(),
      flawless: w.where((r) => r.mistakes == 0 && !r.unlimited).length,
      currentStreak: current,
      longestStreak: longest,
    );
  }

  /// Average winning time per day for the last [days] days (oldest first),
  /// null for days without a win.
  static List<int?> dailyTimes(
    List<GameRecord> h,
    KillerLevel level,
    DateTime now, {
    int days = 30,
  }) {
    final today = _day(now);
    return [
      for (var k = days - 1; k >= 0; k--)
        () {
          final day = DateTime(today.year, today.month, today.day - k);
          final t = [
            for (final r in wins(h, level))
              if (_day(r.date) == day) r.seconds,
          ];
          return t.isEmpty
              ? null
              : (t.reduce((a, b) => a + b) / t.length).round();
        }(),
    ];
  }
}

class Stars {
  const Stars({required this.clean, required this.fast});

  final bool clean;
  final bool fast;

  int get count => 1 + (clean ? 1 : 0) + (fast ? 1 : 0);
}

class LevelStats {
  const LevelStats({
    required this.played,
    required this.won,
    required this.bestSeconds,
    required this.avgSeconds,
    required this.flawless,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int played;
  final int won;
  final int? bestSeconds;
  final int? avgSeconds;
  final int flawless;
  final int currentStreak;
  final int longestStreak;

  int get winRate => played == 0 ? 0 : (100 * won / played).round();
}

/// Daily challenge (TZ §4.2): seed from the date, level from the weekday.
abstract final class Daily {
  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime parse(String key) => DateTime.parse(key);

  /// `YYYYMMDD` as a number.
  static int seed(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  /// Mon–Tue O'rta, Wed–Thu Qiyin, Fri–Sat Ekspert, Sun Iblis.
  static KillerLevel level(DateTime d) => switch (d.weekday) {
        DateTime.monday || DateTime.tuesday => KillerLevel.medium,
        DateTime.wednesday || DateTime.thursday => KillerLevel.hard,
        DateTime.friday || DateTime.saturday => KillerLevel.expert,
        _ => KillerLevel.devil,
      };
}
