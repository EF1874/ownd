import 'package:flutter/material.dart';

/// Centralized color palette for Ownd — Cyber Minimal design language.
/// All colors are defined here to avoid hardcoding across widgets.
class AppColors {
  AppColors._();

  // ─── Primary Palette ─────────────────────────────────────
  static const cyberMint = Color(0xFF4FD1C5); // Soft Teal
  static const electricViolet = Color(0xFF818CF8); // Soft Indigo
  static const neonCoral = Color(0xFFFC8181); // Soft Rose

  // ─── Dark Mode Surfaces ──────────────────────────────────
  static const deepSpace = Color(0xFF1E293B); // Slate 800
  static const charcoal = Color(0xFF334155); // Slate 700
  static const graphite = Color(0xFF475569); // Slate 600
  static const slate = Color(0xFF64748B); // Slate 500

  // ─── Light Mode Surfaces ─────────────────────────────────
  static const snow = Color(0xFFF8FAFC);
  static const frost = Color(0xFFF1F5F9);
  static const cloud = Color(0xFFE2E8F0);

  // ─── Text Colors ─────────────────────────────────────────
  static const silver = Color(0xFFF1F5F9);
  static const ash = Color(0xFF94A3B8);
  static const ink = Color(0xFF334155);
  static const dimInk = Color(0xFF64748B);

  // ─── Semantic Colors ─────────────────────────────────────
  static const success = Color(0xFF4FD1C5);
  static const warning = Color(0xFFF6AD55);
  static const danger = Color(0xFFFC8181);
  static const info = Color(0xFF818CF8);

  // ─── Gradients ────────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    colors: [cyberMint, electricViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [electricViolet, neonCoral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Border / Glow ────────────────────────────────────────
  static Color darkBorder = Colors.white.withValues(alpha: 0.06);
  static Color lightBorder = Colors.black.withValues(alpha: 0.06);
  static Color glowMint = cyberMint.withValues(alpha: 0.15);
  static Color glowViolet = electricViolet.withValues(alpha: 0.15);
}
