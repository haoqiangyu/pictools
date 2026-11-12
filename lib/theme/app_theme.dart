import 'package:flutter/material.dart';

/// Pictools Studio semantic palette. Canvas stays dark in both appearances.
class StudioColors extends ThemeExtension<StudioColors> {
  const StudioColors({
    required this.background,
    required this.surface,
    required this.subtle,
    required this.ink,
    required this.muted,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.success,
    required this.successSoft,
  });
  final Color background,
      surface,
      subtle,
      ink,
      muted,
      border,
      primary,
      onPrimary,
      primarySoft,
      success,
      successSoft;
  static const light = StudioColors(
    background: Color(0xFFF7F6F2),
    surface: Colors.white,
    subtle: Color(0xFFEEEDE7),
    ink: Color(0xFF202522),
    muted: Color(0xFF626B65),
    border: Color(0xFFDADDD5),
    primary: Color(0xFFC84725),
    onPrimary: Colors.white,
    primarySoft: Color(0xFFFAE8DF),
    success: Color(0xFF23744B),
    successSoft: Color(0xFFE5F2E9),
  );
  static const dark = StudioColors(
    background: Color(0xFF171B18),
    surface: Color(0xFF232925),
    subtle: Color(0xFF303831),
    ink: Color(0xFFF5F5EF),
    muted: Color(0xFFB1BAB2),
    border: Color(0xFF465047),
    primary: Color(0xFFFFAE8F),
    onPrimary: Color(0xFF432313),
    primarySoft: Color(0xFF4B3027),
    success: Color(0xFF91D4B1),
    successSoft: Color(0xFF203D2D),
  );
  static StudioColors of(BuildContext context) =>
      Theme.of(context).extension<StudioColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);
  @override
  StudioColors copyWith() => this;
  @override
  StudioColors lerp(covariant StudioColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return StudioColors(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      subtle: c(subtle, other.subtle),
      ink: c(ink, other.ink),
      muted: c(muted, other.muted),
      border: c(border, other.border),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      primarySoft: c(primarySoft, other.primarySoft),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
    );
  }
}

extension StudioThemeContext on BuildContext {
  StudioColors get studio => StudioColors.of(this);
}

class AppTheme {
  AppTheme._();
  // Legacy desktop-only surfaces retain a coherent dark palette.
  static const primaryBg = Color(0xFF171B18);
  static const cardBg = Color(0xFF232925);
  static const borderColor = Color(0xFF465047);
  static const accentColor = Color(0xFFFFAE8F);
  static const secondaryColor = Color(0xFFB1BAB2);
  static const textColor = Color(0xFFF5F5EF);
  static const highlightColor = Color(0xFF23744B);
  static const errorColor = Color(0xFFB63232);
  static const canvas = Color(0xFF202522);
  static ThemeData get lightTheme =>
      _build(StudioColors.light, Brightness.light);
  static ThemeData get darkTheme => _build(StudioColors.dark, Brightness.dark);
  static ThemeData _build(StudioColors c, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.primary,
          brightness: brightness,
        ).copyWith(
          primary: c.primary,
          onPrimary: c.onPrimary,
          surface: c.surface,
          onSurface: c.ink,
          onSurfaceVariant: c.muted,
          outline: c.border,
          surfaceContainerHighest: c.subtle,
          error: brightness == Brightness.light
              ? errorColor
              : const Color(0xFFFFB4AB),
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return base.copyWith(
      extensions: [c],
      scaffoldBackgroundColor: c.background,
      textTheme: base.textTheme
          .apply(bodyColor: c.ink, displayColor: c.ink)
          .copyWith(
            headlineLarge: TextStyle(
              fontSize: 36,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: c.ink,
              letterSpacing: 0,
            ),
            headlineMedium: TextStyle(
              fontSize: 28,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: c.ink,
              letterSpacing: 0,
            ),
            titleLarge: TextStyle(
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: c.ink,
              letterSpacing: 0,
            ),
            titleMedium: TextStyle(
              fontSize: 18,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: c.ink,
              letterSpacing: 0,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: c.ink,
              letterSpacing: 0,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: c.ink,
              letterSpacing: 0,
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: c.muted,
              letterSpacing: 0,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: c.ink,
        ),
      ),
      iconTheme: IconThemeData(color: c.muted, size: 24),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: c.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: shape,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: shape,
          side: BorderSide(color: c.border),
          foregroundColor: c.ink,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2864B4), width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(color: c.background),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.subtle,
        selectedColor: c.primarySoft,
        labelStyle: TextStyle(color: c.ink),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
