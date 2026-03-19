import 'dart:js' as js;

class TtsService {
  static const double _defaultRate = 0.92;
  static const double _defaultPitch = 1.0;
  static const double _defaultVolume = 1.0;
  static const String _fallbackLang = 'en-US';

  // Reproduce text using the browser Web Speech API.
  // Returns false when TTS is not available in the current browser.
  static bool speak(
    String text, {
    String preferredLanguage = 'auto',
  }) {
    final normalized = _normalizeForSpeech(text);
    if (normalized.isEmpty) {
      return false;
    }

    final synthAny = js.context['speechSynthesis'];
    if (synthAny is! js.JsObject) {
      return false;
    }

    final utteranceCtor = js.context['SpeechSynthesisUtterance'];
    if (utteranceCtor == null) {
      return false;
    }

    final targetLanguage = _resolveLanguage(normalized, preferredLanguage);
    synthAny.callMethod('cancel');

    final utterance = js.JsObject(
      utteranceCtor,
      [normalized],
    );

    final selectedVoice = _getBestVoice(synthAny, targetLanguage);
    if (selectedVoice != null) {
      utterance['voice'] = selectedVoice;
    }

    utterance['lang'] = targetLanguage;
    utterance['rate'] = _defaultRate;
    utterance['pitch'] = _defaultPitch;
    utterance['volume'] = _defaultVolume;

    synthAny.callMethod('speak', [utterance]);
    return true;
  }

  static String _normalizeForSpeech(String text) {
    final withSpaces = text
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (withSpaces.isEmpty) {
      return '';
    }

    final words = withSpaces.split(' ');
    final normalizedWords = words.map((word) {
      final hasLetters = RegExp(r'[A-Za-z]').hasMatch(word);
      final isAllCaps =
          hasLetters && word.length > 1 && word == word.toUpperCase();
      if (isAllCaps) {
        return word.toLowerCase();
      }
      return word;
    });

    return normalizedWords.join(' ');
  }

  static String _resolveLanguage(String text, String preferredLanguage) {
    final requested = preferredLanguage.trim();
    if (requested.isNotEmpty && requested.toLowerCase() != 'auto') {
      return requested;
    }

    if (_looksLikeSpanish(text)) {
      return 'es-CO';
    }
    return _fallbackLang;
  }

  static bool _looksLikeSpanish(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'[\u00e1\u00e9\u00ed\u00f3\u00fa\u00f1\u00bf\u00a1]')
        .hasMatch(lower)) {
      return true;
    }

    const hints = <String>[
      ' el ',
      ' la ',
      ' de ',
      ' y ',
      ' que ',
      ' para ',
      ' con ',
      ' por ',
      ' una ',
      ' un ',
      ' estoy ',
      ' gracias ',
      ' hola ',
    ];

    final padded = ' $lower ';
    for (final token in hints) {
      if (padded.contains(token)) {
        return true;
      }
    }
    return false;
  }

  static js.JsObject? _getBestVoice(
    js.JsObject synth,
    String targetLanguage,
  ) {
    final js.JsArray voices;
    try {
      voices = synth.callMethod('getVoices') as js.JsArray;
    } catch (_) {
      return null;
    }

    if (voices.isEmpty) {
      return null;
    }

    final targetLower = targetLanguage.toLowerCase();
    final targetBase = targetLower.split('-').first;

    js.JsObject? googleExact;
    js.JsObject? googleBase;
    js.JsObject? microsoftExact;
    js.JsObject? microsoftBase;
    js.JsObject? anyExact;
    js.JsObject? anyBase;

    for (var i = 0; i < voices.length; i++) {
      final voice = voices[i] as js.JsObject;
      final name = (voice['name']?.toString() ?? '').toLowerCase();
      final lang = (voice['lang']?.toString() ?? '').toLowerCase();

      final isGoogle = name.contains('google');
      final isMicrosoft = name.contains('microsoft');
      final matchesExact = lang == targetLower;
      final matchesBase = lang.startsWith(targetBase);

      if (isGoogle && matchesExact && googleExact == null) {
        googleExact = voice;
      } else if (isGoogle && matchesBase && googleBase == null) {
        googleBase = voice;
      } else if (isMicrosoft && matchesExact && microsoftExact == null) {
        microsoftExact = voice;
      } else if (isMicrosoft && matchesBase && microsoftBase == null) {
        microsoftBase = voice;
      } else if (matchesExact && anyExact == null) {
        anyExact = voice;
      } else if (matchesBase && anyBase == null) {
        anyBase = voice;
      }
    }

    return googleExact ??
        googleBase ??
        microsoftExact ??
        microsoftBase ??
        anyExact ??
        anyBase;
  }

  static void stop() {
    js.context['speechSynthesis']?.callMethod('cancel');
  }

  static bool get isSupported => js.context['speechSynthesis'] != null;

  static void listVoices() {
    final synthAny = js.context['speechSynthesis'];
    if (synthAny is! js.JsObject) {
      print('[TTS] Web Speech API is not available in this browser.');
      return;
    }

    final js.JsArray voices;
    try {
      voices = synthAny.callMethod('getVoices') as js.JsArray;
    } catch (e) {
      print('[TTS] Failed to read voices: $e');
      return;
    }

    if (voices.isEmpty) {
      print('[TTS] No voices are available yet.');
      return;
    }

    print('[TTS] ${voices.length} voices available:');
    for (var i = 0; i < voices.length; i++) {
      final voice = voices[i] as js.JsObject;
      final name = voice['name'];
      final lang = voice['lang'];
      final local = voice['localService'];
      final isDefault = voice['default'];
      print('  [$i] $name | $lang | local=$local | default=$isDefault');
    }

    final best = _getBestVoice(synthAny, _fallbackLang);
    if (best != null) {
      print('[TTS] Auto-selected voice: ${best['name']}');
    } else {
      print('[TTS] Using browser default voice.');
    }
  }
}
