import '../engine/common/bitmask.dart';
import '../engine/killer/hints.dart';
import '../engine/killer/level.dart';

/// All user-visible text (TZ §1). Uzbek, Latin script. Keep every string
/// here so an English translation can be added later in one place.
abstract final class S {
  static const appTitle = 'Killer Sudoku';

  // Bottom navigation
  static const tabHome = 'Bosh sahifa';
  static const tabMe = 'Men';

  // Home
  static const modeTitle = 'Killer Sudoku';
  static const howToPlay = 'Qanday o\'ynaladi';
  static const newGame = 'Yangi o\'yin';
  static const continueGame = 'Davom etish';
  static const dailyChallenge = 'Kundalik tanlov';
  static const play = 'O\'ynash';
  static const done = 'Bajarildi ✓';

  // Levels
  static String level(KillerLevel l) => switch (l) {
        KillerLevel.easy => 'Oson',
        KillerLevel.medium => 'O\'rta',
        KillerLevel.hard => 'Qiyin',
        KillerLevel.expert => 'Ekspert',
        KillerLevel.devil => 'Iblis',
      };

  static String levelEmoji(KillerLevel l) => switch (l) {
        KillerLevel.easy => '🙂',
        KillerLevel.medium => '🤔',
        KillerLevel.hard => '😮',
        KillerLevel.expert => '😨',
        KillerLevel.devil => '😈',
      };

  // Screens
  static const gameTitle = 'O\'yin';
  static const dailyCalendarTitle = 'Kundalik tanlov';
  static const statsTitle = 'Statistika';
  static const settingsTitle = 'Sozlamalar';

  // Game: status row
  static String mistakes(int n, int? limit) =>
      limit == null ? 'Xatolar: $n' : 'Xatolar: $n/$limit';
  static String score(int n) => 'Ball: $n';
  static const pause = 'Pauza';
  static const resume = 'Davom etish';

  // Game: toolbar
  static const toolUndo = 'Orqaga';
  static const toolErase = 'O\'chirish';
  static const toolFastPencil = 'Tez qoralama';
  static const toolPencil = 'Qoralama';
  static const toolHint = 'Aqlli maslahat';
  static const pencilOff = 'O\'CH';
  static const pencilOn = 'YON';
  static const numberFirst = 'Avval raqam';
  static const savePuzzle = 'Saqlanganlarga qo\'shish';
  static const savedPuzzle = 'Jumboq saqlandi';
  static const unsavedPuzzle = 'Saqlanganlardan olib tashlandi';

  // Game: cage panel
  static String cageInfo(int sum, int size, int combos) =>
      'Σ $sum · $size katak · $combos ta to\'plam';
  static const cagePanelIdle = 'Katakni tanlang: kafesga mos raqam to\'plamlari shu yerda chiqadi.';

  // Game: generation
  static const generating = 'Jumboq tuzilmoqda';
  static const generatingSlow =
      'Yagona yechimli jumboq tekshirilmoqda. Qiyin darajalarda bu bir necha soniya olishi mumkin.';

  // Game: win / loss
  static const winTitle = 'Tabriklaymiz!';
  static String winSubtitle(KillerLevel l) => '${level(l)} darajadagi jumboq yechildi';
  static const newRecord = 'Yangi rekord';
  static const statTime = 'Vaqt';
  static const statScore = 'Ball';
  static const statMistakes = 'Xatolar';
  static const statHints = 'Maslahatlar';
  static const nextGame = 'Keyingi o\'yin';
  static const goHome = 'Bosh sahifa';
  static const lossTitle = 'O\'yin tugadi';
  static String lossSubtitle(int n) => '$n ta xato qildingiz.';
  static const lossContinue = 'Davom etish';
  static const lossContinueNote = 'Xatolar nolga tushadi, o\'yin cheklovsiz davom etadi.';

  // New game sheet
  static const newGameSheetTitle = 'Yangi o\'yin';

  static String weeklyWinRate(int? pct) => pct == null ? '—' : '$pct%';
  static const weeklyWinRateLabel = 'Haftalik g\'alaba: ';
  static String lv(int n) => 'Lv$n';
  static String starsProgress(int n) => '$n/100';

