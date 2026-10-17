import 'dart:async';

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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  final repo = await HiveGameRepository.open();
  final kv = await HiveKvStore.open([
    ProgressRepository.box,
    PuzzleCache.box,
  ]);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      gameRepositoryProvider.overrideWithValue(repo),
      kvStoreProvider.overrideWithValue(kv),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const KillerSudokuApp(),
    ),
  );
  unawaited(_warmUp(container));
}

/// Fills the puzzle cache and prepares today's daily challenge in the
/// background (TZ §4.2), so starting a game is instant.
Future<void> _warmUp(ProviderContainer container) async {
  final cache = container.read(puzzleCacheProvider);
  await cache.refill();
  final now = container.read(clockProvider)();
  await cache.daily(Daily.level(now), Daily.seed(now));
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
