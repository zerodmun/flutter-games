import 'dart:math';

/// Represents the current emotional state of the dealer.
///
/// The mood influences the tone and selection of dealer commentary,
/// creating a dynamic and immersive casino atmosphere.
enum DealerMood {
  /// Default calm, professional demeanor.
  neutral,

  /// High-energy, enthusiastic reactions (big bets, hot streaks).
  excited,

  /// Heightened suspense, pivotal game moments.
  dramatic,

  /// Pressure-filled situations (close scores, all-in moments).
  tense,

  /// Celebrating a player victory.
  congratulatory,

  /// Consoling after a loss.
  sympathetic,
}

/// Represents the current phase of a Blackjack game.
enum BlackjackPhase {
  betting,
  dealing,
  playerTurn,
  dealerTurn,
  resolution,
}

/// Represents the current stage of a Poker hand.
enum PokerStage {
  preFlop,
  flop,
  turn,
  river,
  showdown,
}

/// A premium Dealer Commentary System that generates context-aware,
/// cinematic dealer messages for both Blackjack and Poker games.
///
/// This singleton service selects from curated themed message pools,
/// influenced by the dealer's current [DealerMood]. Messages are designed
/// to feel premium, immersive, and varied — never repetitive.
///
/// Usage:
/// ```dart
/// final dealer = DealerService();
/// dealer.updateMood(playerScore: 20, dealerScore: 18, betAmount: 500);
/// final msg = dealer.getBlackjackMessage(
///   BlackjackPhase.playerTurn, 20, 18, 500,
/// );
/// ```
class DealerService {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------

  /// Private constructor.
  DealerService._internal();

  /// The shared singleton instance.
  static final DealerService _instance = DealerService._internal();

  /// Factory constructor returns the singleton instance.
  factory DealerService() => _instance;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final Random _rng = Random();

  /// The dealer's current mood — automatically updated via [updateMood]
  /// or set explicitly via [setMood].
  DealerMood currentMood = DealerMood.neutral;

  // ---------------------------------------------------------------------------
  // Mood Management
  // ---------------------------------------------------------------------------

  /// Explicitly sets the dealer mood.
  void setMood(DealerMood mood) {
    currentMood = mood;
  }

