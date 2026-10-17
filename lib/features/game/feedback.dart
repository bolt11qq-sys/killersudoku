import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings.dart';

enum GameSound { tap, mistake, unit, win }

/// Sound and haptic feedback for game events (TZ §5.1), honouring the
/// sound and vibration settings. Sounds are bundled WAVs made by
/// `tool/gen_sounds.js`.
class GameFeedback {
  GameFeedback(this._settings);

  final AppSettings Function() _settings;
  final Map<GameSound, AudioPlayer> _players = {};

  Future<void> _play(GameSound s) async {
    if (!_settings().sound) return;
    try {
      var p = _players[s];
      if (p == null) {
        p = _players[s] = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
      }
      await p.stop();
      await p.play(AssetSource('sounds/${s.name}.wav'), volume: 0.7);
    } on Object catch (e) {
      // Audio is a nicety; never let it break the game.
      debugPrint('Sound ${s.name} failed: $e');
    }
  }

  void _haptic(Future<void> Function() f) {
    if (_settings().vibration) unawaited(f());
  }

  void tap() {
    unawaited(_play(GameSound.tap));
    _haptic(HapticFeedback.selectionClick);
  }

  void mistake() {
    unawaited(_play(GameSound.mistake));
    _haptic(HapticFeedback.heavyImpact);
  }

  void unitDone() {
    unawaited(_play(GameSound.unit));
    _haptic(HapticFeedback.lightImpact);
  }

  void win() {
    unawaited(_play(GameSound.win));
    _haptic(HapticFeedback.mediumImpact);
  }

  void dispose() {
    for (final p in _players.values) {
      unawaited(p.dispose());
    }
  }
}

final feedbackProvider = Provider<GameFeedback>((ref) {
  final f = GameFeedback(() => ref.read(settingsProvider));
  ref.onDispose(f.dispose);
  return f;
});

/// Silent feedback for widget tests (no audio plugin there).
class SilentFeedback extends GameFeedback {
  SilentFeedback() : super(() => const AppSettings(sound: false, vibration: false));
}
