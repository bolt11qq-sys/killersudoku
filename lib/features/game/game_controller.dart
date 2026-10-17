import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/game_record.dart';
import '../../data/game_repository.dart';
import '../../data/kv_store.dart';
import '../../data/progress.dart';
import '../../data/puzzle_cache.dart';
import '../../data/settings.dart';
import '../../data/stats.dart';
import '../../engine/killer/generator.dart';
import '../../engine/killer/hints.dart';
import '../../engine/killer/level.dart';
import '../../engine/killer/puzzle.dart';
import 'feedback.dart';
import 'game_logic.dart';
import 'game_state.dart';

/// Current time; tests override it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Generates a puzzle in a background isolate (TZ §4.2). Tests override it.
final puzzleGeneratorProvider = Provider<PuzzleGenerator>(
  (ref) => (level, seed) => Isolate.run(() => generate(level, seed)),
);

final puzzleCacheProvider = Provider<PuzzleCache>((ref) {
  final random = Random();
  return PuzzleCache(
    ref.watch(kvStoreProvider),
    ref.watch(puzzleGeneratorProvider),
    () => random.nextInt(1 << 32),
  );
});

/// Cells to flash after a row / column / block / cage is completed.
@immutable
class Flash {
  const Flash(this.id, this.cells);
  final int id;
  final Set<int> cells;
}

/// What the win dialog shows (TZ §3.3): stars and level progress.
@immutable
class WinSummary {
  const WinSummary({
    required this.stars,
    required this.before,
    required this.after,
    required this.newRecord,
  });

  final Stars stars;
  final LevelProgress before;
  final LevelProgress after;
  final bool newRecord;

  bool get levelUp => after.lv > before.lv;
}

/// An open smart hint and the step shown (0 where, 1 why, 2 result).
@immutable
class HintSession {
  const HintSession(this.hint, this.step);
  final Hint hint;
  final int step;
}

@immutable
class GameSession {
  const GameSession({
    this.game,
    this.generating,
    this.flash,
    this.win,
    this.hint,
    this.noteFocus = 0,
    this.version = 0,
  });

  final GameState? game;

  /// Level currently being generated (shows the loading view).
  final KillerLevel? generating;
  final Flash? flash;
  final WinSummary? win;
  final HintSession? hint;

  /// Digit whose pencil marks are highlighted (long press on the pad).
  final int noteFocus;

  /// Bumped whenever history or progress was written, so screens that
  /// derive statistics rebuild.
  final int version;

  bool get canContinue => game != null && !game!.isOver;

  GameSession copy({
    GameState? game,
    Flash? flash,
    WinSummary? win,
    bool clearHint = false,
    HintSession? hint,
    int? noteFocus,
    int? version,
  }) {
    return GameSession(
      game: game ?? this.game,
      generating: generating,
      flash: flash ?? this.flash,
      win: win ?? this.win,
      hint: clearHint ? null : (hint ?? this.hint),
      noteFocus: noteFocus ?? this.noteFocus,
      version: version ?? this.version,
    );
  }
}

final gameProvider =
    NotifierProvider<GameController, GameSession>(GameController.new);

class GameController extends Notifier<GameSession> {
  GameRepository get _repo => ref.read(gameRepositoryProvider);
  ProgressRepository get _progress => ref.read(progressRepositoryProvider);
  AppSettings get _rules => ref.read(settingsProvider);
  DateTime get _now => ref.read(clockProvider)();
  int _flashId = 0;

  @override
  GameSession build() => GameSession(game: _repo.loadCurrent());

  GameState? get _game => state.game;

  // ---- starting games -----------------------------------------------------

  /// Starts a game on [level] with a cached (or fresh) puzzle.
  Future<void> newGame(KillerLevel level) => _start(
        level,
        () => ref.read(puzzleCacheProvider).next(level),
      );

  /// Starts the daily challenge of [day] (TZ §3.4).
  Future<void> startDaily(DateTime day) {
    final level = Daily.level(day);
    return _start(
      level,
      () => ref.read(puzzleCacheProvider).daily(level, Daily.seed(day)),
      dailyKey: Daily.key(day),
    );
  }

