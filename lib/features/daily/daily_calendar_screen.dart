import 'package:flutter/material.dart';

import '../../app/widgets/placeholder_view.dart';
import '../../l10n/strings.dart';

/// Daily challenge calendar (TZ §3.4). Built in stage 6.
class DailyCalendarScreen extends StatelessWidget {
  const DailyCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.dailyCalendarTitle)),
      body: const PlaceholderView(title: S.dailyCalendarTitle),
    );
  }
}
