import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  String? _currentTrack;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool('audio_muted') ?? false;
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    if (_isMuted) {
      await _musicPlayer.setVolume(0.0);
      await _sfxPlayer.setVolume(0.0);
    } else {
      await _musicPlayer.setVolume(0.5);
      await _sfxPlayer.setVolume(1.0);
    }
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_muted', _isMuted);

    if (_isMuted) {
      await _musicPlayer.setVolume(0.0);
      await _sfxPlayer.setVolume(0.0);
    } else {
      await _musicPlayer.setVolume(0.5);
      await _sfxPlayer.setVolume(1.0);
    }
  }

  // ───────────────────────────────────────────────
  //  Music Playback (Looping background tracks)
  // ───────────────────────────────────────────────

  Future<void> _playMusic(String assetPath) async {
    // Don't restart the same track if already playing
    if (_currentTrack == assetPath) return;
    _currentTrack = assetPath;
    if (_isMuted) return;
    try {
      await _musicPlayer.stop();
      await _musicPlayer.play(AssetSource(assetPath));
    } catch (_) {
      // Fail silently if asset is missing or audio driver fails
    }
  }

  /// Smooth jazz lounge music for the lobby screen
  Future<void> playLobbyMusic() async {
    await _playMusic('sounds/lobby_ambient.mp3');
  }

  /// Elegant casino table music for blackjack
  Future<void> playBlackjackMusic() async {
    await _playMusic('sounds/blackjack_music.mp3');
  }

  /// Cool tension atmosphere for poker
  Future<void> playPokerMusic() async {
    await _playMusic('sounds/poker_music.mp3');
  }

  Future<void> stopMusic() async {
    _currentTrack = null;
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  // ───────────────────────────────────────────────
  //  SFX Playback (One-shot sound effects)
  // ───────────────────────────────────────────────

  Future<void> playSfx(String effect) async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.play(AssetSource('sounds/$effect.mp3'));
    } catch (_) {
      // Fail silently if asset is missing
    }
  }

  // SFX triggers
  void playCardSlide() => playSfx('card_slide');
  void playCardFlip() => playSfx('card_flip');
  void playChipsBet() => playSfx('chips_bet');
  void playChipsWin() => playSfx('chips_win');
  void playWin() => playSfx('win');
  void playLose() => playSfx('lose');
  void playClick() => playSfx('click');
  void playPokerChipsSound() => playSfx('poker_chips');
  void playTableAmbience() => playSfx('table_ambience');
  void playCasinoAtmosphere() => playSfx('casino_atmosphere');
  void playTensionStinger() => playSfx('tension_stinger');
  void playVictoryStinger() => playSfx('victory_stinger');
  void playDealerSpeech(String speechType) => playSfx('dealer_$speechType');
}
