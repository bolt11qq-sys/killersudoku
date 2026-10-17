import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// TZ §2: `lib/engine/` must stay pure Dart and never import Flutter.
void main() {
  test('engine does not import Flutter', () {
    final files = Directory('lib/engine')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    for (final f in files) {
      final src = f.readAsStringSync();
      expect(src.contains('package:flutter'), isFalse, reason: f.path);
      expect(src.contains('dart:ui'), isFalse, reason: f.path);
    }
  });
}
