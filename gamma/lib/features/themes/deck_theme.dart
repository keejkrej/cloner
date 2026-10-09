import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeckTheme {
  final String id;
  final String name;
  final LinearGradient backgroundGradient;
  final Color cardBackground;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final TextStyle Function({TextStyle? textStyle}) titleFont;
  final TextStyle Function({TextStyle? textStyle}) bodyFont;
  final bool isDark;

  const DeckTheme({
    required this.id,
    required this.name,
    required this.backgroundGradient,
    required this.cardBackground,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.titleFont,
    required this.bodyFont,
    required this.isDark,
  });

  static final List<DeckTheme> themes = [
    // 1. Modern Dark (Slate & Cyan)
    DeckTheme(
      id: 'modern_dark',
      name: 'Modern Dark',
      backgroundGradient: const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardBackground: const Color(0xFF1E293B),
      primaryTextColor: const Color(0xFFF8FAFC),
      secondaryTextColor: const Color(0xFF94A3B8),
      accentColor: const Color(0xFF38BDF8),
      titleFont: GoogleFonts.inter,
      bodyFont: GoogleFonts.inter,
      isDark: true,
    ),

    // 2. Minimal Light (Porcelain & Emerald)
    DeckTheme(
      id: 'minimal_light',
      name: 'Minimal Light',
      backgroundGradient: const LinearGradient(
        colors: [Color(0xFFF8FAFC), Color(0xFFEDF2F7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      cardBackground: Colors.white,
      primaryTextColor: const Color(0xFF0F172A),
      secondaryTextColor: const Color(0xFF64748B),
      accentColor: const Color(0xFF10B981),
      titleFont: GoogleFonts.plusJakartaSans,
      bodyFont: GoogleFonts.plusJakartaSans,
      isDark: false,
    ),

    // 3. Midnight Nebula (Cyberpunk Magenta & Violet)
    DeckTheme(
      id: 'midnight_nebula',
      name: 'Midnight Nebula',
      backgroundGradient: const LinearGradient(
        colors: [Color(0xFF0D091A), Color(0xFF23113D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardBackground: const Color(0xFF1C1333),
      primaryTextColor: const Color(0xFFFDF4FF),
      secondaryTextColor: const Color(0xFFC084FC),
      accentColor: const Color(0xFFE879F9),
      titleFont: GoogleFonts.spaceGrotesk,
      bodyFont: GoogleFonts.spaceGrotesk,
      isDark: true,
    ),

    // 4. Warm Terracotta (Editorial Serif & Amber)
    DeckTheme(
      id: 'warm_terracotta',
      name: 'Warm Terracotta',
      backgroundGradient: const LinearGradient(
        colors: [Color(0xFFFBF6F0), Color(0xFFF3E9DD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardBackground: const Color(0xFFEFE2D3),
      primaryTextColor: const Color(0xFF2C1E1A),
      secondaryTextColor: const Color(0xFF785E54),
      accentColor: const Color(0xFFC05621),
      titleFont: GoogleFonts.playfairDisplay,
      bodyFont: GoogleFonts.lora,
      isDark: false,
    ),
  ];

  static DeckTheme getById(String id) {
    return themes.firstWhere(
      (t) => t.id == id,
      orElse: () => themes.first,
    );
  }
}
