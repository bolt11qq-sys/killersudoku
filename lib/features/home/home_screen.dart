import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/game_repository.dart';
import '../../data/progress.dart';
import '../../data/stats.dart';
import '../../l10n/strings.dart';
import '../game/game_controller.dart';
import '../game/status_bar.dart';
import '../new_game/new_game_sheet.dart';
import 'daily_card.dart';
import 'how_to_play.dart';

/// Home tab (TZ §3.1): rating and streak chips, daily challenge card, mode
/// title with "Qanday o'ynaladi", then "Davom etish" / "Yangi o'yin".
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _newGame(BuildContext context, WidgetRef ref) async {
    final level = await showNewGameSheet(context);
    if (level == null || !context.mounted) return;
    unawaited(ref.read(gameProvider.notifier).newGame(level));
    unawaited(context.push(Routes.game));
  }

  void _playDaily(BuildContext context, WidgetRef ref, DateTime today) {
    final session = ref.read(gameProvider);
    // Continue today's daily instead of restarting it.
    if (!(session.canContinue &&
        session.game!.dailyKey == Daily.key(today))) {
      unawaited(ref.read(gameProvider.notifier).startDaily(today));
    }
    unawaited(context.push(Routes.game));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final session = ref.watch(gameProvider);
    final now = ref.watch(clockProvider)();
    final history = ref.watch(gameRepositoryProvider).history();
    final progress = ref.watch(progressRepositoryProvider);
    final game = session.canContinue ? session.game : null;
    final today = DateTime(now.year, now.month, now.day);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.screenPadding),
        child: Column(
          children: [
            Row(
              children: [
                _Chip(
                  tooltip: S.ratingTooltip,
                  icon: Icons.psychology_rounded,
                  iconColor: c.primary,
                  text: '${Stats.rating(history)}',
                  background: c.ratingChip,
                ),
                const Spacer(),
                _Chip(
                  tooltip: S.streakTooltip,
                  icon: Icons.local_fire_department_rounded,
                  iconColor: c.streak,
                  text: '${Stats.streak(history, now)}',
                  background: c.surface,
                  dot: !Stats.wonToday(history, now),
                  onTap: () => context.push(Routes.daily),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DailyCard(
              date: today,
              level: Daily.level(today),
              solved: progress.dailySolved.contains(Daily.key(today)),
              onPlay: () => _playDaily(context, ref, today),
              onOpenCalendar: () => context.push(Routes.daily),
            ),
            const Spacer(flex: 2),
            Text(
              S.modeTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDims.modeTitle,
                fontWeight: FontWeight.w800,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ActionChip(
              avatar: Icon(Icons.help_outline_rounded, color: c.primary),
              label: Text(
                S.howToPlay,
                style: TextStyle(color: c.primary, fontSize: 15),
              ),
              backgroundColor: c.surface,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              onPressed: () => showHowToPlay(context),
            ),
            const Spacer(flex: 2),
            if (game != null) ...[
              _HomeButton(
                label: S.continueGame,
                subtitle:
                    '${S.level(game.puzzle.level)} · ${formatTime(game.elapsed)}',
                filled: true,
                onPressed: () => context.push(Routes.game),
              ),
              const SizedBox(height: 12),
            ],
            _HomeButton(
              label: S.newGame,
              filled: game == null,
              onPressed: () => _newGame(context, ref),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Rating / streak chip (TZ §3.1 item 1, §6.3: 44 dp, fully rounded).
class _Chip extends StatelessWidget {
  const _Chip({
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.background,
    this.dot = false,
    this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color background;

  /// Red dot: no puzzle solved today yet (TZ §5.5).
  final bool dot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: AppDims.chipHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, color: iconColor, size: 26),
                      if (dot)
                        Positioned(
                          right: -10,
                          top: -4,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: c.streak,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary (blue) or secondary (white) home button, TZ §3.1 item 4.
class _HomeButton extends StatelessWidget {
  const _HomeButton({
    required this.label,
    required this.filled,
    required this.onPressed,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = filled ? c.surface : c.primary;
    return SizedBox(
      width: double.infinity,
      height: AppDims.primaryButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: filled ? c.primary : c.surface,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.primaryButtonRadius),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: kFontFamily,
                fontSize: AppDims.primaryButtonText,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
