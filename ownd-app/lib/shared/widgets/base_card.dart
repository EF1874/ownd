import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_image.dart';

/// A themed card with optional glass-morphism effect and glow border.
///
/// Usage:
/// - Default: standard themed card
/// - `variant: CardVariant.glass`: frosted glass background
/// - `variant: CardVariant.glow`: subtle neon glow border
class BaseCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final String? backgroundImagePath;
  final CardVariant variant;

  const BaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.color,
    this.backgroundImagePath,
    this.variant = CardVariant.standard,
  });

  @override
  State<BaseCard> createState() => _BaseCardState();
}

class _BaseCardState extends State<BaseCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = Padding(
      padding: widget.padding ?? const EdgeInsets.all(16.0),
      child: widget.child,
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      cardContent = InkWell(
        borderRadius: BorderRadius.circular(16),
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: cardContent,
      );
    }

    Widget cardVariant;
    switch (widget.variant) {
      case CardVariant.glass:
        cardVariant = _buildGlassCard(
          context,
          widget.backgroundImagePath != null || isDark,
          cardContent,
        );
        break;
      case CardVariant.glow:
        cardVariant = _buildGlowCard(context, isDark, cardContent);
        break;
      case CardVariant.standard:
        cardVariant = Card(color: widget.color, child: cardContent);
        break;
    }

    if (widget.backgroundImagePath != null) {
      cardVariant = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AppImage(path: widget.backgroundImagePath!),
            ),
          ),
          cardVariant,
        ],
      );
    }

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.fastOutSlowIn,
      child: cardVariant,
    );
  }

  Widget _buildGlassCard(
    BuildContext context,
    bool useDarkGlass,
    Widget cardContent,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: useDarkGlass
                ? AppColors.charcoal.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.70),
            border: Border.all(
              color: useDarkGlass
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: cardContent,
        ),
      ),
    );
  }

  Widget _buildGlowCard(BuildContext context, bool isDark, Widget cardContent) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: AppColors.cyberMint.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Card(color: widget.color, child: cardContent),
    );
  }
}

enum CardVariant { standard, glass, glow }
