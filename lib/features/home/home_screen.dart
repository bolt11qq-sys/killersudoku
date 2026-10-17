import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../game/game_controller.dart';
import '../game/status_bar.dart';
import '../new_game/new_game_sheet.dart';

/// Home tab (TZ §3.1). Stage 3: mode title, "Davom etish" and
/// "Yangi o'yin"; chips and the daily card arrive in stages 4 and 6.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _newGame(BuildContext context, WidgetRef ref) async {
    final level = await showNewGameSheet(context);
    if (level == null || !context.mounted) return;
    unawaited(ref.read(gameProvider.notifier).newGame(level));
    unawaited(context.push(Routes.game));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final session = ref.watch(gameProvider);
    final game = session.canContinue ? session.game : null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.screenPadding),
        child: Column(
          children: [
            const Spacer(flex: 3),
            Text(
              S.modeTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDims.modeTitle,
                fontWeight: FontWeight.w800,
                color: c.textSecondary,
              ),
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
            const SizedBox(height: 24),
          ],
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
