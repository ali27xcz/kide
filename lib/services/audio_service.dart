import 'package:audioplayers/audioplayers.dart';
import '../utils/sounds.dart';
import 'local_storage.dart';

class AudioService {
  static AudioService? _instance;
  late AudioPlayer _musicPlayer;
  late AudioPlayer _soundPlayer;
  late LocalStorageService _storage;
  
  bool _soundEnabled = true;
  bool _musicEnabled = true;
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
    try {
      _musicPlayer = AudioPlayer();
      _soundPlayer = AudioPlayer();
      _storage = await LocalStorageService.getInstance();
      
      // Load settings (with fallback)
      try {
        final settings = await _storage.getGameSettings();
        _soundEnabled = settings['soundEnabled'] ?? true;
        _musicEnabled = settings['musicEnabled'] ?? true;
      } catch (e) {
        print('Error loading audio settings: $e');
        _soundEnabled = true;
        _musicEnabled = true;
      }
      
      // Configure players (with error handling)
      try {
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        await _soundPlayer.setReleaseMode(ReleaseMode.stop);
      } catch (e) {
        print('Error configuring audio players: $e');
        // Continue without configuration
      }
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing AudioService: $e');
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
    if (!_isInitialized || !_soundEnabled || soundPath.isEmpty) return;
    
    try {
      await _soundPlayer.play(AssetSource(soundPath));
    } catch (e) {
      print('Error playing sound $soundPath: $e');
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
    _soundEnabled = enabled;
    await _storage.updateGameSetting('soundEnabled', enabled);
    
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
  
  // Preload sounds for better performance
  Future<void> preloadSounds() async {
    final soundsToPreload = [
      AppSounds.correctAnswer,
      AppSounds.incorrectAnswer,
      AppSounds.buttonClick,
      AppSounds.celebration,
    ];
    
    for (final soundPath in soundsToPreload) {
      try {
        final player = AudioPlayer();
        await player.setSource(AssetSource(soundPath));
        await player.dispose();
      } catch (e) {
        print('Error preloading sound $soundPath: $e');
      }
    }
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

