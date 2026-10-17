# Killer Sudoku

Oflayn Android Killer Sudoku ilovasi (Flutter). Reklama, internet va hisob qaydnomasi yo'q.

- Texnik topshiriq: [`Sudoku ilovasi TZ.md`](Sudoku%20ilovasi%20TZ.md)
- Ishlab chiquvchi uchun qisqacha: [`CLAUDE.md`](CLAUDE.md)

## APK yuklab olish

Har bir `v*` tegi uchun GitHub Actions APK yig'ib, **Releases** bo'limiga qo'yadi. `main` ga har bir push'dan keyin APK **Actions → Build APK → Artifacts** ichida ham bo'ladi.

## Ishlab chiqish

```
flutter pub get
flutter analyze
flutter test
flutter run
```

JS namunasidan test fikstura yaratish: `node tool/gen_golden.js > test/engine/fixtures/js_golden.json`
