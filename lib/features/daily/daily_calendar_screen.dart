import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/progress.dart';
import '../../data/stats.dart';
import '../../l10n/strings.dart';
import '../game/game_controller.dart';

/// Daily challenge calendar (TZ §3.4): one puzzle per day, gold trophy on
/// solved days, a month trophy when every day of a month is solved. Past
/// days can be played too.
class DailyCalendarScreen extends ConsumerStatefulWidget {
  const DailyCalendarScreen({super.key});

  @override
  ConsumerState<DailyCalendarScreen> createState() =>
      _DailyCalendarScreenState();
}

class _DailyCalendarScreenState extends ConsumerState<DailyCalendarScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _month = DateTime(now.year, now.month);
  }

  void _play(DateTime day) {
    final session = ref.read(gameProvider);
    if (!(session.canContinue && session.game!.dailyKey == Daily.key(day))) {
      unawaited(ref.read(gameProvider.notifier).startDaily(day));
    }
    unawaited(context.push(Routes.game));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    ref.watch(gameProvider.select((s) => s.version));
    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final solved = ref.watch(progressRepositoryProvider).dailySolved;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month).weekday; // 1=Mon
    final monthDone = [
      for (var d = 1; d <= daysInMonth; d++)
        solved.contains(Daily.key(DateTime(_month.year, _month.month, d))),
    ].every((x) => x);
    final canGoNext = DateTime(_month.year, _month.month + 1)
        .isBefore(DateTime(today.year, today.month + 1));

    return Scaffold(
      appBar: AppBar(title: const Text(S.dailyCalendarTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDims.screenPadding),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => setState(() {
                    _month = DateTime(_month.year, _month.month - 1);
                  }),
                ),
                Expanded(
                  child: Text(
                    '${S.monthName(_month.month)} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: canGoNext
                      ? () => setState(() {
                            _month = DateTime(_month.year, _month.month + 1);
                          })
                      : null,
                ),
              ],
            ),
            if (monthDone)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(AppDims.levelCardRadius),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: c.gold, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        S.monthTrophy(_month.month),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final w in S.weekdaysShort)
                  Expanded(
                    child: Text(
                      w,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (var k = 1; k < firstWeekday; k++) const SizedBox.shrink(),
                for (var d = 1; d <= daysInMonth; d++)
                  () {
                    final day = DateTime(_month.year, _month.month, d);
                    return _DayCell(
                      day: d,
                      solved: solved.contains(Daily.key(day)),
                      today: day == today,
                      future: day.isAfter(today),
                      onTap: () => _play(day),
                    );
                  }(),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              S.dailyLevel(Daily.level(today)),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.solved,
    required this.today,
    required this.future,
    required this.onTap,
  });

  final int day;
  final bool solved;
  final bool today;
  final bool future;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: future ? c.bg : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: today
            ? BorderSide(color: c.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: future ? null : onTap,
        child: Center(
          child: solved
              ? Icon(Icons.emoji_events_rounded, color: c.gold, size: 28)
              : Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: today ? FontWeight.w800 : FontWeight.w600,
                    color: future ? c.textSecondary : c.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}
