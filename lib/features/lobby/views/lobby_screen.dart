import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared_casino/theme/casino_theme.dart';
import '../../shared_casino/audio/audio_service.dart';
import '../../shared_casino/views/widgets/animated_casino_background.dart';
import 'blackjack_lobby_screen.dart';
import 'poker_lobby_screen.dart';
import '../../shared_casino/services/progression_service.dart';
import '../../profile/views/profile_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../../shop/views/shop_screen.dart';
import '../../arrows/views/arrows_lobby_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> with TickerProviderStateMixin {
  final AudioService _audio = AudioService();
  final ProgressionService _progression = ProgressionService();
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  double _balance = 1000.0;
  int _blackjackRounds = 0;
  int _pokerRounds = 0;
  int _blackjackWins = 0;
  int _pokerWins = 0;
  int _arrowsCompleted = 0;

  // Daily bonus state
  bool _dailyBonusClaimed = false;

  // Recent activity
  List<Map<String, dynamic>> _recentActivity = [];

  // Custom Avatar & Player Name state
  final List<String> _vipTitles = ['Vegas VIP', 'High Roller', 'Card Shark', 'Lady Luck'];
  int _vipTitleIndex = 0;
  final List<IconData> _vipIcons = [Icons.stars, Icons.monetization_on, Icons.style, Icons.favorite];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(); // Runs continuous ambient micro-rotations

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _loadBalanceAndStats();
    _audio.init().then((_) => _audio.playLobbyMusic());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadBalanceAndStats() async {
    await _progression.init();
    final prefs = await SharedPreferences.getInstance();
    final activityJson = prefs.getStringList('recent_activity') ?? [];
    if (!mounted) return;
    setState(() {
      _balance = prefs.getDouble('balance') ?? 1000.0;
      _blackjackRounds = prefs.getInt('rounds_played') ?? 0;
      _pokerRounds = prefs.getInt('poker_rounds_played') ?? 0;
      _blackjackWins = prefs.getInt('wins') ?? 0;
      _pokerWins = prefs.getInt('poker_wins') ?? 0;
      
      int arrowsCompleted = 0;
      for (int i = 1; i <= 10; i++) {
        if (prefs.getBool('arrows_level_${i}_completed') ?? false) {
          arrowsCompleted++;
        }
      }
      _arrowsCompleted = arrowsCompleted;

      _vipTitleIndex = prefs.getInt('vip_title_idx') ?? 0;
      _dailyBonusClaimed = _isBonusClaimedToday(prefs);
      _recentActivity = activityJson
          .take(3)
          .map((e) {
            try {
              return Map<String, dynamic>.from(json.decode(e) as Map);
            } catch (_) {
              return <String, dynamic>{};
            }
          })
          .where((m) => m.isNotEmpty)
          .toList();
    });
  }

  bool _isBonusClaimedToday(SharedPreferences prefs) {
    final lastClaim = prefs.getString('daily_bonus_date') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return lastClaim == today;
  }

  Future<void> _claimDailyBonus() async {
    if (_dailyBonusClaimed) return;

    _audio.playClick();
    HapticFeedback.heavyImpact();

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Double-check to prevent race conditions
    if (_isBonusClaimedToday(prefs)) {
      if (!mounted) return;
      setState(() => _dailyBonusClaimed = true);
      return;
    }

    final newBalance = _balance + 500.0;
    await prefs.setDouble('balance', newBalance);
    await prefs.setString('daily_bonus_date', today);

    if (!mounted) return;
    setState(() {
      _balance = newBalance;
      _dailyBonusClaimed = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.card_giftcard, color: CasinoTheme.primaryGold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Daily Bonus Claimed! +\$500 added to your balance.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A2E1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }


  void _openBlackjack() {
    _audio.playClick();
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const BlackjackLobbyScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
      ),
    ).then((_) => _loadBalanceAndStats());
  }

  void _openPoker() {
    _audio.playClick();
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const PokerLobbyScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
      ),
    ).then((_) => _loadBalanceAndStats());
  }

  void _openShop() {
    _audio.playClick();
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const ShopScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
      ),
    ).then((_) => _loadBalanceAndStats());
  }

  void _openArrows() {
    _audio.playClick();
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const ArrowsLobbyScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
      ),
    ).then((_) => _loadBalanceAndStats());
  }

  @override
  Widget build(BuildContext context) {
    final double netProfit = _balance - 1000.0;
    final bool isProfitPositive = netProfit >= 0;

    return Scaffold(
      body: Stack(
        children: [
          // 0. Animated particle background (cinematic layer)
          const Positioned.fill(
            child: AnimatedCasinoBackground(),
          ),

          // Main gradient overlay + content
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF06080C),
                  Color(0xFF0A0E14),
                  Color(0xFF080C12),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Semi-transparent overlay to let particles peek through
          Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),

          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. VIP Player Identity Header
                  _buildVipHeader(netProfit, isProfitPositive),
                  const SizedBox(height: 12),

                  // 2. Casino Statistics Dashboard Grid
                  _buildStatsGrid(),
                  const SizedBox(height: 10),

                  // 3. Daily Bonus Section
                  _buildDailyBonusCard(),
                  const SizedBox(height: 10),

                  // 4. Recent Activity Section
                  if (_recentActivity.isNotEmpty) ...[
                    _buildRecentActivityCard(),
                    const SizedBox(height: 14),
                  ],

                  // 5. Section Label
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [CasinoTheme.primaryGold, CasinoTheme.accentNeonCyan],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'SELECT GAME',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 6. Compact Salon Cards
                  _buildCompactGameCard(
                    title: 'ROYAL BLACKJACK',
                    subtitle: 'Classic 21 • Beat the Dealer',
                    statsLabel: '$_blackjackWins/$_blackjackRounds wins',
                    tag: 'CLASSIC',
                    accentColor: CasinoTheme.primaryGold,
                    bgColor: CasinoTheme.lobbyCardDark,
                    icon: Icons.casino,
                    customIcon: _build21CoinIcon(),
                    onTap: _openBlackjack,
                  ),
                  const SizedBox(height: 10),
                  _buildCompactGameCard(
                    title: 'TEXAS HOLD\'EM',
                    subtitle: 'Ring Game • Blinds & Bluffs',
                    statsLabel: '$_pokerWins/$_pokerRounds wins',
                    tag: 'VIP',
                    accentColor: CasinoTheme.accentNeonCyan,
                    bgColor: CasinoTheme.lobbyCyanDeep,
                    icon: Icons.style,
                    customIcon: _buildPokerCardsAndCoinIcon(CasinoTheme.accentNeonCyan),
                    onTap: _openPoker,
                  ),
                  const SizedBox(height: 10),
                  _buildCompactGameCard(
                    title: 'ARROWS PUZZLE',
                    subtitle: 'Precision Timing • Clear all Lines',
                    statsLabel: '$_arrowsCompleted/10 levels completed',
                    tag: 'NEW PUZZLE',
                    accentColor: const Color(0xFF22C55E), // Neon Emerald Green
                    bgColor: const Color(0xFF091C12), // Deep velvet green
                    icon: Icons.double_arrow,
                    customIcon: _buildArrowsIcon(),
                    onTap: _openArrows,
                  ),
                  const SizedBox(height: 10),
                  _buildCompactGameCard(
                    title: 'VIP COIN STORE',
                    subtitle: 'Purchase Betting Chips • 100% OFF SALE',
                    statsLabel: 'Free chips package active',
                    tag: 'SHOP',
                    accentColor: CasinoTheme.neonPink,
                    bgColor: CasinoTheme.lobbyCardDark,
                    icon: Icons.shopping_bag_rounded,
                    customIcon: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            CasinoTheme.neonPink.withValues(alpha: 0.35),
                            CasinoTheme.neonPink.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: CasinoTheme.neonPink.withValues(alpha: 0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: CasinoTheme.neonPink.withValues(alpha: 0.25),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shopping_bag_rounded,
                          color: CasinoTheme.neonPink,
                          size: 24,
                        ),
                      ),
                    ),
                    onTap: _openShop,
                  ),
                  const SizedBox(height: 20),

                  // 7. Version Footer
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: Colors.white70.withValues(alpha: 0.3)),
                        const SizedBox(height: 4),
                        Text(
                          'BEST CASINO v1.0 • Premium Edition',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                            color: Colors.white70.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // VIP Header — Compact dark surface
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildVipHeader(double netProfit, bool isProfitPositive) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111820), Color(0xFF0C1018)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CasinoTheme.tableBorderGold.withValues(alpha: 0.25), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: CasinoTheme.primaryGold.withValues(alpha: 0.04),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with Navigation to Profile Screen
          GestureDetector(
            onTap: () {
              _audio.playClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) => _loadBalanceAndStats());
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CasinoTheme.primaryGold.withValues(alpha: 0.15),
                    CasinoTheme.primaryGold.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(color: CasinoTheme.primaryGold.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Icon(
                _vipIcons[_vipTitleIndex],
                color: CasinoTheme.primaryGold,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name, VIP rank and level progress
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _audio.playClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                ).then((_) => _loadBalanceAndStats());
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _vipTitles[_vipTitleIndex].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: CasinoTheme.primaryGold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: CasinoTheme.accentNeonCyan, size: 10),
                    ],
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'LEGENDARY GUEST',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Net Profit: ${isProfitPositive ? '+' : ''}\$${netProfit.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isProfitPositive ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Level and progression indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: CasinoTheme.primaryGold,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'LVL ${_progression.level}',
                          style: const TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _progression.levelProgress,
                            minHeight: 3,
                            backgroundColor: CasinoTheme.lobbyDivider.withValues(alpha: 0.5),
                            valueColor: const AlwaysStoppedAnimation<Color>(CasinoTheme.accentNeonCyan),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Chips stack counter and Settings button
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _openShop,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CasinoTheme.primaryGold.withValues(alpha: 0.12),
                        CasinoTheme.primaryGold.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CasinoTheme.primaryGold.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: CasinoTheme.primaryGold, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '\$${_balance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: CasinoTheme.primaryGold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.add_circle_outline_rounded, color: CasinoTheme.primaryGold, size: 11),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  _audio.playClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  ).then((_) => _loadBalanceAndStats());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CasinoTheme.lobbyDivider.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.white70, size: 10),
                      SizedBox(width: 3),
                      Text('SETTINGS', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Stats Grid — Dark gradient surfaces
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'BLACKJACK W/L',
            value: '$_blackjackWins/${_blackjackRounds - _blackjackWins}',
            subtitle: 'Rounds: $_blackjackRounds',
            icon: Icons.casino,
            accentColor: CasinoTheme.primaryGold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            title: 'TEXAS POKER W/L',
            value: '$_pokerWins/${_pokerRounds - _pokerWins}',
            subtitle: 'Rounds: $_pokerRounds',
            icon: Icons.style,
            accentColor: CasinoTheme.accentNeonCyan,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF111820), Color(0xFF0C1018)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.6),
        ),
        child: Row(
          children: [
            // Icon circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.08),
              border: Border.all(color: accentColor.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: accentColor, size: 16),
          ),
          const SizedBox(width: 10),
          // Stats text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.8),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 8, color: Colors.white70.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Daily Bonus Card — Dark gradient surface
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildDailyBonusCard() {
    return GestureDetector(
      onTap: _dailyBonusClaimed ? null : _claimDailyBonus,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _dailyBonusClaimed
                ? [const Color(0xFF0E1218), const Color(0xFF0A0D12)]
                : [const Color(0xFF141A10), const Color(0xFF0E1208)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _dailyBonusClaimed
                ? Colors.white.withValues(alpha: 0.4)
                : CasinoTheme.primaryGold.withValues(alpha: 0.2),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            // Gift icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dailyBonusClaimed
                    ? CasinoTheme.lobbyDivider.withValues(alpha: 0.3)
                    : CasinoTheme.primaryGold.withValues(alpha: 0.10),
                border: Border.all(
                  color: _dailyBonusClaimed
                      ? Colors.white.withValues(alpha: 0.4)
                      : CasinoTheme.primaryGold.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons.card_giftcard,
                color: _dailyBonusClaimed
                    ? Colors.white70.withValues(alpha: 0.5)
                    : CasinoTheme.primaryGold,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dailyBonusClaimed ? 'BONUS CLAIMED' : 'DAILY BONUS',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: _dailyBonusClaimed
                          ? Colors.white70.withValues(alpha: 0.5)
                          : CasinoTheme.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _dailyBonusClaimed
                        ? 'Come back tomorrow for more chips!'
                        : 'Tap to claim your daily reward',
                    style: TextStyle(
                      fontSize: 10,
                      color: _dailyBonusClaimed
                          ? Colors.white70.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Claim button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: _dailyBonusClaimed
                    ? null
                    : LinearGradient(
                        colors: [
                          CasinoTheme.primaryGold.withValues(alpha: 0.15),
                          CasinoTheme.primaryGold.withValues(alpha: 0.05),
                        ],
                      ),
                color: _dailyBonusClaimed ? CasinoTheme.lobbyDivider.withValues(alpha: 0.3) : null,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _dailyBonusClaimed
                      ? Colors.white.withValues(alpha: 0.4)
                      : CasinoTheme.primaryGold.withValues(alpha: 0.3),
                  width: 0.6,
                ),
              ),
              child: Text(
                _dailyBonusClaimed ? 'CLAIMED ✓' : 'Claim \$500',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _dailyBonusClaimed
                      ? Colors.white70.withValues(alpha: 0.4)
                      : CasinoTheme.primaryGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Recent Activity Card — Dark gradient surface
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111820), Color(0xFF0C1018)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Colors.white70, size: 12),
              SizedBox(width: 6),
              Text(
                'RECENT ACTIVITY',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._recentActivity.map((activity) {
            final gameType = (activity['game'] as String?) ?? (activity['type'] as String?) ?? 'unknown';
            final result = (activity['result'] as String?) ?? 'win';
            
            final rawAmount = activity['amount'];
            double amount = 0.0;
            if (rawAmount is num) {
              amount = rawAmount.toDouble();
            } else if (rawAmount is String) {
              amount = double.tryParse(rawAmount.replaceAll('+', '').replaceAll('-', '')) ?? 0.0;
            }
            
            final isWin = result.toLowerCase() == 'win' || result.toLowerCase() == 'claim' || gameType.toLowerCase().contains('shop') || gameType.toLowerCase().contains('store');

            IconData gameIcon;
            Color gameColor;
            String displayTitle;
            
            switch (gameType.toLowerCase()) {
              case 'blackjack':
                gameIcon = Icons.casino;
                gameColor = CasinoTheme.primaryGold;
                displayTitle = 'Royal Blackjack';
                break;
              case 'poker':
                gameIcon = Icons.style;
                gameColor = CasinoTheme.accentNeonCyan;
                displayTitle = 'Texas Hold\'em';
                break;
              case 'store':
              case 'shop':
              case 'shop_purchase':
                gameIcon = Icons.shopping_bag_rounded;
                gameColor = CasinoTheme.neonPink;
                displayTitle = 'VIP Coin Store';
                break;
              default:
                gameIcon = Icons.games;
                gameColor = Colors.white70;
                displayTitle = gameType.toUpperCase();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(gameIcon, color: gameColor, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    (result == 'win' && (gameType.toLowerCase() == 'store' || gameType.toLowerCase() == 'shop' || gameType.toLowerCase() == 'shop_purchase')) ? 'CLAIMED' : result.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: isWin ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isWin ? '+' : '-'}\$${amount.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isWin ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Custom visual icons for game cards
  Widget _build21CoinIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // The coin circle
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CasinoTheme.primaryGold,
                CasinoTheme.secondaryGold,
                Color(0xFF8C6D30),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: CasinoTheme.primaryGold.withValues(alpha: 0.35),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        // Inner coin ring
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.25),
              width: 1.0,
            ),
          ),
        ),
        // The number "21"
        const Text(
          '21',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildPokerCardsAndCoinIcon(Color accentColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Left angled mini-card
        Positioned(
          left: 6,
          top: 6,
          child: Transform.rotate(
            angle: -0.22,
            child: Container(
              width: 20,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'A',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
        // Right angled mini-card overlapping
        Positioned(
          right: 6,
          top: 4,
          child: Transform.rotate(
            angle: 0.12,
            child: Container(
              width: 20,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: CasinoTheme.neonPink.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'K',
                style: TextStyle(
                  color: CasinoTheme.neonPink,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
        // Small overlapping gold betting chip at bottom-right
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  CasinoTheme.primaryGold,
                  CasinoTheme.secondaryGold,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.star,
              size: 8,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArrowsIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Left diagonal pointing arrow
        Positioned(
          left: 6,
          bottom: 6,
          child: Transform.rotate(
            angle: -0.45,
            child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF22C55E), size: 18),
          ),
        ),
        // Right diagonal pointing arrow overlapping
        Positioned(
          right: 6,
          top: 6,
          child: Transform.rotate(
            angle: 0.8,
            child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF22C55E), size: 18),
          ),
        ),
        // Central dot indicating crossover
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Colors.white70,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // Compact Premium Game Card — Horizontal dashboard layout
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildCompactGameCard({
    required String title,
    required String subtitle,
    required String statsLabel,
    required String tag,
    required Color accentColor,
    required Color bgColor,
    required IconData icon,
    Widget? customIcon,
    required VoidCallback onTap,
  }) {
    bool isPressed = false;

    return StatefulBuilder(
      builder: (context, setStateCard) {
        return GestureDetector(
          onTapDown: (_) => setStateCard(() => isPressed = true),
          onTapUp: (_) {
            setStateCard(() => isPressed = false);
            onTap();
          },
          onTapCancel: () => setStateCard(() => isPressed = false),
          child: AnimatedScale(
            scale: isPressed ? 0.975 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                final shimmerVal = _shimmerController.value;
                final pulse = 0.06 * sin(shimmerVal * 2 * pi);
                final borderAlpha = (0.25 + pulse).clamp(0.0, 1.0);

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        bgColor,
                        Color.lerp(bgColor, Colors.black, 0.3)!,
                        Color.lerp(bgColor, Colors.black, 0.5)!,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor.withValues(alpha: borderAlpha),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.06),
                        blurRadius: 16,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Subtle radial glow in corner
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accentColor.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Shimmer sweep
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) {
                        return Positioned.fill(
                          child: ShaderMask(
                            blendMode: BlendMode.srcATop,
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.transparent,
                                  accentColor.withValues(alpha: 0.04),
                                  Colors.transparent,
                                ],
                                stops: [
                                  max(0.0, _shimmerController.value - 0.3),
                                  _shimmerController.value,
                                  min(1.0, _shimmerController.value + 0.3),
                                ],
                              ).createShader(bounds);
                            },
                            child: Container(color: CasinoTheme.bgCard),
                          ),
                        );
                      },
                    ),

                    // Content — Horizontal compact layout
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        children: [
                          // Game icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accentColor.withValues(alpha: 0.12),
                                  accentColor.withValues(alpha: 0.04),
                                ],
                              ),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: customIcon ?? Icon(icon, color: accentColor, size: 22),
                          ),
                          const SizedBox(width: 12),

                          // Title + subtitle + stats
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tag badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accentColor.withValues(alpha: 0.12),
                                        accentColor.withValues(alpha: 0.04),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 7,
                                      color: accentColor,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Title
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Subtitle
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70.withValues(alpha: 0.7),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // Stats label
                                Text(
                                  statsLabel,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: accentColor.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // CTA button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accentColor.withValues(alpha: 0.18),
                                  accentColor.withValues(alpha: 0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.3),
                                width: 0.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'PLAY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: accentColor,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 10, color: accentColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
