import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import 'game_state.dart';

/// Five tools under the board (TZ §3.3 item 6).
class GameToolbar extends StatelessWidget {
  const GameToolbar({
    super.key,
    required this.game,
    required this.onUndo,
    required this.onErase,
    required this.onFastPencil,
    required this.onPencil,
    required this.onHint,
  });

  final GameState game;
  final VoidCallback onUndo;
  final VoidCallback onErase;
  final VoidCallback onFastPencil;
  final VoidCallback onPencil;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        _Tool(icon: Icons.undo_rounded, label: S.toolUndo, onTap: onUndo),
        _Tool(
          icon: Icons.backspace_outlined,
          label: S.toolErase,
          onTap: onErase,
        ),
        _Tool(
          icon: Icons.auto_fix_high_outlined,
          label: S.toolFastPencil,
          onTap: onFastPencil,
          badge: game.fastPencilUsed > 0
              ? _CountBadge(game.fastPencilUsed, c.badge, c.surface)
              : null,
        ),
        _Tool(
          icon: Icons.edit_outlined,
          label: S.toolPencil,
          onTap: onPencil,
          active: game.notesMode,
          badge: _Pill(
            game.notesMode ? S.pencilOn : S.pencilOff,
            game.notesMode ? c.primary : c.textSecondary,
            c.surface,
          ),
        ),
        _Tool(
          icon: Icons.lightbulb_outline_rounded,
          label: S.toolHint,
          onTap: onHint,
          badge: game.hintsUsed > 0
              ? _CountBadge(game.hintsUsed, c.badge, c.surface)
              : null,
        ),
      ],
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? badge;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.primary : c.textPrimary;
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: AppDims.toolIcon, color: color),
                    if (badge != null)
                      Positioned(right: -14, top: -8, child: badge!),
                  ],
                ),
                const SizedBox(height: 4),
                // Long labels shrink instead of being cut off.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: AppDims.toolLabel,
                      color: c.textSecondary,
                    ),
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

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count, this.bg, this.fg);

  final int count;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.bg, this.fg);

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      );
}
