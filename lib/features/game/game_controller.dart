import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/game_record.dart';
import '../../data/game_repository.dart';
import '../../data/settings.dart';
import '../../engine/killer/generator.dart';
import '../../engine/killer/level.dart';
import '../../engine/killer/puzzle.dart';
import 'game_logic.dart';
import 'game_state.dart';

typedef PuzzleSource = Future<KillerPuzzle> Function(KillerLevel level);

/// Where new puzzles come from. Generation always runs in a background
/// isolate (TZ §4.2); tests override this with a fixed puzzle.
final puzzleSourceProvider = Provider<PuzzleSource>((ref) {
  final random = Random();
  return (level) {
    final seed = random.nextInt(1 << 32);
    return Isolate.run(() => generate(level, seed));
  };
});

/// Cells to flash after a row / column / block / cage is completed.
@immutable
class Flash {
  const Flash(this.id, this.cells);
  final int id;
  final Set<int> cells;
}

@immutable
class GameSession {
  const GameSession({
    this.game,
    this.generating,
    this.flash,
    this.newRecord = false,
  });

  final GameState? game;

  /// Level currently being generated (shows the loading view).
  final KillerLevel? generating;
  final Flash? flash;

  /// The just-won game beat the previous best time on its level.
  final bool newRecord;

  /// An unfinished game the home screen can offer to continue.
  bool get canContinue => game != null && !game!.isOver;
}

final gameProvider =
    NotifierProvider<GameController, GameSession>(GameController.new);

class GameController extends Notifier<GameSession> {
  GameRepository get _repo => ref.read(gameRepositoryProvider);
  AppSettings get _rules => ref.read(settingsProvider);
  int _flashId = 0;

  @override
  GameSession build() => GameSession(game: _repo.loadCurrent());

  GameState? get _game => state.game;

  /// Starts a new game; an unfinished one is recorded as abandoned.
  Future<void> newGame(KillerLevel level) async {
    await _closeCurrent();
    state = GameSession(generating: level);
    try {
      final puzzle = await ref.read(puzzleSourceProvider)(level);
      // Ignore a result nobody waits for any more.
      if (state.generating != level) return;
      final game = GameState.start(puzzle)
          .copyWith(saved: _repo.isSaved(puzzle));
      state = GameSession(game: game);
      _persist();
    } on Object catch (e, st) {
      // Generation retries many seeds and should never fail; if it does,
      // drop back to "no game" instead of leaving a spinner forever.
      debugPrint('Puzzle generation failed: $e\n$st');
      state = const GameSession();
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

  GameRecord _record(GameState g, GameResult result) => GameRecord(
        date: DateTime.now(),
        level: g.puzzle.level,
        result: result,
        seconds: g.elapsed,
        mistakes: g.mistakes,
        hints: g.hintsUsed,
        score: g.score,
        unlimited: g.unlimited,
        daily: g.daily,
      );

  void _set(GameState g, {Flash? flash}) {
    state = GameSession(game: g, flash: flash ?? state.flash);
  }

  void _persist() {
    final g = _game;
    if (g != null) unawaited(_repo.saveCurrent(g));
  }

  void _update(GameState Function(GameState g) f) {
    final g = _game;
    if (g == null) return;
    final next = f(g);
    if (identical(next, g)) return;
    _set(next);
    _persist();
  }

  // ---- input -------------------------------------------------------------

  /// Tap on a cell. In number-first mode this also places the picked digit.
  void tapCell(int i) {
    final g = _game;
    if (g == null) return;
    _update((g) => GameLogic.select(g, i));
    if (_rules.numberFirst && g.pickedDigit != 0) input(g.pickedDigit);
  }

  /// Tap on a number-pad button.
  void tapDigit(int d) {
    final g = _game;
    if (g == null) return;
    if (_rules.numberFirst) {
      _update((g) => GameLogic.pickDigit(g, d));
    } else {
      input(d);
    }
  }

  void input(int d) {
    final g = _game;
    if (g == null) return;
    final r = GameLogic.input(g, d, _rules);
    if (identical(r.state, g)) return;
    Flash? flash;
    if (r.completed.isNotEmpty) {
      flash = Flash(++_flashId, {for (final u in r.completed) ...u.cells});
    }
    final won = r.state.status == GameStatus.won;
    // Decide "Yangi rekord" before publishing the state: the win dialog
    // opens as soon as listeners see the won status.
    final best = won ? bestTime(g.puzzle.level) : null;
    state = GameSession(
      game: r.state,
      flash: flash ?? state.flash,
      newRecord: won && (best == null || r.state.elapsed < best),
    );
    if (r.mistake && _rules.vibration) {
      unawaited(HapticFeedback.heavyImpact());
    }
    if (won) {
      unawaited(_finishWon(r.state));
    } else {
      _persist();
    }
  }

  Future<void> _finishWon(GameState g) async {
    await _repo.addRecord(_record(g, GameResult.won));
    await _repo.clearCurrent();
  }

  void erase() => _update((g) => GameLogic.erase(g, _rules));
  void undo() => _update(GameLogic.undo);
  void toggleNotesMode() => _update(GameLogic.toggleNotesMode);
  void fastPencil() => _update(GameLogic.fastPencil);
  void toggleCombo(int cage, int mask) =>
      _update((g) => GameLogic.toggleCombo(g, cage, mask));

  // ---- time & status ------------------------------------------------------

  /// One second of play; saved every 5 seconds.
  void tick() {
    final g = _game;
    if (g == null || g.status != GameStatus.playing) return;
    final next = GameLogic.tick(g);
    _set(next);
    if (next.elapsed % 5 == 0) _persist();
  }

  void pause() => _update(GameLogic.pause);
  void resume() => _update(GameLogic.resume);
  void continueAfterLoss() => _update(GameLogic.continueAfterLoss);

  Future<void> toggleSaved() async {
    final g = _game;
    if (g == null) return;
    final saved = !g.saved;
    await _repo.setSaved(g.puzzle, saved: saved);
    _update((g) => g.copyWith(saved: saved));
  }

  /// Best recorded winning time on [level], for "Yangi rekord".
  int? bestTime(KillerLevel level) {
    final times = [
      for (final r in _repo.history())
        if (r.level == level && r.result == GameResult.won) r.seconds,
    ];
    return times.isEmpty ? null : times.reduce(min);
  }
}
