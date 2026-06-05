import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CasinoTheme {
  // Theme Colors
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color secondaryGold = Color(0xFFC5A059);
  static const Color accentNeonCyan = Color(0xFF00E5FF);
  static const Color neonPink = Color(0xFFFF2E93);
  
  static const Color feltGreenDeep = Color(0xFF0A3A20);
  static const Color feltGreenLight = Color(0xFF0D5E3A);
  static const Color tableBorderGold = Color(0xFF8C6D30);
  static const Color woodBorder = Color(0xFF2B1A08);
  
  static const Color bgDarker = Color(0xFF090A0C);
  static const Color bgDark = Color(0xFF111318);
  static const Color bgCard = Color(0xFF1E222B);
  
  static const Color textLight = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textGold = Color(0xFFFFE066);

  // Status Colors
  static const Color successGreen = Color(0xFF22C55E);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color infoCyan = Color(0xFF06B6D4);

  // ── Premium Lobby Palette ──────────────────────────────────────────────────
  // Deep luxury colors for lobby cards, settings tiles, and VIP sections.
  static const Color lobbyCardDark = Color(0xFF0A0E0A);       // Near-black with green tint
  static const Color lobbyCardSurface = Color(0xFF111A14);     // Dark forest surface
  static const Color lobbyGoldShine = Color(0xFFD4A843);       // Warm antique gold
  static const Color lobbyGoldDim = Color(0xFF8C6D30);         // Muted gold for subtle accents
  static const Color lobbyEmerald = Color(0xFF0D3B22);         // Deep emerald green
  static const Color lobbyEmeraldGlow = Color(0xFF1A5C38);     // Lighter emerald for hover
  static const Color lobbyCyanDeep = Color(0xFF0A2A3D);        // Deep teal-blue for poker card
  static const Color lobbyCyanGlow = Color(0xFF0E4466);        // Lighter teal for hover
  static const Color lobbyDivider = Color(0xFF1F2A22);         // Dark divider line

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDarker,
      primaryColor: primaryGold,
      hintColor: accentNeonCyan,
      useMaterial3: true,
      canvasColor: bgDark,           // Dropdown/menu background
      cardColor: bgCard,
      dividerColor: lobbyDivider,
      splashColor: primaryGold.withValues(alpha: 0.08),
      highlightColor: primaryGold.withValues(alpha: 0.05),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryGold,
          letterSpacing: 1.2,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textLight,
          letterSpacing: 1.0,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textLight,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: textMuted,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: accentNeonCyan,
        surface: bgCard,
        onSurface: textLight,
        error: neonPink,
        onPrimary: bgDarker,
        onSecondary: bgDarker,
        onError: Colors.white,
      ),

      // ── Component Themes ─────────────────────────────────────────────
      // Ensures every Material widget renders with dark casino surfaces.

      listTileTheme: const ListTileThemeData(
        tileColor: bgCard,
        textColor: textLight,
        iconColor: textMuted,
        selectedTileColor: lobbyCardSurface,
        selectedColor: primaryGold,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      cardTheme: CardThemeData(
        color: bgCard,
        shadowColor: Colors.black54,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: lobbyGoldDim.withValues(alpha: 0.15)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: lobbyGoldDim.withValues(alpha: 0.2)),
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: textMuted,
          height: 1.4,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1E26),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 13,
          color: textLight,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bgDarker,
        foregroundColor: textLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: primaryGold,
          letterSpacing: 1.5,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: textMuted),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lobbyCardSurface,
          foregroundColor: primaryGold,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textMuted,
          textStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: lobbyDivider,
        thickness: 0.8,
        space: 0,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.outfit(fontSize: 13, color: textLight),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: lobbyGoldDim.withValues(alpha: 0.2)),
        ),
        textStyle: GoogleFonts.outfit(fontSize: 12, color: textLight),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentNeonCyan,
        linearTrackColor: lobbyCardDark,
        circularTrackColor: lobbyCardDark,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentNeonCyan;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentNeonCyan.withValues(alpha: 0.35);
          }
          return lobbyDivider.withValues(alpha: 0.5);
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primaryGold,
        inactiveTrackColor: lobbyCardSurface,
        thumbColor: primaryGold,
        overlayColor: primaryGold.withValues(alpha: 0.12),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGold;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(bgDarker),
        side: BorderSide(color: textMuted, width: 1.5),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGold;
          return textMuted;
        }),
      ),
    );
  }

  // Neon Shadows
  static List<BoxShadow> neonGlow({Color color = accentNeonCyan, double radius = 8}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.5),
        blurRadius: radius,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.2),
        blurRadius: radius * 2,
        spreadRadius: 2,
      ),
    ];
  }

  // Glassmorphic Decoration
  static BoxDecoration glassDecoration({
    Color color = bgCard,
    double opacity = 0.4,
    double borderRadius = 16,
    double borderWidth = 1,
    Color borderColor = lobbyDivider,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
    );
  }

  static CasinoTableStyle getTableStyle(String themeName) {
    switch (themeName) {
      case 'neon_cyber':
        return const CasinoTableStyle(
          feltLight: Color(0xFF0F121C),
          feltDeep: Color(0xFF06070B),
          feltEdge: Color(0xFF010102),
          railColor: Color(0xFF15181E),
          highlightColor: Color(0xFF00E5FF),
          linePatternColor: Color(0xFFFF2E93),
          displayName: 'Neon Cyber',
        );
      case 'luxury_gold':
        return const CasinoTableStyle(
          feltLight: Color(0xFF282A2E),
          feltDeep: Color(0xFF18191B),
          feltEdge: Color(0xFF0A0A0B),
          railColor: Color(0xFF101010),
          highlightColor: Color(0xFFFFD700),
          linePatternColor: Color(0xFF8C6D30),
          displayName: 'Luxury Black Gold',
        );
      case 'emerald_casino':
        return const CasinoTableStyle(
          feltLight: Color(0xFF0D5E3A),
          feltDeep: Color(0xFF0A3A20),
          feltEdge: Color(0xFF03160D),
          railColor: Color(0xFF2B1A08),
          highlightColor: Color(0xFFFFD700),
          linePatternColor: Color(0xFF8C6D30),
          displayName: 'Emerald Casino',
        );
      case 'crimson_royale':
        return const CasinoTableStyle(
          feltLight: Color(0xFF800E13),
          feltDeep: Color(0xFF640D14),
          feltEdge: Color(0xFF38040E),
          railColor: Color(0xFF230007),
          highlightColor: Color(0xFFFFE066),
          linePatternColor: Color(0xFFAD801F),
          displayName: 'Crimson Royale',
        );
      case 'minimal_dark':
        return const CasinoTableStyle(
          feltLight: Color(0xFF1E293B),
          feltDeep: Color(0xFF0F172A),
          feltEdge: Color(0xFF020617),
          railColor: Color(0xFF1E293B),
          highlightColor: Color(0xFF94A3B8),
          linePatternColor: Color(0xFF1E293B),
          displayName: 'Minimal Dark',
        );
      case 'classic_vegas':
      default:
        return const CasinoTableStyle(
          feltLight: Color(0xFF0D5E3A),
          feltDeep: Color(0xFF0A3A20),
          feltEdge: Color(0xFF03160D),
          railColor: Color(0xFF2B1A08),
          highlightColor: Color(0xFF00E5FF),
          linePatternColor: Color(0xFF8C6D30),
          displayName: 'Classic Vegas',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Card Styles per Theme
  // ---------------------------------------------------------------------------
  static CasinoCardStyle getCardStyle(String themeName) {
    switch (themeName) {
      case 'neon_cyber':
        return const CasinoCardStyle(
          cardFaceColor: Color(0xFF0F111E),
          cardBackColor: Color(0xFF06070B),
          cardBorderColor: Color(0xFF00E5FF),
          suitRedColor: Color(0xFFFF2E93),     // Neon pink
          suitBlackColor: Color(0xFF00E5FF),   // Neon cyan
          cardCornerRadius: 10.0,
        );
      case 'luxury_gold':
        return const CasinoCardStyle(
          cardFaceColor: Color(0xFF15181F),
          cardBackColor: Color(0xFF0C0904),
          cardBorderColor: Color(0xFFFFD700),
          suitRedColor: Color(0xFFFF3344),     // Premium scarlet
          suitBlackColor: Color(0xFFFFD700),   // VIP gold
          cardCornerRadius: 8.0,
        );
      case 'crimson_royale':
        return const CasinoCardStyle(
          cardFaceColor: Color(0xFF1A0A0C),
          cardBackColor: Color(0xFF5C0B10),
          cardBorderColor: Color(0xFFFFD700),
          suitRedColor: Color(0xFFFF3B30),     // Royal crimson
          suitBlackColor: Color(0xFFD4AF37),   // Antique gold
          cardCornerRadius: 8.0,
        );
      case 'minimal_dark':
        return const CasinoCardStyle(
          cardFaceColor: Color(0xFF1E293B),
          cardBackColor: Color(0xFF0F172A),
          cardBorderColor: Color(0xFF6B7280),
          suitRedColor: Color(0xFFEF4444),     // Classic red
          suitBlackColor: Color(0xFFE2E8F0),   // Slate white
          cardCornerRadius: 6.0,
        );
      case 'emerald_casino':
      case 'classic_vegas':
      default:
        return const CasinoCardStyle(
          cardFaceColor: Color(0xFF0A1F15),
          cardBackColor: Color(0xFF03160D),
          cardBorderColor: Color(0xFFFFD700),
          suitRedColor: Color(0xFFFF4D4D),     // Vivid red
          suitBlackColor: Color(0xFFE2E8F0),   // Bright silver
          cardCornerRadius: 8.0,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Chip Styles per Theme
  // ---------------------------------------------------------------------------
  static CasinoChipStyle getChipStyle(String themeName) {
    switch (themeName) {
      case 'neon_cyber':
        return const CasinoChipStyle(
          chipBaseColor: Color(0xFF0D0F18),
          chipStripeColor: Color(0xFF00E5FF),
          chipBorderColor: Color(0xFFFF2E93),
          chipTextColor: Color(0xFF00E5FF),
        );
      case 'luxury_gold':
        return const CasinoChipStyle(
          chipBaseColor: Color(0xFF1A1608),
          chipStripeColor: Color(0xFFFFD700),
          chipBorderColor: Color(0xFFC5A059),
          chipTextColor: Color(0xFFFFE066),
        );
      case 'crimson_royale':
        return const CasinoChipStyle(
          chipBaseColor: Color(0xFF640D14),
          chipStripeColor: Color(0xFFFFE066),
          chipBorderColor: Color(0xFFAD801F),
          chipTextColor: Color(0xFFE2E8F0),
        );
      case 'minimal_dark':
        return const CasinoChipStyle(
          chipBaseColor: Color(0xFF374151),
          chipStripeColor: Color(0xFF9CA3AF),
          chipBorderColor: Color(0xFF6B7280),
          chipTextColor: Color(0xFF94A3B8),
        );
      case 'emerald_casino':
      case 'classic_vegas':
      default:
        return const CasinoChipStyle(
          chipBaseColor: Color(0xFF0A3A20),
          chipStripeColor: Color(0xFFFFD700),
          chipBorderColor: Color(0xFFC5A059),
          chipTextColor: Color(0xFFFFE066),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Animation Helpers
  // ---------------------------------------------------------------------------

  /// Creates a shimmer gradient for use in loading/shine effects.
  static LinearGradient shimmerGradient(Color baseColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withValues(alpha: 0.3),
        baseColor.withValues(alpha: 0.7),
        baseColor,
        baseColor.withValues(alpha: 0.7),
        baseColor.withValues(alpha: 0.3),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );
  }

  /// Returns a pulsing color that oscillates opacity based on [phase] (0.0 – 1.0).
  static Color pulseColor(Color color, double phase) {
    final double opacity = 0.5 + 0.5 * math.sin(phase * 2 * math.pi);
    return color.withValues(alpha: opacity.clamp(0.0, 1.0));
  }
}

class CasinoTableStyle {
  final Color feltLight;
  final Color feltDeep;
  final Color feltEdge;
  final Color railColor;
  final Color highlightColor;
  final Color linePatternColor;
  final String displayName;

  const CasinoTableStyle({
    required this.feltLight,
    required this.feltDeep,
    required this.feltEdge,
    required this.railColor,
    required this.highlightColor,
    required this.linePatternColor,
    required this.displayName,
  });
}

/// Visual style definition for playing cards, themed per casino table.
class CasinoCardStyle {
  final Color cardFaceColor;
  final Color cardBackColor;
  final Color cardBorderColor;
  final Color suitRedColor;
  final Color suitBlackColor;
  final double cardCornerRadius;

  const CasinoCardStyle({
    required this.cardFaceColor,
    required this.cardBackColor,
    required this.cardBorderColor,
    required this.suitRedColor,
    required this.suitBlackColor,
    this.cardCornerRadius = 8.0,
  });
}

/// Visual style definition for casino chips, themed per casino table.
class CasinoChipStyle {
  final Color chipBaseColor;
  final Color chipStripeColor;
  final Color chipBorderColor;
  final Color chipTextColor;

  const CasinoChipStyle({
    required this.chipBaseColor,
    required this.chipStripeColor,
    required this.chipBorderColor,
    required this.chipTextColor,
  });
}
