import 'card.dart';
import 'player.dart';

enum GameStage {
  betting,
  dealing,
  playerTurns,
  dealerTurn,
  payouts,
  roundEnded
}

class GameSessionState {
  final List<BlackjackPlayer> players;
  final BlackjackPlayer dealer;
  final int currentPlayerIndex; // Index in the players list, or -1 for dealer
  final int currentHandIndex; // Index of the hand currently being played (for splits)
  final List<BlackjackCard> deck;
  final GameStage stage;
  final double minBet;
  final double maxBet;
  final String tableTheme;
  final int roundNumber;
  final String? statusMessage;

  const GameSessionState({
    this.players = const [],
    required this.dealer,
    this.currentPlayerIndex = 0,
    this.currentHandIndex = 0,
    this.deck = const [],
    this.stage = GameStage.betting,
    this.minBet = 10.0,
    this.maxBet = 500.0,
    this.tableTheme = 'classic_vegas',
    this.roundNumber = 1,
    this.statusMessage,
  });

  bool get isDealerTurn => currentPlayerIndex == -1 || stage == GameStage.dealerTurn;

  BlackjackPlayer? get currentPlayer {
    if (currentPlayerIndex >= 0 && currentPlayerIndex < players.length) {
      return players[currentPlayerIndex];
    }
    return null;
  }

  GameSessionState copyWith({
    List<BlackjackPlayer>? players,
    BlackjackPlayer? dealer,
    int? currentPlayerIndex,
    int? currentHandIndex,
    List<BlackjackCard>? deck,
    GameStage? stage,
    double? minBet,
    double? maxBet,
    String? tableTheme,
    int? roundNumber,
    String? statusMessage,
  }) {
    return GameSessionState(
      players: players ?? this.players,
      dealer: dealer ?? this.dealer,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentHandIndex: currentHandIndex ?? this.currentHandIndex,
      deck: deck ?? this.deck,
      stage: stage ?? this.stage,
      minBet: minBet ?? this.minBet,
      maxBet: maxBet ?? this.maxBet,
      tableTheme: tableTheme ?? this.tableTheme,
      roundNumber: roundNumber ?? this.roundNumber,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  @override
  String toString() {
    return 'GameState(Stage: $stage, Players: ${players.length}, Turn: $currentPlayerIndex, Deck size: ${deck.length})';
  }
}
