import 'package:flutter/material.dart';
import '../../theme/casino_theme.dart';
import '../../audio/audio_service.dart';
import 'casino_button.dart';

class ExitConfirmationDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onLeave;
  final VoidCallback onRestart;
  final String title;

  const ExitConfirmationDialog({
    super.key,
    required this.onResume,
    required this.onLeave,
    required this.onRestart,
    this.title = 'EXIT TABLE',
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onResume,
    required VoidCallback onLeave,
    required VoidCallback onRestart,
    String title = 'EXIT TABLE',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => ExitConfirmationDialog(
        onResume: onResume,
        onLeave: onLeave,
        onRestart: onRestart,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AudioService audio = AudioService();

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CasinoTheme.tableBorderGold.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: CasinoTheme.primaryGold.withValues(alpha: 0.1),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Crown / Warning Icon
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CasinoTheme.primaryGold.withValues(alpha: 0.1),
                  border: Border.all(color: CasinoTheme.primaryGold, width: 1.5),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: CasinoTheme.primaryGold,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),

              // 2. Title
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // 3. Subtitle
              const Text(
                'Are you sure you want to exit the game? If you leave, your current balance will be saved. You can also restart the match or resume playing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // 4. Action Buttons Stack
              // OPTION A: Resume Game (Premium Accent Glow)
              CasinoButton(
                onTap: () {
                  audio.playClick();
                  Navigator.pop(context); // Dismiss dialog
                  onResume();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: CasinoTheme.feltGreenLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                        color: CasinoTheme.feltGreenLight.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'RESUME GAME',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // OPTION B: Restart Match (Secondary Gold)
              CasinoButton(
                onTap: () {
                  audio.playClick();
                  Navigator.pop(context); // Dismiss dialog
                  onRestart();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CasinoTheme.tableBorderGold.withValues(alpha: 0.6)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'RESTART MATCH',
                    style: TextStyle(
                      color: CasinoTheme.primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // OPTION C: Leave Table (Negative Crimson Red)
              CasinoButton(
                onTap: () {
                  audio.playClick();
                  Navigator.pop(context); // Dismiss dialog
                  onLeave();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'LEAVE TABLE',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
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
