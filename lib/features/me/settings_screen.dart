import 'package:flutter/material.dart';

import '../../app/widgets/placeholder_view.dart';
import '../../l10n/strings.dart';

/// Settings (TZ §3.5). Opened from the "Men" tab and from the game screen's
/// gear icon. Built in stage 7.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.settingsTitle)),
      body: const PlaceholderView(title: S.settingsTitle),
    );
  }
}
