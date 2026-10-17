# Sudoku ilovasi TZ

Oct 17, 2026 · @Azizbek

## 1. Loyiha haqida

Shaxsiy foydalanish uchun Android **Killer Sudoku** ilovasi. Interfeys namunadagi ilovaga o'xshaydi, lekin to'liq oflayn ishlaydi, reklama, internet va hisob qaydnomasi yo'q. Asosiy qurilma: Xiaomi 12T. Ilova Google Play'ga chiqarilmaydi.

**Ilovada bitta o'yin rejimi bor: Killer Sudoku.** Asosan boshlang'ich raqamlar yo'q, faqat kafes yig'indilari beriladi (faqat Oson darajasida 6 ta raqam beriladi). Beshta qiyinlik darajasi: Oson, O'rta, Qiyin, Ekspert, Iblis. Mantiq allaqachon veb-versiyada ishlab chiqilgan va Dart'ga ko'chiriladi (4-bo'lim). Classic Sudoku, Tezkor va 16×16 rejimlari ilovada **yo'q**.

**Namunadan olib tashlanadigan qismlar:**

| Element | Qaror |
| --- | --- |
| Battle va Explore tablari | Olib tashlanadi. Pastki menyuda faqat **Bosh sahifa** va **Men** qoladi |
| Reklama banneri (o'yin ekrani pastida) | Olib tashlanadi, o'rni bo'sh qoladi |
| Tangalar (142) va ularga bog'liq hamma narsa | Olib tashlanadi |
| Events kartasi (Arrows GO!) | Olib tashlanadi |
| Hide & Seek nishoni | Olib tashlanadi |
| Classic darajalari, Fast va 16×16 | Olib tashlanadi |
| Ulashish tugmasi va mavzu (palitra) tugmasi | Olib tashlanadi, mavzu sozlamalarga o'tadi |
| Weekly Win Rate, darajalardagi Lv belgilari, yulduz progressi | **Qoladi**, faqat mahalliy statistikadan hisoblanadi |
| Miya reytingi (87) va seriya (17) | **Qoladi** (5-bo'limda qanday hisoblanishi yozilgan) |
| Maslahat va Fast Pencil hisoblagichlari | Cheksiz bo'ladi. Hisoblagich faqat shu o'yinda nechta ishlatilganini ko'rsatadi |

**Til:** interfeys matnlari o'zbekcha (lotin). Barcha matnlar bitta faylda (`lib/l10n/strings.dart`) saqlanadi, keyinchalik inglizchani qo'shish oson bo'lsin.

## 2. Texnologiyalar va loyiha tuzilishi

Flutter (oxirgi stable versiya), faqat Android. Internetga ruxsat (`INTERNET` permission) so'ralmaydi.

| Vazifa | Paket yoki usul |
| --- | --- |
| Holatni boshqarish | `flutter_riverpod` |
| Ma'lumotlarni saqlash | `hive` + `hive_flutter` (o'yinlar, statistika); `shared_preferences` (sozlamalar) |
| Navigatsiya | `go_router` |
| Jumboq generatsiyasi | `Isolate.run` — UI qotmasligi uchun alohida oqimda |
| Shriftlar | `assets/fonts` ichiga qo'shiladi, internetdan yuklanmaydi |
| Tebranish | `HapticFeedback` (Flutter'ning o'zida bor) |
| Testlar | `flutter_test`; dvigatel uchun sof Dart unit testlar |

**Papkalar tuzilishi:**

```
lib/
  main.dart
  app/            router.dart, theme.dart (dizayn tokenlari)
  l10n/           strings.dart (barcha matnlar)
  engine/         UI'dan mustaqil, sof Dart
    killer/       generator.dart, solver.dart, candidates.dart, combos.dart, hints.dart
    common/       bitmask.dart, rng.dart (seed bilan, JS bilan bir xil natija)
  data/           hive modellari, repository'lar, puzzle_cache.dart
  features/
    home/         home_screen.dart, daily_card.dart
    new_game/     new_game_sheet.dart
    game/         game_screen.dart, board/ (board_painter.dart, cage_painter.dart), number_pad.dart, toolbar.dart, cage_panel.dart, hint_panel.dart, win_dialog.dart
    daily/        daily_calendar_screen.dart
    me/           stats_screen.dart, settings_screen.dart
reference/        killer_engine.js, killer-sudoku.html (veb-versiya, port manbasi)
test/
  engine/         generator, solver, candidates, hints testlari va JS bilan solishtirish
```

**Asosiy qoida:** `engine/` papkasi Flutter'ni import qilmaydi. U to'liq unit testlar bilan qoplanadi, shunda o'yin mantiqini interfeysdan alohida tekshirish mumkin bo'ladi.

## 3. Ekranlar

Ilova beshta ekrandan iborat. Pastki menyuda ikki tab bor: **Bosh sahifa** va **Men**. Qolgan ekranlar shu ikkisidan ochiladi.

### 3.1 Bosh sahifa

Namunadagi birinchi skrinshot joylashuvi, yuqoridan pastga:

1. **Yuqori qator.** Chapda miya belgisi va reyting (chip, och ko'k fon). O'ngda olov belgisi va seriya kunlari, oq chip. Tanga chipi yo'q. Seriya chipini bossangiz, Kundalik tanlov kalendari ochiladi.
2. **Kundalik tanlov kartasi** — sana (masalan, "17-okt"), kubok rasmi, oq "O'ynash" tugmasi. Bugungi tanlov yechilgan bo'lsa, tugma o'rnida "Bajarildi ✓" chiqadi. Karusel yo'q, karta yolg'iz turadi.
3. **Markaz.** "Killer Sudoku" yozuvi katta kulrang harflar bilan, tagida "Qanday o'ynaladi" chipi.
4. **Asosiy tugma.** Tugallanmagan o'yin bo'lsa, ikki tugma chiqadi: yuqorida ko'k "Davom etish" (daraja va vaqt bilan), pastda oq "Yangi o'yin". Bo'lmasa, faqat ko'k "Yangi o'yin".
5. **Pastki menyu.** Bosh sahifa va Men.

### 3.2 Yangi o'yin oynasi (bottom sheet)

Ikkinchi skrinshotdagi kabi: orqa fon xiralashadi, pastdan oq oyna chiqadi, tepasida ushlagich chizig'i bor.

- Sarlavha "Yangi o'yin", tagida "Haftalik g'alaba: 31%" (foiz ko'k rangda).
- Har bir daraja oq kartada: emoji, nomi, kulrang `Lv1` belgisi. Belgi to'q fonda bo'lsa, shu darajada yangi bosqich ochilgan.
- Faol darajada o'ng tomonda yulduz progressi turadi (masalan, ⭐ 39/100 va chiziqli progress). Har bir yechilgan o'yin yulduz beradi (5-bo'lim).
- Darajalar: **Oson, O'rta, Qiyin, Ekspert, Iblis**.

### 3.3 O'yin ekrani

Uchinchi va to'rtinchi skrinshotdagi kabi, yuqoridan pastga:

1. **Yuqori panel.** Chapda orqaga strelka. O'ngda ikki belgi: yulduz (jumboqni saqlanganlarga qo'shish) va sozlamalar (shesterna).
2. **Holat qatori.** Chapda yashil belgi bilan to'ldirilgan kataklar (`0/81`), tagida `Xatolar: 0/3`. Markazda ko'k "Ball: 0", tagida daraja nomi. O'ngda taymer `00:00` va pauza tugmasi.
3. **Taxta.** Ekran kengligida, kvadrat. Bloklar orasida qalin chiziq, kataklar orasida ingichka chiziq. Punktir kafes chiziqlari va har kafesning chap yuqori burchagida yig'indi. Tanlangan katakning qatori, ustuni va bloki och ko'k bilan, kafesi esa alohida och fon bilan ajratiladi.
4. **Tez-qoralama almashtirgichi.** Taxtaning o'ng pastida kichik chaqmoqli switch.
5. **Kafes paneli.** Taxta bilan asboblar orasida: tanlangan kafes uchun yig'indi, kataklar soni va raqam to'plamlari. To'plamni bosib chizib qo'yish mumkin, kiritilgan raqamlarga zid to'plamlar o'zi o'chadi, bitta to'plam qolsa u ajratiladi (veb-versiyadagi kabi).
6. **Asboblar qatori.** Beshta belgi va ularning tagida yozuv: Orqaga, O'chirish, Tez qoralama (ko'k raqamli nishon), Qoralama (`O'CH`/`YON` nishoni), Aqlli maslahat (ko'k raqamli nishon).
7. **Raqamlar paneli.** 9 ta oq tugma, katta ko'k raqam, tagida qolgan soni. Raqam to'liq qo'yilgach, tugma yashiriladi va joyi bo'sh qoladi.
8. Reklama banneri yo'q.

**Pauza oynasi:** taxta yashiriladi, markazda vaqt va daraja, "Davom etish" tugmasi.

**G'alaba oynasi:** konfetti animatsiyasi; 3 ta yulduz o'rni, olingan yulduzlar ketma-ket yonadi (har birining tagida sababi: "Yutdingiz", "Toza o'yin", "Tezkor"); daraja progressi chizig'i (masalan, "Ekspert Lv2 · 39 → 42/100") to'lib boradi, yangi bosqich ochilsa "Ekspert Lv3 ochildi!" belgisi chiqadi; vaqt, ball, xatolar, ishlatilgan maslahatlar, "Yangi rekord" belgisi (agar bo'lsa), "Keyingi o'yin" va "Bosh sahifa" tugmalari.

**Mag'lubiyat oynasi** (3 ta xatoda, agar xato cheklovi yoqilgan bo'lsa): "Davom etish" (xatolar soni 0 ga tushadi va o'yin "cheklovsiz" deb belgilanadi) yoki "Yangi o'yin".

### 3.4 Kundalik tanlov kalendari

Oy kalendari. Har kun uchun bitta jumboq, u sanadan olingan seed bilan yaratiladi. Yechilgan kunlarda oltin kubok belgisi turadi. Oyning hamma kunlarini yechsangiz, oy kubogi beriladi. O'tgan kunlarni ham o'ynash mumkin.

### 3.5 Men (statistika va sozlamalar)

- **Statistika:** daraja bo'yicha tablar (Oson, O'rta, Qiyin, Ekspert, Iblis). Har birida: o'ynalgan, yutilgan, g'alaba foizi, eng yaxshi vaqt, o'rtacha vaqt, xatosiz g'alabalar, joriy va eng uzun seriya. Oxirgi 30 kunlik vaqtlar grafigi.
- **Saqlangan jumboqlar:** yulduzcha bilan belgilanganlar ro'yxati, qayta o'ynash mumkin.
- **Sozlamalar:** xato cheklovi (3 ta / o'chiq), xatolarni darhol ko'rsatish, qoralamalarni avto-tozalash, bir xil raqamlarni ajratish, ishlatilgan raqamlarni yashirish, taymerni ko'rsatish, tovush, tebranish, mavzu (yorug' / tungi / tizim).
- **Ma'lumotlar:** statistikani nolga tushirish (tasdiqlash oynasi bilan), barcha ma'lumotlarni JSON faylga eksport qilish va qayta import qilish.

### 3.6 Ekranlar orasidagi o'tishlar

| Qayerdan | Nima bosiladi | Qayerga |
| --- | --- | --- |
| Bosh sahifa | Yangi o'yin | Yangi o'yin oynasi |
| Bosh sahifa | Davom etish | O'yin ekrani (tugallanmagan o'yin) |
| Bosh sahifa | Kundalik tanlov "O'ynash" | O'yin ekrani (bugungi jumboq) |
| Bosh sahifa | Seriya chipi | Kundalik tanlov kalendari |
| Bosh sahifa | Pastki menyu "Men" | Men ekrani |
| Yangi o'yin oynasi | Daraja kartasi | O'yin ekrani |
| Kundalik tanlov kalendari | Kun | O'yin ekrani (shu kunning jumboqi) |
| Men ekrani | Saqlangan jumboq | O'yin ekrani |
| O'yin ekrani | Shesterna | Sozlamalar (Men ekranidagi bo'lim) |
| O'yin ekrani | G'alaba yoki 3-xato | G'alaba / Mag'lubiyat oynasi (ekran emas, dialog) |
| G'alaba oynasi | Keyingi o'yin | O'yin ekrani (shu daraja) |
| G'alaba oynasi | Bosh sahifa | Bosh sahifa |

G'alaba oynasidagi "Bosh sahifa" tugmasi va o'yin ekranidagi orqaga strelka Bosh sahifaga qaytaradi. Tugallanmagan o'yin saqlanib qoladi.

## 4. O'yin mantiqi

Har bir jumboqning **faqat bitta yechimi** bo'lishi shart va bu jumboq ko'rsatilishidan oldin tekshiriladi.

### 4.1 Killer Sudoku generatori

Veb-versiyadagi ishlab chiqilgan mantiq Dart'ga ko'chiriladi. Manba: `reference/killer_engine.js` (dvigatel: generator, yechuvchi, nomzodlar) va `reference/killer-sudoku.html` (to'liq veb-o'yin, maslahatlar va Kafes paneli). Dvigatel Node'da ishlaydi (`require('./killer_engine.js')()`), shuning uchun Dart port natijalarini u bilan solishtirish mumkin.

1. **To'liq yechim.** Bo'sh taxta tasodifiy tartibda backtracking bilan to'ldiriladi. Seed'li RNG ishlatiladi, shunda bir xil seed doim bir xil jumboq beradi (Kundalik tanlov uchun kerak).
2. **Kafeslar.** Tasodifiy katakdan boshlab kafes qo'shni kataklar bilan o'stiriladi. Kafes ichida raqam takrorlanmaydi. O'lchamlar: Oson 2–3, O'rta 2–3, Qiyin 2–4, Ekspert 2–5, Iblis 2–6. 1 katakli kafeslar qo'shni kafesga qo'shib yuboriladi (Oson, O'rta va Qiyin darajalarida bittasi qolishi mumkin).
   - **Oson** darajasida yagona yechim topilgach, yechimdan 6 ta tasodifiy katak (seed bilan) berilgan raqam sifatida ochiladi; har blokda ko'pi bilan bittadan. Berilgan raqamlar qora rangda, o'zgartirib bo'lmaydi. Boshqa darajalarda berilgan raqam yo'q.
3. **Yechuvchi** bitmask'lar bilan ishlaydi (har katakka 9 bitli nomzodlar maskasi), MRV evristikasidan foydalanadi va quyidagi mantiq bilan nomzodlarni qisqartiradi:
   - har bir kafes uchun yig'indiga mos raqam to'plamlari (oldindan hisoblangan jadval: o'lcham × yig'indi → to'plamlar);
   - to'plam raqamlarini kafes kataklariga taqsimlash mumkinmi, shuni tekshirish (har katak o'z nomzodlaridan olsin);
   - **45 qoidasi**: har bir qator, ustun va blokdagi "ichki" kataklar qo'shimcha virtual kafes sifatida qo'shiladi;
   - yashirin va ochiq yolg'izlar.
4. **Yagonalikni tekshirish va tuzatish.** Ikkita yechim topilsa, ular farq qiladigan katakning kafesi va bitta qo'shni kafes buziladi va qaytadan o'stiriladi. Qidiruv tugunlari chegarasi: 700. Chegaradan oshsa, tasodifiy hudud qayta o'stiriladi. `generate()` natija bermasa, yangi seed bilan 6 martagacha qayta uriniladi.
5. **JS bilan moslik.** RNG va seed hisoblash JS'dagi bilan bit darajasida bir xil bo'ladi (32 bitli `imul` va `>>>`), shunda bir xil seed ikkala versiyada bir xil jumboq beradi.

### 4.2 Ishlash tezligi va oldindan tayyorlash

- Generatsiya doim `Isolate.run` ichida bajariladi.
- Har bir daraja uchun **2 tadan tayyor jumboq** Hive'da saqlanadi (`puzzle_cache`). Biri ishlatilgach, orqa fonda yangisi tayyorlanadi. Natijada Yangi o'yin tugmasi doim darhol ishlaydi.
- Maqsadli vaqt (Xiaomi 12T'da): Killer Iblis < 15 s.
- Kundalik tanlov: seed = `YYYYMMDD` sonidan olinadi, daraja hafta kuniga qarab almashadi: Du O'rta, Se O'rta, Ch Qiyin, Pa Qiyin, Ju Ekspert, Sh Ekspert, Ya Iblis.
- Oson va O'rta generatsiyasi kompyuterda < 0.5 s, Iblis eng sekin holatda ~14 s (kompyuterda); shuning uchun Iblis uchun kesh ilova birinchi ochilishidayoq to'ldirila boshlaydi.

### 4.3 Testlar (majburiy)

- Har bir daraja uchun 50 ta seed: yechim yagona, kafes ichida takror yo'q, 1 katakli kafes yo'q (Ekspert va Iblis).
- JS bilan solishtirish: kamida 20 ta seed uchun `reference/killer_engine.js` natijasi (yechim, kafeslar) namuna fayl sifatida saqlanadi va Dart natijasi u bilan aynan mos kelishi tekshiriladi.
- Har bir maslahat turi uchun kamida bitta qo'lda yozilgan test taxtasi.

## 5. Funksiyalar

### 5.1 Raqam kiritish

- Katakni bosib, keyin raqamni bosish. Sozlamalarda teskari tartib ham bor: avval raqam tanlanadi, keyin kataklar bosiladi.
- Berilgan raqamlar (faqat Oson) qora, siz qo'ygan raqamlar ko'k rangda.
- Bir xil raqamlar butun taxtada ajratib ko'rsatiladi.
- Xato raqam (xatolarni darhol ko'rsatish yoqilgan bo'lsa) qizil bo'ladi, xatolar soni oshadi va telefon qisqa tebranadi.
- Qator, ustun, blok yoki kafes to'lganda qisqa yorug'lik to'lqini animatsiyasi o'tadi.

### 5.2 Qoralama va Tez qoralama

- **Qoralama** yoqilganda raqamlar katakka kichik qilib, 3×3 tartibda yoziladi.
- **Tez qoralama** bitta bosishda barcha bo'sh kataklarga hozirgi mumkin bo'lgan nomzodlarni to'ldiradi. Qator, ustun, blok va kafes yig'indisi hisobga olinadi.
- Raqam qo'yilganda shu raqam qator, ustun, blok va kafes qoralamalaridan avtomatik o'chiriladi.
- Qoralama ichidagi raqamni uzoq bossangiz, shu nomzod bor barcha kataklar ajratib ko'rsatiladi.

### 5.3 Aqlli maslahat

Maslahat javobni darhol bermaydi. Har bosishda bitta bosqich ochiladi:

1. **Qayerga qarash kerak.** Taxtaning tegishli qismi ajratiladi va usul nomi chiqadi (masalan, "45 qoidasi: 3-blok").
2. **Nega.** Usul ishlatgan kataklar va nomzodlar rangda ko'rsatiladi, ostida 1–2 jumlalik izoh.
3. **Natija.** "Qo'llash" tugmasi: raqamni qo'yadi yoki nomzodlarni o'chiradi.

Maslahat taxta ustida emas, raqamlar paneli o'rnida chiqadigan panelda ko'rsatiladi. Agar taxtada xato raqam bo'lsa, birinchi maslahat shu haqda aytadi. Maslahatlar veb-versiyadagi tartibda: 45 qoidasi (ichki, tashqi, 2–3 qatorli), yagona variant, yashirin yolg'iz, ikki katak yig'indisi, oxirida eng kam variantli katak.

### 5.4 Xatolar va ball

- **Xato cheklovi** sozlamalarda: 3 ta yoki o'chiq. O'chiq bo'lsa, holat qatorida faqat xatolar soni ko'rinadi.
- **Ball** har bir to'g'ri raqam uchun beriladi: `asosiy ball × daraja koeffitsienti × tezlik bonusi`. Asosiy ball 10. Koeffitsient: Oson 2, O'rta 3, Qiyin 4, Ekspert 5.5, Iblis 7. Oxirgi to'g'ri raqamdan beri 10 soniyadan kam o'tgan bo'lsa ×1.5.
- Qator, ustun, blok yoki kafes to'lsa: +50 × koeffitsient. Xato: −20, lekin ball 0 dan pastga tushmaydi. Maslahat "Qo'llash" bilan qo'yilgan raqam ball bermaydi.

### 5.5 Progress, reyting va seriya

- **Yulduzlar va darajadagi bosqich (`Lv`).** Har bir daraja (Oson … Iblis) o'z bosqichi va yulduz hisobiga ega, masalan "Ekspert Lv2 ⭐ 39/100". Qaysi darajada yutsangiz, yulduz shu darajaga qo'shiladi.
  - Har bir yutilgan o'yin **1 dan 3 tagacha** yulduz beradi:
    - ⭐ yutdingiz (har doim);
    - ⭐ toza o'yin: 0 ta xato (mag'lubiyatdan keyin "Davom etish" ishlatilmagan) **va** Aqlli maslahat bir marta ham ochilmagan;
    - ⭐ tezkor: vaqt shu darajadagi oxirgi 20 ta g'alaba vaqtining medianasidan kam. Shu darajada 5 tadan kam g'alaba bo'lsa, me'yoriy vaqt bilan solishtiriladi: Oson 8 daq, O'rta 12 daq, Qiyin 18 daq, Ekspert 25 daq, Iblis 35 daq.
  - Yutqazilgan yoki tashlab ketilgan o'yin yulduz bermaydi, yulduzlar hech qachon kamaymaydi.
  - Bosqich Lv1 dan boshlanadi. Hisob 100 ga yetsa, bosqich bittaga oshadi va hisob 0 dan davom etadi (ortib qolgani o'tkaziladi: 99 + 3 → keyingi Lv, 2/100). Bosqichning yuqori chegarasi yo'q.
  - Bosqich faqat nishon, o'yinni o'zgartirmaydi.
  - **Yangi o'yin oynasida** har bir daraja kartasida `Lv` nishoni turadi; oxirgi o'ynalgan daraja kartasida o'ng tomonda ⭐ hisob va progress chizig'i chiqadi (namunadagi kabi). Yangi bosqich ochilgan, lekin hali o'ynalmagan darajaning nishoni to'q fonda bo'ladi.
  - Kundalik tanlov ham shu kunning darajasiga yulduz beradi.
- **Haftalik g'alaba foizi:** oxirgi 7 kunda boshlangan o'yinlardan nechtasi yutilgani.
- **Miya reytingi** (0–100): oxirgi 20 ta g'alabaga qarab hisoblanadi. Har g'alabaning bahosi daraja og'irligi, shu daraja uchun o'rtacha vaqtga nisbatan tezlik va xatosizlikdan iborat. Yutqazilgan yoki tashlab ketilgan o'yin reytingni biroz tushiradi.
- **Seriya:** ketma-ket nechta kunda kamida bitta o'yin yechilgani. Bugun hali yechilmagan bo'lsa, olov belgisi yonida qizil nuqta chiqadi.

### 5.6 Boshqa

- Orqaga qaytish cheksiz (o'yin ichida).
- O'yin har bir harakatdan keyin avtomatik saqlanadi. Ilova yopilsa yoki fonda qolsa, taymer to'xtaydi.
- Ilova fonga o'tganda avtomatik pauza.
- Saqlangan jumboqlar (yulduzcha bilan belgilanganlar) Men ekranida ro'yxat bo'lib turadi va ularni qayta o'ynash mumkin.

## 6. Dizayn tizimi

Ranglar va o'lchamlar namunadagi skrinshotlardan olingan (taxminiy). Hammasi `app/theme.dart` faylidagi tokenlar orqali ishlatiladi. Vidjet ichida to'g'ridan-to'g'ri rang kodi yozilmaydi.

### 6.1 Ranglar

| Token | Yorug' mavzu | Tungi mavzu | Qayerda |
| --- | --- | --- | --- |
| `bg` | #F4F6FB | #11141B | Ekran foni |
| `surface` | #FFFFFF | #1B202A | Kartalar, tugmalar, bottom sheet |
| `primary` | #1E5BDB | #6F98FF | Asosiy tugma, siz qo'ygan raqamlar, Ball, faol tab |
| `textPrimary` | #1C2230 | #E6EAF2 | Sarlavhalar, berilgan raqamlar |
| `textSecondary` | #8A93A6 | #8A93A6 | Yozuvlar, "Killer Sudoku" yozuvi, qolgan raqamlar soni |
| `gridThin` | #D5DAE3 | #2C3340 | Kataklar orasidagi chiziq |
| `gridThick` | #6B7385 | #8A93A6 | Bloklar va taxta chegarasi |
| `highlight` | #DCE5F6 | #22304A | Tanlangan qator, ustun, blok |
| `selected` | #BFD0F2 | #2F4670 | Tanlangan katak |
| `sameNumber` | #C9D7F3 | #2A3D60 | Bir xil raqamli kataklar |
| `error` | #D0343A (namunada #E5484D; tanlangan katakda o'qilishi uchun to'qlashtirildi) | #FF6B6B | Xato raqam, xatolar soni |
| `success` | #3DBE6B | #4CD483 | To'ldirilgan kataklar belgisi |
| `badge` | #1E5BDB | #6F98FF | Maslahat va Tez qoralama nishonlari |
| `streak` | #F05A3C | #FF7A5C | Seriya olovi va qizil nuqta |
| `cage` | #4A5568 | #A0AEC0 | Kafes punktir chizig'i va yig'indi |
| `cageFill` | #EAF0FB | #1F2838 | Tanlangan kafes foni |

### 6.2 Shriftlar

- Asosiy matn: **Nunito Sans** (400, 600, 700). Yumaloq va tiniq, namunaga yaqin.
- Raqamlar (taxta va panel): **Nunito Sans 600**, `tabularFigures` bilan.
- "Killer Sudoku" yozuvi: 40 sp, 800, `textSecondary` rangida.
- Taxta raqami: katak balandligining 60%. Qoralama raqami: 22%. Kafes yig'indisi: 20%, 700.

### 6.3 O'lchamlar

| Element | Qiymat |
| --- | --- |
| Ekran chetidan ichki masofa | 16 dp |
| Kartalar radiusi | 20 dp, juda yengil soya |
| Chiplar (reyting, seriya) | balandligi 44 dp, to'liq yumaloq |
| Asosiy tugma | balandligi 64 dp, radius 16, matn 22 sp 700 |
| Bottom sheet daraja kartasi | balandligi 64 dp, radius 16, oralig'i 10 dp |
| Taxta chiziqlari | ingichka 1 dp, qalin 2 dp, tashqi 2.5 dp; kafes punktiri 1.2 dp, katak chetidan 9% ichkarida |
| Raqam tugmasi | kengligi (ekran − 32 − 8×5) / 9, balandligi kenglik × 1.5, radius 12 |
| Asbob belgilari | 28 dp, ostidagi yozuv 13 sp |
| Pastki menyu | balandligi 72 dp, belgi 28 dp |

### 6.4 Harakatlar

- Katak tanlash: ajratish 120 ms ichida.
- Bottom sheet: pastdan 250 ms, orqa fon 40% qoraytiriladi.
- To'lgan qator, ustun, blok yoki kafes: 400 ms yorug'lik to'lqini.
- G'alaba: konfetti 1.5 s.
- Tizimda "animatsiyani kamaytirish" yoqilgan bo'lsa, faqat rang o'zgarishi qoladi.

## 7. Saqlash, ishlab chiqish rejasi va qabul mezonlari

### 7.1 Ma'lumotlar modeli (Hive)

| Box | Nima saqlanadi |
| --- | --- |
| `current_game` | Tugallanmagan o'yin: daraja, seed, kafeslar, yechim, qiymatlar, qoralamalar, chizilgan to'plamlar, orqaga qaytish tarixi, vaqt, xatolar, ball, maslahatlar soni |
| `history` | Har bir tugagan o'yin: sana, daraja, natija (g'alaba / mag'lubiyat / tashlab ketilgan), vaqt, xatolar, maslahatlar, ball |
| `progress` | Har daraja uchun bosqich (`Lv`), joriy yulduz hisobi (0–99) va jami yulduzlar, oxirgi o'ynalgan daraja, reyting, seriya, kundalik tanlov natijalari |
| `puzzle_cache` | Oldindan tayyorlangan jumboqlar (har daraja uchun 2 tadan) |
| `saved` | Yulduzcha bilan saqlangan jumboqlar |

Statistika `history` dan hisoblanadi, alohida saqlanmaydi. Eksport — barcha box'lar bitta JSON faylda.

### 7.2 Bosqichlar

Har bir bosqich ishlaydigan ilova bilan tugaydi. Keyingisiga faqat oldingi bosqich qabul qilingandan keyin o'tiladi.

1. **Asos.** Flutter loyihasi, papkalar, mavzu tokenlari, shriftlar, go\_router, ikki tabli pastki menyu, bo'sh ekranlar.
2. **Killer dvigateli.** `reference/killer_engine.js` ning Dart porti: RNG, generator, yechuvchi, nomzodlar, to'plamlar jadvali, testlar (4.3) va JS bilan solishtirish. Bu bosqichda interfeys yo'q, faqat `flutter test`.
3. **O'yin ekrani.** Taxta va kafeslar (`CustomPainter`), Kafes paneli, raqamlar paneli, asboblar, qoralama, orqaga, xatolar, ball, taymer, pauza, g'alaba va mag'lubiyat oynalari, avtomatik saqlash.
4. **Bosh sahifa va Yangi o'yin oynasi.** Kundalik karta, Davom etish, bottom sheet, jumboqlarni oldindan tayyorlash.
5. **Aqlli maslahat va Tez qoralama.**
6. **Progress.** Yulduzlar, bosqichlar, reyting, seriya, haftalik foiz, Kundalik tanlov va kalendar.
7. **Men ekrani.** Statistika, grafik, saqlanganlar, sozlamalar, eksport va import, tungi mavzu.
8. **Sayqal.** Animatsiyalar, tebranish, tovushlar, ilova belgisi, release APK.

### 7.3 Qabul mezonlari

- [ ] Ilova internetsiz to'liq ishlaydi, `INTERNET` ruxsati yo'q.
- [ ] Battle, Explore, tangalar, reklama, Events va Classic rejimlari yo'q.
- [ ] Bosh sahifa, Yangi o'yin oynasi va O'yin ekrani namunadagi skrinshotlarga joylashuv va ranglar bo'yicha mos keladi.
- [ ] Har bir jumboqning yagona yechimi bor (testlar o'tadi).
- [ ] Dart generatori bir xil seed uchun JS versiyasi bilan bir xil jumboq beradi.
- [ ] Yangi o'yin tugmasi tayyor jumboq bilan 300 ms ichida o'yin ekranini ochadi.
- [ ] Ilova o'ldirilib, qayta ochilganda o'yin aynan shu joyidan davom etadi.
- [ ] Aqlli maslahat javobni birinchi bosishda bermaydi; har bir maslahat turi uchun izoh bor.
- [ ] Har bir g'alaba o'sha darajaga 1–3 yulduz qo'shadi, 100 yulduzda `Lv` oshadi (unit testlar bilan tasdiqlangan).
- [ ] Tungi mavzuda barcha matn o'qiladi.
- [ ] Xiaomi 12T'da taxta bilan ishlash 60 fps'da silliq.
- [ ] `flutter analyze` ogohlantirishsiz, `flutter test` to'liq o'tadi.

### 7.4 Claude Code uchun ish tartibi

- Ishni boshlashdan oldin bu TZ'ni to'liq o'qing va loyiha ildizida `CLAUDE.md` faylini yarating: qisqacha arxitektura, buyruqlar (`flutter run`, `flutter test`), kod qoidalari.
- Bir vaqtda bitta bosqich ustida ishlang. Bosqich oxirida nima qilinganini, qanday sinash kerakligini va qolgan muammolarni qisqa yozing.
- TZ'da noaniq joy chiqsa, taxmin qilmasdan so'rang. Kichik dizayn qarorlarini o'zingiz qabul qiling va bosqich hisobotida yozib qo'ying.
- Dvigatel kodiga izohlarni inglizcha, foydalanuvchiga ko'rinadigan matnlarni o'zbekcha yozing.
