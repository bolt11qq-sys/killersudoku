import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/game_record.dart';
import '../../data/game_repository.dart';
import '../../data/progress.dart';
import '../../data/stats.dart';
import '../../engine/killer/level.dart';
import '../../engine/killer/puzzle.dart';
import '../../l10n/strings.dart';
import '../game/game_controller.dart';
import '../game/status_bar.dart';
import 'times_chart.dart';

/// "Men" tab (TZ §3.5): summary, per-level statistics with a 30-day chart,
/// saved puzzles; settings open from the app bar.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    ref.watch(gameProvider.select((s) => s.version));
    final repo = ref.watch(gameRepositoryProvider);
    final progress = ref.watch(progressRepositoryProvider);
    final now = ref.watch(clockProvider)();
    final history = repo.history();
    final saved = repo.savedPuzzles();
    final totalStars = [
      for (final l in KillerLevel.values) progress.level(l).total,
    ].fold<int>(0, (a, b) => a + b);
    final initial = progress.lastLevel?.index ?? KillerLevel.medium.index;

    return DefaultTabController(
      length: KillerLevel.values.length,
      initialIndex: initial,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(S.tabMe),
          actions: [
            IconButton(
              tooltip: S.settingsTitle,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(Routes.settings),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppDims.screenPadding),
          children: [
            Row(
              children: [
                _Summary(
                  icon: Icons.psychology_rounded,
                  color: c.primary,
                  value: '${Stats.rating(history)}',
                  label: S.ratingLabel,
                ),
                const SizedBox(width: 8),
                _Summary(
                  icon: Icons.local_fire_department_rounded,
                  color: c.streak,
                  value: '${Stats.streak(history, now)}',
                  label: S.streakLabel,
                ),
                const SizedBox(width: 8),
                _Summary(
                  icon: Icons.star_rounded,
                  color: c.gold,
                  value: '$totalStars',
                  label: S.totalStars,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              S.statsTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: c.primary,
              unselectedLabelColor: c.textSecondary,
              indicatorColor: c.primary,
              dividerColor: c.gridThin,
              labelStyle: const TextStyle(
                fontFamily: kFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              tabs: [
                for (final l in KillerLevel.values) Tab(text: S.level(l)),
              ],
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final tab = DefaultTabController.of(context);
                return AnimatedBuilder(
                  animation: tab,
                  builder: (context, _) => _LevelPanel(
                    level: KillerLevel.values[tab.index],
                    history: history,
                    progress: progress.level(KillerLevel.values[tab.index]),
                    now: now,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              S.savedTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (saved.isEmpty)
              Text(
                S.savedEmpty,
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              )
            else
              for (final p in saved) _SavedTile(puzzle: p),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppDims.levelCardRadius),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPanel extends StatelessWidget {
  const _LevelPanel({
    required this.level,
    required this.history,
    required this.progress,
    required this.now,
  });

  final KillerLevel level;
  final List<GameRecord> history;
  final LevelProgress progress;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Stats.levelStats(history, level);
    String time(int? t) => t == null ? '—' : formatTime(t);
    final cells = [
      (S.statPlayed, '${s.played}'),
      (S.statWon, '${s.won}'),
      (S.statWinRate, '${s.winRate}%'),
      (S.statBest, time(s.bestSeconds)),
      (S.statAvg, time(s.avgSeconds)),
      (S.statFlawless, '${s.flawless}'),
      (S.statStreak, '${s.currentStreak}'),
      (S.statLongest, '${s.longestStreak}'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppDims.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                S.levelProgress(level, progress.lv),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(Icons.star_rounded, size: 18, color: c.gold),
              Text(
                ' ${S.starsProgress(progress.stars)}',
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.stars / LevelProgress.starsPerLv,
              minHeight: 6,
              color: c.primary,
              backgroundColor: c.highlight,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.8,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final (label, value) in cells)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TimesChart(
            times: Stats.dailyTimes(history, level, now),
            lastDay: now,
          ),
        ],
      ),
    );
  }
}

class _SavedTile extends ConsumerWidget {
  const _SavedTile({required this.puzzle});

  final KillerPuzzle puzzle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Card(
      color: c.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDims.levelCardRadius),
      ),
      child: ListTile(
        leading: Icon(Icons.star_rounded, color: c.gold),
        title: Text(
          S.level(puzzle.level),
          style: TextStyle(fontWeight: FontWeight.w600, color: c.textPrimary),
        ),
        subtitle: Text(
          '#${puzzle.seed} · ${puzzle.cages.length} kafes',
          style: TextStyle(color: c.textSecondary),
        ),
        trailing: Icon(Icons.play_arrow_rounded, color: c.primary),
        onTap: () {
          unawaited(ref.read(gameProvider.notifier).startSaved(puzzle));
          unawaited(context.push(Routes.game));
        },
      ),
    );
  }
}
