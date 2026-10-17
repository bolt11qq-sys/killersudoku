import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../engine/killer/cage_combos.dart';
import '../../l10n/strings.dart';
import 'game_state.dart';

/// Cage panel (TZ §3.3 item 5): digit sets for the selected cell's cage.
/// Tapping a set crosses it out; sets that contradict the board are dead.
class CagePanel extends StatelessWidget {
  const CagePanel({super.key, required this.game, required this.onToggle});

  final GameState game;
  final void Function(int cage, int mask) onToggle;

  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sel = game.selected;
    if (sel < 0) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            S.cagePanelIdle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ),
      );
    }
    final k = game.puzzle.cageOf[sel];
    final cage = game.puzzle.cages[k];
    final options = cageCombos(cage, game.values);
    final crossed = game.crossed[k] ?? const <int>{};
    final alive = options
        .where((o) => !o.dead && !crossed.contains(o.mask))
        .toList();
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.cageInfo(cage.sum, cage.size, options.length),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, j) {
                final o = options[j];
                return _ComboChip(
                  option: o,
                  crossed: crossed.contains(o.mask),
                  only: alive.length == 1 && alive.first == o,
                  onTap: o.dead ? null : () => onToggle(k, o.mask),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ComboChip extends StatelessWidget {
  const _ComboChip({
    required this.option,
    required this.crossed,
    required this.only,
    required this.onTap,
  });

  final ComboOption option;
  final bool crossed;
  final bool only;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final struck = option.dead || crossed;
    final color = only
        ? c.primary
        : (struck ? c.textSecondary : c.textPrimary);
    return Opacity(
      opacity: option.dead ? 0.4 : (crossed ? 0.6 : 1),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: only ? c.primary : c.gridThin),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(
                option.digits.join(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: color,
                  decoration: struck ? TextDecoration.lineThrough : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
