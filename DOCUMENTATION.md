# Best Casino — Flutter Documentation

## 1. Project Overview

**Project Name:** Best Casino (`flut_blackjack`)  
**Package Name:** `best_casino`  
**Version:** 1.0.0+1  
**SDK:** Dart ^3.12.0 · Flutter  
**Entry Point:** `lib/main.dart`

A premium casino gaming application featuring Blackjack, Texas Hold'em Poker, and an Arrows minigame. Built with a modern dark-theme design system, Riverpod state management, and immersive audio.

---

## 2. Architecture & Design Patterns

### Pattern: MVVM (Model-View-ViewModel)

```
Model (data models)
    ↓
ViewModel (StateNotifier via Riverpod)
    ↓
View (StatefulWidgets consuming providers)
```

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Model** | `data/models/` | Pure Dart classes, enums, immutability via `copyWith` |
| **ViewModel** | `viewmodels/` | `StateNotifier<T>` — game logic, AI, state transitions |
| **View** | `views/` | Flutter widgets consuming providers via `ref.watch`/`ref.listen` |
| **Services** | `services/`, `audio/` | Singleton services (audio, dealer commentary, progression) |

### State Management: Riverpod (`flutter_riverpod`)

- **Provider Declaration:** `StateNotifierProvider<ViewModel, State>` in viewmodel files
- **Immutability:** All state classes use `const` constructors and `copyWith` for updates
- **Reactivity:** Views rebuild only on consumed state changes via `ref.watch(provider)`

### Key Patterns

- **Singleton Services:** `AudioService`, `DealerService`, `ProgressionService` — all use `factory` + private `_internal` constructor
- **Immutable State:** `GameSessionState`, `PokerGameState` — no mutation, only `copyWith`
- **Delegated AI:** `AIManager` (Blackjack) / `PokerAIManager` (Poker) — pure static logic classes
- **Themed Visuals:** `CasinoTableStyle`, `CasinoCardStyle`, `CasinoChipStyle` — configurable per table theme
- **Staggered Animations:** `Future.delayed` chains for card dealing, dealer turns, bot "thinking"

---

## 3. Project Structure

