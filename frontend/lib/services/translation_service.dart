import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

// ── Mode enum ──────────────────────────────────────────────────────────────────
enum TranslationMode { online, offline, emergency }

// ── History entry ──────────────────────────────────────────────────────────────
class HistoryEntry {
  final int? id;
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final String engine;
  final double? latencyMs;
  final bool wasVoiceInput;
  final DateTime createdAt;

  HistoryEntry({
    this.id,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.engine,
    this.latencyMs,
    this.wasVoiceInput = false,
    required this.createdAt,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'],
        sourceText: json['source_text'] ?? '',
        translatedText: json['translated_text'] ?? '',
        sourceLang: json['source_lang'] ?? '',
        targetLang: json['target_lang'] ?? '',
        engine: json['engine'] ?? 'cloud',
        latencyMs: (json['latency_ms'] as num?)?.toDouble(),
        wasVoiceInput: json['was_voice_input'] ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
            : DateTime.now(),
      );
}

// ── Language model ─────────────────────────────────────────────────────────────
class LanguageItem {
  final String name;
  final String flag;
  final TranslateLanguage mlKitLang;
  final String ttsCode;
  final String sttLocale;

  LanguageItem({
    required this.name,
    required this.flag,
    required this.mlKitLang,
    required this.ttsCode,
    required this.sttLocale,
  });

  @override
  bool operator ==(Object other) =>
      other is LanguageItem && other.mlKitLang == mlKitLang;

  @override
  int get hashCode => mlKitLang.hashCode;
}

// ── Translation Service ────────────────────────────────────────────────────────
class TranslationService extends ChangeNotifier {
  static const String _baseUrl = AppConstants.apiBaseUrl;

  // ── Plugins ──────────────────────────────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late OnDeviceTranslator _onDeviceTranslator;
  final _modelManager = OnDeviceTranslatorModelManager();

  // ── Language catalogue ────────────────────────────────────────────────────────
  static final List<LanguageItem> supportedLanguages = [
    LanguageItem(name: 'English',    flag: '🇬🇧', mlKitLang: TranslateLanguage.english,    ttsCode: 'en-US', sttLocale: 'en-US'),
    LanguageItem(name: 'Hindi',      flag: '🇮🇳', mlKitLang: TranslateLanguage.hindi,      ttsCode: 'hi-IN', sttLocale: 'hi-IN'),
    LanguageItem(name: 'Telugu',     flag: '🇮🇳', mlKitLang: TranslateLanguage.telugu,     ttsCode: 'te-IN', sttLocale: 'te-IN'),
    LanguageItem(name: 'Kannada',    flag: '🇮🇳', mlKitLang: TranslateLanguage.kannada,    ttsCode: 'kn-IN', sttLocale: 'kn-IN'),
    LanguageItem(name: 'Tamil',      flag: '🇮🇳', mlKitLang: TranslateLanguage.tamil,      ttsCode: 'ta-IN', sttLocale: 'ta-IN'),
    LanguageItem(name: 'Marathi',    flag: '🇮🇳', mlKitLang: TranslateLanguage.marathi,    ttsCode: 'mr-IN', sttLocale: 'mr-IN'),
    LanguageItem(name: 'Japanese',   flag: '🇯🇵', mlKitLang: TranslateLanguage.japanese,   ttsCode: 'ja-JP', sttLocale: 'ja-JP'),
    LanguageItem(name: 'Spanish',    flag: '🇪🇸', mlKitLang: TranslateLanguage.spanish,    ttsCode: 'es-ES', sttLocale: 'es-ES'),
    LanguageItem(name: 'French',     flag: '🇫🇷', mlKitLang: TranslateLanguage.french,     ttsCode: 'fr-FR', sttLocale: 'fr-FR'),
    LanguageItem(name: 'German',     flag: '🇩🇪', mlKitLang: TranslateLanguage.german,     ttsCode: 'de-DE', sttLocale: 'de-DE'),
    LanguageItem(name: 'Arabic',     flag: '🇸🇦', mlKitLang: TranslateLanguage.arabic,     ttsCode: 'ar-SA', sttLocale: 'ar-SA'),
    LanguageItem(name: 'Chinese',    flag: '🇨🇳', mlKitLang: TranslateLanguage.chinese,    ttsCode: 'zh-CN', sttLocale: 'zh-CN'),
    LanguageItem(name: 'Korean',     flag: '🇰🇷', mlKitLang: TranslateLanguage.korean,     ttsCode: 'ko-KR', sttLocale: 'ko-KR'),
    LanguageItem(name: 'Portuguese', flag: '🇵🇹', mlKitLang: TranslateLanguage.portuguese, ttsCode: 'pt-PT', sttLocale: 'pt-PT'),
    LanguageItem(name: 'Russian',    flag: '🇷🇺', mlKitLang: TranslateLanguage.russian,    ttsCode: 'ru-RU', sttLocale: 'ru-RU'),
    LanguageItem(name: 'Malayalam',  flag: '🇮🇳', mlKitLang: TranslateLanguage.english, ttsCode: 'ml-IN', sttLocale: 'ml-IN'),
  ];

