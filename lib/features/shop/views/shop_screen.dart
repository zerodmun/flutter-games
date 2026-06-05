import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared_casino/audio/audio_service.dart';
import '../../shared_casino/theme/casino_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  final AudioService _audio = AudioService();
  double _balance = 1000.0;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadBalance();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _balance = prefs.getDouble('balance') ?? 1000.0;
    });
  }

  Future<void> _purchaseCoins(int coinsToAdd, String bundleName) async {
    _audio.playChipsWin();
    HapticFeedback.vibrate();

    final prefs = await SharedPreferences.getInstance();
    final currentBalance = prefs.getDouble('balance') ?? 1000.0;
    final newBalance = currentBalance + coinsToAdd;
    await prefs.setDouble('balance', newBalance);

    final activityJson = prefs.getStringList('recent_activity') ?? [];
    final newActivity = {
      'game': 'store',
      'result': 'win',
      'amount': coinsToAdd.toDouble(),
      'title': 'Purchased $bundleName',
      'timestamp': DateTime.now().toIso8601String(),
    };
    activityJson.insert(0, json.encode(newActivity));
    await prefs.setStringList('recent_activity', activityJson.take(10).toList());

    if (!mounted) return;
    setState(() {
      _balance = newBalance;
    });

    _showSuccessDialog(coinsToAdd, bundleName);
  }

  void _showSuccessDialog(int amount, String bundleName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: CasinoTheme.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: CasinoTheme.primaryGold, width: 1.5),
          ),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  CasinoTheme.primaryGold.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: CasinoTheme.primaryGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: CasinoTheme.neonGlow(color: CasinoTheme.primaryGold, radius: 12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.monetization_on,
                      color: CasinoTheme.primaryGold,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'TRANSACTION COMPLETE',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: CasinoTheme.primaryGold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+$amount Coins Added!',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: CasinoTheme.textLight,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your purchase of "$bundleName" was successful. Enjoy high stakes!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: CasinoTheme.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    _audio.playClick();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [CasinoTheme.primaryGold, Color(0xFFFFA000)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: CasinoTheme.neonGlow(color: CasinoTheme.primaryGold, radius: 8),
                    ),
                    child: Center(
                      child: Text(
                        'COLLECT CHIPS',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: CasinoTheme.bgDarker,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CasinoTheme.bgDarker,
      body: Stack(
        children: [
          // ── Background Glow ──
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CasinoTheme.neonPink.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CasinoTheme.primaryGold.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── 1. App Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _audio.playClick();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: CasinoTheme.bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: const Center(
                            child: Icon(Icons.arrow_back_rounded, color: CasinoTheme.textLight, size: 20),
                          ),
                        ),
                      ),
                      Text(
                        'VIP COIN STORE',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                      // Elegant shop tag icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: CasinoTheme.bgCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: CasinoTheme.neonPink.withValues(alpha: 0.25)),
                        ),
                        child: const Center(
                          child: Icon(Icons.shopping_bag_rounded, color: CasinoTheme.neonPink, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // ── 2. Balance Board ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                CasinoTheme.bgCard,
                                CasinoTheme.bgCard.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'YOUR CURRENT BALANCE',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: CasinoTheme.textMuted,
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: CasinoTheme.primaryGold.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.monetization_on,
                                        color: CasinoTheme.primaryGold,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '\$${_balance.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: CasinoTheme.primaryGold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── 3. Summer Sale Banner ──
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            final glowColor = CasinoTheme.neonPink.withValues(alpha: 0.2 + (_glowController.value * 0.2));
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: CasinoTheme.bgCard,
                                border: Border.all(
                                  color: CasinoTheme.neonPink.withValues(alpha: 0.5 + (_glowController.value * 0.3)),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: glowColor,
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.percent_rounded, color: CasinoTheme.neonPink, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '100% OFF CELEBRATION SALE',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: CasinoTheme.neonPink,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'All betting coin bundles are fully FREE right now!',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: CasinoTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // ── 4. Store Grid ──
                        _buildShopCard(
                          title: 'Handful of Chips',
                          description: 'Perfect for casual play and learning Blackjack.',
                          coins: 10000,
                          originalPrice: '\$0.99',
                          icon: Icons.monetization_on_outlined,
                          accentColor: CasinoTheme.primaryGold,
                        ),
                        const SizedBox(height: 14),
                        _buildShopCard(
                          title: 'Stack of Gold',
                          description: 'Enter intermediate rooms and double down confidently.',
                          coins: 50000,
                          originalPrice: '\$4.99',
                          icon: Icons.layers_rounded,
                          accentColor: CasinoTheme.accentNeonCyan,
                        ),
                        const SizedBox(height: 14),
                        _buildShopCard(
                          title: 'High Roller Vault',
                          description: 'Own the Texas Hold\'em tables with aggressive stacks.',
                          coins: 250000,
                          originalPrice: '\$19.99',
                          icon: Icons.vpn_key_rounded,
                          accentColor: CasinoTheme.neonPink,
                          isBestSeller: true,
                        ),
                        const SizedBox(height: 14),
                        _buildShopCard(
                          title: 'Casino Tycoon Treasury',
                          description: 'Ultimate wealth. Become a legend and rule the casino.',
                          coins: 1000000,
                          originalPrice: '\$49.99',
                          icon: Icons.account_balance_wallet_rounded,
                          accentColor: const Color(0xFF00E676),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard({
    required String title,
    required String description,
    required int coins,
    required String originalPrice,
    required IconData icon,
    required Color accentColor,
    bool isBestSeller = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CasinoTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBestSeller ? CasinoTheme.neonPink.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
          width: isBestSeller ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isBestSeller)
            BoxShadow(
              color: CasinoTheme.neonPink.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Stack(
        children: [
          if (isBestSeller)
            Positioned(
              top: 0,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: CasinoTheme.neonPink,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  'BEST BUY',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Bundle Icon with accent highlight
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                ),
                const SizedBox(width: 16),

                // Bundle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: CasinoTheme.textMuted,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Chips quantity badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: CasinoTheme.primaryGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, color: CasinoTheme.primaryGold, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              '+${coins.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} CHIPS',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: CasinoTheme.primaryGold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Price and Action Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      originalPrice,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: CasinoTheme.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'FREE',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF00E676),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _purchaseCoins(coins, title),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: CasinoTheme.neonGlow(color: accentColor, radius: 5),
                        ),
                        child: Text(
                          'CLAIM',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: CasinoTheme.bgDarker,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
