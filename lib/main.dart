import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'data/game_repository.dart';
import 'data/kv_store.dart';
import 'data/progress.dart';
import 'data/puzzle_cache.dart';
import 'data/settings.dart';
import 'data/stats.dart';
import 'features/game/game_controller.dart';
import 'l10n/strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // In release a failing widget would paint an empty box; show the error
  // text instead so a screenshot tells what went wrong.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => Material(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(details.exceptionAsString()),
          ),
        );
  }
  // Any startup failure is shown on screen instead of a blank window.
  final ProviderContainer container;
  try {
    container = await _boot();
  } on Object catch (e, st) {
    runApp(StartupErrorApp(error: e, stack: st));
    return;
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const KillerSudokuApp(),
    ),
  );
  unawaited(_warmUp(container).catchError((Object e) {
    debugPrint('Warm-up failed: $e');
  }));
}

/// Runs one startup step, failing with its [name] if it errors or hangs.
Future<T> _step<T>(String name, Future<T> Function() f) async {
  try {
    return await f().timeout(const Duration(seconds: 15));
  } on Object catch (e) {
    throw StartupException(name, e);
  }
}

Future<ProviderContainer> _boot() async {
  await _step(
    'orientation',
    () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  );
  await _step('hive', Hive.initFlutter);
  final repo = await _step('games', HiveGameRepository.open);
  final kv = await _step(
    'storage',
    () => HiveKvStore.open([ProgressRepository.box, PuzzleCache.box]),
  );
  final prefs = await _step('settings', SharedPreferences.getInstance);
  return ProviderContainer(
    overrides: [
      gameRepositoryProvider.overrideWithValue(repo),
      kvStoreProvider.overrideWithValue(kv),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
}

/// Fills the puzzle cache and prepares today's daily challenge in the
/// background (TZ §4.2), so starting a game is instant.
Future<void> _warmUp(ProviderContainer container) async {
  final cache = container.read(puzzleCacheProvider);
  await cache.refill();
  final now = container.read(clockProvider)();
  await cache.daily(Daily.level(now), Daily.seed(now));
}

class StartupException implements Exception {
  StartupException(this.step, this.cause);
  final String step;
  final Object cause;

  @override
  String toString() => 'Startup step "$step" failed: $cause';
}

class KillerSudokuApp extends ConsumerWidget {
  const KillerSudokuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: S.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(settingsProvider.select((s) => s.themeMode)),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

/// Shown when startup fails, with the error text so it can be reported.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error, required this.stack});

  final Object error;
  final StackTrace stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppDims.screenPadding),
            children: [
              const Text(
                S.startupError,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SelectableText('$error'),
              const SizedBox(height: 12),
              if (kDebugMode) SelectableText('$stack'),
            ],
          ),
        ),
      ),
    );
  }
}
