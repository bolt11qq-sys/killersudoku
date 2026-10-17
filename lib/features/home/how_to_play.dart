import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';

/// "Qanday o'ynaladi" rules sheet (TZ §3.1 item 3).
Future<void> showHowToPlay(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) {
      final c = context.colors;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDims.screenPadding,
            0,
            AppDims.screenPadding,
            AppDims.screenPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  S.rulesTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final (mark, text) in S.rules)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          mark,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: c.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
