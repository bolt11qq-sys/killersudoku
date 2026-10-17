import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/widgets/placeholder_view.dart';
import '../../l10n/strings.dart';

/// "Men" tab: statistics, saved puzzles, settings entry (TZ §3.5).
/// Built in stage 7.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.tabMe),
        actions: [
          IconButton(
            tooltip: S.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: const PlaceholderView(title: S.statsTitle),
    );
  }
}
