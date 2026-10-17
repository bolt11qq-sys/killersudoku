import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import 'game_controller.dart';

/// Smart hint panel shown in place of the number pad (TZ §5.3): one step
/// per tap — where to look, why, then "Qo'llash".
class HintPanel extends StatelessWidget {
  const HintPanel({
    super.key,
    required this.session,
    required this.onNext,
    required this.onApply,
    required this.onClose,
  });

  final HintSession session;
  final VoidCallback onNext;
  final VoidCallback onApply;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final h = session.hint, step = session.step;
    final last = step == 2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppDims.levelCardRadius),
        border: Border.all(color: c.hintFill, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, size: 20, color: c.streak),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  S.hintTitle(h),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              for (var k = 0; k < 3; k++)
                Container(
                  width: 18,
                  height: 4,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: k <= step ? c.streak : c.gridThin,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 6),
          // Long explanations scroll; the buttons below always stay visible.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                S.hintText(h, step),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onClose,
                child: Text(
                  S.hintClose,
                  style: TextStyle(color: c.textSecondary),
                ),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: last ? onApply : onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  last ? S.hintApply : S.hintNext,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
