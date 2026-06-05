import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CasinoButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const CasinoButton({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<CasinoButton> createState() => _CasinoButtonState();
}

class _CasinoButtonState extends State<CasinoButton> with SingleTickerProviderStateMixin {
  late double _scale;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      lowerBound: 0.0,
      upperBound: 0.08,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1.0 - _controller.value;

    return GestureDetector(
      onTapDown: widget.enabled && widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.enabled && widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.enabled && widget.onTap != null ? _onTapCancel : null,
      child: Transform.scale(
        scale: _scale,
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.4,
          child: widget.child,
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onTap != null) widget.onTap!();
  }

  void _onTapCancel() {
    _controller.reverse();
  }
}
