import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/game_repository.dart';
import '../../data/progress.dart';
import '../../data/stats.dart';
import '../../engine/killer/level.dart';
import '../../l10n/strings.dart';
import '../game/game_controller.dart';

/// "Yangi o'yin" bottom sheet (TZ §3.2): weekly win rate, one card per
/// level with its `Lv` badge, star progress on the last played level.
Future<KillerLevel?> showNewGameSheet(BuildContext context) {
  return showModalBottomSheet<KillerLevel>(
    context: context,
    isScrollControlled: true,
    // Above the bottom navigation, like the sample.
    useRootNavigator: true,
    sheetAnimationStyle: const AnimationStyle(
      duration: AppDurations.bottomSheet,
      reverseDuration: AppDurations.bottomSheet,
    ),
    builder: (context) => const _NewGameSheet(),
  );
}

class _NewGameSheet extends ConsumerWidget {
  const _NewGameSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    ref.watch(gameProvider.select((s) => s.version));
    final history = ref.watch(gameRepositoryProvider).history();
    final progress = ref.watch(progressRepositoryProvider);
    final rate = Stats.weeklyWinRate(history, ref.watch(clockProvider)());
    final last = progress.lastLevel;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDims.screenPadding,
          0,
          AppDims.screenPadding,
          AppDims.screenPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.newGameSheetTitle,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                text: S.weeklyWinRateLabel,
                style: TextStyle(fontSize: 16, color: c.textSecondary),
                children: [
                  TextSpan(
                    text: S.weeklyWinRate(rate),
                    style: TextStyle(color: c.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final level in KillerLevel.values) ...[
              _LevelCard(
                level: level,
                progress: progress.level(level),
                active: level == last,
                onTap: () => Navigator.pop(context, level),
              ),
              const SizedBox(height: AppDims.levelCardGap),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.progress,
    required this.active,
    required this.onTap,
  });

  final KillerLevel level;
  final LevelProgress progress;

  /// Last played level: shows the star progress (TZ §3.2).
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = progress.isNew;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppDims.levelCardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDims.levelCardRadius),
        onTap: onTap,
        child: SizedBox(
          height: AppDims.levelCardHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(S.levelEmoji(level), style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 14),
                Text(
                  S.level(level),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: dark ? c.textPrimary : c.bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    S.lv(progress.lv),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: dark ? c.surface : c.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                if (active)
                  SizedBox(
                    width: 108,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 20, color: c.gold),
                              Text(
                                ' ${S.starsProgress(progress.stars)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress.stars / LevelProgress.starsPerLv,
                            minHeight: 5,
                            color: c.primary,
                            backgroundColor: c.highlight,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
