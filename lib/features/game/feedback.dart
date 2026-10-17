import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings.dart';

/// Haptic feedback for game events (TZ §5.1), honouring the vibration
/// setting. Sounds are added in stage 8.
class GameFeedback {
  GameFeedback(this._settings);

  final AppSettings Function() _settings;

  void tap() {
    if (_settings().vibration) unawaited(HapticFeedback.selectionClick());
  }

  void mistake() {
    if (_settings().vibration) unawaited(HapticFeedback.heavyImpact());
  }

  void unitDone() {
    if (_settings().vibration) unawaited(HapticFeedback.lightImpact());
  }

  void win() {
    if (_settings().vibration) unawaited(HapticFeedback.mediumImpact());
  }
}

final feedbackProvider = Provider<GameFeedback>(
  (ref) => GameFeedback(() => ref.read(settingsProvider)),
);
