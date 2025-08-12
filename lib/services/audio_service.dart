import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:math' as math;
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
  String? _bgMusicAssetPath; // current selected background music
  String? _menuMusicAssetPath; // dedicated games menu background music
  String _bgMusicMime = 'audio/mpeg';
  // Music context to avoid races: 'general' or 'menu'
  String _musicContext = 'general';
  bool _isRecovering = false;
  
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
      
      // Apply more specific contexts per player (helps Android emulator and route changes)
      try {
        await _musicPlayer.setAudioContext(
          AudioContext(
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
          ),
        );
        await _soundPlayer.setAudioContext(
          AudioContext(
            android: AudioContextAndroid(
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.assistanceSonification,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
              isSpeakerphoneOn: true,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.ambient,
              options: {AVAudioSessionOptions.mixWithOthers},
            ),
          ),
        );
        print('🔊 AudioService: Per-player AudioContexts applied');
      } catch (e) {
        print('🔊 AudioService: Error setting per-player AudioContexts: $e');
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
      
      // Resolve background music asset paths (general and games menu)
      try {
        // General background
        final generalCandidates = [
          AppSounds.backgroundMusic,
          'sounds/background_music.ogg',
          'sounds/background_music.mp3',
          'sounds/background_music.wav',
        ];
        for (final p in generalCandidates) {
          try {
            final bd = await rootBundle.load('assets/' + p);
            if (bd.lengthInBytes < 128) continue;
            _bgMusicAssetPath = p;
            if (p.endsWith('.ogg')) _bgMusicMime = 'audio/ogg';
            else if (p.endsWith('.wav')) _bgMusicMime = 'audio/wav';
            else _bgMusicMime = 'audio/mpeg';
            break;
          } catch (_) {}
        }
        // Games menu background
        try {
          final bd = await rootBundle.load('assets/' + AppSounds.gamesMenuBackgroundMusic);
          if (bd.lengthInBytes >= 128) {
            _menuMusicAssetPath = AppSounds.gamesMenuBackgroundMusic;
          }
        } catch (_) {}
      } catch (_) {}

      // Prepare just_audio for background music (more robust on Android)
      if (_bgMusicAssetPath != null) {
        try {
          _jaMusic = ja.AudioPlayer();
          await _jaMusic!.setAsset('assets/'+_bgMusicAssetPath!);
          await _jaMusic!.setLoopMode(ja.LoopMode.one);
          await _jaMusic!.setVolume(0.6);
        } catch (e) {
          print('🔊 AudioService: just_audio init failed: $e');
          try { await _jaMusic?.dispose(); } catch (_) {}
          _jaMusic = null;
        }
      } else {
        // No valid background asset found -> disable music gracefully
        _musicEnabled = false;
        try { await _storage.updateGameSetting('musicEnabled', false); } catch (_) {}
      }

      // Load a fallback background asset (short transition) to loop quietly if main BGM fails
      try {
        _bgFallbackBytes = await _loadAssetBytes(AppSounds.pageTransition);
      } catch (_) {
        _bgFallbackBytes = null;
      }

      _isInitialized = true;
      print('🔊 AudioService: Initialization completed successfully');
      // Start according to current context
      if (_musicEnabled) {
        if (_musicContext == 'menu') {
          await playMenuBackgroundMusic();
        } else {
          await playBackgroundMusic();
        }
      }
    } catch (e) {
      print('🔊 AudioService: ERROR during initialization: $e');
      _isInitialized = false; // Mark as failed
    }
  }
  
  // Background Music Methods
  Future<void> playBackgroundMusic() async {
    if (!_isInitialized || !_musicEnabled || _bgMusicBroken) return;
    // Do not override menu BGM if it's the current context
    if (_musicContext == 'menu') return;
    try {
      _musicContext = 'general';
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
      // If no valid bgm, silently skip
      if (_bgMusicAssetPath != null) {
        final rel = _bgMusicAssetPath!;
        await _musicPlayer.play(AssetSource(rel));
      }
      return;
    } catch (e) {
      print('Error playing background music: $e');
      // Try fallback short transition loop quietly
      try {
        // As a last resort, just disable bgm to avoid crashes on some devices
        _musicEnabled = false;
        await _storage.updateGameSetting('musicEnabled', false);
        return;
      } catch (e2) {
        print('Error playing fallback bgm: $e2');
        _bgMusicBroken = true; // stop retrying in this session
        try {
          _musicEnabled = false;
          await _storage.updateGameSetting('musicEnabled', false);
        } catch (_) {}
      }
    }
  }

  Future<void> playMenuBackgroundMusic() async {
    if (!_isInitialized || !_musicEnabled || _bgMusicBroken) return;
    if (_menuMusicAssetPath == null) {
      await playBackgroundMusic();
      return;
    }
    try {
      _musicContext = 'menu';
      // Stop any general music and play menu-specific track
      if (_jaMusic != null) {
        try { await _jaMusic!.stop(); } catch (_) {}
      }
      await _musicPlayer.stop();
      await _musicPlayer.play(AssetSource(_menuMusicAssetPath!));
    } catch (e) {
      print('Error playing menu background music: $e');
      await playBackgroundMusic();
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
      await _recoverPlayers();
      try {
        await playBackgroundMusic();
      } catch (_) {}
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
      // Prefer bytes source (more reliable on emulators and after route changes)
      final bd = await _loadAssetBytes(soundPath);
      if (bd != null) {
        try {
          await _soundPlayer.play(BytesSource(bd, mimeType: _inferMimeType(soundPath)));
          print('🔊 AudioService: Sound played successfully (bytes): $soundPath');
          return;
        } catch (e) {
          print('🔊 AudioService: Bytes playback failed, falling back to AssetSource: $e');
          await _soundPlayer.play(AssetSource(soundPath));
          print('🔊 AudioService: Sound played successfully (asset): $soundPath');
          return;
        }
      }
      // If asset missing/broken
      final lower = soundPath.toLowerCase();
      // For UI micro-sounds (click/hover/transition), skip synthesis to avoid unwanted beeps
      if (lower.contains('click') || lower.contains('hover') || lower.contains('transition')) {
        print('🔊 AudioService: UI sound missing, skipping synthesis: $soundPath');
        return;
      }
      // Do NOT synthesize for key experience sounds (end game / game over / mascot)
      final isKeyExperienceSound = lower.contains('endgame') || lower.contains('game-over') || lower.contains('mascot_');
      if (isKeyExperienceSound) {
        print('🔊 AudioService: Key sound missing, skipping synthesis: $soundPath');
        return;
      }
      // Otherwise synthesize a short tone as a fallback
      final synth = _generateToneForPath(soundPath);
      await _soundPlayer.play(BytesSource(synth, mimeType: 'audio/wav'));
      print('🔊 AudioService: Sound synthesized for: $soundPath');
    } catch (e) {
      print('🔊 AudioService: ERROR playing sound $soundPath: $e');
      await _recoverPlayers();
      // Retry once after recovery
      try {
        final cached = _sfxBytesCache[soundPath] ?? await _loadAssetBytes(soundPath);
        if (cached != null) {
          await _soundPlayer.play(BytesSource(cached, mimeType: _inferMimeType(soundPath)));
          print('🔊 AudioService: Sound recovered and played (bytes): $soundPath');
          return;
        }
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
      AppSounds.endGame,
      AppSounds.gameOver,
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
      final bytes = byteData.buffer.asUint8List();
      // Treat tiny files as invalid
      if (bytes.lengthInBytes < 128) return null;
      // Cache for faster retries and emulator reliability
      _sfxBytesCache[relativePath] = bytes;
      return bytes;
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

  // ======= Tone synthesis fallback =======
  Uint8List _generateToneForPath(String path) {
    // Map different categories to different tones/durations
    double freq = 440; // A4 default
    int ms = 180;
    final p = path.toLowerCase();
    if (p.contains('correct')) { freq = 880; ms = 220; }
    else if (p.contains('incorrect') || p.contains('try_again')) { freq = 220; ms = 250; }
    else if (p.contains('level_up') || p.contains('celebration') || p.contains('game_complete')) { freq = 660; ms = 300; }
    else if (p.contains('click') || p.contains('hover')) { freq = 520; ms = 120; }
    else if (p.contains('/numbers/')) {
      // numbers/1.mp3 .. -> map to frequency 300 + n*20
      final match = RegExp(r"numbers/(\d+)").firstMatch(p);
      final n = match != null ? int.tryParse(match.group(1)!) ?? 1 : 1;
      freq = 300 + (n.clamp(1, 20) * 20);
      ms = 120;
    } else if (p.contains('/colors/')) {
      if (p.contains('red')) freq = 500;
      else if (p.contains('blue')) freq = 600;
      else if (p.contains('green')) freq = 700;
      else if (p.contains('yellow')) freq = 800;
      else if (p.contains('orange')) freq = 550;
      else if (p.contains('purple')) freq = 650;
      ms = 140;
    } else if (p.contains('/shapes/')) {
      if (p.contains('circle')) freq = 430;
      else if (p.contains('square')) freq = 470;
      else if (p.contains('triangle')) freq = 510;
      else if (p.contains('rectangle')) freq = 490;
      else if (p.contains('star')) freq = 750;
      ms = 160;
    }
    return _sineWav(frequencyHz: freq, durationMs: ms, volume: 0.6);
  }

  Uint8List _sineWav({double frequencyHz = 440, int sampleRate = 44100, int durationMs = 200, double volume = 0.5}) {
    final int totalSamples = ((durationMs / 1000) * sampleRate).round();
    final bytesPerSample = 2; // 16-bit PCM
    final dataSize = totalSamples * bytesPerSample;
    final int headerSize = 44;
    final totalSize = headerSize + dataSize;
    final buffer = BytesBuilder();
    void writeString(String s) => buffer.add(s.codeUnits);
    void writeInt32(int value) => buffer.add([value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF]);
    void writeInt16(int value) => buffer.add([value & 0xFF, (value >> 8) & 0xFF]);
    // RIFF header
    writeString('RIFF');
    writeInt32(totalSize - 8);
    writeString('WAVE');
    writeString('fmt ');
    writeInt32(16); // PCM chunk size
    writeInt16(1); // PCM format
    writeInt16(1); // mono
    writeInt32(sampleRate);
    writeInt32(sampleRate * bytesPerSample);
    writeInt16(bytesPerSample); // block align
    writeInt16(16); // bits per sample
    writeString('data');
    writeInt32(dataSize);
    // Samples
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final sample = (volume * 32767 * math.sin(2 * 3.141592653589793 * frequencyHz * t)).round();
      writeInt16(sample);
    }
    return Uint8List.fromList(buffer.toBytes());
  }

  // ======= Robust recovery on device route changes or emulator failures =======
  Future<void> _recoverPlayers() async {
    if (_isRecovering) return;
    _isRecovering = true;
    print('🔊 AudioService: Attempting player recovery...');
    try {
      // Stop and dispose existing players
      try { await _musicPlayer.stop(); } catch (_) {}
      try { await _soundPlayer.stop(); } catch (_) {}
      try { await _jaMusic?.dispose(); } catch (_) {}

      // Recreate players
      _musicPlayer = AudioPlayer(playerId: 'music');
      _soundPlayer = AudioPlayer(playerId: 'sfx');

      // Re-apply per-player audio contexts
      try {
        await _musicPlayer.setAudioContext(
          AudioContext(
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
          ),
        );
        await _soundPlayer.setAudioContext(
          AudioContext(
            android: AudioContextAndroid(
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.assistanceSonification,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
              isSpeakerphoneOn: true,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.ambient,
              options: {AVAudioSessionOptions.mixWithOthers},
            ),
          ),
        );
      } catch (e) {
        print('🔊 AudioService: Error re-applying AudioContexts during recovery: $e');
      }

      // Re-apply release modes and volumes
      try {
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        await _soundPlayer.setReleaseMode(ReleaseMode.stop);
        await _musicPlayer.setVolume(0.6);
        await _soundPlayer.setVolume(1.0);
      } catch (_) {}

      // Recreate just_audio player if we had a bg music asset
      if (_bgMusicAssetPath != null) {
        try {
          _jaMusic = ja.AudioPlayer();
          await _jaMusic!.setAsset('assets/'+_bgMusicAssetPath!);
          await _jaMusic!.setLoopMode(ja.LoopMode.one);
          await _jaMusic!.setVolume(0.6);
        } catch (e) {
          print('🔊 AudioService: just_audio recovery failed: $e');
          try { await _jaMusic?.dispose(); } catch (_) {}
          _jaMusic = null;
        }
      }

      print('🔊 AudioService: Player recovery complete');
    } catch (e) {
      print('🔊 AudioService: Player recovery error: $e');
    } finally {
      _isRecovering = false;
    }
  }

  // Public hook to be called on potential route changes (e.g., Bluetooth disconnect)
  Future<void> recoverAudioRoute() async {
    await _recoverPlayers();
    if (_musicEnabled) {
      try { await playBackgroundMusic(); } catch (_) {}
    }
  }
  
  // Game-specific sound sequences
  Future<void> playGameStartSequence() async {
    await playMascotWelcome();
    await Future.delayed(const Duration(milliseconds: 500));
    await playButtonClickSound();
  }
  
  Future<void> playGameEndSequence(bool isSuccess) async {
    // On success: ensure EndGame.mp3 is actually played; if missing, do not substitute to other SFX
    if (isSuccess) {
      bool played = false;
      try { played = await _playIfAssetExists(AppSounds.endGame); } catch (_) { played = false; }
      if (!played) {
        print('🔊 AudioService: EndGame.mp3 not found or invalid. Please add assets/sounds/EndGame.mp3');
      }
      return;
    } else {
      // On failure, play end cue then game over / try again
      try { await _playIfAssetExists(AppSounds.endGame); } catch (_) {}
      // Play game over sound on full failure (bytes-only). If missing, play random try again phrase
      final playedOver = await _playIfAssetExists(AppSounds.gameOver).catchError((_) => false) ?? false;
      if (!playedOver) {
        await playRandomTryAgain();
      }
      // Then mascot try again (skip if missing)
      final _ = await _playIfAssetExists(AppSounds.mascotTryAgain).catchError((_) => false);
    }
  }

  Future<bool> _playIfAssetExists(String relativePath) async {
    try {
      final bd = await _loadAssetBytes(relativePath);
      if (bd == null || bd.isEmpty) return false;
      await _soundPlayer.play(BytesSource(bd, mimeType: _inferMimeType(relativePath)));
      return true;
    } catch (_) {
      return false;
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