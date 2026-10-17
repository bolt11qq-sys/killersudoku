import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Minimal string key-value storage per box, so repositories work the same
/// on Hive and in tests ([MemoryKvStore]).
abstract class KvStore {
  String? get(String box, String key);
  Future<void> put(String box, String key, String value);
  Future<void> delete(String box, String key);
  Future<void> clear(String box);
  Map<String, String> all(String box);
}

/// Overridden in `main()` (Hive) and in tests.
final kvStoreProvider = Provider<KvStore>(
  (ref) => throw UnimplementedError('KvStore not provided'),
);

class HiveKvStore implements KvStore {
  HiveKvStore(this._boxes);

  /// Opens [names] as string boxes; call after `Hive.initFlutter()`.
  static Future<HiveKvStore> open(List<String> names) async => HiveKvStore({
        for (final n in names) n: await Hive.openBox<String>(n),
      });

  final Map<String, Box<String>> _boxes;

  Box<String> _box(String name) =>
      _boxes[name] ?? (throw StateError('Box $name is not open'));

  @override
  String? get(String box, String key) => _box(box).get(key);

  @override
  Future<void> put(String box, String key, String value) =>
      _box(box).put(key, value);

  @override
  Future<void> delete(String box, String key) => _box(box).delete(key);

  @override
  Future<void> clear(String box) async {
    await _box(box).clear();
  }

  @override
  Map<String, String> all(String box) {
    final b = _box(box);
    return {for (final k in b.keys) '$k': b.get(k)!};
  }
}

class MemoryKvStore implements KvStore {
  final Map<String, Map<String, String>> data = {};

  Map<String, String> _box(String name) => data.putIfAbsent(name, () => {});

  @override
  String? get(String box, String key) => _box(box)[key];

  @override
  Future<void> put(String box, String key, String value) async =>
      _box(box)[key] = value;

  @override
  Future<void> delete(String box, String key) async => _box(box).remove(key);

  @override
  Future<void> clear(String box) async => _box(box).clear();

  @override
  Map<String, String> all(String box) => Map.of(_box(box));
}
