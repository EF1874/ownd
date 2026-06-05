import 'dart:async';
import 'package:flutter/material.dart';

/// A premium, custom Toast utility that shows overlay toast notifications.
/// Automatically wraps around text content, centers, and fades/scales in and out.
class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _currentTimer;
  static AnimationController? _currentController;

  /// Show a toast notification that wraps around text.
  /// Set [isError] to true to show a red error toast.
  static void show(BuildContext context, String message, {bool isError = false}) {
    // Dismiss any active toast immediately
    dismiss();

    final overlayState = Overlay.of(context);
    
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        isError: isError,
        onCreated: (controller) {
          _currentController = controller;
        },
        onDismissed: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
            _currentController = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  /// Dismiss the current toast immediately with fade-out animation.
  static void dismiss() {
    _currentTimer?.cancel();
    _currentTimer = null;
    
    final entry = _currentEntry;
    final controller = _currentController;
    if (entry != null && controller != null) {
      controller.reverse().then((_) {
        try {
          entry.remove();
        } catch (_) {}
        if (_currentEntry == entry) {
          _currentEntry = null;
          _currentController = null;
        }
      });
    }
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final ValueChanged<AnimationController> onCreated;
  final VoidCallback onDismissed;

  const _ToastWidget({
    required this.message,
    required this.isError,
    required this.onCreated,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    widget.onCreated(_controller);
    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final bgColor = (widget.isError
        ? Colors.red
        : theme.colorScheme.inverseSurface).withValues(alpha: 0.745);
        
    final textColor = widget.isError
        ? Colors.white
        : theme.colorScheme.onInverseSurface;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
