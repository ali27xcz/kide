import 'package:audioplayers/audioplayers.dart';
import '../utils/sounds.dart';
import 'local_storage.dart';

class AudioService {
  static AudioService? _instance;
  late AudioPlayer _musicPlayer;
  late AudioPlayer _soundPlayer;
  late LocalStorageService _storage;
  
  bool _soundEnabled = false; // Disabled by default due to MediaPlayer issues
  bool _musicEnabled = false;
  bool _isInitialized = false;
  
  AudioService._();
  
  static Future<AudioService> getInstance() async {
    _instance ??= AudioService._();
    if (!_instance!._isInitialized) {
      await _instance!._initialize();
    }
    return _instance!;
  }
  
  Future<void> _initialize() async {
    print('🔊 AudioService: Starting initialization...');
    try {
      _musicPlayer = AudioPlayer(playerId: 'music');
      _soundPlayer = AudioPlayer(playerId: 'sfx');
      _storage = await LocalStorageService.getInstance();
      print('🔊 AudioService: Players created successfully');
      
      // Load settings (disabled by default to avoid MediaPlayer issues)
      try {
        final settings = await _storage.getGameSettings();
        _soundEnabled = settings['soundEnabled'] ?? false;
        _musicEnabled = settings['musicEnabled'] ?? false;
        print('🔊 AudioService: Settings loaded - Sound: $_soundEnabled, Music: $_musicEnabled');
      } catch (e) {
        print('🔊 AudioService: Error loading settings: $e');
        _soundEnabled = false;
        _musicEnabled = false;
      }
      
      // Basic player configuration only - no AudioContext
      try {
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        await _soundPlayer.setReleaseMode(ReleaseMode.stop);
        await _musicPlayer.setVolume(0.6);
        await _soundPlayer.setVolume(1.0);
      } catch (e) {
        print('Error configuring audio players: $e');
        // Continue without configuration
      }
      
      _isInitialized = true;
      print('🔊 AudioService: Initialization completed successfully');
    } catch (e) {
      print('🔊 AudioService: ERROR during initialization: $e');
      _isInitialized = false; // Mark as failed
    }
  }
  
