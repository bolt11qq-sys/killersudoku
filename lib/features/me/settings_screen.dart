import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/backup.dart';
import '../../data/game_repository.dart';
import '../../data/kv_store.dart';
import '../../data/settings.dart';
import '../../l10n/strings.dart';
import '../game/game_controller.dart';

/// Settings (TZ §3.5): game rules, appearance, and data (reset, export,
/// import). Opened from the "Men" tab and from the game screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    void set(AppSettings v) => ctrl.update(v);

    Widget toggle(String title, bool value, AppSettings Function(bool) f) =>
        _Switch(title: title, value: value, onChanged: (v) => set(f(v)));

    return Scaffold(
      appBar: AppBar(title: const Text(S.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppDims.screenPadding),
        children: [
          const _Header(S.sectionGame),
          _Card(children: [
            toggle(S.setMistakeLimit, s.mistakeLimit,
                (v) => s.copyWith(mistakeLimit: v)),
            toggle(S.setShowErrors, s.showErrors,
                (v) => s.copyWith(showErrors: v)),
            toggle(S.setAutoNotes, s.autoRemoveNotes,
                (v) => s.copyWith(autoRemoveNotes: v)),
            toggle(S.setHighlightSame, s.highlightSame,
                (v) => s.copyWith(highlightSame: v)),
            toggle(S.setHideUsed, s.hideUsedNumbers,
                (v) => s.copyWith(hideUsedNumbers: v)),
            toggle(S.setShowTimer, s.showTimer,
                (v) => s.copyWith(showTimer: v)),
            toggle(S.setNumberFirst, s.numberFirst,
                (v) => s.copyWith(numberFirst: v)),
            toggle(S.setSound, s.sound, (v) => s.copyWith(sound: v)),
            toggle(S.setVibration, s.vibration,
                (v) => s.copyWith(vibration: v)),
          ]),
          const _Header(S.sectionLook),
          _Card(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Expanded(child: Text(S.setTheme)),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(S.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(S.themeDark),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(S.themeSystem),
                      ),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (v) =>
                        set(s.copyWith(themeMode: v.first)),
                  ),
                ],
              ),
            ),
          ]),
          const _Header(S.sectionData),
          _Card(children: [
            _Action(
              icon: Icons.upload_file_rounded,
              title: S.exportData,
              onTap: () => _export(context, ref),
            ),
            _Action(
              icon: Icons.download_rounded,
              title: S.importData,
              onTap: () => _import(context, ref),
            ),
            _Action(
              icon: Icons.delete_outline_rounded,
              title: S.resetStats,
              danger: true,
              onTap: () => _reset(context, ref),
            ),
          ]),
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String text) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(S.confirm),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    if (!await _confirm(context, S.resetStatsConfirm)) return;
    await ref.read(gameRepositoryProvider).clearHistory();
    ref.read(gameProvider.notifier).dataChanged();
    if (context.mounted) _toast(context, S.resetDone);
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final json = Backup.export(
      games: ref.read(gameRepositoryProvider),
      kv: ref.read(kvStoreProvider),
      settings: ref.read(settingsProvider),
    );
    final now = DateTime.now();
    final name = 'killer_sudoku_'
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}.json';
    final uri = await FilePicker.saveFile(
      fileName: name,
      bytes: utf8.encode(json),
      mimeType: 'application/json',
    );
    if (uri != null && context.mounted) _toast(context, S.exportDone);
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (files.isEmpty || !context.mounted) return;
    if (!await _confirm(context, S.importConfirm)) return;
    try {
      final text = utf8.decode(await files.first.readAsBytes());
      final settings = await Backup.import(
        text,
        games: ref.read(gameRepositoryProvider),
        kv: ref.read(kvStoreProvider),
      );
      await ref.read(settingsProvider.notifier).update(settings);
      ref.read(gameProvider.notifier).dataChanged();
      if (context.mounted) _toast(context, S.importDone);
    } on FormatException {
      if (context.mounted) _toast(context, S.importFailed);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.colors.textSecondary,
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppDims.levelCardRadius),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        value: value,
        onChanged: onChanged,
      );
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = danger ? c.error : c.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontSize: 16, color: color)),
      onTap: onTap,
    );
  }
}