```
lib/
├── main.dart                              # App entry, ProviderScope, MaterialApp
├── features/
│   ├── shared_casino/                     # Shared infrastructure
│   │   ├── audio/audio_service.dart        # Singleton — music/SFX playback
│   │   ├── services/
│   │   │   ├── dealer_service.dart         # Singleton — Dealer commentary system
│   │   │   └── progression_service.dart    # Singleton — XP, levels, achievements
│   │   ├── theme/casino_theme.dart         # Full dark theme, table/card/chip styles
│   │   └── views/widgets/
│   │       ├── animated_casino_background.dart
│   │       ├── casino_button.dart
│   │       ├── chip_stack.dart
│   │       ├── circular_countdown_timer.dart
│   │       ├── dealer_message_bubble.dart
│   │       ├── exit_confirmation_dialog.dart
│   │       └── particle_win_effect.dart
│   │
│   ├── lobby/views/                        # Hub screens
│   │   ├── lobby_screen.dart               # Main lobby — balance, stats, game cards
│   │   ├── blackjack_lobby_screen.dart     # Blackjack table selection
│   │   ├── poker_lobby_screen.dart         # Poker table selection
│   │   ├── custom_table_screen.dart        # Blackjack custom table config
│   │   └── poker_custom_table_screen.dart  # Poker custom table config
│   │
│   ├── blackjack/                          # Blackjack game module
│   │   ├── data/models/
│   │   │   ├── card.dart                   # CardRank, CardSuit, BlackjackCard
│   │   │   ├── hand.dart                   # BlackjackHand (score, status, splits)
│   │   │   ├── player.dart                 # BlackjackPlayer (bot personality, AI)
│   │   │   └── game_state.dart             # GameSessionState (stage, players, deck)
│   │   ├── viewmodels/
│   │   │   ├── game_view_model.dart        # Core game logic StateNotifier
│   │   │   └── ai_manager.dart             # Bot AI: strategy, personality, card counting
│   │   └── views/
│   │       ├── blackjack_screen.dart       # Main game UI
│   │       └── widgets/
│   │           ├── animated_card.dart
│   │           ├── chip_stack.dart
│   │           ├── particle_win_effect.dart
│   │           └── table_felt_painter.dart
│   │
│   ├── poker/                              # Texas Hold'em module
│   │   ├── data/models/
│   │   │   ├── poker_card.dart             # PokerRank, PokerSuit, PokerCard
│   │   │   ├── poker_hand_score.dart       # HandRank, PokerHandScore (comparable)
│   │   │   ├── poker_player.dart           # PokerPlayer (status, actions, chips)
│   │   │   └── poker_state.dart            # PokerGameState (stage, pot, blinds)
│   │   ├── viewmodels/
│   │   │   ├── poker_view_model.dart       # Core game logic StateNotifier (770 lines)
│   │   │   ├── poker_ai_manager.dart       # Bot AI for poker
│   │   │   └── poker_hand_evaluator.dart   # 7-card → best 5-card hand evaluation
│   │   └── views/
│   │       ├── poker_game_screen.dart      # Main game UI
│   │       └── widgets/
│   │           ├── animated_poker_card.dart
│   │           └── poker_felt_painter.dart
│   │
│   ├── arrows/                             # Casual minigame
│   │   ├── models/arrows_models.dart       # Arrow, state models
│   │   ├── services/collision_engine.dart  # Collision detection
│   │   └── views/
│   │       ├── arrows_game_screen.dart     # Game screen
│   │       ├── arrows_lobby_screen.dart    # Lobby/level select
│   │       └── widgets/
│   │           ├── arrows_painter.dart
│   │           └── particle_system.dart
│   │
│   ├── profile/views/profile_screen.dart   # Player profile, stats, achievements
│   ├── settings/views/settings_screen.dart # Audio, theme, reset
│   └── shop/views/shop_screen.dart         # Chip purchase store
│
test/
├── blackjack_test.dart                     # Blackjack logic tests
└── poker_test.dart                         # Poker hand evaluator tests

assets/
├── sounds/                                 # Music tracks + SFX (.mp3)
└── images/                                 # Avatar images etc.

tools/
└── generate_casino_music.py                # Python script for music generation
```

---

## 4. Technology Stack

| Technology | Purpose |
|------------|---------|
| **Flutter / Dart 3.12** | Cross-platform UI framework |
| **flutter_riverpod** | State management (StateNotifier pattern) |
| **google_fonts** | Outfit font family across all text |
| **shared_preferences** | Local persistence (balance, XP, stats) |
| **audioplayers** | Music + SFX playback |
| **vector_math** | Vector calculations (2D game math) |
| **flutter_lints** | Code quality/linting |

---

## 5. Theme & Design System

### Core File: `lib/features/shared_casino/theme/casino_theme.dart`

#### Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `primaryGold` | `#FFD700` | Headlines, accents, primary buttons |
| `secondaryGold` | `#C5A059` | Subtle gold accents |
| `accentNeonCyan` | `#00E5FF` | Poker theme, switches, toggles |
| `neonPink` | `#FF2E93` | Error states, cyber theme |
| `bgDarker` | `#090A0C` | Scaffold background |
| `bgDark` | `#111318` | Secondary surfaces, bottom sheets |
| `bgCard` | `#1E222B` | Card backgrounds, list tiles |
| `feltGreenDeep` | `#0A3A20` | Classic table felt |
| `feltGreenLight` | `#0D5E3A` | Lighter felt variant |
| `textLight` | `#E2E8F0` | Primary text |
| `textMuted` | `#94A3B8` | Secondary/helper text |

#### Lobby Palette (Premium)

| Token | Hex | Usage |
|-------|-----|-------|
| `lobbyCardDark` | `#0A0E0A` | Blackjack game card background |
| `lobbyCardSurface` | `#111A14` | Button/lobby card surface |
| `lobbyCyanDeep` | `#0A2A3D` | Poker game card background |
| `lobbyGoldShine` | `#D4A843` | VIP gold accents |
| `lobbyGoldDim` | `#8C6D30` | Borders, dividers |
| `lobbyEmerald` | `#0D3B22` | Emerald accents |
| `lobbyDivider` | `#1F2A22` | Dividers, borders |

