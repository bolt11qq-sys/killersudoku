import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/settings.dart';
import '../../l10n/strings.dart';
import 'game_state.dart';

String formatTime(int seconds) {
  final h = seconds ~/ 3600, m = (seconds ~/ 60) % 60, s = seconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Status row (TZ §3.3 item 2): progress and mistakes, score and level,
/// timer and pause.
class StatusBar extends StatelessWidget {
  const StatusBar({
    super.key,
    required this.game,
    required this.settings,
    required this.onPause,
  });

  final GameState game;
  final AppSettings settings;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final small = TextStyle(fontSize: 14, color: c.textSecondary);
    final limit = settings.mistakeLimit && !game.unlimited
        ? AppSettings.maxMistakes
        : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: c.success),
                  const SizedBox(width: 4),
                  Text('${game.filledCorrect}/${game.toFill}', style: small),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                S.mistakes(game.mistakes, limit),
                style: small.copyWith(
                  color: game.mistakes > 0 ? c.error : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                S.score(game.score),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(S.level(game.puzzle.level), style: small),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (settings.showTimer)
                Text(
                  formatTime(game.elapsed),
                  style: small.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              IconButton(
                tooltip: S.pause,
                visualDensity: VisualDensity.compact,
                onPressed: game.isOver ? null : onPause,
                icon: Icon(
                  game.status == GameStatus.paused
                      ? Icons.play_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