  /// Replays a starred puzzle (TZ §5.6).
  Future<void> startSaved(KillerPuzzle puzzle) =>
      _start(puzzle.level, () async => puzzle);

  Future<void> _start(
    KillerLevel level,
    Future<KillerPuzzle> Function() source, {
    String? dailyKey,
  }) async {
    await _closeCurrent();
    state = GameSession(generating: level, version: state.version + 1);
    try {
      final puzzle = await source();
      if (state.generating != level) return;
      await _progress.setLastLevel(level);
      await _progress.setLevel(level, _progress.level(level).seen());
      final game = GameState.start(puzzle, dailyKey: dailyKey)
          .copyWith(saved: _repo.isSaved(puzzle));
      state = GameSession(game: game, version: state.version + 1);
      _persist();
    } on Object catch (e, st) {
      // Generation retries many seeds and should never fail; if it does,
      // drop back to "no game" instead of leaving a spinner forever.
      debugPrint('Puzzle generation failed: $e\n$st');
      state = GameSession(version: state.version + 1);
    }
  }

  /// Records the current game in history before it is replaced.
  Future<void> _closeCurrent() async {
    final g = _game;
    if (g == null || g.status == GameStatus.won) return;
    final started = g.history.isNotEmpty || g.elapsed > 0;
    if (g.status == GameStatus.lost || started) {
      await _repo.addRecord(_record(
        g,
        g.status == GameStatus.lost ? GameResult.lost : GameResult.abandoned,
      ));
    }
    await _repo.clearCurrent();
  }

  GameRecord _record(GameState g, GameResult result, {int stars = 0}) =>
      GameRecord(
        date: _now,
        level: g.puzzle.level,
        result: result,
        seconds: g.elapsed,
        mistakes: g.mistakes,
        hints: g.hintsUsed,
        score: g.score,
        unlimited: g.unlimited,
        daily: g.daily,
        stars: stars,
      );

  void _persist() {
    final g = _game;
    if (g != null) unawaited(_repo.saveCurrent(g));
  }

  /// Applies a board change; any change closes an open hint.
  void _update(GameState Function(GameState g) f, {bool keepHint = false}) {
    final g = _game;
    if (g == null) return;
    final next = f(g);
    if (identical(next, g)) return;
    if (next.status == GameStatus.won && g.status != GameStatus.won) {
      _onWon(next);
    } else {
      state = state.copy(game: next, clearHint: !keepHint);
      _persist();
    }
  }

  // ---- input -------------------------------------------------------------

  /// Tap on a cell. In number-first mode this also places the picked digit.
  void tapCell(int i) {
    final g = _game;
    if (g == null) return;
    _update((g) => GameLogic.select(g, i), keepHint: true);
    if (_rules.numberFirst && g.pickedDigit != 0) input(g.pickedDigit);
    if (state.noteFocus != 0) state = state.copy(noteFocus: 0);
  }

  /// Tap on a number-pad button.
  void tapDigit(int d) {
    if (_game == null) return;
    if (_rules.numberFirst) {
      _update((g) => GameLogic.pickDigit(g, d), keepHint: true);
    } else {
      input(d);
    }
  }

  /// Long press on a pad digit: highlight cells with that pencil mark
  /// (TZ §5.2); pressing the same digit again clears it.
  void focusNotes(int d) =>
      state = state.copy(noteFocus: state.noteFocus == d ? 0 : d);

  void input(int d) {
    final g = _game;
    if (g == null) return;
    final r = GameLogic.input(g, d, _rules);
    if (identical(r.state, g)) return;
    Flash? flash;
    if (r.completed.isNotEmpty) {
      flash = Flash(++_flashId, {for (final u in r.completed) ...u.cells});
    }
    final fb = ref.read(feedbackProvider);
    if (r.mistake) {
      fb.mistake();
    } else if (r.completed.isNotEmpty) {
      fb.unitDone();
    } else if (!g.notesMode) {
      fb.tap();
    }
    if (r.state.status == GameStatus.won) {
      _onWon(r.state, flash: flash);
    } else {
      state = state.copy(game: r.state, flash: flash, clearHint: true);
      _persist();
    }
  }

