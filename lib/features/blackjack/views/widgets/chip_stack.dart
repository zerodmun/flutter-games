import 'package:flutter/material.dart';
import '../../../shared_casino/theme/casino_theme.dart';

enum ChipValue {
  ten(10, Color(0xFFE2E8F0), Color(0xFF1E293B)),   // White/Silver
  twentyFive(25, Color(0xFF10B981), Colors.white), // Green
  oneHundred(100, Color(0xFF1E1B4B), Colors.white), // Black
  fiveHundred(500, Color(0xFF8B5CF6), Colors.white); // Purple

  final double value;
  final Color color;
  final Color textColor;
  const ChipValue(this.value, this.color, this.textColor);
}

class BetChip extends StatelessWidget {
  final ChipValue chip;
  final double size;
  final VoidCallback? onTap;
  final bool isSelected;

  const BetChip({
    super.key,
    required this.chip,
    this.size = 50.0,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              chip.color,
              chip.color.withValues(alpha: 0.85),
              chip.color.withValues(alpha: 0.7),
            ],
          ),
          border: Border.all(
            color: isSelected ? CasinoTheme.accentNeonCyan : CasinoTheme.tableBorderGold,
            width: isSelected ? 3.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(1, 3),
            ),
            if (isSelected)
              ...CasinoTheme.neonGlow(color: CasinoTheme.accentNeonCyan, radius: 4),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dotted outer casino ring
            Positioned.fill(
              child: CustomPaint(
                painter: _ChipBorderPainter(color: chip.textColor.withValues(alpha: 0.35)),
              ),
            ),
            // Inner Core Circle
            Container(
              width: size * 0.6,
              height: size * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black26,
                border: Border.all(
                  color: chip.textColor.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '\$${chip.value.toInt()}',
                style: TextStyle(
                  color: chip.textColor,
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChipStack extends StatelessWidget {
  final double totalBet;
  final double chipSize;

  const ChipStack({
    super.key,
    required this.totalBet,
    this.chipSize = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    if (totalBet <= 0) return const SizedBox.shrink();

    // Deconstruct the totalBet value into chips
    final List<ChipValue> chipsToRender = [];
    double remaining = totalBet;

    // Greedy deconstruction
    final sortedChips = ChipValue.values.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (var c in sortedChips) {
      while (remaining >= c.value) {
        chipsToRender.add(c);
        remaining -= c.value;
      }
    }

    // Limit maximum stacked chips visually to 5 so it doesn't overflow screen
    final visibleChips = chipsToRender.take(5).toList();

    return SizedBox(
      width: chipSize + (visibleChips.length * 1.5),
      height: chipSize + (visibleChips.length * 4.0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: List.generate(visibleChips.length, (index) {
          final chip = visibleChips[index];
          // Offset each chip upwards slightly to create 3D stacking effect
          final double bottomOffset = index * 4.0;
          return Positioned(
            bottom: bottomOffset,
            child: BetChip(
              chip: chip,
              size: chipSize,
            ),
          );
        }),
      ),
    );
  }
}

class _ChipBorderPainter extends CustomPainter {
  final Color color;
  _ChipBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double center = size.width / 2;
    final double radius = (size.width / 2) - 4.5;

    // Draw a dashed circle
    const int dashCount = 8;
    final double dashAngle = (2 * 3.14159) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final double angle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(center, center), radius: radius),
        angle,
        dashAngle * 0.4,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
