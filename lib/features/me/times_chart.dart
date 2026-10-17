import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../game/status_bar.dart';

/// Average winning time per day for the last 30 days (TZ §3.5). One
/// series, so no legend: the title names it. Bars are thin, rounded at the
/// data end and anchored to the baseline; only the best day is labelled;
/// tapping a bar shows its date and time.
class TimesChart extends StatefulWidget {
  const TimesChart({super.key, required this.times, required this.lastDay});

  /// Oldest first; null = no win that day.
  final List<int?> times;
  final DateTime lastDay;

  @override
  State<TimesChart> createState() => _TimesChartState();
}

class _TimesChartState extends State<TimesChart> {
  int? _selected;

  DateTime _dayOf(int k) => DateTime(
        widget.lastDay.year,
        widget.lastDay.month,
        widget.lastDay.day - (widget.times.length - 1 - k),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasData = widget.times.any((t) => t != null);
    final sel = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.chartTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: sel != null && widget.times[sel] != null
              ? Text(
                  '${S.dailyDate(_dayOf(sel))} · ${formatTime(widget.times[sel]!)}',
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                )
              : null,
        ),
        SizedBox(
          height: 140,
          child: hasData
              ? LayoutBuilder(
                  builder: (context, box) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      final k = (d.localPosition.dx /
                              box.maxWidth *
                              widget.times.length)
                          .floor()
                          .clamp(0, widget.times.length - 1);
                      setState(() => _selected = _selected == k ? null : k);
                    },
                    child: CustomPaint(
                      size: Size(box.maxWidth, box.maxHeight),
                      painter: _BarsPainter(
                        times: widget.times,
                        selected: _selected,
                        bar: c.primary,
                        selectedBar: c.textPrimary,
                        axis: c.gridThin,
                        label: c.textSecondary,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    S.chartEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
                  ),
                ),
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.times,
    required this.selected,
    required this.bar,
    required this.selectedBar,
    required this.axis,
    required this.label,
  });

  final List<int?> times;
  final int? selected;
  final Color bar;
  final Color selectedBar;
  final Color axis;
  final Color label;

  static const double _labelSpace = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final max = times.whereType<int>().fold<int>(1, math.max);
    final best = times.whereType<int>().fold<int?>(
          null,
          (m, t) => m == null || t < m ? t : m,
        );
    final slot = size.width / times.length;
    const gap = 2.0;
    final w = math.max(2.0, slot - gap);
    final base = size.height - 1;
    const top = _labelSpace;
    canvas.drawLine(
      Offset(0, base + 0.5),
      Offset(size.width, base + 0.5),
      Paint()
        ..color = axis
        ..strokeWidth = 1,
    );
    final paint = Paint();
    for (var k = 0; k < times.length; k++) {
      final t = times[k];
      if (t == null) continue;
      final h = math.max(3.0, (base - top) * t / max);
      final x = k * slot + gap / 2;
      paint.color = k == selected ? selectedBar : bar;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, base - h, w, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        paint,
      );
      // Selective direct label: the fastest day only.
      if (t == best) {
        final tp = TextPainter(
          text: TextSpan(
            text: formatTime(t),
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: label,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final lx = (x + w / 2 - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp
          ..paint(canvas, Offset(lx, base - h - tp.height - 2))
          ..dispose();
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.times != times ||
      old.selected != selected ||
      old.bar != bar ||
      old.selectedBar != selectedBar;
}
