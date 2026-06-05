import 'package:flutter/material.dart';
import '../../../shared_casino/theme/casino_theme.dart';

class PokerTableFeltPainter extends CustomPainter {
  final String theme;

  PokerTableFeltPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final style = CasinoTheme.getTableStyle(theme);

    // 1. Felt Radial Background
    final feltPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.0,
        colors: [style.feltLight, style.feltDeep, style.feltEdge],
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
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.11, 0, size.height * 0.08)
      ..close();
    canvas.drawPath(railPath, railPaint);

    // Rail separator border
    final goldBorderPaint = Paint()
      ..color = theme.contains('dark') || theme.contains('cyber') ? style.highlightColor : CasinoTheme.tableBorderGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final Path goldBorderPath = Path()
      ..moveTo(0, size.height * 0.08)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.11, size.width, size.height * 0.08);
    canvas.drawPath(goldBorderPath, goldBorderPaint);

    // Neon glow line under the border
    final neonPaint = Paint()
      ..color = style.highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(goldBorderPath, neonPaint);

    // 3. Central Large Ellipse betting line (The Poker ring)
    final ringPaint = Paint()
      ..color = style.linePatternColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.45),
        width: size.width * 0.82,
        height: size.height * 0.52,
      ),
      ringPaint,
    );

    // 4. Central Community Card Slots zones
    final slotPaint = Paint()
      ..color = style.linePatternColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double slotW = 54;
    final double slotH = 76;
    final double spacing = 8;
    final double startX = (size.width - (5 * slotW + 4 * spacing)) / 2;
    final double centerY = size.height * 0.38;

    for (int i = 0; i < 5; i++) {
      final x = startX + i * (slotW + spacing);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, centerY - (slotH / 2), slotW, slotH),
          const Radius.circular(6),
        ),
        slotPaint,
      );
    }

    // 5. Poker Room Branding Typography
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      text: 'TEXAS HOLD\'EM POKER',
      style: TextStyle(
        color: (theme.contains('cyber') ? style.highlightColor : CasinoTheme.primaryGold).withValues(alpha: 0.75),
        fontSize: 14,
        fontWeight: FontWeight.w900,
        letterSpacing: 4.0,
      ),
    );
    textPainter.layout(minWidth: size.width);
    textPainter.paint(canvas, Offset(0, centerY + (slotH / 2) + 14));

    // Blinds & Stakes info label
    textPainter.text = TextSpan(
      text: 'No Limit • Pot-Limit Side Pots Active',
      style: TextStyle(
        color: CasinoTheme.textMuted.withValues(alpha: 0.5),
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
    textPainter.layout(minWidth: size.width);
    textPainter.paint(canvas, Offset(0, centerY + (slotH / 2) + 36));
  }

  @override
  bool shouldRepaint(covariant PokerTableFeltPainter oldDelegate) {
    return oldDelegate.theme != theme;
  }
}
