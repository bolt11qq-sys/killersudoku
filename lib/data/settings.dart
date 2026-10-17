import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User settings (TZ §3.5). Stored in shared_preferences; the settings
/// screen arrives in stage 7, the game already honours every value.
@immutable
class AppSettings {
  const AppSettings({
    this.mistakeLimit = true,
    this.showErrors = true,
    this.autoRemoveNotes = true,
    this.highlightSame = true,
    this.hideUsedNumbers = true,
    this.showTimer = true,
    this.numberFirst = false,
    this.sound = true,
    this.vibration = true,
    this.themeMode = ThemeMode.system,
  });

  /// Lose after 3 mistakes (otherwise only count them).
  final bool mistakeLimit;

  /// Mark wrong digits red and count them as mistakes immediately.
  final bool showErrors;
  final bool autoRemoveNotes;
  final bool highlightSame;
  final bool hideUsedNumbers;
  final bool showTimer;

  /// Input order: pick a digit first, then tap cells (the ⚡ switch).
  final bool numberFirst;
  final bool sound;
  final bool vibration;
  final ThemeMode themeMode;

  static const int maxMistakes = 3;

  AppSettings copyWith({
    bool? mistakeLimit,
    bool? showErrors,
    bool? autoRemoveNotes,
    bool? highlightSame,
    bool? hideUsedNumbers,
    bool? showTimer,
    bool? numberFirst,
    bool? sound,
    bool? vibration,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      mistakeLimit: mistakeLimit ?? this.mistakeLimit,
      showErrors: showErrors ?? this.showErrors,
      autoRemoveNotes: autoRemoveNotes ?? this.autoRemoveNotes,
      highlightSame: highlightSame ?? this.highlightSame,
      hideUsedNumbers: hideUsedNumbers ?? this.hideUsedNumbers,
      showTimer: showTimer ?? this.showTimer,
      numberFirst: numberFirst ?? this.numberFirst,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Overridden in `main()` with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not provided'),
);

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  static const _p = 'settings.';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final p = _prefs;
    const d = AppSettings();
    bool b(String k, bool def) => p.getBool('$_p$k') ?? def;
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
      themeMode: ThemeMode.values[
          (p.getInt('${_p}themeMode') ?? d.themeMode.index)
              .clamp(0, ThemeMode.values.length - 1)],
    );
  }

  Future<void> update(AppSettings s) async {
    state = s;
    final p = _prefs;
    await Future.wait([
      p.setBool('${_p}mistakeLimit', s.mistakeLimit),
      p.setBool('${_p}showErrors', s.showErrors),
      p.setBool('${_p}autoRemoveNotes', s.autoRemoveNotes),
      p.setBool('${_p}highlightSame', s.highlightSame),
      p.setBool('${_p}hideUsedNumbers', s.hideUsedNumbers),
      p.setBool('${_p}showTimer', s.showTimer),
      p.setBool('${_p}numberFirst', s.numberFirst),
      p.setBool('${_p}sound', s.sound),
      p.setBool('${_p}vibration', s.vibration),
      p.setInt('${_p}themeMode', s.themeMode.index),
    ]);
  }
}
