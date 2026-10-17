import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../engine/killer/level.dart';
import '../engine/killer/puzzle.dart';
import 'kv_store.dart';

typedef PuzzleGenerator = Future<KillerPuzzle> Function(
  KillerLevel level,
  int seed,
);

/// Ready-made puzzles, two per level (TZ §4.2), so "Yangi o'yin" opens
/// instantly. Refilling runs one generation at a time in the background.
class PuzzleCache {
  PuzzleCache(this._kv, this._generate, this._nextSeed);

  static const box = 'puzzle_cache';
  static const int perLevel = 2;

  /// Fill order: quick levels first so most choices are ready soonest.
  static const fillOrder = [
    KillerLevel.medium,
    KillerLevel.easy,
    KillerLevel.hard,
    KillerLevel.expert,
    KillerLevel.devil,
  ];

  final KvStore _kv;
  final PuzzleGenerator _generate;
  final int Function() _nextSeed;
  Future<void>? _refilling;

  List<Map<String, Object?>> _list(KillerLevel l) {
    final raw = _kv.get(box, l.id);
    if (raw == null) return [];
    try {
      return [
        for (final p in jsonDecode(raw) as List<Object?>)
          (p! as Map<Object?, Object?>).cast<String, Object?>(),
      ];
    } on Object {
      return [];
    }
  }

  Future<void> _save(KillerLevel l, List<Map<String, Object?>> list) =>
      _kv.put(box, l.id, jsonEncode(list));

  int count(KillerLevel l) => _list(l).length;

  /// Removes and returns a cached puzzle, or null when the level is empty.
  KillerPuzzle? take(KillerLevel l) {
    final list = _list(l);
    if (list.isEmpty) return null;
    final first = list.removeAt(0);
    unawaited(_save(l, list));
    return KillerPuzzle.fromJson(first);
  }

  /// A puzzle for [level]: from the cache if possible, generated otherwise.
  /// Either way the cache is topped up afterwards.
  Future<KillerPuzzle> next(KillerLevel level) async {
    final cached = take(level);
    final puzzle = cached ?? await _generate(level, _nextSeed());
    unawaited(refill());
    return puzzle;
  }

  static String _dailyKey(int seed) => 'daily:$seed';

  /// The daily challenge puzzle for a date seed. Generated once (it is
  /// deterministic) and kept, so reopening a day is instant.
  Future<KillerPuzzle> daily(KillerLevel level, int seed) async {
    final raw = _kv.get(box, _dailyKey(seed));
    if (raw != null) {
      try {
        return KillerPuzzle.fromJson(
          (jsonDecode(raw) as Map<Object?, Object?>).cast<String, Object?>(),
        );
      } on Object {
        // Fall through and regenerate.
      }
    }
    final p = await _generate(level, seed);
    await _kv.put(box, _dailyKey(seed), jsonEncode(p.toJson()));
    return p;
  }

  /// Tops every level up to [perLevel]; concurrent calls share one run.
  Future<void> refill() => _refilling ??= _refill().whenComplete(() {
        _refilling = null;
      });

  Future<void> _refill() async {
    for (final l in fillOrder) {
      while (count(l) < perLevel) {
        try {
          final p = await _generate(l, _nextSeed());
          await _save(l, [..._list(l), p.toJson()]);
        } on Object catch (e) {
          debugPrint('Cache refill failed for ${l.id}: $e');
          return;
        }
      }
    }
  }
}
