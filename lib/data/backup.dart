import 'dart:convert';

import 'package:flutter/material.dart';

import '../engine/killer/puzzle.dart';
import '../features/game/game_state.dart';
import 'game_record.dart';
import 'game_repository.dart';
import 'kv_store.dart';
import 'progress.dart';
import 'settings.dart';

/// Export / import of all user data as one JSON document (TZ §3.5, §7.1).
/// The puzzle cache is left out: it is regenerated automatically.
abstract final class Backup {
  static const app = 'killer_sudoku';
  static const version = 1;

  static String export({
    required GameRepository games,
    required KvStore kv,
    required AppSettings settings,
  }) {
    final current = games.loadCurrent();
    return const JsonEncoder.withIndent(' ').convert({
      'app': app,
      'version': version,
      'current': current?.toJson(),
      'history': [for (final r in games.history()) r.toJson()],
      'saved': [for (final p in games.savedPuzzles()) p.toJson()],
      'progress': kv.all(ProgressRepository.box),
      'settings': settingsToJson(settings),
    });
  }

  /// Restores a document produced by [export]. Throws [FormatException]
  /// when it is not one, without changing anything.
  static Future<AppSettings> import(
    String text, {
    required GameRepository games,
    required KvStore kv,
  }) async {
    final Map<String, Object?> j;
    final GameState? current;
    final List<GameRecord> history;
    final List<KillerPuzzle> saved;
    final Map<String, String> progress;
    final AppSettings settings;
    try {
      j = (jsonDecode(text) as Map<Object?, Object?>).cast<String, Object?>();
      if (j['app'] != app) throw const FormatException('not a backup');
      Map<String, Object?> obj(Object? o) =>
          (o! as Map<Object?, Object?>).cast<String, Object?>();
      current = j['current'] == null ? null : GameState.fromJson(obj(j['current']));
      history = [
        for (final r in j['history']! as List<Object?>) GameRecord.fromJson(obj(r)),
      ];
      saved = [
        for (final p in j['saved']! as List<Object?>) KillerPuzzle.fromJson(obj(p)),
      ];
      progress = obj(j['progress']).cast<String, String>();
      settings = settingsFromJson(obj(j['settings']));
    } on FormatException {
      rethrow;
    } on Object catch (e) {
      throw FormatException('invalid backup: $e');
    }
    await games.replaceAll(current: current, history: history, saved: saved);
    await kv.clear(ProgressRepository.box);
    for (final e in progress.entries) {
      await kv.put(ProgressRepository.box, e.key, e.value);
    }
    return settings;
  }

  static Map<String, Object> settingsToJson(AppSettings s) => {
        'mistakeLimit': s.mistakeLimit,
        'showErrors': s.showErrors,
        'autoRemoveNotes': s.autoRemoveNotes,
        'highlightSame': s.highlightSame,
        'hideUsedNumbers': s.hideUsedNumbers,
        'showTimer': s.showTimer,
        'numberFirst': s.numberFirst,
        'sound': s.sound,
        'vibration': s.vibration,
        'themeMode': s.themeMode.name,
      };

  static AppSettings settingsFromJson(Map<String, Object?> j) {
    const d = AppSettings();
    bool b(String k, bool def) => (j[k] as bool?) ?? def;
    return AppSettings(
      mistakeLimit: b('mistakeLimit', d.mistakeLimit),
      showErrors: b('showErrors', d.showErrors),
      autoRemoveNotes: b('autoRemoveNotes', d.autoRemoveNotes),
      highlightSame: b('highlightSame', d.highlightSame),
      hideUsedNumbers: b('hideUsedNumbers', d.hideUsedNumbers),
      showTimer: b('showTimer', d.showTimer),
      numberFirst: b('numberFirst', d.numberFirst),
      sound: b('sound', d.sound),
      vibration: b('vibration', d.vibration),
      themeMode: ThemeMode.values.asNameMap()[j['themeMode']] ?? d.themeMode,
    );
  }
}
