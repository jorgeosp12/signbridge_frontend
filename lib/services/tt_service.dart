import 'dart:js' as js;

/// Servicio de Text-to-Speech para Flutter Web.
/// Usa la Web Speech API nativa del navegador — sin dependencias externas.
/// El audio sale por el dispositivo de salida predeterminado del sistema,
/// lo que permite enrutarlo a un cable virtual (VB-Cable) para Zoom/Meet.
class TtsService {
  static const double _defaultRate   = 0.75;
  static const double _defaultPitch  = 1.0;
  static const double _defaultVolume = 1.0;
  static const String _defaultLang   = 'en-US';

  /// Sintetiza y reproduce [text] en voz alta.
  /// Selecciona automáticamente la mejor voz disponible en el navegador.
  static void speak(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final synth = js.context['speechSynthesis'];
    if (synth == null) return;

    synth.callMethod('cancel');

    final utterance = js.JsObject(
      js.context['SpeechSynthesisUtterance'],
      [trimmed],
    );

    final selectedVoice = _getBestVoice(synth);
    if (selectedVoice != null) {
      utterance['voice'] = selectedVoice;
    }

    utterance['lang']   = _defaultLang;
    utterance['rate']   = _defaultRate;
    utterance['pitch']  = _defaultPitch;
    utterance['volume'] = _defaultVolume;

    synth.callMethod('speak', [utterance]);
  }

  /// Selecciona la mejor voz disponible siguiendo este orden de prioridad:
  /// 1. Google en-US
  /// 2. Cualquier Google en inglés
  /// 3. Microsoft en-US
  /// 4. Cualquier Microsoft en inglés
  /// 5. Cualquier voz en-US
  /// 6. null (usa la voz por defecto del navegador)
  static js.JsObject? _getBestVoice(js.JsObject synth) {
    final js.JsArray voices;
    try {
      voices = synth.callMethod('getVoices') as js.JsArray;
    } catch (_) {
      return null;
    }

    if (voices.isEmpty) return null;

    js.JsObject? googleEnUs;
    js.JsObject? googleEn;
    js.JsObject? microsoftEnUs;
    js.JsObject? microsoftEn;
    js.JsObject? anyEnUs;

    for (var i = 0; i < voices.length; i++) {
      final voice = voices[i] as js.JsObject;
      final name  = voice['name'].toString().toLowerCase();
      final lang  = voice['lang'].toString().toLowerCase();

      final isGoogle    = name.contains('google');
      final isMicrosoft = name.contains('microsoft');
      final isEnUs      = lang == 'en-us';
      final isEn        = lang.startsWith('en');

      if (isGoogle && isEnUs && googleEnUs == null) {
        googleEnUs = voice;
      } else if (isGoogle && isEn && googleEn == null) {
        googleEn = voice;
      } else if (isMicrosoft && isEnUs && microsoftEnUs == null) {
        microsoftEnUs = voice;
      } else if (isMicrosoft && isEn && microsoftEn == null) {
        microsoftEn = voice;
      } else if (isEnUs && anyEnUs == null) {
        anyEnUs = voice;
      }
    }

    return googleEnUs ?? googleEn ?? microsoftEnUs ?? microsoftEn ?? anyEnUs;
  }

  /// Detiene la reproducción inmediatamente.
  static void stop() {
    js.context['speechSynthesis']?.callMethod('cancel');
  }

  /// Verifica si el navegador soporta Web Speech API.
  static bool get isSupported => js.context['speechSynthesis'] != null;

  /// Imprime en consola todas las voces disponibles en el navegador.
  /// Llama esto una vez al iniciar la app para ver qué voces hay disponibles.
  static void listVoices() {
    final synth = js.context['speechSynthesis'];
    if (synth == null) {
      print('[TTS] Web Speech API no soportada en este navegador.');
      return;
    }

    final js.JsArray voices;
    try {
      voices = synth.callMethod('getVoices') as js.JsArray;
    } catch (e) {
      print('[TTS] Error obteniendo voces: $e');
      return;
    }

    if (voices.isEmpty) {
      print('[TTS] No hay voces disponibles todavía (puede que no hayan cargado aún).');
      return;
    }

    print('[TTS] ${voices.length} voces disponibles:');
    for (var i = 0; i < voices.length; i++) {
      final voice     = voices[i] as js.JsObject;
      final name      = voice['name'];
      final lang      = voice['lang'];
      final local     = voice['localService'];
      final isDefault = voice['default'];
      print('  [$i] $name | $lang | local=$local | default=$isDefault');
    }

    final best = _getBestVoice(synth);
    if (best != null) {
      print('[TTS] Voz seleccionada automáticamente: ${best['name']}');
    } else {
      print('[TTS] Usando voz por defecto del navegador.');
    }
  }
}