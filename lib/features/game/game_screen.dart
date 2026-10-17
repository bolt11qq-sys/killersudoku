import 'package:flutter/material.dart';

import '../../app/widgets/placeholder_view.dart';
import '../../l10n/strings.dart';

/// Game screen (TZ §3.3). Built in stage 3.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const PlaceholderView(title: S.gameTitle),
    );
  }
}
