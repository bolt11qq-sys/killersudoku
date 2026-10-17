# Killer Sudoku (Flutter, Android)

Offline personal Killer Sudoku app. The full spec is `Sudoku ilovasi TZ.md` (Uzbek) — read it before any work; it is the source of truth. Sample UI screenshots: `photo_*.jpg`. Reference web implementation to port: `reference/killer_engine.js` (engine) and `reference/killer-sudoku.html` (game UI, hints, cage panel).

## Commands

```
flutter pub get
flutter analyze          # must be warning-free
flutter test             # must fully pass
flutter run              # needs an Android device/emulator + Android SDK
node -e "const E=require('./reference/killer_engine.js')(); console.log(E.generate('expert', 1))"   # JS reference output
```

## Architecture

- `lib/engine/` — pure Dart, **never imports Flutter**. `killer/` (generator, solver, candidates, combos, hints), `common/` (bitmask, seeded RNG). Fully unit-tested; generator output must match the JS reference bit-for-bit for the same seed (32-bit `imul`/`>>>` emulation; JS's lossy `s*1103515245+12345` reseed must be reproduced via `double`).
- `lib/data/` — Hive boxes (`current_game`, `history`, `progress`, `puzzle_cache`, `saved`) and repositories; settings in `shared_preferences`.
- `lib/features/` — screens: `home`, `new_game` (bottom sheet), `game`, `daily`, `me`.
- `lib/app/` — `theme.dart` (design tokens), `router.dart` (go_router; two-tab `StatefulShellRoute` + full-screen routes), `shell.dart` (bottom nav).
- `lib/l10n/strings.dart` — every user-visible string (class `S`).
- State: `flutter_riverpod`. Generation runs in `Isolate.run`.

## Rules

- Colors only via `context.colors` (`AppColors` tokens), sizes via `AppDims`; no raw `Color(...)` outside `theme.dart`.
- User-visible text: Uzbek (Latin), only in `strings.dart`. Code comments: English.
- No `INTERNET` permission in the release manifest; no network code at all.
- Levels: Oson, O'rta, Qiyin, Ekspert, Iblis (Killer only — Classic was dropped).
- Work one TZ stage (§7.2) at a time; finish each with a short report: what was done, how to test, open issues.
- Ask instead of guessing when the TZ is unclear; small design decisions are fine but list them in the stage report.

## Stage status

- [x] 1. Asos
- [x] 2. Killer dvigateli
- [ ] 3. O'yin ekrani
- [ ] 4. Bosh sahifa va Yangi o'yin oynasi
- [ ] 5. Aqlli maslahat va Tez qoralama
- [ ] 6. Progress
- [ ] 7. Men ekrani
- [ ] 8. Sayqal