  // Home
  static const ratingTooltip = 'Miya reytingi';
  static const streakTooltip = 'Seriya: ketma-ket yechilgan kunlar';
  static String dailyDate(DateTime d) => '${d.day}-${monthShort(d.month)}';
  static String monthShort(int m) => const [
        'yan', 'fev', 'mar', 'apr', 'may', 'iyun',
        'iyul', 'avg', 'sen', 'okt', 'noy', 'dek',
      ][m - 1];
  static String monthName(int m) => const [
        'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
        'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr',
      ][m - 1];
  static const weekdaysShort = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  // How to play
  static const rulesTitle = 'Qanday o\'ynaladi';
  static const rules = [
    ('1–9', 'Har bir qator, ustun va 3×3 blokda 1 dan 9 gacha raqamlar bir martadan.'),
    ('Σ', 'Punktir kafes ichidagi raqamlar yig\'indisi burchakdagi songa teng. Kafes ichida raqam takrorlanmaydi.'),
    ('45', 'Har qator, ustun va blok yig\'indisi 45. Ichidagi to\'liq kafeslarni ayirsangiz, qolgan kataklarni topasiz.'),
    ('⚡', '"Avval raqam" yoqilsa, avval raqamni tanlab, keyin kataklarni bosasiz.'),
    ('✎', 'Kafes panelida to\'plamni bosib chizib qo\'yish mumkin. Raqamni uzoq bossangiz, shu qoralama bor kataklar ajraladi.'),
  ];

  // Win dialog: stars and level progress
  static const starWin = 'Yutdingiz';
  static const starClean = 'Toza o\'yin';
  static const starFast = 'Tezkor';
  static String levelProgress(KillerLevel l, int lv) => '${level(l)} Lv$lv';
  static String levelUp(KillerLevel l, int lv) => '${level(l)} Lv$lv ochildi!';

  // Smart hint (TZ §5.3)
  static const hintNext = 'Keyingisi';
  static const hintApply = 'Qo\'llash';
  static const hintClose = 'Yopish';
  static String hintStep(int step) => '${step + 1}/3';

  static String region(Region r) => switch (r.kind) {
        RegionKind.row => '${r.start + 1}-qator',
        RegionKind.column => '${r.start + 1}-ustun',
        RegionKind.block => '${r.start + 1}-blok',
        RegionKind.rows => '${r.start + 1}–${r.start + r.count}-qatorlar',
        RegionKind.columns => '${r.start + 1}–${r.start + r.count}-ustunlar',
      };

  static String _cell(int i) => '${i ~/ 9 + 1}-qator, ${i % 9 + 1}-ustun';
  static String _digits(int mask) => digitsOf(mask).join(' ');

  /// Technique name shown on every step.
  static String hintTitle(Hint h) => switch (h.kind) {
        HintKind.wrongDigits => 'Xato raqamlar',
        HintKind.innie => '45 qoidasi: ${region(h.region!)}',
        HintKind.outie => '45 qoidasi (tashqi katak): ${region(h.region!)}',
        HintKind.nakedSingle => 'Yagona variant',
        HintKind.hiddenSingle => 'Yashirin yolg\'iz: ${region(h.region!)}',
        HintKind.pairSum => 'Ikki katak yig\'indisi: ${region(h.region!)}',
        HintKind.lastResort => 'Eng kam variantli katak',
      };

  /// Text for step 0 (where), 1 (why) and 2 (result).
  static String hintText(Hint h, int step) {
    final r = h.region == null ? '' : region(h.region!);
    switch (h.kind) {
      case HintKind.wrongDigits:
        final n = h.focus.length;
        return [
          'Taxtada $n ta noto\'g\'ri raqam bor. Ular bilan davom etsangiz, mantiq boshi berk ko\'chaga olib boradi.',
          'Noto\'g\'ri raqamlar belgilandi. Birinchisi: ${_cell(h.focus.first)}.',
          '"Qo\'llash" barcha noto\'g\'ri raqamlarni o\'chiradi.',
        ][step];
      case HintKind.innie:
        return [
          '${r}ni ko\'rib chiqing: 45 qoidasi bilan bu hududdagi bitta katakni aniq topish mumkin.',
          '$r yig\'indisi ${h.total}. Butunlay ichida turgan kafeslar yig\'indisi ${h.inside}. Belgilangan katak = ${h.total} − ${h.inside}.',
          'Demak, bu katakka ${h.digit} yoziladi.',
        ][step];
      case HintKind.outie:
        return [
          '${r}ni ko\'rib chiqing: chegarani kesib o\'tgan kafeslardan faqat bitta katak tashqarida qolgan.',
          '$r yig\'indisi ${h.total}, ichidagi kafeslar ${h.inside}, chegarani kesgan kafeslar jami ${h.crossing}. Tashqi katak = ${h.crossing} − (${h.total} − ${h.inside}).',
          'Demak, tashqi katakka ${h.digit} yoziladi.',
        ][step];
      case HintKind.nakedSingle:
        return [
          'Belgilangan katakka diqqat qiling: qator, ustun, blok va kafes birgalikda faqat bitta raqamni qoldiradi.',
          'Qator, ustun va blokda bor: ${_digits(h.houseMask)}. Kafes Σ${h.cageSum} uchun hali mumkin: ${_digits(h.cageMask)}.',
          'Ikkalasini solishtirsangiz, faqat ${h.digit} qoladi.',
        ][step];
      case HintKind.hiddenSingle:
        return [
          '${r}da ${h.digit} raqami faqat bitta katakka sig\'adi. Qaysi?',
          'Mana shu katak. Qolgan joylarda ${h.digit} qator, ustun yoki kafes yig\'indisi tufayli taqiqlangan.',
          'Shu katakka ${h.digit} yoziladi.',
        ][step];
      case HintKind.pairSum:
        final cells = h.allowed.keys.toList();
        return [
          '${r}da 45 qoidasini qo\'llang: ikki katakning yig\'indisi aniq chiqadi.',
          'Belgilangan ikki katak yig\'indisi = ${h.total} − ${h.inside} = ${h.total - h.inside}. Ular bir hududda, demak raqamlari har xil.',
          'Mos keladigan nomzodlar: ${_digits(h.allowed[cells[0]]!)} va ${_digits(h.allowed[cells[1]]!)}. "Qo\'llash" qoralamani shunga qisqartiradi.',
        ][step];
      case HintKind.lastResort:
        return [
          'Oddiy qadam yo\'q. Eng kam variantli katak belgilandi.',
          'Bu katak uchun nomzodlar: ${_digits(h.houseMask)}. Har bir variant qo\'shni kafeslarga qanday ta\'sir qilishini kuzating.',
          'To\'g\'ri javob: ${h.digit}.',
        ][step];
    }
  }

