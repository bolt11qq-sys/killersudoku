import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../engine/killer/level.dart';
import '../../l10n/strings.dart';

/// "Yangi o'yin" bottom sheet (TZ §3.2). Stage 3: level choice only;
/// weekly win rate, Lv badges and star progress come in stages 4 and 6.
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

class _NewGameSheet extends StatelessWidget {
  const _NewGameSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
            const SizedBox(height: 16),
            for (final level in KillerLevel.values) ...[
              _LevelCard(
                level: level,
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
  const _LevelCard({required this.level, required this.onTap});

  final KillerLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
