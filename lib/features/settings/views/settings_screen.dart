import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared_casino/theme/casino_theme.dart';
import '../../shared_casino/services/progression_service.dart';
import '../../shared_casino/audio/audio_service.dart';
import '../../shared_casino/views/widgets/animated_casino_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProgressionService _progression = ProgressionService();
  final AudioService _audio = AudioService();

  String _selectedTheme = 'classic_vegas';

  final List<Map<String, String>> _themes = const [
    {
      'id': 'classic_vegas',
      'name': 'Classic Vegas',
      'description': 'Deep green felt with traditional mahogany trim.',
    },
    {
      'id': 'emerald_casino',
      'name': 'Emerald Casino',
      'description': 'Bright jade felt designed for higher stakes.',
    },
    {
      'id': 'neon_cyber',
      'name': 'Neon Cyber',
      'description': 'Dark tech felt with glowing pink and cyan details.',
    },
    {
      'id': 'crimson_royale',
      'name': 'Crimson Royale',
      'description': 'Deep red velvet felt reserved for royalty.',
    },
    {
      'id': 'luxury_gold',
      'name': 'Black Gold Luxury',
      'description': 'Jet black felt with heavy polished gold accents.',
    },
    {
      'id': 'minimal_dark',
      'name': 'Minimal Dark',
      'description': 'Clean grey slate felt with soft white borders.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _progression.init();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedTheme = prefs.getString('global_felt_theme') ?? 'classic_vegas';
    });
  }

  Future<void> _selectTheme(String themeId, bool isUnlocked) async {
    if (!isUnlocked) {
      _audio.playClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: CasinoTheme.neonPink),
              const SizedBox(width: 10),
              Text(
                'Unlock at Level ${_progression.getRequiredLevel(themeId)}!',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E0E12),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    _audio.playChipsBet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_felt_theme', themeId);
    if (!mounted) return;
    setState(() {
      _selectedTheme = themeId;
    });
  }

  Future<void> _resetAccountData() async {
    _audio.playClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CasinoTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CasinoTheme.neonPink, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: CasinoTheme.neonPink),
            SizedBox(width: 10),
            Text('RESET ALL DATA?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This action is irreversible. All chips balance, progression levels, XP, and unlock achievements will be permanently wiped.',
          style: TextStyle(color: Colors.white, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await _progression.resetAll();
              
              if (mounted) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Account reset complete. Relogging as new VIP guest.'),
                    backgroundColor: Colors.black,
                  ),
                );
              }
              await _loadSettings();
            },
            child: const Text('DELETE EVERYTHING', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: AnimatedCasinoBackground(),
          ),

          // Dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.88),
                  const Color(0xFF050A05).withValues(alpha: 0.92),
                  Colors.black.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header Bar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CasinoTheme.lobbyCardSurface,
                            border: Border.all(
                              color: CasinoTheme.lobbyGoldDim.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: CasinoTheme.primaryGold, size: 18),
                            onPressed: () {
                              _audio.playClick();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        Column(
                          children: [
                            const Text(
                              'CASINO SETTINGS',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                                color: CasinoTheme.primaryGold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 40,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    CasinoTheme.primaryGold.withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),

                // ── 1. Audio Controls Card ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionLabel('SOUND SYSTEM'),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                CasinoTheme.lobbyCardSurface,
                                CasinoTheme.lobbyCardDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: CasinoTheme.lobbyGoldDim.withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _audio.isMuted
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : CasinoTheme.accentNeonCyan.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: _audio.isMuted
                                        ? Colors.white12
                                        : CasinoTheme.accentNeonCyan.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Icon(
                                  _audio.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                  color: _audio.isMuted ? Colors.white70 : CasinoTheme.accentNeonCyan,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _audio.isMuted ? 'SOUND MUTED' : 'SOUND ENABLED',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Atmospheric music & deal FX',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Switch
                              Switch(
                                value: _audio.isMuted,
                                activeTrackColor: CasinoTheme.accentNeonCyan.withValues(alpha: 0.4),
                                activeThumbColor: CasinoTheme.accentNeonCyan,
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                                inactiveThumbColor: CasinoTheme.textMuted,
                                onChanged: (val) async {
                                  await _audio.toggleMute();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 2. Felt Theme Selector ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionLabel('UNLOCKED FELT THEMES'),
                        const SizedBox(height: 4),
                        Text(
                          'Select your luxury felt table. Locked themes unlock as you level up.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final theme = _themes[index];
                        final themeId = theme['id']!;
                        final isUnlocked = _progression.isThemeUnlocked(themeId);
                        final isSelected = _selectedTheme == themeId;
                        final reqLevel = _progression.getRequiredLevel(themeId);

                        // Visual style models per theme for visual previews
                        final tblStyle = CasinoTheme.getTableStyle(themeId);
                        final cardStyle = CasinoTheme.getCardStyle(themeId);
                        final chipStyle = CasinoTheme.getChipStyle(themeId);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => _selectTheme(themeId, isUnlocked),
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isSelected
                                      ? [
                                          tblStyle.feltDeep.withValues(alpha: 0.7),
                                          Color.lerp(tblStyle.feltDeep, Colors.black, 0.5)!,
                                        ]
                                      : [
                                          CasinoTheme.lobbyCardSurface,
                                          CasinoTheme.lobbyCardDark,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? tblStyle.highlightColor.withValues(alpha: 0.6)
                                      : (isUnlocked
                                          ? CasinoTheme.lobbyGoldDim.withValues(alpha: 0.12)
                                          : Colors.white.withValues(alpha: 0.05)),
                                  width: isSelected ? 1.5 : 0.8,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: tblStyle.highlightColor.withValues(alpha: 0.12),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  // Visual Table Preview
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [tblStyle.feltLight, tblStyle.feltDeep],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: tblStyle.railColor, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Preview card
                                        Positioned(
                                          left: 6,
                                          top: 12,
                                          child: Transform.rotate(
                                            angle: -0.2,
                                            child: Container(
                                              width: 20,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: cardStyle.cardFaceColor,
                                                borderRadius: BorderRadius.circular(3),
                                                border: Border.all(color: cardStyle.cardBorderColor, width: 0.5),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text('A', style: TextStyle(fontSize: 9, color: cardStyle.suitRedColor, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ),
                                        // Preview chip
                                        Positioned(
                                          right: 5,
                                          bottom: 5,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: chipStyle.chipBaseColor,
                                              border: Border.all(color: chipStyle.chipBorderColor, width: 1.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Theme Name & Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              theme['name']!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isUnlocked ? Colors.white : Colors.white30,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            if (isSelected)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: tblStyle.highlightColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'ACTIVE',
                                                  style: TextStyle(
                                                    fontSize: 7,
                                                    fontWeight: FontWeight.w900,
                                                    color: tblStyle.highlightColor,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          theme['description']!,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isUnlocked
                                                ? Colors.white70.withValues(alpha: 0.7)
                                                : Colors.white.withValues(alpha: 0.12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Locked indicator
                                  if (!isUnlocked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: CasinoTheme.lobbyGoldDim.withValues(alpha: 0.2),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.lock_rounded, color: CasinoTheme.lobbyGoldDim, size: 10),
                                          const SizedBox(width: 4),
                                          Text(
                                            'LVL $reqLevel',
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: CasinoTheme.lobbyGoldDim,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _themes.length,
                    ),
                  ),
                ),

                // ── 3. Danger Zone ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A0A0E),
                            const Color(0xFF0D0508),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: CasinoTheme.neonPink.withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: CasinoTheme.neonPink.withValues(alpha: 0.8), size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'DANGER ZONE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: CasinoTheme.neonPink,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Wiping all saved data will completely reset player streaks, total career stats, XP progression, and balance chips.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70.withValues(alpha: 0.6),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CasinoTheme.neonPink.withValues(alpha: 0.1),
                              foregroundColor: CasinoTheme.neonPink,
                              side: BorderSide(
                                color: CasinoTheme.neonPink.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            onPressed: _resetAccountData,
                            child: const Text(
                              'RESET PLATFORM DATA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Section Label ──
  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: CasinoTheme.lobbyGoldDim,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white70.withValues(alpha: 0.8),
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}
