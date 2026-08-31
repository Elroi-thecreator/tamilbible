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
  double _pitch = 0.8; // Lower pitch produces a clear male voice
  int? _currentSpeakingVerse;

  TtsState get state => _state;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  int? get currentSpeakingVerse => _currentSpeakingVerse;

  Future<void> _initTts() async {
    await _tts.setLanguage("ta-IN");
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_pitch);

    // Try setting an explicit male voice if supported by the Android TTS engine
    try {
      final List<dynamic>? voices = await _tts.getVoices;
      if (voices != null) {
        for (var voice in voices) {
          final name = voice['name']?.toString().toLowerCase() ?? '';
          final locale = voice['locale']?.toString() ?? '';
          if (locale.contains('ta') && (name.contains('male') || name.contains('network') || name.contains('tag'))) {
            await _tts.setVoice({"name": voice['name'], "locale": locale});
            break;
          }
        }
      }
    } catch (_) {}

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

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _tts.setPitch(pitch);
    notifyListeners();
  }
}