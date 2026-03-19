import 'dart:js' as js;

/// Servicio de Text-to-Speech para Flutter Web.
/// Usa la Web Speech API nativa del navegador — sin dependencias externas.
/// El audio sale por el dispositivo de salida predeterminado del sistema,
/// lo que permite enrutarlo a un cable virtual (VB-Cable) para Zoom/Meet.
class TtsService {
  static const double _defaultRate   = 0.9;  // velocidad (0.1 - 10)
  static const double _defaultPitch  = 1.0;  // tono (0 - 2)
  static const double _defaultVolume = 1.0;  // volumen (0 - 1)
  static const String _defaultLang   = 'en-US';

  /// Sintetiza y reproduce [text] en voz alta.
  /// Si ya hay algo reproduciéndose, lo cancela primero.
  static void speak(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final synth = js.context['speechSynthesis'];
    if (synth == null) return; // navegador no soporta Web Speech API

    // Cancela cualquier utterance en curso
    synth.callMethod('cancel');

    final utterance = js.JsObject(
      js.context['SpeechSynthesisUtterance'],
      [trimmed],
    );

    utterance['lang']   = _defaultLang;
    utterance['rate']   = _defaultRate;
    utterance['pitch']  = _defaultPitch;
    utterance['volume'] = _defaultVolume;

    synth.callMethod('speak', [utterance]);
  }

  /// Detiene la reproducción inmediatamente.
  static void stop() {
    js.context['speechSynthesis']?.callMethod('cancel');
  }

  /// Verifica si el navegador soporta Web Speech API.
  static bool get isSupported =>
      js.context['speechSynthesis'] != null;
}