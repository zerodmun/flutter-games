import 'package:flutter/material.dart';
import '../../../shared_casino/theme/casino_theme.dart';

class TableFeltPainter extends CustomPainter {
  final String theme;

  TableFeltPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final style = CasinoTheme.getTableStyle(theme);

    // 1. Felt Background Base Radial Gradient
    final feltPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.4),
        radius: 1.0,
        colors: [
          style.feltLight,
          style.feltDeep,
          style.feltEdge,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, feltPaint);

    // 2. Table Rail Rim at the top
    final railPaint = Paint()
      ..color = style.railColor
      ..style = PaintingStyle.fill;
    
    final Path railPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.08)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.12, 0, size.height * 0.08)
      ..close();
    canvas.drawPath(railPath, railPaint);

    // Rim separator line
    final goldBorderPaint = Paint()
      ..color = theme.contains('dark') || theme.contains('cyber') ? style.highlightColor : CasinoTheme.tableBorderGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Path goldBorderPath = Path()
      ..moveTo(0, size.height * 0.08)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.12, size.width, size.height * 0.08);
    canvas.drawPath(goldBorderPath, goldBorderPaint);

    // Neon glow line under the rail
    final neonPaint = Paint()
      ..color = style.highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawPath(goldBorderPath, neonPaint);

    // 3. Dealer Card Slot Outline
    final dealerBoxPaint = Paint()
      ..color = style.linePatternColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final double boxWidth = 90;
    final double boxHeight = 125;
    final double centerX = size.width / 2;
    final double dealerY = size.height * 0.22;

    // Draw card outlines
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX - 40, dealerY), width: boxWidth, height: boxHeight),
        const Radius.circular(8),
      ),
      dealerBoxPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX + 40, dealerY), width: boxWidth, height: boxHeight),
        const Radius.circular(8),
      ),
      dealerBoxPaint,
    );

    // 4. Large Curved Betting Arc for Players
    final arcPaint = Paint()
      ..color = style.linePatternColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(
      Rect.fromLTRB(size.width * 0.1, size.height * 0.15, size.width * 0.9, size.height * 0.85),
      3.14,
      -3.14,
      false,
      arcPaint,
    );

    // 5. Casino typography Rules (Painted on the Felt)
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Text: BLACKJACK PAYS 3 TO 2
    textPainter.text = TextSpan(
      text: 'BLACKJACK PAYS 3 TO 2',
      style: TextStyle(
        color: (theme.contains('cyber') ? style.highlightColor : CasinoTheme.primaryGold).withValues(alpha: 0.85),
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
    textPainter.layout(minWidth: size.width);
    textPainter.paint(canvas, Offset(0, size.height * 0.38));

    // Text: Dealer must stand on 17 and draw to 16
    textPainter.text = TextSpan(
      text: 'Dealer must stand on all 17s • Insurance pays 2 to 1',
      style: TextStyle(
        color: CasinoTheme.textLight.withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.0,
      ),
    );
    textPainter.layout(minWidth: size.width);
    textPainter.paint(canvas, Offset(0, size.height * 0.44));

    // Text: Insurance Line Arc
    textPainter.text = TextSpan(
      text: 'INSURANCE PAYS 2 TO 1',
      style: TextStyle(
        color: style.linePatternColor,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 3.0,
      ),
    );
    textPainter.layout(minWidth: size.width);
    textPainter.paint(canvas, Offset(0, size.height * 0.53));
  }

  @override
  bool shouldRepaint(covariant TableFeltPainter oldDelegate) {
    return oldDelegate.theme != theme;
  }
}
