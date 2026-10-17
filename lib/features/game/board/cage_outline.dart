import 'dart:ui';

import '../../../app/theme.dart';

/// Dashed cage outlines in board units (one cell = 1.0), inset from the
/// cell edges by [AppDims.cageInset]. Port of `drawOverlay` from the web
/// version, with collinear pieces merged so the dash pattern runs smoothly.
class CageOutline {
  CageOutline._(this.lines, this.corners);

  /// Long straight outline pieces (dashed).
  final List<(Offset, Offset)> lines;

  /// Short inner-corner pieces (drawn solid).
  final List<(Offset, Offset)> corners;

  factory CageOutline.build(List<int> cageOf) {
    const d = AppDims.cageInset;
    bool same(int i, int r, int c) =>
        r >= 0 && r < 9 && c >= 0 && c < 9 && cageOf[r * 9 + c] == cageOf[i];
    final h = <(Offset, Offset)>[];
    final v = <(Offset, Offset)>[];
    final corners = <(Offset, Offset)>[];
    for (var i = 0; i < 81; i++) {
      final r = i ~/ 9, c = i % 9;
      final x0 = c.toDouble(), y0 = r.toDouble(), x1 = x0 + 1, y1 = y0 + 1;
      final u = same(i, r - 1, c), dn = same(i, r + 1, c);
      final l = same(i, r, c - 1), rt = same(i, r, c + 1);
      final left = l ? x0 : x0 + d, right = rt ? x1 : x1 - d;
      final top = u ? y0 : y0 + d, bottom = dn ? y1 : y1 - d;
      if (!u) h.add((Offset(left, y0 + d), Offset(right, y0 + d)));
      if (!dn) h.add((Offset(left, y1 - d), Offset(right, y1 - d)));
      if (!l) v.add((Offset(x0 + d, top), Offset(x0 + d, bottom)));
      if (!rt) v.add((Offset(x1 - d, top), Offset(x1 - d, bottom)));
      void notch(double cx, double cy, double sx, double sy) {
        corners
          ..add((Offset(cx, cy + sy * d), Offset(cx + sx * d, cy + sy * d)))
          ..add((Offset(cx + sx * d, cy + sy * d), Offset(cx + sx * d, cy)));
      }

      if (u && l && !same(i, r - 1, c - 1)) notch(x0, y0, 1, 1);
      if (u && rt && !same(i, r - 1, c + 1)) notch(x1, y0, -1, 1);
      if (dn && l && !same(i, r + 1, c - 1)) notch(x0, y1, 1, -1);
      if (dn && rt && !same(i, r + 1, c + 1)) notch(x1, y1, -1, -1);
    }
    return CageOutline._(
      [..._merge(h, horizontal: true), ..._merge(v, horizontal: false)],
      corners,
    );
  }

  static List<(Offset, Offset)> _merge(
    List<(Offset, Offset)> segs, {
    required bool horizontal,
  }) {
    double key(Offset o) => horizontal ? o.dy : o.dx;
    double pos(Offset o) => horizontal ? o.dx : o.dy;
    final sorted = [...segs]
      ..sort((a, b) {
        final k = key(a.$1).compareTo(key(b.$1));
        return k != 0 ? k : pos(a.$1).compareTo(pos(b.$1));
      });
    final out = <(Offset, Offset)>[];
    for (final s in sorted) {
      if (out.isNotEmpty) {
        final last = out.last;
        if ((key(last.$1) - key(s.$1)).abs() < 1e-9 &&
            (pos(last.$2) - pos(s.$1)).abs() < 1e-9) {
          out[out.length - 1] = (last.$1, s.$2);
          continue;
        }
      }
      out.add(s);
    }
    return out;
  }
}
