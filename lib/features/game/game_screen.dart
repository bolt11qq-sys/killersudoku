import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/settings.dart';
import '../../l10n/strings.dart';
import 'board/board_view.dart';
import 'cage_panel.dart';
import 'game_controller.dart';
import 'game_state.dart';
import 'number_pad.dart';
import 'status_bar.dart';
import 'toolbar.dart';
import 'win_dialog.dart';

/// Game screen (TZ §3.3).
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;
  bool _dialogOpen = false;

  GameController get _ctrl => ref.read(gameProvider.notifier);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _ctrl.tick());
    // TZ §5.6: pause when the app goes to the background.
    _lifecycle = AppLifecycleListener(onHide: _ctrl.pause);
    // A game restored from disk may already be over.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = ref.read(gameProvider).game;
      if (game != null) _showEndDialog(game);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _showEndDialog(GameState game) async {
    if (_dialogOpen || !mounted) return;
    if (game.status == GameStatus.won) {
      _dialogOpen = true;
      final choice = await showWinDialog(
        context,
        game,
        newRecord: ref.read(gameProvider).newRecord,
      );
      _dialogOpen = false;
      if (!mounted) return;
      if (choice == WinChoice.next) {
        unawaited(_ctrl.newGame(game.puzzle.level));
      } else {
        context.go(Routes.home);
      }
    } else if (game.status == GameStatus.lost) {
      _dialogOpen = true;
      final choice = await showLossDialog(context, game);
      _dialogOpen = false;
      if (!mounted) return;
      if (choice == LossChoice.continueGame) {
        _ctrl.continueAfterLoss();
      } else {
        unawaited(_ctrl.newGame(game.puzzle.level));
      }
    }
  }

  void _onHint() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(S.hintComingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameProvider, (prev, next) {
      final g = next.game;
      if (g != null && g.status != prev?.game?.status) _showEndDialog(g);
    });
    final session = ref.watch(gameProvider);
    final settings = ref.watch(settingsProvider);
    final game = session.game;
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        actions: [
          if (game != null)
            IconButton(
              tooltip: S.savePuzzle,
              icon: Icon(
                game.saved ? Icons.star_rounded : Icons.star_outline_rounded,
                color: game.saved ? c.streak : c.textPrimary,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await _ctrl.toggleSaved();
                final saved = ref.read(gameProvider).game?.saved ?? false;
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(saved ? S.savedPuzzle : S.unsavedPuzzle),
                    duration: const Duration(seconds: 2),
                  ));
              },
            ),
          IconButton(
            tooltip: S.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              _ctrl.pause();
              context.push(Routes.settings);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: session.generating != null
            ? const _Generating()
            : game == null
                ? const SizedBox.shrink()
                : _GameBody(
                    game: game,
                    settings: settings,
                    flash: session.flash,
                    controller: _ctrl,
                    onHint: _onHint,
                  ),
      ),
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody({
    required this.game,
    required this.settings,
    required this.flash,
    required this.controller,
    required this.onHint,
  });

  final GameState game;
  final AppSettings settings;
  final Flash? flash;
  final GameController controller;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final paused = game.status == GameStatus.paused;
    return LayoutBuilder(
      builder: (context, box) {
        const pad = AppDims.screenPadding;
        final width = box.maxWidth - 2 * pad;
        final padHeight =
            (width - 8 * AppDims.numberButtonGap) / 9 * 1.5;
        // Everything except the board, so the board shrinks on short screens.
        final reserved = 52 + 36 + CagePanel.height + 68 + padHeight + 40;
        final board = (box.maxHeight - reserved).clamp(200.0, width);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: pad),
          child: Column(
            children: [
              StatusBar(
                game: game,
                settings: settings,
                onPause: paused ? controller.resume : controller.pause,
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: board,
                height: board,
                child: Stack(
                  children: [
                    BoardView(
                      game: game,
                      onTapCell: controller.tapCell,
                      highlightSame: settings.highlightSame,
                      showErrors: settings.showErrors,
                      hidden: paused,
                      flash: flash,
                    ),
                    if (paused)
                      Positioned.fill(
                        child: _PausedCard(
                          game: game,
                          onResume: controller.resume,
                        ),
                      ),
                  ],
                ),
              ),
              _NumberFirstSwitch(settings: settings),
              CagePanel(game: game, onToggle: controller.toggleCombo),
              // Spare height goes here, keeping the controls near the thumb.
              const Spacer(),
              GameToolbar(
                game: game,
                onUndo: controller.undo,
                onErase: controller.erase,
                onFastPencil: controller.fastPencil,
                onPencil: controller.toggleNotesMode,
                onHint: onHint,
              ),
              const SizedBox(height: 8),
              NumberPad(
                game: game,
                hideUsed: settings.hideUsedNumbers,
                onDigit: controller.tapDigit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

/// The small ⚡ switch under the board: number-first input (TZ §3.3, §5.1).
class _NumberFirstSwitch extends ConsumerWidget {
  const _NumberFirstSwitch({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            S.numberFirst,
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
          Icon(Icons.bolt_rounded, size: 18, color: c.textSecondary),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: settings.numberFirst,
              onChanged: (v) {
                ref
                    .read(settingsProvider.notifier)
                    .update(settings.copyWith(numberFirst: v));
                // Leaving number-first mode drops the picked digit.
                final ctrl = ref.read(gameProvider.notifier);
                final picked = ref.read(gameProvider).game?.pickedDigit ?? 0;
                if (!v && picked != 0) ctrl.tapDigit(picked);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PausedCard extends StatelessWidget {
  const _PausedCard({required this.game, required this.onResume});

  final GameState game;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.pause,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatTime(game.elapsed)} · ${S.level(game.puzzle.level)}',
            style: TextStyle(fontSize: 16, color: c.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(S.resume),
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.surface,
              minimumSize: const Size(180, 52),
              textStyle: const TextStyle(
                fontFamily: kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.primaryButtonRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Generating extends StatelessWidget {
  const _Generating();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: c.primary),
            const SizedBox(height: 20),
            Text(
              S.generating,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.generatingSlow,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
