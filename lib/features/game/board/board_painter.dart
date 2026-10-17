
import 'package:flutter/rendering.dart';

import '../../../app/theme.dart';
import '../../../engine/common/bitmask.dart';
import '../../../engine/common/board.dart';
import '../game_state.dart';
import 'cage_outline.dart';

/// Reuses laid-out text between frames; cleared when the cell size changes.
class TextCache {
  final Map<String, TextPainter> _cache = {};
  double _cell = 0;

  TextPainter get(
    String text,
    Color color,
    double size,
    FontWeight weight,
    double cell,
  ) {
    if (cell != _cell) {
      clear();
      _cell = cell;
    }
    final key = '$text|${color.toARGB32()}|$size|${weight.value}';
    return _cache.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: size,
            fontWeight: weight,
            color: color,
            height: 1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  void clear() {
    for (final p in _cache.values) {
      p.dispose();
    }
    _cache.clear();
  }
}

/// Paints the Killer board (TZ §3.3, §6): highlights, grid, dashed cages,
/// cage sums, digits and pencil marks.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.game,
    required this.outline,
    required this.colors,
    required this.texts,
    required this.highlightSame,
    required this.showErrors,
    required this.hidden,
    required this.flashCells,
    required this.flash,
  });

  final GameState game;
  final CageOutline outline;
  final AppColors colors;
  final TextCache texts;
  final bool highlightSame;
  final bool showErrors;

  /// Paused: draw an empty grid only.
  final bool hidden;
  final Set<int> flashCells;

  /// Flash strength 0..1 (completed row / column / block / cage).
  final double flash;

  /// Digit whose cells and notes are highlighted.
  int get _focusDigit {
    if (game.pickedDigit != 0) return game.pickedDigit;
    final s = game.selected;
    return s >= 0 ? game.values[s] : 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 9;
    final c = colors;
    canvas.drawRect(Offset.zero & size, Paint()..color = c.surface);
    if (!hidden) _paintCells(canvas, cell);
    _paintGrid(canvas, size, cell);
    if (hidden) return;
    _paintCages(canvas, cell);
    _paintText(canvas, cell);
  }

  /// Highlight colour of a cell, or null for the plain surface.
  /// Priority: selected > same digit > selected cage > row/column/block.
  Color? _bgFor(int i, int focus) {
    final c = colors;
    final sel = game.selected;
    if (i == sel) return c.selected;
    if (focus != 0 && game.values[i] == focus) return c.sameNumber;
    if (sel < 0) return null;
    if (game.puzzle.cageOf[i] == game.puzzle.cageOf[sel]) return c.cageFill;
    if (rowOf[i] == rowOf[sel] ||
        colOf[i] == colOf[sel] ||
        blockOf[i] == blockOf[sel]) {
      return c.highlight;
    }
    return null;
  }

  void _paintCells(Canvas canvas, double cell) {
    final c = colors;
    final focus = highlightSame ? _focusDigit : 0;
    final paint = Paint();
    for (var i = 0; i < 81; i++) {
      final bg = _bgFor(i, focus);
      final rect = Rect.fromLTWH(colOf[i] * cell, rowOf[i] * cell, cell, cell);
      if (bg != null) canvas.drawRect(rect, paint..color = bg);
      if (flash > 0 && flashCells.contains(i)) {
        canvas.drawRect(
          rect,
          paint..color = c.primary.withValues(alpha: 0.28 * flash),
        );
      }
    }
  }

  void _paintGrid(Canvas canvas, Size size, double cell) {
    final c = colors;
    final thin = Paint()
      ..color = c.gridThin
      ..strokeWidth = AppDims.gridThin;
    final thick = Paint()
      ..color = c.gridThick
      ..strokeWidth = AppDims.gridThick;
    for (var k = 1; k < 9; k++) {
      final p = k * cell;
      final paint = k % 3 == 0 ? thick : thin;
      canvas
        ..drawLine(Offset(p, 0), Offset(p, size.height), paint)
        ..drawLine(Offset(0, p), Offset(size.width, p), paint);
    }
    const o = AppDims.gridOuter;
    canvas.drawRect(
      Rect.fromLTWH(o / 2, o / 2, size.width - o, size.height - o),
      Paint()
        ..color = c.gridThick
        ..style = PaintingStyle.stroke
        ..strokeWidth = o,
    );
  }

  void _paintCages(Canvas canvas, double cell) {
    final paint = Paint()
      ..color = colors.cage
      ..strokeWidth = AppDims.cageStroke
      ..style = PaintingStyle.stroke;
    final dash = cell * 0.07, gap = cell * 0.05;
    for (final (a, b) in outline.lines) {
      _dashed(canvas, a * cell, b * cell, dash, gap, paint);
    }
    for (final (a, b) in outline.corners) {
      canvas.drawLine(a * cell, b * cell, paint);
    }
  }

  void _dashed(
    Canvas canvas,
    Offset a,
    Offset b,
    double dash,
    double gap,
    Paint paint,
  ) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var t = 0.0;
    while (t < total) {
      final end = (t + dash).clamp(0.0, total);
      canvas.drawLine(a + dir * t, a + dir * end, paint);
      t += dash + gap;
    }
  }

  void _paintText(Canvas canvas, double cell) {
    final c = colors;
    final focus = highlightSame ? _focusDigit : 0;

    // Cage sums, top-left of each cage's first cell, on a patch of the
    // cell background so the dashed line does not run through the number.
    final bgPaint = Paint();
    for (var k = 0; k < game.puzzle.cages.length; k++) {
      final cage = game.puzzle.cages[k];
      final i = cage.cells.first;
      final tp = texts.get(
        '${cage.sum}',
        c.cage,
        cell * AppDims.cageSumScale,
        FontWeight.w700,
        cell,
      );
      final pos = Offset(
        colOf[i] * cell + cell * 0.05,
        rowOf[i] * cell + cell * 0.04,
      );
      canvas.drawRect(
        Rect.fromLTWH(pos.dx - 1, pos.dy - 1, tp.width + 2, tp.height + 2),
        bgPaint..color = _bgFor(i, focus) ?? c.surface,
      );
      tp.paint(canvas, pos);
    }

    for (var i = 0; i < 81; i++) {
      final x = colOf[i] * cell, y = rowOf[i] * cell;
      final v = game.values[i];
      if (v != 0) {
        final color = game.isGiven(i)
            ? c.textPrimary
            : (showErrors && game.isWrong(i) ? c.error : c.primary);
        final tp = texts.get(
          '$v',
          color,
          cell * AppDims.digitScale,
          FontWeight.w600,
          cell,
        );
        // Nudged down a little to leave room for the cage sum.
        tp.paint(
          canvas,
          Offset(
            x + (cell - tp.width) / 2,
            y + (cell - tp.height) / 2 + cell * 0.04,
          ),
        );
        continue;
      }
      final notes = game.notes[i];
      if (notes == 0) continue;
      // 3×3 pencil marks inside the area below the cage sum.
      final top = y + cell * 0.24, left = x + cell * 0.1;
      final w = cell * 0.8 / 3, h = cell * 0.7 / 3;
      for (final d in digitsOf(notes)) {
        final hl = d == focus;
        final tp = texts.get(
          '$d',
          hl ? c.primary : c.textSecondary,
          cell * AppDims.noteScale,
          hl ? FontWeight.w800 : FontWeight.w600,
          cell,
        );
        final col = (d - 1) % 3, row = (d - 1) ~/ 3;
        tp.paint(
          canvas,
          Offset(
            left + col * w + (w - tp.width) / 2,
            top + row * h + (h - tp.height) / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.game != game ||
      old.colors != colors ||
      old.hidden != hidden ||
      old.flash != flash ||
      old.highlightSame != highlightSame ||
      old.showErrors != showErrors;
}
