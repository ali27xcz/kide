import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import '../utils/sounds.dart';
import 'local_storage.dart';

class AudioService {
  static AudioService? _instance;
  static Future<void>? _initFuture;
  late AudioPlayer _musicPlayer;
  late AudioPlayer _soundPlayer;
  ja.AudioPlayer? _jaMusic;
  late LocalStorageService _storage;
  final Map<String, Uint8List> _sfxBytesCache = {};
  Uint8List? _bgMusicBytes;
  Uint8List? _bgFallbackBytes;
  bool _bgMusicBroken = false;
  
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _isInitialized = false;
  
  AudioService._();
  
  static Future<AudioService> getInstance() async {
    _instance ??= AudioService._();
    if (!_instance!._isInitialized) {
      _initFuture ??= _instance!._initialize();
      await _initFuture;
      _initFuture = null;
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
      
      // Set a robust audio context for Android/iOS to ensure output to speaker and proper focus
      try {
        final context = AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
            stayAwake: true,
            isSpeakerphoneOn: true,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        );
        await AudioPlayer.global.setAudioContext(context);
        print('🔊 AudioService: Global AudioContext set');
      } catch (e) {
        print('🔊 AudioService: Error setting AudioContext: $e');
      }

      // Load settings
      try {
        final settings = await _storage.getGameSettings();
        _soundEnabled = settings['soundEnabled'] ?? true;
        _musicEnabled = settings['musicEnabled'] ?? true;
        // Force-enable on startup to recover from previous emulator/device failures
        if (!_soundEnabled) {
          _soundEnabled = true;
          await _storage.updateGameSetting('soundEnabled', true);
        }
        if (!_musicEnabled) {
          _musicEnabled = true;
          await _storage.updateGameSetting('musicEnabled', true);
        }
        print('🔊 AudioService: Settings loaded - Sound: $_soundEnabled, Music: $_musicEnabled');
      } catch (e) {
        print('🔊 AudioService: Error loading settings: $e');
        _soundEnabled = true;
        _musicEnabled = true;
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
      
      // Prepare just_audio for background music (more robust on Android)
      try {
        _jaMusic = ja.AudioPlayer();
        await _jaMusic!.setAsset('assets/${AppSounds.backgroundMusic}');
        await _jaMusic!.setLoopMode(ja.LoopMode.one);
        await _jaMusic!.setVolume(0.6);
      } catch (e) {
        print('🔊 AudioService: just_audio init failed: $e');
        // Disable just_audio path and fallback to bytes
        try {
          await _jaMusic?.dispose();
        } catch (_) {}
        _jaMusic = null;
        try {
          _bgMusicBytes = await _loadAssetBytes(AppSounds.backgroundMusic);
        } catch (_) {
          _bgMusicBytes = null;
        }
      }

      // Load a fallback background asset (short transition) to loop quietly if main BGM fails
      try {
        _bgFallbackBytes = await _loadAssetBytes(AppSounds.pageTransition);
      } catch (_) {
        _bgFallbackBytes = null;
      }

      _isInitialized = true;
      print('🔊 AudioService: Initialization completed successfully');
      // Attempt to start background music immediately if enabled
      await playBackgroundMusic();
    } catch (e) {
      print('🔊 AudioService: ERROR during initialization: $e');
      _isInitialized = false; // Mark as failed
    }
  }
  
