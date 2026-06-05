import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/casino_theme.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final IconData icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.icon,
  });
}

class ProgressionService {
  static final ProgressionService _instance = ProgressionService._internal();
  factory ProgressionService() => _instance;
  ProgressionService._internal();

  int _xp = 0;
  int _streak = 0;
  List<String> _completedAchievements = [];

  int get xp => _xp;
  int get streak => _streak;
  List<String> get completedAchievements => _completedAchievements;

  // Level is derived: every 500 XP is 1 level
  int get level => (_xp ~/ 500) + 1;
  double get levelProgress => (_xp % 500) / 500.0;
  int get xpToNextLevel => 500 - (_xp % 500);

  final List<Achievement> achievementsList = const [
    Achievement(
      id: 'first_win',
      title: 'First Win',
      description: 'Win any round of Blackjack or Poker.',
      xpReward: 100,
      icon: Icons.emoji_events,
    ),
    Achievement(
      id: 'high_roller',
      title: 'High Roller',
      description: 'Place a bet of \$500 or more.',
      xpReward: 150,
      icon: Icons.monetization_on,
    ),
    Achievement(
      id: 'blackjack_elite',
      title: 'Blackjack Elite',
      description: 'Get a natural 21 Blackjack.',
      xpReward: 200,
      icon: Icons.style,
    ),
    Achievement(
      id: 'poker_royal',
      title: 'Poker Royal',
      description: 'Win a Poker hand with three of a kind or better.',
      xpReward: 250,
      icon: Icons.workspace_premium,
    ),
    Achievement(
      id: 'streak_master',
      title: 'Streak Master',
      description: 'Reach a 3-game winning streak.',
      xpReward: 150,
      icon: Icons.whatshot,
    ),
    Achievement(
      id: 'level_three',
      title: 'High Society',
      description: 'Reach Level 3 in the casino.',
      xpReward: 200,
      icon: Icons.stars,
    ),
  ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt('casino_xp') ?? 0;
    _streak = prefs.getInt('casino_streak') ?? 0;
    _completedAchievements = prefs.getStringList('casino_achievements') ?? [];
  }

  Future<void> addXp(int amount, [BuildContext? context]) async {
    if (amount <= 0) return;
    
    final oldLevel = level;
    _xp += amount;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('casino_xp', _xp);

    if (context != null && context.mounted && level > oldLevel) {
      _showLevelUpBanner(context, level);
      
      // Auto unlock Level 3 achievement
      if (level >= 3) {
        await completeAchievement('level_three', context);
      }
    }
  }

  Future<void> completeAchievement(String id, [BuildContext? context]) async {
    if (_completedAchievements.contains(id)) return;

    final achievement = achievementsList.firstWhere((a) => a.id == id, orElse: () => achievementsList.first);
    _completedAchievements.add(id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('casino_achievements', _completedAchievements);

    if (context != null && context.mounted) {
      _showAchievementBanner(context, achievement);
    }
    
    if (context != null && context.mounted) {
      await addXp(achievement.xpReward, context);
    } else {
      await addXp(achievement.xpReward);
    }
  }

  Future<void> recordWin([BuildContext? context]) async {
    _streak++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('casino_streak', _streak);

    if (_streak >= 3) {
      if (context != null && context.mounted) {
        await completeAchievement('streak_master', context);
      } else {
        await completeAchievement('streak_master');
      }
    }
  }

  Future<void> recordLoss() async {
    _streak = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('casino_streak', 0);
  }

  bool isThemeUnlocked(String themeName) {
    return level >= getRequiredLevel(themeName);
  }

  int getRequiredLevel(String themeName) {
    switch (themeName) {
      case 'classic_vegas':
        return 1;
      case 'emerald_casino':
        return 2;
      case 'neon_cyber':
        return 3;
      case 'crimson_royale':
        return 4;
      case 'luxury_gold':
        return 5;
      case 'minimal_dark':
        return 6;
      default:
        return 1;
    }
  }

  Future<void> resetAll() async {
    _xp = 0;
    _streak = 0;
    _completedAchievements = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('casino_xp', 0);
    await prefs.setInt('casino_streak', 0);
    await prefs.setStringList('casino_achievements', []);
  }

  void _showLevelUpBanner(BuildContext context, int newLevel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.stars, color: CasinoTheme.primaryGold, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LEVEL UP!',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: CasinoTheme.primaryGold, letterSpacing: 1.5),
                  ),
                  Text(
                    'You are now Level $newLevel! New felt themes unlocked.',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F1E15),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CasinoTheme.primaryGold, width: 1.5),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showAchievementBanner(BuildContext context, Achievement achievement) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(achievement.icon, color: CasinoTheme.accentNeonCyan, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACHIEVEMENT UNLOCKED!',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: CasinoTheme.accentNeonCyan, letterSpacing: 1.5),
                  ),
                  Text(
                    '${achievement.title}: ${achievement.description}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '+${achievement.xpReward} XP Reward',
                    style: const TextStyle(color: CasinoTheme.textGold, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0E1B24),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CasinoTheme.accentNeonCyan, width: 1.5),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
