import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/l10n/strings.dart';

import 'helpers.dart';

void main() {
  testWidgets('home shows mode title, new game button and two tabs',
      (tester) async {
    await pumpApp(tester);

    expect(find.text(S.modeTitle), findsOneWidget);
    expect(find.text(S.newGame), findsOneWidget);
    expect(find.text(S.continueGame), findsNothing);
    expect(find.text(S.tabHome), findsOneWidget);
    expect(find.text(S.tabMe), findsOneWidget);
    // TZ §1: no Battle / Explore tabs.
    expect(find.text('Battle'), findsNothing);
    expect(find.text('Explore'), findsNothing);
  });

  testWidgets('bottom navigation switches to Men and back', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text(S.tabMe));
    await settle(tester);
    expect(find.text(S.statsTitle), findsOneWidget);

    await tester.tap(find.text(S.tabHome));
    await settle(tester);
    expect(find.text(S.modeTitle), findsOneWidget);
  });

  testWidgets('settings opens from the Men tab', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text(S.tabMe));
    await settle(tester);
    await tester.tap(find.byTooltip(S.settingsTitle));
    await settle(tester);
    expect(find.text(S.settingsTitle), findsWidgets);
  });

  testWidgets('dark theme renders without errors', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);
    expect(find.text(S.modeTitle), findsOneWidget);
  });
}