  // ── State ─────────────────────────────────────────────────────────────────────
  bool _isListening = false;
  bool _isTypingMode = false;
  String _sourceText = 'Click the mic or type to begin...';
  String _translatedText = '';
  LanguageItem _sourceLang = supportedLanguages[0];
  LanguageItem _targetLang = supportedLanguages[2];
  TranslationMode _currentMode = TranslationMode.online;
  bool _isEmergencyMode = false;
  bool _isDownloading = false;
  bool _isTranslating = false;
  double _lastLatencyMs = 0;
  String _lastEngine = 'cloud';
  String? _authToken;

  List<HistoryEntry> _localHistory = [];

  void updateAuth(dynamic auth) {
    if (auth.token != _authToken) {
      _authToken = auth.token;
      notifyListeners();
    }
  }

  // ── Getters ───────────────────────────────────────────────────────────────────
  bool get isListening      => _isListening;
  bool get isTypingMode     => _isTypingMode;
  bool get isTranslating    => _isTranslating;
  String get sourceText     => _sourceText;
  String get translatedText => _translatedText;
  LanguageItem get sourceLang   => _sourceLang;
  LanguageItem get targetLang   => _targetLang;
  TranslationMode get currentMode => _currentMode;
  bool get isEmergencyMode  => _isEmergencyMode;
  bool get isDownloading    => _isDownloading;
  double get lastLatencyMs  => _lastLatencyMs;
  String get lastEngine     => _lastEngine;
  List<HistoryEntry> get localHistory => List.unmodifiable(_localHistory);

  // ── Constructor ───────────────────────────────────────────────────────────────
  TranslationService() {
    _initTranslator();
    _initConnectivity();
    _initTts();
  }

  // ── Init ──────────────────────────────────────────────────────────────────────
  void _initTranslator() {
    _onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: _sourceLang.mlKitLang,
      targetLanguage: _targetLang.mlKitLang,
    );
  }