  // Background Music Methods
  Future<void> playBackgroundMusic() async {
    if (!_isInitialized || !_musicEnabled) return;
    try {
      await _musicPlayer.play(AssetSource(AppSounds.backgroundMusic));
    } catch (e) {
      print('Error playing background music: $e');
      // Auto-disable music on unrecoverable emulator errors to avoid loops
      try {
        _musicEnabled = false;
        await _storage.updateGameSetting('musicEnabled', false);
      } catch (_) {}
    }
  }
  
  Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (e) {
      print('Error stopping background music: $e');
    }
  }
  
  Future<void> pauseBackgroundMusic() async {
    try {
      await _musicPlayer.pause();
    } catch (e) {
      print('Error pausing background music: $e');
    }
  }
  
  Future<void> resumeBackgroundMusic() async {
    if (!_musicEnabled) return;
    
    try {
      await _musicPlayer.resume();
    } catch (e) {
      print('Error resuming background music: $e');
    }
  }
  
  // Sound Effects Methods
  Future<void> playSound(String soundPath) async {
    print('🔊 AudioService: playSound called - Path: $soundPath, Enabled: $_soundEnabled, Initialized: $_isInitialized');
    if (!_isInitialized || !_soundEnabled || soundPath.isEmpty) {
      print('🔊 AudioService: Sound not played - Initialized: $_isInitialized, Enabled: $_soundEnabled, Path empty: ${soundPath.isEmpty}');
      return;
    }
    
    try {
      print('🔊 AudioService: Attempting to play sound: $soundPath');
      await _soundPlayer.play(AssetSource(soundPath));
      print('🔊 AudioService: Sound played successfully: $soundPath');
    } catch (e) {
      print('🔊 AudioService: ERROR playing sound $soundPath: $e');
      // Auto-disable sounds on emulator media errors to keep UX smooth
      try {
        _soundEnabled = false;
        await _storage.updateGameSetting('soundEnabled', false);
      } catch (_) {}
    }
  }
  
  Future<void> playCorrectSound() async {
    await playSound(AppSounds.correctAnswer);
  }
  
  Future<void> playIncorrectSound() async {
    await playSound(AppSounds.incorrectAnswer);
  }
  
  Future<void> playGameCompleteSound() async {
    await playSound(AppSounds.gameComplete);
  }
  
  Future<void> playLevelUpSound() async {
    await playSound(AppSounds.levelUp);
  }
  
  Future<void> playCelebrationSound() async {
    await playSound(AppSounds.celebration);
  }
  
  Future<void> playButtonClickSound() async {
    await playSound(AppSounds.buttonClick);
  }
  
  Future<void> playButtonHoverSound() async {
    await playSound(AppSounds.buttonHover);
  }
  
  // Character Sounds
  Future<void> playMascotWelcome() async {
    await playSound(AppSounds.mascotWelcome);
  }
  
  Future<void> playMascotEncouragement() async {
    await playSound(AppSounds.mascotEncouragement);
  }
  
  Future<void> playMascotCelebration() async {
    await playSound(AppSounds.mascotCelebration);
  }
  
  Future<void> playMascotTryAgain() async {
    await playSound(AppSounds.mascotTryAgain);
  }
  
  // Educational Sounds
  Future<void> playNumberSound(int number) async {
    final soundPath = AppSounds.getNumberSound(number);
    await playSound(soundPath);
  }
  
  Future<void> playShapeSound(String shape) async {
    final soundPath = AppSounds.getShapeSound(shape);
    await playSound(soundPath);
  }
  
  Future<void> playColorSound(String color) async {
    final soundPath = AppSounds.getColorSound(color);
    await playSound(soundPath);
  }
  
  // Random Encouragement
  Future<void> playRandomEncouragement() async {
    if (AppSounds.encouragementSounds.isEmpty) return;
    
    final randomIndex = DateTime.now().millisecondsSinceEpoch % AppSounds.encouragementSounds.length;
    final soundPath = AppSounds.encouragementSounds[randomIndex];
    await playSound(soundPath);
  }
  
  Future<void> playRandomTryAgain() async {
    if (AppSounds.tryAgainSounds.isEmpty) return;
    
    final randomIndex = DateTime.now().millisecondsSinceEpoch % AppSounds.tryAgainSounds.length;
    final soundPath = AppSounds.tryAgainSounds[randomIndex];
    await playSound(soundPath);
  }
  
  // Settings Methods
  Future<void> setSoundEnabled(bool enabled) async {
    print('🔊 AudioService: setSoundEnabled called with: $enabled');
    _soundEnabled = enabled;
    await _storage.updateGameSetting('soundEnabled', enabled);
    print('🔊 AudioService: Sound enabled set to: $_soundEnabled');
    
    if (!enabled) {
      await _soundPlayer.stop();
    }
  }
  
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await _storage.updateGameSetting('musicEnabled', enabled);
    
    if (!enabled) {
      await stopBackgroundMusic();
    } else {
      await playBackgroundMusic();
    }
  }
  
  bool get isSoundEnabled => _soundEnabled;
  bool get isMusicEnabled => _musicEnabled;
  
  // Volume Control
  Future<void> setMusicVolume(double volume) async {
    try {
      await _musicPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Error setting music volume: $e');
    }
  }
  
  Future<void> setSoundVolume(double volume) async {
    try {
      await _soundPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Error setting sound volume: $e');
    }
  }
  
  // Player State
  bool get isMusicPlaying {
    return _musicPlayer.state == PlayerState.playing;
  }
  
  bool get isSoundPlaying {
    return _soundPlayer.state == PlayerState.playing;
  }
  
  // Cleanup
  Future<void> dispose() async {
    try {
      await _musicPlayer.dispose();
      await _soundPlayer.dispose();
    } catch (e) {
      print('Error disposing audio players: $e');
    }
  }

  // Stop all playing audio (music and sfx)
  Future<void> stopAll() async {
    try {
      await _musicPlayer.stop();
    } catch (_) {}
    try {
      await _soundPlayer.stop();
    } catch (_) {}
  }
  
  // Skip preloading to avoid MediaPlayer issues
  Future<void> preloadSounds() async {
    print('Audio preloading skipped to avoid MediaPlayer conflicts on Android');
  }
  
  // Game-specific sound sequences
  Future<void> playGameStartSequence() async {
    await playMascotWelcome();
    await Future.delayed(const Duration(milliseconds: 500));
    await playButtonClickSound();
  }
  
  Future<void> playGameEndSequence(bool isSuccess) async {
    if (isSuccess) {
      await playCelebrationSound();
      await Future.delayed(const Duration(milliseconds: 1000));
      await playMascotCelebration();
    } else {
      await playMascotTryAgain();
    }
  }
  
  Future<void> playLevelCompleteSequence(int stars) async {
    await playGameCompleteSound();
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Play different sounds based on stars earned
    if (stars >= 3) {
      await playCelebrationSound();
      await playMascotCelebration();
    } else if (stars >= 2) {
      await playRandomEncouragement();
    } else {
      await playMascotEncouragement();
    }
  }
}