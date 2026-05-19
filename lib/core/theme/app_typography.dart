import 'package:flutter/material.dart';

/// Typography system for Ownd — uses system fonts with monospace
/// for numeric displays to achieve a geek aesthetic.
///
/// Future enhancement: add Google Fonts (Inter, JetBrains Mono)
/// when bundling fonts. For now, use platform defaults + monospace.
class AppTypography {
  AppTypography._();

  // ─── Font Families ────────────────────────────────────────
  // Using platform default for body text.
  // Monospace for numbers/costs to give a "terminal" feel.
  static const String monoFamily = 'monospace';

  // ─── Display (Large numbers, hero text) ───────────────────
  static TextStyle displayLarge(BuildContext context) => Theme.of(context)
      .textTheme
      .displayLarge!
      .copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.5);

  // ─── Headlines ────────────────────────────────────────────
  static TextStyle headlineLarge(BuildContext context) => Theme.of(context)
      .textTheme
      .headlineLarge!
      .copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.5);

  static TextStyle headlineMedium(BuildContext context) => Theme.of(
    context,
  ).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w600);

  // ─── Money / Numbers (Monospace for geek look) ────────────
  static TextStyle moneyLarge(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
        fontFamily: monoFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle moneyMedium(BuildContext context) => Theme.of(context)
      .textTheme
      .titleMedium!
      .copyWith(fontFamily: monoFamily, fontWeight: FontWeight.w600);

  static TextStyle moneySmall(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyMedium!
      .copyWith(fontFamily: monoFamily, fontWeight: FontWeight.w500);

  // ─── Labels ───────────────────────────────────────────────
  static TextStyle labelSmall(BuildContext context) => Theme.of(context)
      .textTheme
      .labelSmall!
      .copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.5);

  static TextStyle labelMedium(BuildContext context) => Theme.of(
    context,
  ).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500);

  // ─── Body ─────────────────────────────────────────────────
  static TextStyle bodyLarge(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w400);

  static TextStyle bodyMedium(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w400);
}
