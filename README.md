# Killer Sudoku

Oflayn Android Killer Sudoku ilovasi (Flutter). Reklama, internet va hisob qaydnomasi yo'q.

- Texnik topshiriq: [`Sudoku ilovasi TZ.md`](Sudoku%20ilovasi%20TZ.md)
- Ishlab chiquvchi uchun qisqacha: [`CLAUDE.md`](CLAUDE.md)

## APK yuklab olish

Har bir `v*` tegi uchun GitHub Actions APK yig'ib, **Releases** bo'limiga qo'yadi. `main` ga har bir push'dan keyin APK **Actions → Build APK → Artifacts** ichida ham bo'ladi.

## Imzo kaliti (bir marta sozlanadi)

Yangi versiya eskisining ustiga (ma'lumotlar o'chmasdan) o'rnatilishi uchun har bir APK bir xil kalit bilan imzolanishi kerak. Repozitoriyning **Settings → Secrets and variables → Actions** bo'limiga ikkita secret qo'shing:

| Secret | Qiymati |
| --- | --- |
| `KEYSTORE_BASE64` | `release.p12.base64.txt` faylining butun matni |
| `KEYSTORE_PASSWORD` | `key.properties` dagi `storePassword` qiymati |

Kalit fayllari repozitoriyda yo'q (maxfiy). Ularni yo'qotmang: kalitsiz keyingi versiyalarni eski ilova ustiga o'rnatib bo'lmaydi. Secret'lar bo'lmasa, APK vaqtinchalik debug kalit bilan imzolanadi.

Lokal release yig'ish uchun `android/key.properties` (git'ga kirmaydi) shu kalitga ishora qiladi.

## Ishlab chiqish

```
flutter pub get
flutter analyze
flutter test test
flutter run
```

- JS namunasidan test fikstura: `node tool/gen_golden.js > test/engine/fixtures/js_golden.json`
- Tovushlar: `node tool/gen_sounds.js`
- Ilova belgisi: `flutter test tool/render_icon_test.dart`, keyin `dart run flutter_launcher_icons`