  Future<void> _initTts() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    
    // Log available voices for debugging
    try {
      final voices = await _tts.getVoices;
      debugPrint('Available TTS Voices: ${voices.length}');
    } catch (_) {}
  }

  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!_isEmergencyMode) {
        final hasInternet = results.any((r) => r != ConnectivityResult.none);
        _currentMode = hasInternet ? TranslationMode.online : TranslationMode.offline;
        notifyListeners();
      }
    });
    _refreshConnectivity();
  }

  Future<void> _refreshConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final hasInternet = results.any((r) => r != ConnectivityResult.none);
    _currentMode = hasInternet ? TranslationMode.online : TranslationMode.offline;
    notifyListeners();
  }

  // ── Language setters ──────────────────────────────────────────────────────────
  void updateSourceLang(LanguageItem lang) {
    _sourceLang = lang;
    _translatedText = '';
    _sourceText = 'Click the mic or type to begin...';
    _initTranslator();
    notifyListeners();
  }

  void updateTargetLang(LanguageItem lang) {
    _targetLang = lang;
    _translatedText = '';
    _initTranslator();
    notifyListeners();
  }

  void swapLanguages() {
    final tmp = _sourceLang;
    updateSourceLang(_targetLang);
    updateTargetLang(tmp);
  }

  // ── Typing mode ───────────────────────────────────────────────────────────────
  void setTypingMode(bool value) {
    _isTypingMode = value;
    if (value) {
      _isListening = false;
      _speech.stop();
      _sourceText = '';
    } else {
      _sourceText = 'Click the mic or type to begin...';
    }
    notifyListeners();
  }

  Future<void> translateTypedText(String text) async {
    if (text.trim().isEmpty) return;
    _sourceText = text;
    notifyListeners();
    await _performTranslation(text.trim(), voiceInput: false);
  }

  // ── Emergency mode ────────────────────────────────────────────────────────────
  void toggleEmergencyMode() {
    _isEmergencyMode = !_isEmergencyMode;
    _currentMode = _isEmergencyMode ? TranslationMode.emergency : TranslationMode.online;
    if (!_isEmergencyMode) _refreshConnectivity();
    notifyListeners();
  }

  // ── Speech-to-text ────────────────────────────────────────────────────────────
  Future<void> startListening() async {
    if (_isListening) { stopListening(); return; }

    _isTypingMode = false;
    _sourceText = 'Initializing mic...';
    notifyListeners();

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'notListening' || status == 'done') && _isListening) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (_isListening) _startSpeechListen();
            });
          }
        },
        onError: (err) {
          if (err.errorMsg == 'error_permission' || err.errorMsg == 'not-allowed') {
            _sourceText = 'MIC BLOCKED — Allow microphone access in browser settings.';
          } else if (err.errorMsg == 'network') {
            _sourceText = 'MIC ERROR — Internet required for voice recognition.';
          } else {
            _sourceText = 'MIC: ${err.errorMsg}. Tap again to retry.';
          }
          _isListening = false;
          notifyListeners();
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () => false);

      if (available) {
        _isListening = true;
        _translatedText = '';
        _sourceText = 'Listening... speak clearly';
        notifyListeners();
        _startSpeechListen();
      } else {
        _sourceText = 'Microphone unavailable. Check browser permissions.';
        _isListening = false;
        notifyListeners();
      }
    } catch (e) {
      _sourceText = 'STT error. Click the page first, then the mic.';
      _isListening = false;
      notifyListeners();
    }
  }

  void _startSpeechListen() {
    if (!_isListening) return;
    _speech.listen(
      onResult: (result) {
        _sourceText = result.recognizedWords;
        if (result.finalResult && _sourceText.trim().isNotEmpty) {
          _performTranslation(_sourceText.trim(), voiceInput: true);
        }
        notifyListeners();
      },
      localeId: _sourceLang.sttLocale,
      pauseFor: const Duration(seconds: 8),
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  // ── Translation ───────────────────────────────────────────────────────────────
  Future<void> _performTranslation(String text, {bool voiceInput = false}) async {
    _isTranslating = true;
    notifyListeners();

    final stopwatch = Stopwatch()..start();

    try {
      if (_authToken != null) {
        // Dynamic timeout: 12 seconds base, plus 1 second per 20 characters. Capped at 60s max.
        final int dynamicTimeout = (12 + (text.length ~/ 20)).clamp(12, 60);
        
        final response = await http.post(
          Uri.parse('$_baseUrl/translate'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',
          },
          body: jsonEncode({
            'text': text,
            'source_lang': _sourceLang.name,
            'target_lang': _targetLang.name,
            'was_voice_input': voiceInput,
          }),
        ).timeout(Duration(seconds: dynamicTimeout));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _translatedText = data['translated'];
          _lastLatencyMs = (data['latency_ms'] as num?)?.toDouble() ?? stopwatch.elapsedMilliseconds.toDouble();
          _lastEngine = data['engine'] ?? 'cloud';

          _addToLocalHistory(HistoryEntry(
            id: null,
            sourceText: text,
            translatedText: _translatedText,
            sourceLang: _sourceLang.name,
            targetLang: _targetLang.name,
            engine: _lastEngine,
            latencyMs: _lastLatencyMs,
            wasVoiceInput: voiceInput,
            createdAt: DateTime.now(),
          ));
        } else {
          await _fallbackOffline(text, voiceInput: voiceInput, stopwatch: stopwatch);
        }
      } else {
        await _fallbackOffline(text, voiceInput: voiceInput, stopwatch: stopwatch);
      }
    } catch (e) {
      debugPrint('Translation Error: $e');
      if (_translatedText.isEmpty) {
        _translatedText = 'API Unreachable. Ensure backend is running @ 127.0.0.1:8000';
      }
      await _fallbackOffline(text, voiceInput: voiceInput, stopwatch: stopwatch);
    }

    stopwatch.stop();
    _isTranslating = false;
    notifyListeners();
    
    // Auto-speak translated output for all modes
    if (_translatedText.isNotEmpty && 
        !_translatedText.startsWith('[') &&
        !_translatedText.startsWith('API')) {
      await _speak(_translatedText, _targetLang.name);
    }
  }

  Future<void> _fallbackOffline(String text, {required bool voiceInput, required Stopwatch stopwatch}) async {
    try {
      final isDownloaded = await _modelManager.isModelDownloaded(_targetLang.mlKitLang.bcpCode);
      if (!isDownloaded) {
        _isDownloading = true;
        _translatedText = 'Downloading ${_targetLang.name} model...';
        notifyListeners();
        await _modelManager.downloadModel(_targetLang.mlKitLang.bcpCode);
        _isDownloading = false;
      }
      _translatedText = await _onDeviceTranslator.translateText(text);
      _lastLatencyMs = stopwatch.elapsedMilliseconds.toDouble();
      _lastEngine = 'offline';

      _addToLocalHistory(HistoryEntry(
        id: null,
        sourceText: text,
        translatedText: _translatedText,
        sourceLang: _sourceLang.name,
        targetLang: _targetLang.name,
        engine: 'offline',
        latencyMs: _lastLatencyMs,
        wasVoiceInput: voiceInput,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Offline Fallback Error: $e');
      if (_translatedText.isEmpty || _translatedText == 'Downloading ${_targetLang.name} model...') {
        _translatedText = 'Translation failed. Check connection.';
      }
      _lastEngine = 'error';
    }
    _isDownloading = false;
  }

  // ── Offline Model Management ──────────────────────────────────────────────────
  Future<List<LanguageItem>> getDownloadedModels() async {
    List<LanguageItem> downloaded = [];
    // English is usually built-in or acts differently, but we check all supported.
    for (var lang in supportedLanguages) {
      try {
        final isDownloaded = await _modelManager.isModelDownloaded(lang.mlKitLang.bcpCode);
        if (isDownloaded) {
          downloaded.add(lang);
        }
      } catch (e) {
        debugPrint('Error checking model for ${lang.name}: $e');
      }
    }
    return downloaded;
  }

  Future<bool> deleteModel(LanguageItem lang) async {
    try {
      final success = await _modelManager.deleteModel(lang.mlKitLang.bcpCode);
      return success;
    } catch (e) {
      debugPrint('Error deleting model for ${lang.name}: $e');
      return false;
    }
  }

  Future<bool> downloadModel(LanguageItem lang) async {
    try {
      final success = await _modelManager.downloadModel(lang.mlKitLang.bcpCode);
      return success;
    } catch (e) {
      debugPrint('Error downloading model for ${lang.name}: $e');
      return false;
    }
  }

  // ── Local history ─────────────────────────────────────────────────────────────
  void _addToLocalHistory(HistoryEntry entry) {
    _localHistory.insert(0, entry);
    if (_localHistory.length > 100) _localHistory = _localHistory.sublist(0, 100);
  }

  Future<List<HistoryEntry>> fetchHistory() async {
    if (_authToken == null) return _localHistory;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/history?limit=100'),
        headers: {'Authorization': 'Bearer $_authToken'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => HistoryEntry.fromJson(e)).toList();
      }
    } catch (_) {}
    return _localHistory;
  }

  Future<void> deleteHistoryItem(int id) async {
    if (_authToken == null) return;
    try {
      await http.delete(
        Uri.parse('$_baseUrl/history/$id'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    if (_authToken == null) return;
    try {
      await http.delete(
        Uri.parse('$_baseUrl/history'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );
      _localHistory.clear();
      notifyListeners();
    } catch (_) {}
  }

  // ── TTS ───────────────────────────────────────────────────────────────────────
  Future<void> _speak(String text, String languageName) async {
    if (text.isEmpty) return;
    try {
      // Use Backend TTS for higher quality and better language support on Web
      String url = '$_baseUrl/tts?text=${Uri.encodeComponent(text)}&lang=$languageName';
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint('Cloud TTS Error, falling back to local: $e');
      // Final fallback to local TTS if cloud fails
      await _tts.setLanguage(_targetLang.ttsCode);
      await _tts.speak(text);
    }
  }

  Future<void> speakTranslation() async => _speak(_translatedText, _targetLang.name);
  Future<void> speakSource() async => _speak(_sourceText, _sourceLang.name);

  // ── Clipboard ─────────────────────────────────────────────────────────────────
  Future<void> copyTranslation() async {
    if (_translatedText.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _translatedText));
    }
  }

  Future<void> copySourceText() async {
    if (_sourceText.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _sourceText));
    }
  }

  // ── Emergency audio ───────────────────────────────────────────────────────────
  Future<void> playEmergencyCode(String code) async {
    const phrases = {
      'E01': 'I need medical help immediately',
      'E02': 'Please call the police now',
      'E03': 'I am lost, please help me find my way',
      'E04': 'I need water and food',
      'E05': 'There is danger nearby, stay away',
      'E06': 'I need a doctor urgently',
      'E07': 'Please call an ambulance',
    };

    final phrase = phrases[code] ?? 'Emergency';
    _sourceText = 'SOS: $phrase';
    notifyListeners();

    try {
      String translated;
      if (_authToken != null) {
        final response = await http.post(
          Uri.parse('$_baseUrl/translate'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',
          },
          body: jsonEncode({
            'text': phrase,
            'source_lang': 'English',
            'target_lang': _targetLang.name,
            'was_voice_input': false,
          }),
        ).timeout(const Duration(seconds: 4), onTimeout: () => http.Response('Timeout', 408));

        translated = response.statusCode == 200
            ? jsonDecode(response.body)['translated']
            : await _onDeviceTranslator.translateText(phrase);
      } else {
        translated = await _onDeviceTranslator.translateText(phrase);
      }

      _translatedText = translated;
      notifyListeners();
      // Use cloud TTS for consistent quality across all languages
      await _speak(translated, _targetLang.name);
    } catch (e) {
      _translatedText = phrase;
      notifyListeners();
      await _speak(phrase, 'English');
    }
  }

  // ── Clear ─────────────────────────────────────────────────────────────────────
  void clearTexts() {
    _sourceText = 'Click the mic or type to begin...';
    _translatedText = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _audioPlayer.dispose();
    _onDeviceTranslator.close();
    super.dispose();
  }
}
