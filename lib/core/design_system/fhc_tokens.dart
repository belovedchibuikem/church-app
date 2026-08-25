import 'package:flutter/material.dart';

abstract final class FhcColors {
  static const green = Color(0xFF006B45);
  static const greenDark = Color(0xFF004B36);
  static const greenDeep = Color(0xFF003D2D);
  static const mint = Color(0xFFEAF4EF);
  static const navy = Color(0xFF061B3D);
  static const midnight = Color(0xFF001823);
  static const gold = Color(0xFFF0A900);
  static const purple = Color(0xFF49347E);
  static const blue = Color(0xFF063E70);
  static const wine = Color(0xFF6F2336);
  static const orange = Color(0xFFE85D04);
  static const church = green;
  static const mission = purple;
  static const kca = blue;
  static const press = wine;
  static const media = orange;
  static const eventsAccent = Color(0xFFC62828);
  static const ink = Color(0xFF111514);
  static const muted = Color(0xFF66706D);
  static const hint = Color(0xFF9AA19F);
  static const border = Color(0xFFE1E6E3);
  static const canvas = Color(0xFFF6F8F7);
  static const white = Colors.white;
  static const red = Color(0xFFE02424);
}

abstract final class FhcSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class FhcRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const device = 24.0;
  static const button = sm;
  static const field = sm;
  static const card = md;
}

abstract final class FhcSizes {
  static const buttonHeight = 48.0;
  static const topBarHeight = 52.0;
  static const bottomNavHeight = 64.0;
  static const fieldHint = 12.0;
  static const navIcon = 22.0;
  static const minTap = 44.0;
}

abstract final class FhcTypography {
  static const display = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: FhcColors.ink,
  );
  static const title = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: FhcColors.ink,
  );
  static const titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: FhcColors.ink,
  );
  static const body = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: FhcColors.ink,
  );
  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: FhcColors.ink,
  );
  static const hint = TextStyle(fontSize: 12, color: FhcColors.hint);
  static const caption = TextStyle(
    fontSize: 11,
    height: 1.35,
    color: FhcColors.muted,
  );
  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: FhcColors.white,
    letterSpacing: 0.1,
  );
  static const nav = TextStyle(fontSize: 10, height: 1.1);
}

abstract final class FhcElevation {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 3)),
  ];
}

abstract final class FhcMotion {
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 240);
}

OutlineInputBorder _outline({
  Color color = FhcColors.border,
  double width = 1,
}) {
  return OutlineInputBorder(
    borderSide: BorderSide(color: color, width: width),
    borderRadius: BorderRadius.circular(FhcRadius.field),
  );
}

ThemeData buildFhcTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: FhcColors.green,
    primary: FhcColors.green,
    onPrimary: FhcColors.white,
    secondary: FhcColors.gold,
    surface: FhcColors.white,
    onSurface: FhcColors.ink,
    error: FhcColors.red,
  ).copyWith(outline: FhcColors.border);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: FhcColors.canvas,
    fontFamily: 'FhcRoboto',
    dividerColor: FhcColors.border,
    canvasColor: FhcColors.canvas,
    splashColor: FhcColors.green.withValues(alpha: 0.08),
    highlightColor: FhcColors.green.withValues(alpha: 0.04),
    visualDensity: VisualDensity.standard,
    textTheme: const TextTheme(
      headlineMedium: FhcTypography.display,
      titleLarge: FhcTypography.title,
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: FhcColors.ink,
      ),
      bodyMedium: FhcTypography.body,
      bodySmall: FhcTypography.caption,
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: FhcColors.ink,
      ),
      labelMedium: FhcTypography.label,
    ),
    dividerTheme: const DividerThemeData(
      color: FhcColors.border,
      space: 1,
      thickness: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FhcColors.green,
        foregroundColor: FhcColors.white,
        disabledBackgroundColor: FhcColors.green.withValues(alpha: 0.45),
        disabledForegroundColor: FhcColors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FhcRadius.button),
        ),
        textStyle: FhcTypography.button,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      hintStyle: FhcTypography.hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: _outline(),
      enabledBorder: _outline(),
      focusedBorder: _outline(color: FhcColors.green, width: 1.5),
      errorBorder: _outline(color: FhcColors.red),
    ),
    cardTheme: CardThemeData(
      color: FhcColors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FhcRadius.card),
        side: const BorderSide(color: FhcColors.border),
      ),
      shadowColor: const Color(0x14000000),
    ),
  );
}
