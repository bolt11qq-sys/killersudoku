import 'package:flutter/material.dart';

/// Design tokens from TZ §6. Widgets must read colors from [AppColors]
/// (via `context.colors`) and sizes from [AppDims]; no raw color literals
/// outside this file.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.gridThin,
    required this.gridThick,
    required this.highlight,
    required this.selected,
    required this.sameNumber,
    required this.error,
    required this.success,
    required this.badge,
    required this.streak,
    required this.cage,
    required this.cageFill,
    required this.ratingChip,
    required this.shadow,
  });

  final Color bg;
  final Color surface;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final Color gridThin;
  final Color gridThick;
  final Color highlight;
  final Color selected;
  final Color sameNumber;
  final Color error;
  final Color success;
  final Color badge;
  final Color streak;
  final Color cage;
  final Color cageFill;

  /// Light-blue background of the brain-rating chip on the home screen.
  final Color ratingChip;

  /// Very light card shadow (TZ §6.3: "juda yengil soya").
  final Color shadow;

  static const light = AppColors(
    bg: Color(0xFFF4F6FB),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF1E5BDB),
    textPrimary: Color(0xFF1C2230),
    textSecondary: Color(0xFF8A93A6),
    gridThin: Color(0xFFD5DAE3),
    gridThick: Color(0xFF6B7385),
    highlight: Color(0xFFDCE5F6),
    selected: Color(0xFFBFD0F2),
    sameNumber: Color(0xFFC9D7F3),
    // TZ had #E5484D; darkened so a wrong digit stays ≥ 3:1 on `selected`.
    error: Color(0xFFD0343A),
    success: Color(0xFF3DBE6B),
    badge: Color(0xFF1E5BDB),
    streak: Color(0xFFF05A3C),
    cage: Color(0xFF4A5568),
    cageFill: Color(0xFFEAF0FB),
    ratingChip: Color(0xFFDCE5F6),
    shadow: Color(0x0F1C2230),
  );

  static const dark = AppColors(
    bg: Color(0xFF11141B),
    surface: Color(0xFF1B202A),
    primary: Color(0xFF6F98FF),
    textPrimary: Color(0xFFE6EAF2),
    textSecondary: Color(0xFF8A93A6),
    gridThin: Color(0xFF2C3340),
    gridThick: Color(0xFF8A93A6),
    highlight: Color(0xFF22304A),
    selected: Color(0xFF2F4670),
    sameNumber: Color(0xFF2A3D60),
    error: Color(0xFFFF6B6B),
    success: Color(0xFF4CD483),
    badge: Color(0xFF6F98FF),
    streak: Color(0xFFFF7A5C),
    cage: Color(0xFFA0AEC0),
    cageFill: Color(0xFF1F2838),
    ratingChip: Color(0xFF22304A),
    shadow: Color(0x33000000),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? primary,
    Color? textPrimary,
    Color? textSecondary,
    Color? gridThin,
    Color? gridThick,
    Color? highlight,
    Color? selected,
    Color? sameNumber,
    Color? error,
    Color? success,
    Color? badge,
    Color? streak,
    Color? cage,
    Color? cageFill,
    Color? ratingChip,
    Color? shadow,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      gridThin: gridThin ?? this.gridThin,
      gridThick: gridThick ?? this.gridThick,
      highlight: highlight ?? this.highlight,
      selected: selected ?? this.selected,
      sameNumber: sameNumber ?? this.sameNumber,
      error: error ?? this.error,
      success: success ?? this.success,
      badge: badge ?? this.badge,
      streak: streak ?? this.streak,
      cage: cage ?? this.cage,
      cageFill: cageFill ?? this.cageFill,
      ratingChip: ratingChip ?? this.ratingChip,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      primary: l(primary, other.primary),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      gridThin: l(gridThin, other.gridThin),
      gridThick: l(gridThick, other.gridThick),
      highlight: l(highlight, other.highlight),
      selected: l(selected, other.selected),
      sameNumber: l(sameNumber, other.sameNumber),
      error: l(error, other.error),
      success: l(success, other.success),
      badge: l(badge, other.badge),
      streak: l(streak, other.streak),
      cage: l(cage, other.cage),
      cageFill: l(cageFill, other.cageFill),
      ratingChip: l(ratingChip, other.ratingChip),
      shadow: l(shadow, other.shadow),
    );
  }
}

/// Sizes from TZ §6.3, in logical pixels (dp / sp).
abstract final class AppDims {
  static const double screenPadding = 16;
  static const double cardRadius = 20;
  static const double chipHeight = 44;
  static const double primaryButtonHeight = 64;
  static const double primaryButtonRadius = 16;
  static const double primaryButtonText = 22;
  static const double levelCardHeight = 64;
  static const double levelCardRadius = 16;
  static const double levelCardGap = 10;
  static const double gridThin = 1;
  static const double gridThick = 2;
  static const double gridOuter = 2.5;
  static const double cageStroke = 1.2;

  /// Cage dashed outline inset, as a fraction of the cell side.
  static const double cageInset = 0.09;
  static const double numberButtonRadius = 12;
  static const double numberButtonGap = 5;
  static const double toolIcon = 28;
  static const double toolLabel = 13;
  static const double bottomNavHeight = 72;
  static const double bottomNavIcon = 28;
  static const double modeTitle = 40;

  /// Board text sizes as fractions of the cell height (TZ §6.2).
  static const double digitScale = 0.60;
  static const double noteScale = 0.22;
  static const double cageSumScale = 0.20;

  /// Width of one number-pad button: (screen − 32 − 8×gap) / 9.
  static double numberButtonWidth(double screenWidth) =>
      (screenWidth - 2 * screenPadding - 8 * numberButtonGap) / 9;
}

/// Animation durations from TZ §6.4.
abstract final class AppDurations {
  static const cellSelect = Duration(milliseconds: 120);
  static const bottomSheet = Duration(milliseconds: 250);
  static const lineWave = Duration(milliseconds: 400);
  static const confetti = Duration(milliseconds: 1500);
  static const double sheetBarrierOpacity = 0.40;
}

const String kFontFamily = 'NunitoSans';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: c.primary,
    brightness: brightness,
  ).copyWith(
    primary: c.primary,
    onPrimary: c.surface,
    surface: c.surface,
    onSurface: c.textPrimary,
    error: c.error,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: c.bg,
    splashFactory: InkSparkle.splashFactory,
    extensions: [c],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.bg,
      modalBarrierColor: Colors.black.withValues(
        alpha: AppDurations.sheetBarrierOpacity,
      ),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDims.cardRadius),
        ),
      ),
    ),
  );
}

extension AppThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
