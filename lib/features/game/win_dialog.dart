import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import 'game_state.dart';
import 'status_bar.dart';

enum WinChoice { next, home }

enum LossChoice { continueGame, newGame }

/// Win dialog (TZ §3.3). Stars and level progress are added in stage 6,
/// confetti in stage 8.
Future<WinChoice?> showWinDialog(
  BuildContext context,
  GameState game, {
  required bool newRecord,
}) {
  return showDialog<WinChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final c = context.colors;
      return _GameDialog(
        icon: Icons.emoji_events_rounded,
        iconColor: c.streak,
        title: S.winTitle,
        subtitle: S.winSubtitle(game.puzzle.level),
        badge: newRecord ? S.newRecord : null,
        stats: [
          (S.statTime, formatTime(game.elapsed)),
          (S.statScore, '${game.score}'),
          (S.statMistakes, '${game.mistakes}'),
          (S.statHints, '${game.hintsUsed}'),
        ],
        primary: (S.nextGame, () => Navigator.pop(context, WinChoice.next)),
        secondary: (S.goHome, () => Navigator.pop(context, WinChoice.home)),
      );
    },
  );
}

/// Loss dialog after reaching the mistake limit (TZ §3.3).
Future<LossChoice?> showLossDialog(BuildContext context, GameState game) {
  return showDialog<LossChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final c = context.colors;
      return _GameDialog(
        icon: Icons.heart_broken_rounded,
        iconColor: c.error,
        title: S.lossTitle,
        subtitle: '${S.lossSubtitle(game.mistakes)}\n${S.lossContinueNote}',
        primary: (
          S.lossContinue,
          () => Navigator.pop(context, LossChoice.continueGame),
        ),
        secondary: (
          S.newGame,
          () => Navigator.pop(context, LossChoice.newGame),
        ),
      );
    },
  );
}

class _GameDialog extends StatelessWidget {
  const _GameDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    this.badge,
    this.stats = const [],
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final List<(String, String)> stats;
  final (String, VoidCallback) primary;
  final (String, VoidCallback) secondary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDims.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: 8),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.surface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: c.textSecondary),
            ),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final (label, value) in stats)
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: primary.$2,
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDims.primaryButtonRadius),
                  ),
                ),
                child: Text(
                  primary.$1,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: secondary.$2,
                child: Text(
                  secondary.$1,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
