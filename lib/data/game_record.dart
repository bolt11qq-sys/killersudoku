import '../engine/killer/level.dart';

enum GameResult { won, lost, abandoned }

/// One finished game, stored in the `history` box (TZ §7.1). Statistics,
/// stars and rating are computed from these records.
class GameRecord {
  const GameRecord({
    required this.date,
    required this.level,
    required this.result,
    required this.seconds,
    required this.mistakes,
    required this.hints,
    required this.score,
    this.unlimited = false,
    this.daily = false,
    this.stars = 0,
  });

  final DateTime date;
  final KillerLevel level;
  final GameResult result;
  final int seconds;
  final int mistakes;
  final int hints;
  final int score;

  /// Continued after the mistake limit was reached.
  final bool unlimited;
  final bool daily;

  /// Stars earned (1..3 for a win, 0 otherwise).
  final int stars;

  Map<String, Object> toJson() => {
        'date': date.toIso8601String(),
        'level': level.id,
        'result': result.name,
        'seconds': seconds,
        'mistakes': mistakes,
        'hints': hints,
        'score': score,
        'unlimited': unlimited,
        'daily': daily,
        'stars': stars,
      };

  factory GameRecord.fromJson(Map<String, Object?> j) => GameRecord(
        date: DateTime.parse(j['date']! as String),
        level: KillerLevel.fromId(j['level']! as String),
        result: GameResult.values.byName(j['result']! as String),
        seconds: j['seconds']! as int,
        mistakes: j['mistakes']! as int,
        hints: j['hints']! as int,
        score: j['score']! as int,
        unlimited: (j['unlimited'] as bool?) ?? false,
        daily: (j['daily'] as bool?) ?? false,
        stars: (j['stars'] as int?) ?? 0,
      );
}
