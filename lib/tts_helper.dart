import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, paused, stopped }

class TtsEngine extends ChangeNotifier {
  static final TtsEngine instance = TtsEngine._();
  TtsEngine._() {
    _initTts();
  }

  final FlutterTts _tts = FlutterTts();
  TtsState _state = TtsState.stopped;
  double _speechRate = 0.45; // Natural pace for Tamil
  int? _currentSpeakingVerse;

  TtsState get state => _state;
  double get speechRate => _speechRate;
  int? get currentSpeakingVerse => _currentSpeakingVerse;

  Future<void> _initTts() async {
    await _tts.setLanguage("ta-IN");
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      _state = TtsState.playing;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      _state = TtsState.stopped;
      _currentSpeakingVerse = null;
      notifyListeners();
    });

    _tts.setCancelHandler(() {
      _state = TtsState.stopped;
      _currentSpeakingVerse = null;
      notifyListeners();
    });

    _tts.setPauseHandler(() {
      _state = TtsState.paused;
      notifyListeners();
    });

    _tts.setContinueHandler(() {
      _state = TtsState.playing;
      notifyListeners();
    });
  }

  Future<void> speakText(String text, {int? verseNumber}) async {
    _currentSpeakingVerse = verseNumber;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> pause() async {
    await _tts.pause();
  }

  Future<void> stop() async {
    await _tts.stop();
    _currentSpeakingVerse = null;
    _state = TtsState.stopped;
    notifyListeners();
  }

  Future<void> setRate(double rate) async {
    _speechRate = rate;
    await _tts.setSpeechRate(rate);
    notifyListeners();
  }
}