import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../game_controller.dart';
import '../game_state.dart';
import 'board_painter.dart';
import 'cage_outline.dart';

/// Square board: paints the game and turns taps into cell indices.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.game,
    required this.onTapCell,
    required this.highlightSame,
    required this.showErrors,
    this.hidden = false,
    this.flash,
  });

  final GameState game;
  final ValueChanged<int> onTapCell;
  final bool highlightSame;
  final bool showErrors;
  final bool hidden;
  final Flash? flash;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  final _texts = TextCache();
  late CageOutline _outline;
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: AppDurations.lineWave,
  );

  @override
  void initState() {
    super.initState();
    _outline = CageOutline.build(widget.game.puzzle.cageOf);
  }

  @override
  void didUpdateWidget(BoardView old) {
    super.didUpdateWidget(old);
    if (!identical(old.game.puzzle, widget.game.puzzle)) {
      _outline = CageOutline.build(widget.game.puzzle.cageOf);
    }
    final f = widget.flash;
    if (f != null && f.id != old.flash?.id) {
      if (MediaQuery.disableAnimationsOf(context)) return;
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    _texts.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, box) {
          final cell = box.maxWidth / 9;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final r = (d.localPosition.dy / cell).floor().clamp(0, 8);
              final c = (d.localPosition.dx / cell).floor().clamp(0, 8);
              widget.onTapCell(r * 9 + c);
            },
            child: AnimatedBuilder(
              animation: _flash,
              builder: (context, _) => CustomPaint(
                size: Size.square(box.maxWidth),
                painter: BoardPainter(
                  game: widget.game,
                  outline: _outline,
                  colors: colors,
                  texts: _texts,
                  highlightSame: widget.highlightSame,
                  showErrors: widget.showErrors,
                  hidden: widget.hidden,
                  flashCells: widget.flash?.cells ?? const {},
                  // Fades in then out over the animation.
                  flash: _flash.isAnimating
                      ? 1 - (2 * _flash.value - 1).abs()
                      : 0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
