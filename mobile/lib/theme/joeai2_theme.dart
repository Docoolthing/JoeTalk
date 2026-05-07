import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens from JoeAI2 `public/styles.css` (ckcps / school site palette).
abstract final class CkcpsColors {
  static const Color blue = Color(0xFF05236B);
  static const Color blueMid = Color(0xFF16356F);
  static const Color tealDark = Color(0xFF0A828F);
  static const Color tealBorder = Color(0xFF097D8C);
  static const Color green = Color(0xFF1D9E70);
  static const Color text = Color(0xFF333333);
  static const Color muted = Color(0xFF666666);
  static const Color bgPage = Color(0xFFF5F5F5);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color navBg = Color(0xFFF9F9F9);
  static const Color ctaBlue = Color(0xFF2164AC);
  static const Color sendBlue = Color(0xFF2FA2DB);
  static const Color hoverYellow = Color(0xFFFFB400);
  static const Color ghostOrange = Color(0xFFFF8400);
  static const Color linkHover = Color(0xFFFF5D8B);
  static const Color yellow = Color(0xFFFFC600);
  static const Color assistantPanel = Color(0xFFF9FEFF);
  static const Color hairline = Color(0xFFDDDDDD);
}

/// Page gradient from `.page-shell` in JoeAI2.
const LinearGradient joeAi2PageGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFE8F4F5),
    CkcpsColors.bgPage,
    CkcpsColors.panel,
  ],
  stops: [0.0, 0.45, 1.0],
);

ThemeData buildJoeAi2Theme() {
  final colorScheme = ColorScheme.light(
    primary: CkcpsColors.sendBlue,
    onPrimary: Colors.white,
    primaryContainer: CkcpsColors.ctaBlue,
    onPrimaryContainer: Colors.white,
    secondary: CkcpsColors.tealDark,
    onSecondary: Colors.white,
    surface: CkcpsColors.panel,
    onSurface: CkcpsColors.text,
    onSurfaceVariant: CkcpsColors.muted,
    outline: CkcpsColors.hairline,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: CkcpsColors.bgPage,
  );

  return base.copyWith(
    textTheme: GoogleFonts.notoSansTextTheme(base.textTheme).apply(
      bodyColor: CkcpsColors.text,
      displayColor: CkcpsColors.blue,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: CkcpsColors.navBg,
      foregroundColor: CkcpsColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: CkcpsColors.panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0x1F05236B)),
      ),
      shadowColor: Colors.black,
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CkcpsColors.sendBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? CkcpsColors.tealDark
            : null,
      ),
    ),
  );
}

TextStyle ckcpsEyebrowStyle() {
  return GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: CkcpsColors.tealDark,
    height: 1.3,
  );
}

TextStyle ckcpsAppTitleStyle() {
  return GoogleFonts.notoSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: CkcpsColors.blue,
    height: 1.2,
    shadows: const [
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 3),
        blurRadius: 2,
      ),
    ],
  );
}

TextStyle ckcpsSubtitleStyle() {
  return GoogleFonts.notoSans(
    fontSize: 15,
    color: CkcpsColors.muted,
    height: 1.5,
  );
}

ButtonStyle ckcpsGhostButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: CkcpsColors.ghostOrange,
    backgroundColor: CkcpsColors.panel,
    side: const BorderSide(color: Color(0x1405236B)),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    textStyle: GoogleFonts.notoSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
}

BoxDecoration ckcpsChatWindowDecoration() {
  return BoxDecoration(
    color: CkcpsColors.panel,
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
    border: const Border(
      left: BorderSide(color: Color(0x1F05236B)),
      right: BorderSide(color: Color(0x1F05236B)),
      bottom: BorderSide(color: Color(0x1F05236B)),
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x33000000),
        offset: Offset(0, 0),
        blurRadius: 3,
        spreadRadius: 0,
      ),
    ],
  );
}

BoxDecoration ckcpsBrandRibbonDecoration() {
  return const BoxDecoration(
    color: CkcpsColors.panel,
    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    border: Border(
      top: BorderSide(
        color: CkcpsColors.blue,
        width: 5,
      ),
    ),
    boxShadow: [
      BoxShadow(
        color: Color(0x0F000000),
        offset: Offset(0, -1),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ],
  );
}
