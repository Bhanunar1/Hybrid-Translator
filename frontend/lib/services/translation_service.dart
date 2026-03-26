import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;

// ── Mode enum ──────────────────────────────────────────────────────────────────
enum TranslationMode { online, offline, emergency }

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

// ── Service ────────────────────────────────────────────────────────────────────
class TranslationService extends ChangeNotifier {
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
    LanguageItem(name: 'Malayalam',  flag: '🇮🇳', mlKitLang: TranslateLanguage.english,    ttsCode: 'ml-IN', sttLocale: 'ml-IN'),
  ];

  // ── State ─────────────────────────────────────────────────────────────────────
  bool _isListening = false;
  String _sourceText = 'Click the mic to begin...';
  String _translatedText = '';
  LanguageItem _sourceLang = supportedLanguages[0]; // English
  LanguageItem _targetLang = supportedLanguages[2]; // Telugu
  TranslationMode _currentMode = TranslationMode.online;
  bool _isEmergencyMode = false;
  bool _isDownloading = false;
  String? _authToken;

  void updateAuth(dynamic auth) {
    if (auth.token != _authToken) {
      _authToken = auth.token;
      notifyListeners();
    }
  }

  // ── Getters ───────────────────────────────────────────────────────────────────
  bool get isListening     => _isListening;
  String get sourceText    => _sourceText;
  String get translatedText => _translatedText;
  LanguageItem get sourceLang   => _sourceLang;
  LanguageItem get targetLang   => _targetLang;
  TranslationMode get currentMode  => _currentMode;
  bool get isEmergencyMode => _isEmergencyMode;
  bool get isDownloading   => _isDownloading;

  // ── Constructor ───────────────────────────────────────────────────────────────
  TranslationService() {
    _initTranslator();
    _initConnectivity();
  }

  // ── Initializers ──────────────────────────────────────────────────────────────
  void _initTranslator() {
    _onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: _sourceLang.mlKitLang,
      targetLanguage: _targetLang.mlKitLang,
    );
  }
  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!_isEmergencyMode) {
        final hasInternet = results.isNotEmpty &&
            results.any((r) => r != ConnectivityResult.none);
        _currentMode = hasInternet
            ? TranslationMode.online
            : TranslationMode.offline;
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
    _sourceText = 'Click the mic to begin...';
    _initTranslator();
    notifyListeners();
  }

  void updateTargetLang(LanguageItem lang) {
    _targetLang = lang;
    _translatedText = '';
    _initTranslator();
    notifyListeners();
  }

  // ── Emergency mode ────────────────────────────────────────────────────────────
  void toggleEmergencyMode() {
    _isEmergencyMode = !_isEmergencyMode;
    _currentMode = _isEmergencyMode
        ? TranslationMode.emergency
        : TranslationMode.online;
    if (!_isEmergencyMode) _refreshConnectivity();
    notifyListeners();
  }

  // ── Speech-to-text ────────────────────────────────────────────────────────────
  Future<void> startListening() async {
    if (_isListening) {
      stopListening();
      return;
    }
    
    _sourceText = 'Initializing mic...';
    notifyListeners();

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'notListening' || status == 'done') {
            if (_isListening) {
              Future.delayed(const Duration(milliseconds: 800), () {
                if (_isListening) _startSpeechListen();
              });
            }
          }
        },
        onError: (err) {
          debugPrint('STT Error: ${err.errorMsg}');
          if (err.errorMsg == 'error_permission' || err.errorMsg == 'not-allowed') {
            _sourceText = 'MIC ERROR: Blocked. Click the LOCK icon in address bar -> Allow Microphone.';
          } else if (err.errorMsg == 'network') {
            _sourceText = 'MIC ERROR: Internet required for Edge voice recognition.';
          } else {
             _sourceText = 'MIC STATUS: ${err.errorMsg}. Try again.';
          }
          _isListening = false;
          notifyListeners();
        }
      ).timeout(const Duration(seconds: 10), onTimeout: () => false);

      if (available) {
        _isListening = true;
        _translatedText = '';
        _sourceText = 'Mic Ready. Speak clearly...';
        notifyListeners();
        _startSpeechListen();
      } else {
        _sourceText = 'MIC ERROR: Engine failed. \n1. Check Edge Settings. \n2. Refresh Page.';
        _isListening = false;
        notifyListeners();
      }
    } catch (e) {
      _sourceText = 'STT ERROR: Interaction required. Click page then Mic.';
      _isListening = false;
      notifyListeners();
    }
  }

  void _startSpeechListen() {
    if (!_isListening) return;
    try {
      _speech.listen(
        onResult: (result) {
          _sourceText = result.recognizedWords;
          if (result.finalResult && _sourceText.trim().isNotEmpty) {
            _performTranslation(_sourceText.trim());
          }
          notifyListeners();
        },
        localeId: _sourceLang.sttLocale,
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('Listen error: $e');
    }
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  // ── Translation ───────────────────────────────────────────────────────────────
  Future<void> _performTranslation(String text) async {
    try {
      if (_currentMode == TranslationMode.online) {
        final response = await http.post(
          Uri.parse('http://localhost:8000/translate'),
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
          body: jsonEncode({
            'text': text,
            'source_lang': _sourceLang.name,
            'target_lang': _targetLang.name,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _translatedText = data['translated'];
        } else {
          _translatedText = await _onDeviceTranslator.translateText(text);
        }
      } else {
        final isDownloaded =
            await _modelManager.isModelDownloaded(_targetLang.mlKitLang.bcpCode);
        if (!isDownloaded) {
          _isDownloading = true;
          _translatedText = 'Downloading ${_targetLang.name} model…';
          notifyListeners();
          await _modelManager.downloadModel(_targetLang.mlKitLang.bcpCode);
          _isDownloading = false;
        }
        _translatedText = await _onDeviceTranslator.translateText(text);
      }
    } catch (e) {
      try {
        _translatedText = await _onDeviceTranslator.translateText(text);
      } catch (_) {
        _translatedText = 'Translation failed. Check connection.';
      }
    }
    _isDownloading = false;
    notifyListeners();
    await _speak(_translatedText);
  }

  // ── TTS ───────────────────────────────────────────────────────────────────────
  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    await _tts.setLanguage(_targetLang.ttsCode);
    await _tts.speak(text);
  }

  Future<void> speakTranslation() async => _speak(_translatedText);

  // ── Emergency audio ───────────────────────────────────────────────────────────
  Future<void> playEmergencyCode(String code) async {
    String phrase = '';
    switch (code) {
      case 'E01': phrase = 'I need medical help immediately'; break;
      case 'E02': phrase = 'Please call the police now'; break;
      case 'E03': phrase = 'I am lost, please help me find my way'; break;
      case 'E04': phrase = 'I need water and food'; break;
      case 'E05': phrase = 'There is danger nearby, stay away'; break;
      default: phrase = 'Emergency';
    }

    _sourceText = 'SOS: $phrase';
    notifyListeners();

    try {
      String translated;
      final response = await http.post(
        Uri.parse('http://localhost:8000/translate'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'text': phrase,
          'source_lang': 'English',
          'target_lang': _targetLang.name,
        }),
      ).timeout(const Duration(seconds: 4), onTimeout: () => http.Response('Timeout', 408));

      if (response.statusCode == 200) {
        translated = jsonDecode(response.body)['translated'];
      } else {
        final emergencyTranslator = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.english,
          targetLanguage: _targetLang.mlKitLang,
        );
        translated = await emergencyTranslator.translateText(phrase);
        await emergencyTranslator.close();
      }
      
      _translatedText = translated;
      notifyListeners();
      
      await _tts.setLanguage(_targetLang.ttsCode);
      await _tts.setVolume(1.0);
      await _tts.speak(translated);
    } catch (e) {
      _translatedText = phrase;
      notifyListeners();
      await _tts.setLanguage('en-US');
      await _tts.speak(phrase);
    }
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
