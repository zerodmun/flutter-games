import 'poker_card.dart';
import 'poker_player.dart';

enum PokerStage {
  blinds,
  preFlop,
  flop,
  turn,
  river,
  showdown,
  roundEnded
}

class PokerGameState {
  final List<PokerPlayer> players;
  final List<PokerCard> communityCards;
  final List<PokerCard> deck;
  final int dealerIndex;
  final int currentPlayerIndex;
  final PokerStage stage;
  final double pot;
  final double currentRaise; // The minimum amount of the next raise
  final double smallBlind;
  final double bigBlind;
  final String? statusMessage;
  final int roundNumber;
  final String tableTheme;
  final double currentBetToCall; // The total bet amount a player must match to call
  final int turnTimeLeft;
  final bool isFastMode;
  final bool isFastForward;

  const PokerGameState({
    this.players = const [],
    this.communityCards = const [],
    this.deck = const [],
    this.dealerIndex = 0,
    this.currentPlayerIndex = 0,
    this.stage = PokerStage.blinds,
    this.pot = 0.0,
    this.currentRaise = 0.0,
    this.smallBlind = 10.0,
    this.bigBlind = 20.0,
    this.statusMessage,
    this.roundNumber = 1,
    this.tableTheme = 'classic_vegas',
    this.currentBetToCall = 0.0,
    this.turnTimeLeft = 15,
    this.isFastMode = false,
    this.isFastForward = false,
  });

  PokerPlayer? get currentPlayer {
    if (currentPlayerIndex >= 0 && currentPlayerIndex < players.length) {
      return players[currentPlayerIndex];
    }
    return null;
  }

  PokerGameState copyWith({
    List<PokerPlayer>? players,
    List<PokerCard>? communityCards,
    List<PokerCard>? deck,
    int? dealerIndex,
    int? currentPlayerIndex,
    PokerStage? stage,
    double? pot,
    double? currentRaise,
    double? smallBlind,
    double? bigBlind,
    String? statusMessage,
    int? roundNumber,
    String? tableTheme,
    double? currentBetToCall,
    int? turnTimeLeft,
    bool? isFastMode,
    bool? isFastForward,
  }) {
    return PokerGameState(
      players: players ?? this.players,
      communityCards: communityCards ?? this.communityCards,
      deck: deck ?? this.deck,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      stage: stage ?? this.stage,
      pot: pot ?? this.pot,
      currentRaise: currentRaise ?? this.currentRaise,
      smallBlind: smallBlind ?? this.smallBlind,
      bigBlind: bigBlind ?? this.bigBlind,
      statusMessage: statusMessage ?? this.statusMessage,
      roundNumber: roundNumber ?? this.roundNumber,
      tableTheme: tableTheme ?? this.tableTheme,
      currentBetToCall: currentBetToCall ?? this.currentBetToCall,
      turnTimeLeft: turnTimeLeft ?? this.turnTimeLeft,
      isFastMode: isFastMode ?? this.isFastMode,
      isFastForward: isFastForward ?? this.isFastForward,
    );
  }

  @override
  String toString() {
    return 'PokerGameState(Stage: $stage, Pot: $pot, Active Turn: $currentPlayerIndex, Comm: ${communityCards.length}, FastForward: $isFastForward)';
  }
}
