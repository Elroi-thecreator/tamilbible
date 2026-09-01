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
  double _speechRate = 0.45;
  double _pitch = 0.85;

  List<String> _verseQueue = [];
  int _currentIndex = 0;

  TtsState get state => _state;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  int get currentIndex => _currentIndex;

  Future<void> _initTts() async {
    await _tts.setLanguage("ta-IN");
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_pitch);

    _tts.setCompletionHandler(() {
      _playNextVerse();
    });

    _tts.setErrorHandler((msg) {
      _state = TtsState.stopped;
      notifyListeners();
    });

    _tts.setCancelHandler(() {
      _state = TtsState.stopped;
      notifyListeners();
    });
  }

  Future<void> startChapter(List<String> verses) async {
    _verseQueue = verses.where((v) => v.trim().isNotEmpty).toList();
    _currentIndex = 0;
    if (_verseQueue.isEmpty) return;

    _state = TtsState.playing;
    notifyListeners();
    await _speakCurrent();
  }

  Future<void> _speakCurrent() async {
    if (_currentIndex < _verseQueue.length && _state == TtsState.playing) {
      notifyListeners();
      await _tts.speak(_verseQueue[_currentIndex]);
    } else {
      stop();
    }
  }

  void _playNextVerse() {
    if (_state != TtsState.playing) return;
    _currentIndex++;
    if (_currentIndex < _verseQueue.length) {
      _speakCurrent();
    } else {
      stop();
    }
  }

  Future<void> pause() async {
    _state = TtsState.paused;
    await _tts.stop();
    notifyListeners();
  }

  Future<void> resume() async {
    if (_verseQueue.isEmpty) return;
    _state = TtsState.playing;
    notifyListeners();
    await _speakCurrent();
  }

  Future<void> stop() async {
    _state = TtsState.stopped;
    _verseQueue.clear();
    _currentIndex = 0;
    await _tts.stop();
    notifyListeners();
  }

  Future<void> setRate(double rate) async {
    _speechRate = rate;
    await _tts.setSpeechRate(rate);
    notifyListeners();
  }
}