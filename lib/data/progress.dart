import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/killer/level.dart';
import 'kv_store.dart';

/// Stars and stage (`Lv`) of one level (TZ §5.5).
@immutable
class LevelProgress {
  const LevelProgress({
    this.lv = 1,
    this.stars = 0,
    this.total = 0,
    this.seenLv = 1,
  });

  static const int starsPerLv = 100;

  final int lv;

  /// Stars towards the next Lv (0..99).
  final int stars;

  /// All stars ever earned on this level.
  final int total;

  /// Highest Lv the player has started a game at; a higher [lv] shows the
  /// dark "new" badge.
  final int seenLv;

  bool get isNew => lv > seenLv;

  /// Adds [n] stars; overflow carries into the next Lv.
  LevelProgress add(int n) {
    final s = stars + n;
    return LevelProgress(
      lv: lv + s ~/ starsPerLv,
      stars: s % starsPerLv,
      total: total + n,
      seenLv: seenLv,
    );
  }

  LevelProgress seen() => LevelProgress(
        lv: lv,
        stars: stars,
        total: total,
        seenLv: lv,
      );

  Map<String, int> toJson() =>
      {'lv': lv, 'stars': stars, 'total': total, 'seenLv': seenLv};

  factory LevelProgress.fromJson(Map<String, Object?> j) => LevelProgress(
        lv: j['lv']! as int,
        stars: j['stars']! as int,
        total: j['total']! as int,
        seenLv: (j['seenLv'] as int?) ?? 1,
      );
}

/// The `progress` box (TZ §7.1): per-level stars and Lv, last played level
/// and solved daily challenges. Kept apart from `history`, so resetting
/// statistics does not take away earned stages and trophies.
class ProgressRepository {
  ProgressRepository(this._kv);

  static const box = 'progress';
  final KvStore _kv;

  LevelProgress level(KillerLevel l) {
    final raw = _kv.get(box, 'level:${l.id}');
    if (raw == null) return const LevelProgress();
    return LevelProgress.fromJson(
      (jsonDecode(raw) as Map<Object?, Object?>).cast<String, Object?>(),
    );
  }

  Future<void> setLevel(KillerLevel l, LevelProgress p) =>
      _kv.put(box, 'level:${l.id}', jsonEncode(p.toJson()));

  KillerLevel? get lastLevel {
    final id = _kv.get(box, 'lastLevel');
    return id == null ? null : KillerLevel.fromId(id);
  }

  Future<void> setLastLevel(KillerLevel l) => _kv.put(box, 'lastLevel', l.id);

  /// Daily challenge date keys (`YYYY-MM-DD`) that were solved.
  Set<String> get dailySolved {
    final raw = _kv.get(box, 'daily');
    if (raw == null) return {};
    return {...(jsonDecode(raw) as List<Object?>).cast<String>()};
  }

  Future<void> addDailySolved(String key) =>
      _kv.put(box, 'daily', jsonEncode([...dailySolved, key]..sort()));
}

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(kvStoreProvider)),
);
