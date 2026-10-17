import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../l10n/strings.dart';

/// Home tab (TZ §3.1). Stage 1: mode title and the primary button only;
/// chips, daily card and "Davom etish" arrive in stage 4.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
            _PrimaryButton(
              label: S.newGame,
              onPressed: () => context.push(Routes.game),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      height: AppDims.primaryButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.primaryButtonRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: kFontFamily,
            fontSize: AppDims.primaryButtonText,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
