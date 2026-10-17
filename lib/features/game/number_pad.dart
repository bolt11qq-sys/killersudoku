import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'game_state.dart';

/// Nine digit buttons (TZ §3.3 item 7, §6.3). A completed digit's button is
/// hidden but keeps its slot.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.game,
    required this.hideUsed,
    required this.onDigit,
    this.onLongPress,
    this.noteFocus = 0,
  });

  final GameState game;
  final bool hideUsed;
  final ValueChanged<int> onDigit;

  /// Long press: highlight this pencil-mark digit on the board.
  final ValueChanged<int>? onLongPress;
  final int noteFocus;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const gap = AppDims.numberButtonGap;
        final w = (box.maxWidth - 8 * gap) / 9;
        return Row(
          children: [
            for (var d = 1; d <= 9; d++) ...[
              if (d > 1) const SizedBox(width: gap),
              _DigitButton(
                digit: d,
                width: w,
                left: 9 - game.placedCorrect(d),
                hideUsed: hideUsed,
                notesMode: game.notesMode,
                picked: game.pickedDigit == d || noteFocus == d,
                onTap: () => onDigit(d),
                onLongPress: onLongPress == null ? null : () => onLongPress!(d),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DigitButton extends StatelessWidget {
  const _DigitButton({
    required this.digit,
    required this.width,
    required this.left,
    required this.hideUsed,
    required this.notesMode,
    required this.picked,
    required this.onTap,
    this.onLongPress,
  });

  final int digit;
  final double width;
  final int left;
  final bool hideUsed;
  final bool notesMode;
  final bool picked;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = left <= 0;
    final fg = picked ? c.surface : (notesMode ? c.textSecondary : c.primary);
    return Visibility(
      visible: !(done && hideUsed),
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: SizedBox(
        width: width,
        height: width * 1.5,
        child: Material(
          color: picked ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(AppDims.numberButtonRadius),
          elevation: 0,
          shadowColor: c.shadow,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDims.numberButtonRadius),
            onTap: done ? null : onTap,
            onLongPress: onLongPress,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$digit',
                  style: TextStyle(
                    fontSize: width * (notesMode ? 0.62 : 0.8),
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                Text(
                  done ? '' : '$left',
                  style: TextStyle(
                    fontSize: 13,
                    color: picked ? c.surface : c.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
