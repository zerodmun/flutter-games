import 'package:flutter/material.dart';

class CircularCountdownTimer extends StatelessWidget {
  final int timeLeft;
  final int totalDuration;
  final double size;
  final Color activeColor;

  const CircularCountdownTimer({
    super.key,
    required this.timeLeft,
    required this.totalDuration,
    this.size = 28.0,
    this.activeColor = const Color(0xFF00E5FF),
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = (timeLeft / totalDuration).clamp(0.0, 1.0);
    final bool isLowTime = timeLeft <= 3;
    final Color color = isLowTime ? const Color(0xFFFF2E93) : activeColor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background grey ring track
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 2.5,
            color: Colors.white12,
          ),
          // Active timer countdown ring
          CircularProgressIndicator(
            value: ratio,
            strokeWidth: 2.5,
            color: color,
            backgroundColor: Colors.transparent,
          ),
          // Countdown number
          Text(
            '$timeLeft',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
