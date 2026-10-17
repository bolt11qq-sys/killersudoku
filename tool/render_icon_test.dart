// Renders the launcher icon PNGs (run: flutter test tool/render_icon_test.dart)
// then `dart run flutter_launcher_icons` turns them into Android mipmaps.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _blue = Color(0xFF1E5BDB);
const _white = Color(0xFFFFFFFF);
const _ink = Color(0xFF1C2230);
const _cage = Color(0xFF4A5568);
const _highlight = Color(0xFFDCE5F6);

/// Draws a mini Killer board: 3×3 cells, one highlighted L-shaped dashed
/// cage with its sum, and a blue digit. [inset] leaves the adaptive-icon
/// safe zone free.
void _paintBoard(Canvas canvas, double size, double inset) {
  final side = size - 2 * inset;
  final cell = side / 3;
  final o = Offset(inset, inset);
  final r = RRect.fromRectAndRadius(o & Size(side, side), Radius.circular(side * 0.08));
  canvas.drawRRect(r, Paint()..color = _white);
  canvas.save();
  canvas.clipRRect(r);
  // Cage cells: (0,0), (1,0), (1,1).
  final p = Paint()..color = _highlight;
  for (final (cx, cy) in [(0, 0), (0, 1), (1, 1)]) {
    canvas.drawRect(Rect.fromLTWH(o.dx + cx * cell, o.dy + cy * cell, cell, cell), p);
  }
  canvas.restore();
  final grid = Paint()
    ..color = const Color(0xFFD5DAE3)
    ..strokeWidth = side * 0.012;
  for (var k = 1; k < 3; k++) {
    canvas
      ..drawLine(o + Offset(k * cell, 0), o + Offset(k * cell, side), grid)
      ..drawLine(o + Offset(0, k * cell), o + Offset(side, k * cell), grid);
  }
  canvas.drawRRect(
    r,
    Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.03,
  );
  // Dashed L-shaped cage outline, inset into the cells.
  final d = cell * 0.12;
  final pts = [
    o + Offset(d, d),
    o + Offset(cell - d, d),
    o + Offset(cell - d, cell + d),
    o + Offset(2 * cell - d, cell + d),
    o + Offset(2 * cell - d, 2 * cell - d),
    o + Offset(d, 2 * cell - d),
    o + Offset(d, d),
  ];
  final dash = Paint()
    ..color = _cage
    ..strokeWidth = side * 0.018
    ..strokeCap = StrokeCap.butt;
  final len = cell * 0.09, gap = cell * 0.07;
  for (var k = 0; k + 1 < pts.length; k++) {
    final a = pts[k], b = pts[k + 1];
    final total = (b - a).distance, dir = (b - a) / total;
    for (var t = 0.0; t < total; t += len + gap) {
      canvas.drawLine(a + dir * t, a + dir * (t + len).clamp(0, total), dash);
    }
  }
  void text(String s, Offset at, double fontSize, Color color, FontWeight w) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontFamily: 'NunitoSans', fontSize: fontSize, fontWeight: w, color: color, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  text('24', o + Offset(cell * 0.3, cell * 0.25), cell * 0.24, _cage, FontWeight.w800);
  text('7', o + Offset(cell * 0.56, cell * 0.64), cell * 0.56, _blue, FontWeight.w700);
  text('9', o + Offset(cell * 1.5, cell * 1.55), cell * 0.72, _blue, FontWeight.w700);
  text('8', o + Offset(cell * 0.5, cell * 1.55), cell * 0.72, _blue, FontWeight.w700);
}

Future<void> _save(String path, double size, void Function(Canvas) paint) async {
  final rec = ui.PictureRecorder();
  paint(Canvas(rec));
  final img = await rec.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('render launcher icons', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('NunitoSans');
      for (final w in ['Bold', 'ExtraBold']) {
        loader.addFont(Future.value(ByteData.sublistView(
          File('assets/fonts/NunitoSans-$w.ttf').readAsBytesSync(),
        )));
      }
      await loader.load();
      const size = 1024.0;
      // Legacy icon: blue rounded background with the board.
      await _save('assets/icon/icon.png', size, (c) {
        c.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, size, size), const Radius.circular(size * 0.22)),
          Paint()..color = _blue,
        );
        _paintBoard(c, size, size * 0.17);
      });
      // Adaptive foreground: board inside the 66 % safe zone.
      await _save('assets/icon/icon_fg.png', size, (c) => _paintBoard(c, size, size * 0.25));
    });
  });
}
