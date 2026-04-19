import 'package:flutter/material.dart';

const Color kAccentYellow = Color(0xFFFFEB3B);
const Color kBackgroundBlack = Color(0xFF000000);

final StadiumBorder kCapsuleShape = StadiumBorder();

ThemeData buildHuaxingTheme() {
  final ColorScheme colorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: kAccentYellow,
    onPrimary: Colors.black,
    secondary: kAccentYellow,
    onSecondary: Colors.black,
    surface: const Color(0xFF121212),
    onSurface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: kAccentYellow,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.08)),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: kCapsuleShape,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _capsuleFilledStyle(colorScheme),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _capsuleElevatedStyle(colorScheme),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _capsuleOutlinedStyle(colorScheme),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _capsuleTextStyle(colorScheme),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.6),
      disabledColor: colorScheme.surfaceContainerHighest.withOpacity(0.35),
      selectedColor: colorScheme.primary,
      secondarySelectedColor: colorScheme.primary,
      labelStyle: TextStyle(color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: colorScheme.onPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: StadiumBorder(
        side: BorderSide(color: colorScheme.primary.withOpacity(0.35)),
      ),
    ),
  );
}

ButtonStyle _capsuleFilledStyle(ColorScheme scheme) {
  return FilledButton.styleFrom(
    foregroundColor: scheme.onPrimary,
    backgroundColor: scheme.primary,
    disabledForegroundColor: scheme.onPrimary.withOpacity(0.38),
    disabledBackgroundColor: scheme.primary.withOpacity(0.38),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    minimumSize: const Size(48, 48),
    shape: kCapsuleShape,
  );
}

ButtonStyle _capsuleElevatedStyle(ColorScheme scheme) {
  return ElevatedButton.styleFrom(
    foregroundColor: scheme.onPrimary,
    backgroundColor: scheme.primary,
    disabledForegroundColor: scheme.onPrimary.withOpacity(0.38),
    disabledBackgroundColor: scheme.surfaceContainerHighest.withOpacity(0.5),
    elevation: 2,
    shadowColor: scheme.primary.withOpacity(0.45),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    minimumSize: const Size(48, 48),
    shape: kCapsuleShape,
  );
}

ButtonStyle _capsuleOutlinedStyle(ColorScheme scheme) {
  return OutlinedButton.styleFrom(
    foregroundColor: scheme.primary,
    backgroundColor: Colors.transparent,
    disabledForegroundColor: scheme.primary.withOpacity(0.38),
    side: BorderSide(color: scheme.primary, width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    minimumSize: const Size(48, 48),
    shape: kCapsuleShape,
  );
}

ButtonStyle _capsuleTextStyle(ColorScheme scheme) {
  return TextButton.styleFrom(
    foregroundColor: scheme.primary,
    disabledForegroundColor: scheme.primary.withOpacity(0.38),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    minimumSize: const Size(48, 48),
    shape: kCapsuleShape,
  );
}
