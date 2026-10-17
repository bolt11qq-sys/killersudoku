import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/daily/daily_calendar_screen.dart';
import '../features/game/game_screen.dart';
import '../features/home/home_screen.dart';
import '../features/me/settings_screen.dart';
import '../features/me/stats_screen.dart';
import 'shell.dart';

abstract final class Routes {
  static const home = '/';
  static const me = '/me';
  static const game = '/game';
  static const daily = '/daily';
  static const settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      // The two bottom-navigation tabs keep their own state.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.me,
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Full-screen routes, shown above the bottom navigation.
      GoRoute(
        path: Routes.game,
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: Routes.daily,
        builder: (context, state) => const DailyCalendarScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