  // Daily calendar
  static String monthTrophy(int m) => '${monthName(m)} kubogi qo\'lga kiritildi!';
  static String dailyLevel(KillerLevel l) => 'Bugungi daraja: ${level(l)}';
  static const dailyFuture = 'Bu kun hali kelmagan.';

  // Me: statistics
  static const statPlayed = 'O\'ynalgan';
  static const statWon = 'Yutilgan';
  static const statWinRate = 'G\'alaba foizi';
  static const statBest = 'Eng yaxshi vaqt';
  static const statAvg = 'O\'rtacha vaqt';
  static const statFlawless = 'Xatosiz g\'alabalar';
  static const statStreak = 'Joriy seriya';
  static const statLongest = 'Eng uzun seriya';
  static const chartTitle = 'Oxirgi 30 kun: o\'rtacha vaqt';
  static const chartEmpty = 'Bu darajada oxirgi 30 kunda g\'alaba yo\'q.';
  static const savedTitle = 'Saqlangan jumboqlar';
  static const savedEmpty = 'O\'yin ekranidagi yulduzchani bossangiz, jumboq shu yerda saqlanadi.';
  static const totalStars = 'Jami yulduzlar';
  static const ratingLabel = 'Miya reytingi';
  static const streakLabel = 'Kunlik seriya';

  // Settings (TZ §3.5)
  static const sectionGame = 'O\'yin';
  static const sectionLook = 'Ko\'rinish';
  static const sectionData = 'Ma\'lumotlar';
  static const setMistakeLimit = 'Xato cheklovi (3 ta)';
  static const setShowErrors = 'Xatolarni darhol ko\'rsatish';
  static const setAutoNotes = 'Qoralamalarni avto-tozalash';
  static const setHighlightSame = 'Bir xil raqamlarni ajratish';
  static const setHideUsed = 'Ishlatilgan raqamlarni yashirish';
  static const setShowTimer = 'Taymerni ko\'rsatish';
  static const setNumberFirst = 'Avval raqam, keyin katak';
  static const setSound = 'Tovush';
  static const setVibration = 'Tebranish';
  static const setTheme = 'Mavzu';
  static const themeLight = 'Yorug\'';
  static const themeDark = 'Tungi';
  static const themeSystem = 'Tizim';
  static const resetStats = 'Statistikani nolga tushirish';
  static const resetStatsConfirm =
      'Barcha o\'yinlar tarixi o\'chiriladi. Yulduzlar, Lv va kubok belgilari saqlanib qoladi. Davom etasizmi?';
  static const resetDone = 'Statistika tozalandi';
  static const exportData = 'Ma\'lumotlarni eksport qilish';
  static const importData = 'Ma\'lumotlarni import qilish';
  static const importConfirm =
      'Fayldagi ma\'lumotlar hozirgilarning o\'rnini egallaydi. Davom etasizmi?';
  static const exportDone = 'Ma\'lumotlar saqlandi';
  static const importDone = 'Ma\'lumotlar tiklandi';
  static const importFailed = 'Fayl o\'qilmadi: bu ilovaning eksport fayli emas.';
  static const cancel = 'Bekor qilish';
  static const confirm = 'Ha';
}
