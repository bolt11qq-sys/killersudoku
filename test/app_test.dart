import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:killer_sudoku/l10n/strings.dart';
import 'package:killer_sudoku/main.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: KillerSudokuApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home shows mode title, new game button and two tabs',
      (tester) async {
    await _pumpApp(tester);

    expect(find.text(S.modeTitle), findsOneWidget);
    expect(find.text(S.newGame), findsOneWidget);
    expect(find.text(S.tabHome), findsOneWidget);
    expect(find.text(S.tabMe), findsOneWidget);
    // TZ §1: no Battle / Explore tabs.
    expect(find.text('Battle'), findsNothing);
    expect(find.text('Explore'), findsNothing);
  });

  testWidgets('bottom navigation switches to Men and back', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text(S.tabMe));
    await tester.pumpAndSettle();
    expect(find.text(S.statsTitle), findsOneWidget);

    await tester.tap(find.text(S.tabHome));
    await tester.pumpAndSettle();
    expect(find.text(S.modeTitle), findsOneWidget);
  });

  testWidgets('new game opens the game screen and back returns home',
      (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text(S.newGame));
    await tester.pumpAndSettle();
    expect(find.text(S.gameTitle), findsOneWidget);
    expect(find.text(S.tabHome), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(S.modeTitle), findsOneWidget);
  });

  testWidgets('settings opens from the Men tab', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text(S.tabMe));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(S.settingsTitle));
    await tester.pumpAndSettle();
    expect(find.text(S.settingsTitle), findsWidgets);
  });

  testWidgets('dark theme renders without errors', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpApp(tester);
    expect(find.text(S.modeTitle), findsOneWidget);
  });
}