  // Background Music Methods
  Future<void> playBackgroundMusic() async {
    if (!_isInitialized || !_musicEnabled || _bgMusicBroken) return;
    try {
      if (_jaMusic != null) {
        try {
          await _jaMusic!.play();
          return;
        } catch (e) {
          print('Error playing just_audio music: $e');
          try { await _jaMusic!.dispose(); } catch (_) {}
          _jaMusic = null;
        }
      }
      if (_bgMusicBytes != null) {
        await _musicPlayer.play(BytesSource(_bgMusicBytes!, mimeType: 'audio/mpeg'));
        return;
      } else {
        await _musicPlayer.play(AssetSource(AppSounds.backgroundMusic));
        return;
      }
    } catch (e) {
      print('Error playing background music: $e');
      // Try fallback short transition loop quietly
      try {
        if (_bgFallbackBytes != null) {
          await _musicPlayer.setReleaseMode(ReleaseMode.loop);
          await _musicPlayer.setVolume(0.3);
          await _musicPlayer.play(BytesSource(_bgFallbackBytes!, mimeType: 'audio/mpeg'));
          return;
        } else {
          await _musicPlayer.play(AssetSource(AppSounds.pageTransition));
          await _musicPlayer.setReleaseMode(ReleaseMode.loop);
          await _musicPlayer.setVolume(0.3);
          return;
        }
      } catch (e2) {
        print('Error playing fallback bgm: $e2');
        _bgMusicBroken = true; // stop retrying in this session
      }
    }
  }
  
  Future<void> stopBackgroundMusic() async {
    try {
      if (_jaMusic != null) {
        await _jaMusic!.stop();
      }
      await _musicPlayer.stop();
    } catch (e) {
      print('Error stopping background music: $e');
    }
  }
  
  Future<void> pauseBackgroundMusic() async {
    try {
      if (_jaMusic != null) {
        await _jaMusic!.pause();
      }
      await _musicPlayer.pause();
    } catch (e) {
      print('Error pausing background music: $e');
    }
  }
  
  Future<void> resumeBackgroundMusic() async {
    if (!_musicEnabled) return;
    
    try {
      if (_jaMusic != null) {
        await _jaMusic!.play();
      } else {
        await _musicPlayer.resume();
      }
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
      if (_sfxBytesCache.containsKey(soundPath)) {
        final String mime = _inferMimeType(soundPath);
        await _soundPlayer.play(BytesSource(_sfxBytesCache[soundPath]!, mimeType: mime));
      } else {
        await _soundPlayer.play(AssetSource(soundPath));
      }
      print('🔊 AudioService: Sound played successfully: $soundPath');
    } catch (e) {
      print('🔊 AudioService: ERROR playing sound $soundPath: $e');
      // Do not auto-disable; allow retry on next taps
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
    if (_jaMusic != null) {
      final s = _jaMusic!.playerState.playing;
      return s;
    }
    return _musicPlayer.state == PlayerState.playing;
  }
  
  bool get isSoundPlaying {
    return _soundPlayer.state == PlayerState.playing;
  }
  
  // Cleanup
  Future<void> dispose() async {
    try {
      if (_jaMusic != null) {
        await _jaMusic!.dispose();
      }
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
    // Preload common UI/SFX into memory and play via BytesSource to bypass MediaPlayer FD issues
    final List<String> commonSfx = [
      AppSounds.buttonClick,
      AppSounds.buttonHover,
      AppSounds.correctAnswer,
      AppSounds.incorrectAnswer,
      AppSounds.celebration,
      AppSounds.gameComplete,
      AppSounds.levelUp,
      AppSounds.mascotWelcome,
      AppSounds.mascotEncouragement,
      AppSounds.mascotCelebration,
      AppSounds.mascotTryAgain,
      ...AppSounds.encouragementSounds,
      ...AppSounds.tryAgainSounds,
    ];

    for (final path in commonSfx) {
      if (_sfxBytesCache.containsKey(path)) continue;
      try {
        final bytes = await _loadAssetBytes(path);
        if (bytes != null) {
          _sfxBytesCache[path] = bytes;
        }
      } catch (_) {
        // ignore individual preload failures
      }
    }
    print('🔊 AudioService: Preloaded SFX assets in memory: ${_sfxBytesCache.length}');
  }

  Future<Uint8List?> _loadAssetBytes(String relativePath) async {
    try {
      // All sounds are declared under assets/sounds/* in pubspec
      final byteData = await rootBundle.load('assets/$relativePath');
      return byteData.buffer.asUint8List();
    } catch (e) {
      print('🔊 AudioService: Failed to load asset bytes for $relativePath: $e');
      return null;
    }
  }

  String _inferMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    if (lower.endsWith('.aac')) return 'audio/aac';
    return 'audio/mpeg';
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