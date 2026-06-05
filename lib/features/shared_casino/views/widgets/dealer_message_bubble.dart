import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/casino_theme.dart';
import '../../services/dealer_service.dart';

/// A premium glassmorphic bubble that displays dealer commentary with
/// an animated typing effect, mood-driven accent colors, and auto-fade.
///
/// Place this widget anywhere in the game layout:
/// ```dart
/// DealerMessageBubble(
///   message: dealerService.getBlackjackMessage(...),
///   mood: dealerService.currentMood,
///   displayDuration: const Duration(seconds: 4),
/// )
/// ```
class DealerMessageBubble extends StatefulWidget {
  /// The message to display with a typing animation.
  final String message;

  /// Current dealer mood — drives accent color & subtle styling.
  final DealerMood mood;

  /// How long the fully-typed message stays visible before fading out.
  /// Defaults to 4 seconds.
  final Duration displayDuration;

  /// Speed of the typing animation per character.
  /// Defaults to 35 ms per character.
  final Duration typingSpeed;

  /// Optional callback fired after the bubble has fully faded out.
  final VoidCallback? onDismissed;

  const DealerMessageBubble({
    super.key,
    required this.message,
    this.mood = DealerMood.neutral,
    this.displayDuration = const Duration(seconds: 4),
    this.typingSpeed = const Duration(milliseconds: 35),
    this.onDismissed,
  });

  @override
  State<DealerMessageBubble> createState() => _DealerMessageBubbleState();
}

class _DealerMessageBubbleState extends State<DealerMessageBubble>
    with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Controllers & State
  // ---------------------------------------------------------------------------

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  Timer? _typingTimer;
  Timer? _dismissTimer;

  /// The portion of [widget.message] currently visible (typing effect).
  String _visibleText = '';

  /// Index of the next character to reveal.
  int _charIndex = 0;

  /// Whether the typing animation has completed.
  bool _typingComplete = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Fade in and start typing.
    _fadeController.forward();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant DealerMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the message changed, restart the whole animation cycle.
    if (oldWidget.message != widget.message) {
      _reset();
      _fadeController.forward();
      _startTyping();
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _dismissTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Animation Logic
  // ---------------------------------------------------------------------------

  /// Resets all animation state for a fresh message.
  void _reset() {
    _typingTimer?.cancel();
    _dismissTimer?.cancel();
    _charIndex = 0;
    _visibleText = '';
    _typingComplete = false;
    _fadeController.value = 0.0;
  }

  /// Starts the per-character typing animation.
  void _startTyping() {
    if (widget.message.isEmpty) {
      _typingComplete = true;
      _scheduleDismiss();
      return;
    }

    _typingTimer = Timer.periodic(widget.typingSpeed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_charIndex < widget.message.length) {
        setState(() {
          _charIndex++;
          _visibleText = widget.message.substring(0, _charIndex);
        });
      } else {
        timer.cancel();
        _typingComplete = true;
        _scheduleDismiss();
      }
    });
  }

  /// Schedules the fade-out after [widget.displayDuration].
  void _scheduleDismiss() {
    _dismissTimer = Timer(widget.displayDuration, () {
      if (!mounted) return;
      _fadeController.reverse().then((_) {
        widget.onDismissed?.call();
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Mood → Accent Color Mapping
  // ---------------------------------------------------------------------------

  /// Returns an accent [Color] appropriate for the current [DealerMood].
  Color _accentColorForMood(DealerMood mood) {
    switch (mood) {
      case DealerMood.neutral:
        return CasinoTheme.accentNeonCyan;
      case DealerMood.excited:
        return CasinoTheme.primaryGold;
      case DealerMood.dramatic:
        return CasinoTheme.neonPink;
      case DealerMood.tense:
        return const Color(0xFFFF6B35); // Amber-orange tension.
      case DealerMood.congratulatory:
        return const Color(0xFF00E676); // Vibrant green success.
      case DealerMood.sympathetic:
        return const Color(0xFF7C8FFF); // Soft indigo comfort.
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColorForMood(widget.mood);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: FadeTransition(
        key: ValueKey<String>(widget.message),
        opacity: _fadeAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            // Glassmorphic backdrop.
            color: CasinoTheme.bgCard.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              // Outer accent glow.
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 2,
              ),
              // Inner depth shadow.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Accent pip / mood indicator.
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: CasinoTheme.neonGlow(
                    color: accentColor,
                    radius: 6,
                  ),
                ),
              ),

              // Message text with typing cursor.
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _visibleText,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CasinoTheme.textLight,
                          height: 1.4,
                          letterSpacing: 0.3,
                        ),
                      ),
                      // Blinking cursor while typing.
                      if (!_typingComplete)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _TypingCursor(color: accentColor),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Blinking Cursor
// =============================================================================

/// A small blinking cursor widget shown during the typing animation.
class _TypingCursor extends StatefulWidget {
  final Color color;

  const _TypingCursor({required this.color});

  @override
  State<_TypingCursor> createState() => _TypingCursorState();
}

class _TypingCursorState extends State<_TypingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blinkController,
      child: Container(
        width: 2,
        height: 18,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
