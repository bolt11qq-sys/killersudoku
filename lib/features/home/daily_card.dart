import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../engine/killer/level.dart';
import '../../l10n/strings.dart';

/// Daily challenge card (TZ §3.1 item 2): date, trophy, "O'ynash" or
/// "Bajarildi ✓" when today's puzzle is solved.
class DailyCard extends StatelessWidget {
  const DailyCard({
    super.key,
    required this.date,
    required this.level,
    required this.solved,
    required this.onPlay,
    required this.onOpenCalendar,
  });

  final DateTime date;
  final KillerLevel level;
  final bool solved;
  final VoidCallback onPlay;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      borderRadius: BorderRadius.circular(AppDims.cardRadius),
      clipBehavior: Clip.antiAlias,
      color: c.surface,
      elevation: 0,
      child: InkWell(
        onTap: onOpenCalendar,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.surface, c.highlight],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.dailyChallenge,
                      style: TextStyle(fontSize: 15, color: c.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.dailyDate(date),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      S.level(level),
                      style: TextStyle(fontSize: 14, color: c.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: solved ? onOpenCalendar : onPlay,
                        style: FilledButton.styleFrom(
                          backgroundColor: c.surface,
                          foregroundColor: solved ? c.success : c.primary,
                          elevation: 1,
                          shadowColor: c.shadow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          solved ? S.done : S.play,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.emoji_events_rounded,
                size: 96,
                color: solved ? c.gold : c.gridThin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
