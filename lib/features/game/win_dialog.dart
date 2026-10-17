import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/progress.dart';
import '../../l10n/strings.dart';
import 'game_controller.dart';
import 'game_state.dart';
import 'status_bar.dart';

enum WinChoice { next, home }

enum LossChoice { continueGame, newGame }

/// Win dialog (TZ §3.3): confetti, stars lighting up one by one, level
/// progress, time / score / mistakes / hints and the record badge.
Future<WinChoice?> showWinDialog(
  BuildContext context,
  GameState game,
  WinSummary? win,
) {
  return showDialog<WinChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _WinDialog(game: game, win: win),
  );
}

/// Loss dialog after reaching the mistake limit (TZ §3.3).
Future<LossChoice?> showLossDialog(BuildContext context, GameState game) {
  return showDialog<LossChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final c = context.colors;
      return _DialogFrame(
        children: [
          Icon(Icons.heart_broken_rounded, size: 56, color: c.error),
          const SizedBox(height: 8),
          const _Title(S.lossTitle),
          const SizedBox(height: 4),
          _Subtitle('${S.lossSubtitle(game.mistakes)}\n${S.lossContinueNote}'),
          const SizedBox(height: 20),
          _Buttons(
            primary: (
              S.lossContinue,
              () => Navigator.pop(context, LossChoice.continueGame),
            ),
            secondary: (
              S.newGame,
              () => Navigator.pop(context, LossChoice.newGame),
            ),
          ),
        ],
      );
    },
  );
}

class _WinDialog extends StatefulWidget {
  const _WinDialog({required this.game, required this.win});

  final GameState game;
  final WinSummary? win;

  @override
  State<_WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends State<_WinDialog> with TickerProviderStateMixin {
  late final AnimationController _stars = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: AppDurations.confetti,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stars.isAnimating || _stars.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      // TZ §6.4: reduced motion keeps only the final state.
      _stars.value = 1;
    } else {
      _stars.forward();
      _confetti.forward();
    }
  }

  @override
  void dispose() {
    _stars.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final g = widget.game, w = widget.win;
    final level = g.puzzle.level;
    return Stack(
      children: [
        _DialogFrame(
          children: [
            if (w != null)
              AnimatedBuilder(
                animation: _stars,
                builder: (context, _) => _StarsRow(win: w, t: _stars.value),
              )
            else
              Icon(Icons.emoji_events_rounded, size: 56, color: c.streak),
            const SizedBox(height: 8),
            if (w?.newRecord ?? false) ...[
              _Badge(S.newRecord, c.primary),
              const SizedBox(height: 8),
            ],
            const _Title(S.winTitle),
            const SizedBox(height: 4),
            _Subtitle(S.winSubtitle(level)),
            if (w != null) ...[
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _stars,
                builder: (context, _) => _LevelBar(
                  win: w,
                  levelName: (lv) => S.levelProgress(level, lv),
                  levelUpText: S.levelUp(level, w.after.lv),
                  t: Curves.easeOut.transform(
                    ((_stars.value - 0.5) * 2).clamp(0.0, 1.0),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (label, value) in [
                  (S.statTime, formatTime(g.elapsed)),
                  (S.statScore, '${g.score}'),
                  (S.statMistakes, '${g.mistakes}'),
                  (S.statHints, '${g.hintsUsed}'),
                ])
                  Expanded(child: _Stat(label, value)),
              ],
            ),
            const SizedBox(height: 20),
            _Buttons(
              primary: (S.nextGame, () => Navigator.pop(context, WinChoice.next)),
              secondary: (S.goHome, () => Navigator.pop(context, WinChoice.home)),
            ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (context, _) => _confetti.isAnimating
                  ? CustomPaint(
                      painter: _ConfettiPainter(
                        t: _confetti.value,
                        colors: [c.primary, c.streak, c.success, c.badge, c.error],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.win, required this.t});

  final WinSummary win;

  /// Animation progress 0..1; star k lights at t ≥ (k + 1) / 6.
  final double t;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final earned = [true, win.stars.clean, win.stars.fast];
    const labels = [S.starWin, S.starClean, S.starFast];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var k = 0; k < 3; k++)
          Expanded(
            child: Column(
              children: [
                () {
                  final start = k / 6, lit = earned[k] && t >= start;
                  final pop = earned[k]
                      ? Curves.elasticOut.transform(
                          ((t - start) * 6).clamp(0.0, 1.0),
                        )
                      : 1.0;
                  return Transform.scale(
                    scale: lit ? 0.6 + 0.4 * pop : 0.9,
                    child: Icon(
                      Icons.star_rounded,
                      size: k == 1 ? 60 : 48,
                      color: lit ? c.gold : c.gridThin,
                    ),
                  );
                }(),
                Text(
                  labels[k],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: earned[k] ? c.textPrimary : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({
    required this.win,
    required this.levelName,
    required this.levelUpText,
    required this.t,
  });

  final WinSummary win;
  final String Function(int lv) levelName;
  final String levelUpText;
  final double t;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const per = LevelProgress.starsPerLv;
    // Animate from the old count; on level-up fill to 100 then show the
    // new level's remainder.
    final up = win.levelUp;
    final from = win.before.stars / per;
    final to = up ? 1.0 : win.after.stars / per;
    final shownUp = up && t >= 1;
    final value = shownUp ? win.after.stars / per : from + (to - from) * t;
    final count = shownUp
        ? win.after.stars
        : (win.before.stars + (win.stars.count * t).round()).clamp(0, per);
    return Column(
      children: [
        Row(
          children: [
            Text(
              levelName(shownUp ? win.after.lv : win.before.lv),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.star_rounded, size: 18, color: c.gold),
            Text(
              ' ${S.starsProgress(count)}',
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            color: c.primary,
            backgroundColor: c.highlight,
          ),
        ),
        if (shownUp) ...[
          const SizedBox(height: 8),
          _Badge(levelUpText, c.success),
        ],
      ],
    );
  }
}

/// Falling confetti, painted from a fixed seed so every frame is cheap.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t, required this.colors});

  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final paint = Paint();
    for (var k = 0; k < 90; k++) {
      final x0 = rnd.nextDouble() * size.width;
      final speed = 0.6 + rnd.nextDouble() * 0.8;
      final drift = (rnd.nextDouble() - 0.5) * 80;
      final spin = rnd.nextDouble() * 12;
      final y = -20 + (size.height + 40) * t * speed;
      final x = x0 + drift * t + math.sin(t * 8 + k) * 10;
      paint.color = colors[k % colors.length].withValues(
        alpha: (1 - t).clamp(0.0, 1.0),
      );
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(spin * t)
        ..drawRect(const Rect.fromLTWH(-4, -2, 8, 4), paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

class _DialogFrame extends StatelessWidget {
  const _DialogFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDims.cardRadius),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: context.colors.textPrimary,
        ),
      );
}

class _Subtitle extends StatelessWidget {
  const _Subtitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, color: context.colors.textSecondary),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.colors.surface,
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
      ],
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({required this.primary, required this.secondary});

  final (String, VoidCallback) primary;
  final (String, VoidCallback) secondary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: primary.$2,
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.surface,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDims.primaryButtonRadius),
              ),
            ),
            child: Text(
              primary.$1,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: secondary.$2,
            child: Text(
              secondary.$1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