  /// Automatically determines the appropriate [DealerMood] based on the
  /// current game state.
  ///
  /// Call this at key moments (after a bet, after a card is dealt, etc.)
  /// to keep dealer commentary tonally consistent.
  void updateMood({
    int? playerScore,
    int? dealerScore,
    double? betAmount,
    double? potSize,
    bool? playerWon,
    bool? playerLost,
  }) {
    // Congratulatory / sympathetic take priority.
    if (playerWon == true) {
      currentMood = DealerMood.congratulatory;
      return;
    }
    if (playerLost == true) {
      currentMood = DealerMood.sympathetic;
      return;
    }

    // High-stakes excitement.
    if ((betAmount != null && betAmount >= 500) ||
        (potSize != null && potSize >= 1000)) {
      currentMood = DealerMood.excited;
      return;
    }

    // Tense close games.
    if (playerScore != null && dealerScore != null) {
      final diff = (playerScore - dealerScore).abs();
      if (diff <= 2 && playerScore >= 17) {
        currentMood = DealerMood.tense;
        return;
      }
      if (playerScore >= 19 || dealerScore >= 19) {
        currentMood = DealerMood.dramatic;
        return;
      }
    }

    currentMood = DealerMood.neutral;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Picks a random entry from [pool]. Returns the provided [fallback] if
  /// the pool is empty.
  String _pick(List<String> pool, [String fallback = '...']) {
    if (pool.isEmpty) return fallback;
    return pool[_rng.nextInt(pool.length)];
  }

  /// Merges the mood-specific messages with the base list, giving
  /// mood-aware variety.
  String _pickWithMood(
    List<String> basePool,
    Map<DealerMood, List<String>> moodPools, [
    String fallback = '...',
  ]) {
    final moodMessages = moodPools[currentMood] ?? const [];
    final combined = [...basePool, ...moodMessages];
    return _pick(combined, fallback);
  }

  // ---------------------------------------------------------------------------
  // Blackjack Messages
  // ---------------------------------------------------------------------------

  /// Returns a context-aware dealer message for the current Blackjack phase.
  ///
  /// The message is selected from curated pools based on [gamePhase],
  /// [playerScore], [dealerScore], and [betAmount], further influenced
  /// by the dealer's [currentMood].
  String getBlackjackMessage(
    BlackjackPhase gamePhase,
    int playerScore,
    int dealerScore,
    double betAmount,
  ) {
    // Auto-adjust mood for contextual accuracy.
    updateMood(
      playerScore: playerScore,
      dealerScore: dealerScore,
      betAmount: betAmount,
    );

    switch (gamePhase) {
      case BlackjackPhase.betting:
        return _pickWithMood(
          _bjBetting,
          {
            DealerMood.excited: const [
              'The table is hot tonight — place your wager!',
              'I can feel the energy. What\'s your play?',
            ],
            DealerMood.neutral: const [
              'Take your time. The cards will wait.',
              'A measured bet is a wise bet.',
            ],
          },
        );

      case BlackjackPhase.dealing:
        return _pickWithMood(
          _bjDealing,
          {
            DealerMood.dramatic: const [
              'Destiny is being dealt…',
              'The cards have spoken.',
            ],
          },
        );

      case BlackjackPhase.playerTurn:
        if (playerScore == 21) {
          return _pick(const [
            'Blackjack! A magnificent hand!',
            'Twenty-one — perfection.',
            'Natural blackjack. The crowd goes wild.',
          ]);
        }
        if (playerScore >= 17) {
          return _pickWithMood(
            const [
              'You\'re in strong territory. Stand or push your luck?',
              'A respectable hand. The question is — do you dare?',
              'Seventeen and above. Tread carefully.',
            ],
            {
              DealerMood.tense: const [
                'One card could make or break you…',
                'The razor\'s edge. Choose wisely.',
              ],
              DealerMood.dramatic: const [
                'All eyes are on your next move.',
                'The table holds its breath.',
              ],
            },
          );
        }
        return _pickWithMood(
          const [
            'Interesting position. What will it be?',
            'Hit or stand? The choice is yours.',
            'The cards are listening…',
          ],
          {
            DealerMood.excited: const [
              'Room to maneuver — I like it!',
              'Plenty of possibilities here.',
            ],
          },
        );

      case BlackjackPhase.dealerTurn:
        return _pickWithMood(
          _bjDealerTurn,
          {
            DealerMood.dramatic: const [
              'Now it\'s my turn to test fate.',
              'The dealer reveals…',
            ],
            DealerMood.tense: const [
              'Let\'s see what the house has in store.',
              'This could go either way.',
            ],
          },
        );

      case BlackjackPhase.resolution:
        return _pickWithMood(
          const [
            'And there we have it.',
            'The hand is complete.',
            'A round to remember.',
          ],
          {
            DealerMood.congratulatory: const [
              'Well played! The house tips its hat.',
              'Victory suits you.',
            ],
            DealerMood.sympathetic: const [
              'The cards weren\'t kind this time.',
              'Every loss sharpens the instinct.',
            ],
          },
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Poker Messages
  // ---------------------------------------------------------------------------

  /// Returns a context-aware dealer message for the current Poker stage.
  ///
  /// Commentary adapts to [pokerStage], [potSize], [numActivePlayers],
  /// and whether it is the player's turn ([isPlayerTurn]).
  String getPokerMessage(
    PokerStage pokerStage,
    double potSize,
    int numActivePlayers,
    bool isPlayerTurn,
  ) {
    updateMood(potSize: potSize);

    switch (pokerStage) {
      case PokerStage.preFlop:
        return _pickWithMood(
          _pokerPreFlop,
          {
            DealerMood.excited: const [
              'Big blinds on the table — let\'s see who\'s bold.',
              'The opening act. Don\'t blink.',
            ],
          },
        );

      case PokerStage.flop:
        return _pickWithMood(
          _pokerFlop,
          {
            DealerMood.dramatic: const [
              'Three cards that could change everything.',
              'The flop speaks volumes. Listen closely.',
            ],
            DealerMood.tense: const [
              'The board is treacherous…',
              'Connections everywhere — who\'s ahead?',
            ],
          },
        );

      case PokerStage.turn:
        return _pickWithMood(
          _pokerTurn,
          {
            DealerMood.dramatic: const [
              'The turn card arrives. Recalculate.',
              'One card reshapes the battlefield.',
            ],
            DealerMood.excited: const [
              'The pot is swelling — who wants it most?',
            ],
          },
        );

      case PokerStage.river:
        return _pickWithMood(
          _pokerRiver,
          {
            DealerMood.dramatic: const [
              'The river — last chance for glory.',
              'Final card. Final breath.',
            ],
            DealerMood.tense: const [
              'Everything rides on this card.',
              'Do or die. The river decides.',
            ],
          },
        );

      case PokerStage.showdown:
        if (numActivePlayers <= 2) {
          return _pick(const [
            'Heads up — reveal your cards.',
            'Two remain. Show your strength.',
            'Cards on the table. No more secrets.',
          ]);
        }
        return _pickWithMood(
          const [
            'Showdown! Let\'s see what you\'re holding.',
            'The moment of truth has arrived.',
            'All cards face up. No hiding now.',
          ],
          {
            DealerMood.excited: const [
              'What a hand! This showdown is one for the books.',
            ],
          },
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Betting Prompts
  // ---------------------------------------------------------------------------

  /// Returns a contextual betting prompt influenced by [timeRemaining],
  /// [betAmount], and [balance].
  String getBettingPrompt(
    int timeRemaining,
    double betAmount,
    double balance,
  ) {
    if (timeRemaining <= 5) {
      return _pick(const [
        'Last call for bets!',
        'Five seconds — make your move!',
        'The clock is ticking…',
        'Now or never!',
      ]);
    }

    if (betAmount >= balance * 0.5) {
      return _pickWithMood(
        const [
          'Going big tonight. Fortune favors the bold.',
          'A wager that commands attention.',
          'The stakes have never been higher.',
        ],
        {
          DealerMood.excited: const [
            'Now THAT\'S a bet. All eyes on you.',
            'Bold move. I respect it.',
          ],
          DealerMood.tense: const [
            'Half your stack on the line… nerves of steel.',
          ],
        },
      );
    }

    return _pickWithMood(
      const [
        'Place your bets, ladies and gentlemen.',
        'What\'s your wager this round?',
        'The table awaits your decision.',
        'How much are you willing to risk?',
      ],
      {
        DealerMood.neutral: const [
          'Take your time. Consider your position.',
        ],
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Win / Loss Messages
  // ---------------------------------------------------------------------------

  /// Returns a celebratory message after a player win.
  ///
  /// Incorporates [winAmount] and [gameName] for specificity.
  String getWinMessage(double winAmount, String gameName) {
    setMood(DealerMood.congratulatory);

    if (winAmount >= 1000) {
      return _pick(const [
        'A spectacular win! The high-roller table is calling.',
        'Incredible. You just made history at this table.',
        'One thousand and beyond — a legendary hand.',
        'The house salutes you. What a triumph!',
        'You\'ve cleaned the felt tonight. Magnificent.',
      ]);
    }
    if (winAmount >= 500) {
      return _pick(const [
        'A handsome reward. Well deserved.',
        'Five hundred reasons to celebrate.',
        'The cards smiled upon you tonight.',
        'A victory that echoes through the hall.',
      ]);
    }
    return _pick(const [
      'Winner, winner. Nicely done.',
      'A win is a win — savor it.',
      'Well played. The pot is yours.',
      'Victory! May the streak continue.',
      'Fortune has chosen its champion.',
    ]);
  }

  /// Returns a consoling message after a player loss.
  ///
  /// [gameName] contextualizes the message.
  String getLoseMessage(String gameName) {
    setMood(DealerMood.sympathetic);

    return _pick(const [
      'The house wins this round. But the night is young.',
      'A setback, nothing more. Champions are built from losses.',
      'The cards can be cruel. Your moment will come.',
      'Not this time. But fortune is a wheel — it turns.',
      'Every great player has weathered a storm.',
      'The table remembers resilience, not defeat.',
      'Shake it off. The next hand could change everything.',
      'Even the legends lose a hand. Keep your composure.',
    ]);
  }

  // ---------------------------------------------------------------------------
  // Greetings & Farewells
  // ---------------------------------------------------------------------------

  /// Returns a premium dealer greeting when the player enters.
  String getDealerGreeting() {
    setMood(DealerMood.neutral);

    return _pick(const [
      'Welcome to the table. Let\'s make tonight unforgettable.',
      'Good evening. May fortune walk beside you.',
      'The stage is set. Welcome, player.',
      'Ah, a new challenger. I\'ve been expecting you.',
      'Take a seat. The cards are feeling generous tonight.',
      'Welcome back. The felt remembers you.',
      'Step right up. Destiny is dealt one card at a time.',
      'The house welcomes you. Shall we begin?',
    ]);
  }

  /// Returns a premium dealer farewell when the player leaves.
  String getDealerFarewell() {
    return _pick(const [
      'Until next time. May luck travel with you.',
      'The table will miss you. Come back soon.',
      'A pleasure, as always. Safe travels.',
      'The cards will be here when you return.',
      'Farewell, player. The house respects a graceful exit.',
      'Until we meet again at the felt.',
      'Go well. And remember — the house always has a seat for you.',
      'The night may end, but the game never does. See you soon.',
    ]);
  }

  // ---------------------------------------------------------------------------
  // Curated Message Pools (private, const)
  // ---------------------------------------------------------------------------

  static const List<String> _bjBetting = [
    'Place your bets, ladies and gentlemen.',
    'The felt is waiting for your wager.',
    'How much do you trust your instincts?',
    'Set your stake. Let the cards decide the rest.',
    'A new hand, a new opportunity.',
  ];

  static const List<String> _bjDealing = [
    'Cards are in the air…',
    'Let\'s see what fate has in store.',
    'Two cards each. Here we go.',
    'The deal begins. Watch closely.',
    'Fresh cards, fresh possibilities.',
  ];

  static const List<String> _bjDealerTurn = [
    'My turn. Let\'s see what the house holds.',
    'The dealer plays…',
    'Time for the house to show its hand.',
    'Stand back — the dealer draws.',
    'And now, the moment you\'ve been waiting for.',
  ];

  static const List<String> _pokerPreFlop = [
    'Hole cards dealt. Read \'em and weep — or smile.',
    'Two cards, infinite possibilities.',
    'The hand begins. Trust your read.',
    'Pre-flop. What\'s your opening move?',
    'Pocket cards in hand. The game is afoot.',
  ];

  static const List<String> _pokerFlop = [
    'The flop is down. Three cards to ponder.',
    'Community cards revealed. Adjust your strategy.',
    'The board takes shape. Who\'s connected?',
    'Three on the felt. The plot thickens.',
  ];

  static const List<String> _pokerTurn = [
    'The turn. One more piece of the puzzle.',
    'Fourth street arrives. Reconsider your odds.',
    'The turn card changes the calculus.',
    'Another card, another layer of intrigue.',
  ];

  static const List<String> _pokerRiver = [
    'The river. Your last card, your last chance.',
    'Fifth street. Everything is on the line.',
    'The final community card. Make your move.',
    'The river flows. Where does it take you?',
  ];
}
