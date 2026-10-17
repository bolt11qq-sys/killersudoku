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
  static const hintComingSoon = 'Aqlli maslahat 5-bosqichda qo\'shiladi.';
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

  // Placeholders for screens built in later stages
  static const comingSoon = 'Bu ekran keyingi bosqichlarda tayyor bo\'ladi.';
}
