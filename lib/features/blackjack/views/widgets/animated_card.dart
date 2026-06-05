import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/models/card.dart';
import '../../../shared_casino/theme/casino_theme.dart';

class AnimatedCard extends StatefulWidget {
  final BlackjackCard card;
  final int index; // Stagger offset
  final double width;
  final double height;
  final String tableTheme;

  const AnimatedCard({
    super.key,
    required this.card,
    required this.index,
    required this.tableTheme,
    this.width = 64,
    this.height = 92,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _flipAnimation = Tween<double>(
      begin: pi,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.card.isFaceUp) {
      _controller.value = 1.0;
    } else {
      _controller.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.card.isFaceUp != oldWidget.card.isFaceUp) {
      if (widget.card.isFaceUp) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stagger entry: slide in from top right (shoe position)
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, slideVal, child) {
        return Transform.translate(
          // Slide from top-right shoe coordinates (approx 200, -200)
          offset: Offset(
            (250 * slideVal) + (widget.index * 15.0),
            (-200 * slideVal),
          ),
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(0.12) // Slight table tilt angle
              ..rotateY(_flipAnimation.value),
            alignment: Alignment.center,
            child: _flipAnimation.value >= pi / 2
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildCardBack(),
                  )
                : _buildCardFront(),
          ),
        );
      },
    );
  }

  Widget _buildCardFront() {
    final cardStyle = CasinoTheme.getCardStyle(widget.tableTheme);
    final isRed = widget.card.suit.isRed;
    final suitSymbol = widget.card.suit.symbol;
    final label = widget.card.rank.label;
    final suitColor = isRed ? cardStyle.suitRedColor : cardStyle.suitBlackColor;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: cardStyle.cardFaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.card.rank.value >= 10
              ? CasinoTheme.primaryGold
              : cardStyle.cardBorderColor.withValues(alpha: 0.35),
          width: widget.card.rank.value >= 10 ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
          if (widget.card.rank.value >= 10)
            ...CasinoTheme.neonGlow(color: CasinoTheme.primaryGold, radius: 1.5),
        ],
      ),
      padding: const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          // Upper-left rank and suit
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: suitColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                Text(
                  suitSymbol,
                  style: TextStyle(
                    color: suitColor,
                    fontSize: 10,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // Large Center suit icon
          Center(
            child: Text(
              suitSymbol,
              style: TextStyle(
                color: suitColor,
                fontSize: widget.card.rank.value >= 10 ? 28 : 22,
              ),
            ),
          ),
          // Bottom-right flipped rank and suit
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: pi,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: suitColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    suitSymbol,
                    style: TextStyle(
                      color: suitColor,
                      fontSize: 10,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    final cardStyle = CasinoTheme.getCardStyle(widget.tableTheme);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: cardStyle.cardBackColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cardStyle.cardBorderColor.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(2, 4),
          ),
          ...CasinoTheme.neonGlow(color: cardStyle.cardBorderColor, radius: 2),
        ],
      ),
      child: Center(
        child: Container(
          width: widget.width - 12,
          height: widget.height - 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: CasinoTheme.primaryGold.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Geometric line patterns representing high-end back
              Positioned.fill(
                child: CustomPaint(
                  painter: _CardBackGeometricPainter(borderColor: cardStyle.cardBorderColor),
                ),
              ),
              const Icon(
                Icons.casino,
                color: CasinoTheme.primaryGold,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBackGeometricPainter extends CustomPainter {
  final Color borderColor;

  _CardBackGeometricPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor.withValues(alpha: 0.15)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw diamond grid lines
    const int step = 8;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(size.width, size.height - i * (size.height / size.width)), paint);
      canvas.drawLine(Offset(0, i * (size.height / size.width)), Offset(size.width - i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