  /// Publishes the won game together with its stars and progress in one
  /// update (the win dialog opens as soon as listeners see the won
  /// status), then stores everything.
  void _onWon(GameState g, {Flash? flash}) {
    final level = g.puzzle.level;
    final history = _repo.history();
    final best = Stats.wins(history, level).map((r) => r.seconds).fold<int?>(
          null,
          (m, s) => m == null || s < m ? s : m,
        );
    final stars = Stats.starsFor(
      level: level,
      seconds: g.elapsed,
      mistakes: g.mistakes,
      hints: g.hintsUsed,
      unlimited: g.unlimited,
      history: history,
    );
    final before = _progress.level(level);
    final after = before.add(stars.count);
    state = state.copy(
      game: g,
      flash: flash,
      clearHint: true,
      win: WinSummary(
        stars: stars,
        before: before,
        after: after,
        newRecord: best == null || g.elapsed < best,
      ),
    );
    ref.read(feedbackProvider).win();
    unawaited(_storeWin(g, stars.count, after));
  }

  Future<void> _storeWin(GameState g, int stars, LevelProgress after) async {
    await _repo.addRecord(_record(g, GameResult.won, stars: stars));
    await _progress.setLevel(g.puzzle.level, after);
    if (g.dailyKey != null) await _progress.addDailySolved(g.dailyKey!);
    await _repo.clearCurrent();
    state = state.copy(version: state.version + 1);
  }

  void erase() => _update((g) => GameLogic.erase(g, _rules));
  void undo() => _update(GameLogic.undo);
  void toggleNotesMode() =>
      _update(GameLogic.toggleNotesMode, keepHint: true);
  void fastPencil() => _update(GameLogic.fastPencil);
  void toggleCombo(int cage, int mask) =>
      _update((g) => GameLogic.toggleCombo(g, cage, mask), keepHint: true);

  // ---- smart hint (TZ §5.3) ----------------------------------------------

  /// Opens a hint, or shows its next step.
  void hint() {
    final g = _game;
    if (g == null || g.status != GameStatus.playing) return;
    final open = state.hint;
    if (open != null) {
      if (open.step < 2) {
        state = state.copy(hint: HintSession(open.hint, open.step + 1));
      }
      return;
    }
    final h = findHint(g.puzzle, g.values, g.notes);
    if (h == null) return;
    final next = g.copyWith(
      hintsUsed: g.hintsUsed + 1,
      selected: h.target ?? (h.focus.isNotEmpty ? h.focus.first : g.selected),
    );
    state = state.copy(game: next, hint: HintSession(h, 0));
    _persist();
  }

  void closeHint() => state = state.copy(clearHint: true);

  void applyHint() {
    final open = state.hint;
    if (open == null) return;
    _update((g) => GameLogic.applyHint(g, open.hint, _rules));
  }

  // ---- time & status ------------------------------------------------------

  /// One second of play; saved every 5 seconds.
  void tick() {
    final g = _game;
    if (g == null || g.status != GameStatus.playing) return;
    final next = GameLogic.tick(g);
    state = state.copy(game: next);
    if (next.elapsed % 5 == 0) _persist();
  }

  void pause() => _update(GameLogic.pause, keepHint: true);
  void resume() => _update(GameLogic.resume, keepHint: true);
  void continueAfterLoss() => _update(GameLogic.continueAfterLoss);

  Future<void> toggleSaved() async {
    final g = _game;
    if (g == null) return;
    final saved = !g.saved;
    await _repo.setSaved(g.puzzle, saved: saved);
    _update((g) => g.copyWith(saved: saved), keepHint: true);
    state = state.copy(version: state.version + 1);
  }

  /// Signals that stored data changed outside the controller (import,
  /// reset), so derived screens rebuild.
  void dataChanged() {
    state = GameSession(
      game: _repo.loadCurrent(),
      version: state.version + 1,
    );
  }
}