#### Typography: Google Fonts Outfit

- `displayLarge`: 32px Bold Gold — main headings
- `displayMedium`: 24px Bold Light — section headings
- `titleLarge`: 20px SemiBold Light — card titles
- `bodyLarge`: 16px Normal Light — body text
- `bodyMedium`: 14px Muted — secondary text

#### Component Theming

All Material widgets are themed: `listTileTheme`, `cardTheme`, `dialogTheme`, `snackBarTheme`, `bottomSheetTheme`, `appBarTheme`, `elevatedButtonTheme`, `textButtonTheme`, `dividerTheme`, `popupMenuTheme`, `tooltipTheme`, `progressIndicatorTheme`, `switchTheme`, `sliderTheme`, `checkboxTheme`, `radioTheme`.

#### Table Themes (6 variants)

Defined in `getTableStyle(themeName)`:

| Theme | Felt Colors | Accent | Unlock Level |
|-------|-------------|--------|--------------|
| Classic Vegas | Green (#0D5E3A / #0A3A20) | Cyan | 1 |
| Emerald Casino | Same greens | Gold | 2 |
| Neon Cyber | Dark slate (#0F121C) | Neon Cyan + Pink | 3 |
| Crimson Royale | Deep red (#800E13) | Gold | 4 |
| Luxury Black Gold | Dark charcoal (#282A2E) | Gold | 5 |
| Minimal Dark | Slate (#1E293B) | Silver | 6 |

Each theme also carries configurable `CasinoCardStyle` (card face/back colors, suit colors, border) and `CasinoChipStyle` (chip colors, stripe, text).

#### Visual Helpers

- `neonGlow(color, radius)` — dual-layer box shadow for glow effects
- `glassDecoration(color, opacity, borderRadius)` — glassmorphic background
- `shimmerGradient(baseColor)` — animated loading shine
- `pulseColor(color, phase)` — oscillating opacity for pulse animations

---

## 6. Feature Modules

### 6.1 Lobby (`lobby/views/`)

**`lobby_screen.dart`** — Main hub screen (1460 lines). Features:
- Animated background (`AnimatedCasinoBackground`) with floating particles
- Balance display with daily bonus claiming
- Game cards for Blackjack, Poker, Arrows (`_buildCompactGameCard`)
- Recent activity feed (persisted via `SharedPreferences`)
- VIP title rotation, stats counters, progression display
- Navigation buttons to Profile, Shop, Settings
- Shimmer animation controller for card shine effects

**`blackjack_lobby_screen.dart`** — Blackjack table selection. Quick Play button, Custom Table config, theme preview cards.

**`poker_lobby_screen.dart`** — Poker table selection. Quick Play, Custom Room, theme previews.

**`custom_table_screen.dart`** — Sliders/selectors for: starting money, min/max bet, player count (1-6), bot personalities, felt theme.

**`poker_custom_table_screen.dart`** — Similar config for poker: blinds, player count, speed mode, theme.

### 6.2 Blackjack (`blackjack/`)

#### Models

| File | Key Types |
|------|-----------|
| `card.dart` | `CardSuit` (enum), `CardRank` (enum with values), `BlackjackCard` (suit, rank, isFaceUp) |
| `hand.dart` | `HandStatus` (enum: betting/playing/stood/busted/blackjack/won/lost/push/surrendered), `BlackjackHand` (cards, bet, score, isSoft, isBlackjack, isBusted, isFromSplit) |
| `player.dart` | `BotDifficulty` (easy/normal/hard/casinoPro), `BotPersonality` (aggressive/careful/riskyGambler/professional), `BlackjackPlayer` (id, name, balance, hands, bot config, lastEmote) |
| `game_state.dart` | `GameStage` (betting/dealing/playerTurns/dealerTurn/payouts/roundEnded), `GameSessionState` (players, dealer, deck, currentPlayerIndex, stage, etc.) |

#### ViewModel (`game_view_model.dart` — 854 lines)

The `GameViewModel` extends `StateNotifier<GameSessionState>` and manages the full game lifecycle:

1. **`initializeTable()`** — Setup players, deck shoe (6 decks = 312 cards), theme, min/max bet
2. **`placeBet()` / `clearBet()`** — Chip management per player
3. **`startRound()`** — Staggered card dealing (400ms delays per card). Deals 2 cards to each player + 2 to dealer (1 face down)
4. **Player Actions:** `hit()`, `stand()`, `doubleDown()`, `split()`, `surrender()`
5. **`_startDealerTurn()`** — Reveal hole card, draw until ≥17, evaluate
6. **`_evaluatePayouts()`** — Compare scores, apply 3:2 for blackjack, push/loss logic
7. **`startNewRound()`** — Reset for next round

#### AI Manager (`ai_manager.dart`)

Uses perfect basic strategy with:
- **Basic Strategy Table:** Hard totals, soft totals, split recommendations, surrender candidates
- **Card Counting (Pro):** Illustrious 18 adjustments (stand 16 vs 10 when count positive, etc.)
- **Personality Biases:** Aggressive (more doubles/hits), Careful (early stand), RiskyGambler (bad splits), Professional (pure math)
- **Difficulty Tiers:** Easy (25% random mistakes), Normal (8%), Hard/Pro (0%)
- **Emote System:** Personality-specific emoji reactions based on hand confidence

### 6.3 Poker — Texas Hold'em (`poker/`)

#### Models

| File | Key Types |
|------|-----------|
| `poker_card.dart` | `PokerSuit`, `PokerRank` (Ace = 14), `PokerCard` |
| `poker_hand_score.dart` | `HandRank` (highCard → royalFlush), `PokerHandScore` (rank + kicker values, implements `Comparable`) |
| `poker_player.dart` | `PokerPlayerStatus` (active/folded/allIn/outOfChips), `PokerPlayer`, `PokerAction` (fold/check/call/raise/allIn) |
| `poker_state.dart` | `PokerStage` (blinds/preFlop/flop/turn/river/showdown/roundEnded), `PokerGameState` (players, communityCards, pot, blinds, timers) |

#### ViewModel (`poker_view_model.dart` — 770 lines)

Full Texas Hold'em lifecycle:
1. **`initializeTable()`** — Setup players, blinds, dealer button
2. **`startRound()`** — Collect blinds (small ½, big full), deal 2 hole cards
3. **Betting Rounds:** Pre-flop → Flop → Turn → River → Showdown
4. **`executeAction()`** — Handle fold/check/call/raise/allIn with bet validation
5. **Community Cards:** Deal 3 (flop) + 1 (turn) + 1 (river) with delays
6. **Showdown:** Evaluate all active players' hands, determine winner(s), split pot
7. **Auto-Progress:** Timer-driven turn system (15s normal, 8s fast mode), auto-fold on timeout
8. **Fast-Forward / Skip:** `toggleFastForward()` — speed up bot decisions

#### Hand Evaluator (`poker_hand_evaluator.dart`)

Given 7 cards (2 hole + 5 community), find best 5-card hand:
- Generates all C(7,5) = 21 combinations
- Evaluates each 5-card set for rank: straight flush → four of a kind → full house → flush → straight → three of a kind → two pair → pair → high card
- Handles Ace-low straights (A-2-3-4-5)
- Returns `PokerHandScore` which is `Comparable` for winner resolution

#### AI Manager (`poker_ai_manager.dart`)

Bot decision-making for poker using:
- Hand strength evaluation (pocket pairs, suited connectors, high card values)
- Position-aware betting (early/middle/late)
- Pot odds consideration
- Personality-driven aggression levels
- Reaction emote system

### 6.4 Arrows Minigame (`arrows/`)

A casual reaction-based game where players dodge falling arrows.

| File | Purpose |
|------|---------|
| `arrows_models.dart` | Arrow definitions, game state, levels |
| `collision_engine.dart` | Hitbox detection between player and arrows |
| `arrows_game_screen.dart` | Main gameplay, scoring, lives, level progression |
| `arrows_lobby_screen.dart` | Level select with completion tracking |
| `arrows_painter.dart` | Custom `CustomPainter` for arrow rendering |
| `particle_system.dart` | Particle effects for collisions/explosions |

---

## 7. Services

### Audio Service (`audio_service.dart`)

Singleton with 2 audio players:
- `_musicPlayer` — Looping background tracks (lobby, blackjack, poker)
- `_sfxPlayer` — One-shot sound effects

**Sessions persisted:** mute state in `SharedPreferences`

**Music Tracks:** lobby_ambient.mp3, blackjack_music.mp3, poker_music.mp3

**SFX:** card_slide, card_flip, chips_bet, chips_win, win, lose, click, poker_chips, table_ambience, casino_atmosphere, tension_stinger, victory_stinger, dealer_* speech types

### Dealer Service (`dealer_service.dart`)

Premium dealer commentary system with mood engine:
- 6 moods: neutral, excited, dramatic, tense, congratulatory, sympathetic
- Auto-mood detection: high bets → excited, close scores → tense, wins → congratulatory
- Blackjack messages per phase (betting → dealing → playerTurn → dealerTurn → resolution)
- Poker messages per stage (preFlop → flop → turn → river → showdown)
- Betting prompts (urgency when time low, excitement on large bets)
- Win/loss messages (tiered by amount)
- Greetings/farewells
- 500+ unique message lines across all pools

### Progression Service (`progression_service.dart`)

XP/Level/Achievement system:
- Level = (XP / 500) + 1, progress bar shown in lobby
- 6 achievements: First Win, High Roller ($500+ bet), Blackjack Elite (natural 21), Poker Royal (3-of-a-kind+), Streak Master (3 wins), High Society (Level 3)
- Theme unlocks based on level (1: Classic → 6: Minimal Dark)
- Level-up banners and achievement unlock snackbars
- Data persisted in `SharedPreferences`

---

## 8. State Management Deep Dive

### Provider Pattern

```dart
// Declaration in viewmodel file
final gameProvider = StateNotifierProvider<GameViewModel, GameSessionState>((ref) {
  return GameViewModel();
});

// Consumption in view
final gameState = ref.watch(gameProvider);

// Actions via notifier
ref.read(gameProvider.notifier).hit();
```

### State Immutability

All state classes are `const` with `copyWith`:

```dart
state = state.copyWith(
  players: updatedPlayers,
  stage: GameStage.dealerTurn,
  statusMessage: 'Dealer\'s turn.',
);
```

### Game Stage Lifecycle

**Blackjack:** `betting → dealing → playerTurns → dealerTurn → payouts → roundEnded → betting`

**Poker:** `blinds → preFlop → flop → turn → river → showdown → roundEnded → blinds`

### Timer Management

Poker uses `Timer` for turn countdown (auto-fold on expiry):
```dart
_state = state.copyWith(turnTimeLeft: timeRemaining);
if (timeRemaining <= 0) {
  executeAction(PokerAction.fold());
}
```

---

## 9. Conventions

- **Imports:** Relative paths within features, no barrel files
- **Naming:** `_buildXxx` for widget methods, `_xxx` for private members
- **Widgets:** StatefulWidget + State pattern for screens, StatelessWidget for simple components
- **Constants:** All colors/themes in `CasinoTheme`, no magic color literals in views
- **Comments:** JSDoc-style doc comments on all public APIs
- **Formatting:** Standard `dart format`, `flutter_lints` enforced

---

## 10. Testing

Test files at `test/`:

| File | Scope |
|------|-------|
| `blackjack_test.dart` | Blackjack game logic, hand scoring, AI decisions |
| `poker_test.dart` | Hand evaluator: all 9 hand ranks, kicker resolution, edge cases |

**Run tests:**
```
flutter test
```

---

## 11. Assets

### Audio (`assets/sounds/`)

Music files generated via `tools/generate_casino_music.py` (Python script using synthesis libraries).

### Images (`assets/images/`)

Avatar images and other visual assets.

---

## 12. Build & Run

```bash
# Get dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Run tests
flutter test

# Analyze code
dart analyze lib/
```
