import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/runtime_config.dart';
import '../services/signbridge_api_client.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_layout.dart';
import '../services/tt_service.dart';

enum _CaptureState { idle, signing, predicting }

class _FrameExtraction {
  final List<double> features;
  final bool handsVisible;

  const _FrameExtraction({
    required this.features,
    required this.handsVisible,
  });
}

class CameraTestSection extends StatefulWidget {
  final bool engineOn;

  const CameraTestSection({
    super.key,
    required this.engineOn,
  });

  @override
  State<CameraTestSection> createState() => _CameraTestSectionWebState();
}

class _CameraTestSectionWebState extends State<CameraTestSection> {
  static int _viewIdCounter = 0;

  static const _featureDim = 858;
  static const _minFramesPerSign = 10;
  static const _noHandPatience = 10;
  static const _cooldownFrames = 15;
  static const _maxSignFrames = 150;
  static const _frameInterval = Duration(milliseconds: 33);
  static const _sentenceProcessingTimeout = Duration(seconds: 4);
  static const _minWordsForGrammarPass = 2;
  static const _videoStartTimeout = Duration(seconds: 2);
  static const _videoAdvanceCheck = Duration(milliseconds: 450);
  static const _cameraReleaseDelay = Duration(milliseconds: 220);

  late final String _viewType;
  late html.VideoElement _video;
  html.DivElement? _videoHost;
  int _previewVersion = 0;
  final FocusNode _hotkeysFocusNode = FocusNode();

  final List<List<double>> _signFrames = <List<double>>[];
  final List<String> _sentenceWords = <String>[];

  html.MediaStream? _stream;
  Timer? _frameTimer;
  js.JsObject? _mediaPipeSession;
  SignBridgeApiClient? _apiClient;

  _CaptureState _captureState = _CaptureState.idle;
  int _noHandCounter = 0;
  int _cooldownRemaining = 0;

  bool _cameraOn = false;
  bool _isLoading = false;
  bool _isFrameBusy = false;
  bool _isPredicting = false;
  bool _isConfirmingSentence = false;
  bool _mediaPipeReady = false;

  String? _errorText;
  String _statusText = 'Presiona "Encender cámara" para iniciar.';
  String? _lastPredictionLabel;
  double? _lastPredictionConfidence;
  List<TopKPrediction> _lastTopK = const <TopKPrediction>[];
  String? _selectedTopChoiceLabel;
  int? _lastEditableWordIndex;
  int? _lastLatencyMs;

  @override
  void initState() {
    super.initState();

    _viewType = 'signbridge-webcam-view-${_viewIdCounter++}';
    _video = _buildVideoElement();

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        _videoHost ??= html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'black'
          ..style.overflow = 'hidden';
        _attachVideoElement(_video);
        return _videoHost!;
      },
    );

    _apiClient = SignBridgeApiClient(
      baseUrl: RuntimeConfig.apiBaseUrl,
      apiKey: RuntimeConfig.apiKey,
      maxRetries: 3,
    );

    if (RuntimeConfig.apiKey.isEmpty) {
      _errorText = 'Falta la clave de conexion del servicio.';
    }
  }

  @override
  void didUpdateWidget(covariant CameraTestSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engineOn && !widget.engineOn && _cameraOn) {
      unawaited(_turnOffCamera(disposeSession: true));
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _stopStream();
    unawaited(_disposeMediaPipeSession());
    _apiClient?.close();
    _hotkeysFocusNode.dispose();
    super.dispose();
  }

  js.JsObject? get _mediaPipeBridge {
    final bridge = js.context['signBridgeMp'];
    if (bridge is js.JsObject) {
      return bridge;
    }
    return null;
  }

  Future<void> _initializeMediaPipe() async {
    if (_mediaPipeReady) {
      return;
    }
    final bridge = _mediaPipeBridge;
    if (bridge == null) {
      throw StateError(
        'MediaPipe bridge not found. Confirm web/index.html loads mediapipe_bridge.js.',
      );
    }

    final session = bridge.callMethod('createSession', <Object?>[_video]);
    if (session is! js.JsObject) {
      throw StateError('MediaPipe session was not created correctly.');
    }
    _mediaPipeSession = session;
    _mediaPipeReady = true;
  }

  Future<void> _disposeMediaPipeSession() async {
    final bridge = _mediaPipeBridge;
    if (bridge == null || _mediaPipeSession == null) {
      _mediaPipeSession = null;
      _mediaPipeReady = false;
      return;
    }

    bridge.callMethod('disposeSession', <Object?>[_mediaPipeSession]);
    _mediaPipeSession = null;
    _mediaPipeReady = false;
  }

  void _stopStream() {
    final currentStream = _stream;
    if (currentStream != null) {
      for (final track in currentStream.getTracks()) {
        track.stop();
      }
    }
    _stream = null;
    _video.pause();
    _video.srcObject = null;
    _video.removeAttribute('src');
    _video.load();
  }

  html.VideoElement _buildVideoElement() {
    return html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..controls = false
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.border = 'none'
      ..style.backgroundColor = 'black';
  }

  void _attachVideoElement(html.VideoElement element) {
    final host = _videoHost;
    if (host == null) {
      return;
    }
    host.children
      ..clear()
      ..add(element);
  }

  void _recreateVideoElement() {
    _video = _buildVideoElement();
    _previewVersion += 1;
    _attachVideoElement(_video);
  }

  Future<html.MediaStream> _requestCameraStream(
    html.MediaDevices mediaDevices,
  ) {
    return mediaDevices.getUserMedia(<String, Object>{
      'video': <String, Object>{'facingMode': 'user'},
      'audio': false,
    });
  }

  Future<void> _attachStreamAndPlay(html.MediaStream stream) async {
    final video = _video;
    _stream = stream;
    video.srcObject = stream;

    if (!(video.readyState >= 2 &&
        video.videoWidth > 0 &&
        video.videoHeight > 0)) {
      try {
        await video.onLoadedMetadata.first.timeout(_videoStartTimeout);
      } catch (_) {
        // Continue and let play() decide.
      }
    }

    try {
      await video.play();
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await video.play();
    }

    final startTime = video.currentTime;
    await Future<void>.delayed(_videoAdvanceCheck);
    final endTime = video.currentTime;
    if (video.paused || endTime <= startTime + 0.01) {
      throw StateError('Camera stream is frozen.');
    }
  }

  Future<void> _turnOnCamera() async {
    if (_isLoading) {
      return;
    }
    if (!widget.engineOn) {
      setState(() {
        _errorText = 'Primero enciende el motor de IA.';
      });
      return;
    }

    if (RuntimeConfig.apiKey.isEmpty) {
      setState(() {
        _errorText = 'Falta la clave de conexion del servicio.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
      _statusText = 'Iniciando cámara y MediaPipe';
    });

    try {
      _stopStream();
      await Future<void>.delayed(_cameraReleaseDelay);
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw StateError('Media devices are not available in this browser.');
      }

      try {
        final stream = await _requestCameraStream(mediaDevices);
        await _attachStreamAndPlay(stream);
      } catch (_) {
        _stopStream();
        await Future<void>.delayed(_cameraReleaseDelay);
        final retryStream = await _requestCameraStream(mediaDevices);
        await _attachStreamAndPlay(retryStream);
      }

      if (!_mediaPipeReady) {
        await _initializeMediaPipe();
      }

      _frameTimer?.cancel();
      _frameTimer = Timer.periodic(_frameInterval, (_) {
        unawaited(_processFrame());
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _cameraOn = true;
        _isLoading = false;
        _statusText = 'Cámara activa. Esperando manos';
      });

      _hotkeysFocusNode.requestFocus();
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint('Camera initialization failed: $error');
      await _disposeMediaPipeSession();
      _stopStream();
      setState(() {
        _isLoading = false;
        _cameraOn = false;
        _errorText = _friendlyCameraError(error);
        _statusText = 'La cámara esta apagada.';
      });
    }
  }

  Future<void> _turnOffCamera({bool disposeSession = false}) async {
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
      _cameraOn = false;
      _statusText = 'Apagando cámara';
    });

    _frameTimer?.cancel();
    _frameTimer = null;
    _isFrameBusy = false;
    _stopStream();
    if (disposeSession) {
      await _disposeMediaPipeSession();
      _recreateVideoElement();
    }
    await Future<void>.delayed(_cameraReleaseDelay);

    if (!mounted) {
      return;
    }

    setState(() {
      _cameraOn = false;
      _isLoading = false;
      _captureState = _CaptureState.idle;
      _isPredicting = false;
      _signFrames.clear();
      _lastTopK = const <TopKPrediction>[];
      _selectedTopChoiceLabel = null;
      _lastEditableWordIndex = null;
      _noHandCounter = 0;
      _cooldownRemaining = 0;
      _statusText = 'La cámara esta apagada.';
      _errorText = null;
    });
  }

  Future<void> _toggleCamera() async {
    if (_isLoading) {
      return;
    }
    if (_cameraOn) {
      await _turnOffCamera(disposeSession: false);
    } else {
      await _turnOnCamera();
    }
  }

  Future<void> _processFrame() async {
    if (!_cameraOn || !widget.engineOn || !_mediaPipeReady || _isPredicting) {
      return;
    }
    if (_isFrameBusy) {
      return;
    }

    _isFrameBusy = true;
    try {
      final extraction = _extractFrame();
      _consumeExtraction(extraction);
    } catch (error) {
      if (mounted) {
        debugPrint('Frame processing failed: $error');
        setState(() {
          _errorText = _friendlyFrameError(error);
          _statusText = 'La captura se pauso por un problema temporal.';
        });
      }
    } finally {
      _isFrameBusy = false;
    }
  }

  _FrameExtraction _extractFrame() {
    final bridge = _mediaPipeBridge;
    final session = _mediaPipeSession;

    if (bridge == null || session == null) {
      throw StateError('MediaPipe session is not initialized.');
    }

    final rawResult = bridge.callMethod(
      'getLatestExtraction',
      <Object?>[session],
    );
    if (rawResult is! js.JsObject) {
      throw StateError('Invalid extraction payload from MediaPipe bridge.');
    }

    final rawFeatures = rawResult['features'];
    if (rawFeatures is! js.JsArray) {
      throw StateError('Missing features list in MediaPipe payload.');
    }

    final features = <double>[];
    for (var index = 0; index < rawFeatures.length; index++) {
      final value = rawFeatures[index];
      if (value is num) {
        features.add(value.toDouble());
      }
    }

    if (features.length != _featureDim) {
      throw StateError(
          'Expected $_featureDim features, got ${features.length}.');
    }

    final handsVisible = rawResult['handsVisible'] == true;

    return _FrameExtraction(
      features: features,
      handsVisible: handsVisible,
    );
  }

  void _consumeExtraction(_FrameExtraction extraction) {
    if (_cooldownRemaining > 0) {
      _cooldownRemaining -= 1;
      return;
    }

    if (_captureState == _CaptureState.idle && extraction.handsVisible) {
      setState(() {
        _captureState = _CaptureState.signing;
        _statusText = 'Grabando Seña';
        _signFrames
          ..clear()
          ..add(extraction.features);
        _noHandCounter = 0;
      });
      return;
    }

    if (_captureState == _CaptureState.signing) {
      _signFrames.add(extraction.features);
      _noHandCounter = extraction.handsVisible ? 0 : _noHandCounter + 1;

      final reachedSignEnd = _noHandCounter >= _noHandPatience;
      final reachedMaxFrames = _signFrames.length >= _maxSignFrames;

      if (reachedSignEnd || reachedMaxFrames) {
        final framesForPrediction = _signFrames
            .map((frame) => List<double>.from(frame))
            .toList(growable: false);

        setState(() {
          _captureState = _CaptureState.predicting;
          _isPredicting = true;
          _statusText = 'Enviando Seña al backend';
        });

        unawaited(_predictCurrentSign(framesForPrediction));
      }
    }
  }

  Future<void> _predictCurrentSign(List<List<double>> frames) async {
    if (frames.length < _minFramesPerSign) {
      if (mounted) {
        setState(() {
          _statusText =
              'Seña omitida: demasiado corta (${frames.length} frames).';
        });
      }
      _resetAfterPrediction();
      return;
    }

    final stopwatch = Stopwatch()..start();
    try {
      final prediction = await _apiClient!.predictSign(frames);
      stopwatch.stop();

      if (!mounted) {
        return;
      }

      final topChoices = _buildTopChoices(prediction);
      setState(() {
        _lastPredictionLabel = prediction.label;
        _lastPredictionConfidence = prediction.confidence;
        _lastTopK = topChoices;
        _selectedTopChoiceLabel = prediction.label;
        _lastLatencyMs = stopwatch.elapsedMilliseconds;
        _sentenceWords.add(prediction.label);
        _lastEditableWordIndex = _sentenceWords.length - 1;
        _statusText =
            'Seña reconocida. Continua para construir la oración.';
        _errorText = null;
      });
    } on ApiException catch (error) {
      if (mounted) {
        debugPrint(
            'Prediction request failed [${error.statusCode}]: ${error.message}');
        setState(() {
          _errorText = _friendlyPredictionError(error);
          _statusText = 'No se pudo completar la predicción.';
        });
      }
    } catch (error) {
      if (mounted) {
        debugPrint('Prediction failed: $error');
        setState(() {
          _errorText = _friendlyPredictionError(error);
          _statusText = 'No se pudo completar la predicción.';
        });
      }
    } finally {
      _resetAfterPrediction();
    }
  }

  void _resetAfterPrediction() {
    if (!mounted) {
      return;
    }
    setState(() {
      _signFrames.clear();
      _noHandCounter = 0;
      _cooldownRemaining = _cooldownFrames;
      _captureState = _CaptureState.idle;
      _isPredicting = false;
    });
  }

  Future<void> _confirmSentence() async {
    if (_sentenceWords.isEmpty) {
      setState(() {
        _statusText = 'Aun no hay palabras capturadas.';
      });
      return;
    }

    final rawSentence = _sentenceWords.join(' ');
    setState(() {
      _isConfirmingSentence = true;
      _statusText = 'Procesando oración';
    });

    var sentenceForOutput = rawSentence;
    var usedGrammarEndpoint = false;
    final shouldProcessSentence =
        _sentenceWords.length >= _minWordsForGrammarPass;

    try {
      if (shouldProcessSentence) {
        try {
          final processedSentence = await _apiClient!.processSentence(
            rawSentence,
            maxAttempts: 1,
            requestTimeout: _sentenceProcessingTimeout,
          );
          if (processedSentence.trim().isNotEmpty) {
            sentenceForOutput = processedSentence.trim();
            usedGrammarEndpoint = true;
          }
        } catch (error) {
          debugPrint('Sentence processing failed: $error');
          if (mounted) {
            setState(() {
              _errorText = _friendlySentenceProcessingError(error);
            });
          }
        }
      }

      final outputWords = sentenceForOutput
          .split(RegExp(r'\s+'))
          .map((word) => word.trim())
          .where((word) => word.isNotEmpty)
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _sentenceWords
          ..clear()
          ..addAll(outputWords);
        _lastTopK = const <TopKPrediction>[];
        _selectedTopChoiceLabel = null;
        _lastEditableWordIndex = null;
        _statusText = usedGrammarEndpoint
            ? 'Oración corregida. Reproduciendo voz.'
            : 'Oración confirmada. Reproduciendo voz.';
      });

      await Future<void>.delayed(Duration.zero);

      if (RuntimeConfig.enableBrowserTts) {
        final didSpeak = TtsService.speak(
          sentenceForOutput,
          preferredLanguage: RuntimeConfig.ttsLanguage,
        );
        if (!didSpeak && mounted) {
          setState(() {
            _errorText =
                'La salida de voz no esta disponible en este navegador.';
          });
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _statusText = usedGrammarEndpoint
            ? 'Oración corregida y confirmada.'
            : 'Oración confirmada.';
      });
    } catch (error) {
      if (mounted) {
        debugPrint('Voice output failed: $error');
        setState(() {
          _errorText = 'No se pudo reproducir la voz. Intentalo de nuevo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirmingSentence = false;
        });
      }
    }
  }

  void _removeLastWord() {
    if (_sentenceWords.isEmpty) {
      return;
    }
    setState(() {
      final removedIndex = _sentenceWords.length - 1;
      _sentenceWords.removeLast();
      if (_lastEditableWordIndex == removedIndex) {
        _lastTopK = const <TopKPrediction>[];
        _selectedTopChoiceLabel = null;
        _lastEditableWordIndex = null;
      }
      _statusText = 'Se elimino la ultima palabra.';
    });
  }

  void _clearSentence() {
    setState(() {
      _sentenceWords.clear();
      _lastTopK = const <TopKPrediction>[];
      _selectedTopChoiceLabel = null;
      _lastEditableWordIndex = null;
      _statusText = 'Oración limpiada.';
    });
  }

  List<TopKPrediction> _buildTopChoices(SignPrediction prediction) {
    final byLabel = <String, TopKPrediction>{};

    void upsert(String label, double confidence) {
      if (label.isEmpty) {
        return;
      }
      final existing = byLabel[label];
      if (existing == null || confidence > existing.confidence) {
        byLabel[label] = TopKPrediction(label: label, confidence: confidence);
      }
    }

    upsert(prediction.label, prediction.confidence);
    for (final candidate in prediction.topK) {
      upsert(candidate.label, candidate.confidence);
    }

    final sorted = byLabel.values.toList(growable: false)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    if (sorted.length <= 5) {
      return sorted;
    }
    return sorted.sublist(0, 5);
  }

  void _selectTopChoice(String label) {
    if (_lastEditableWordIndex == null ||
        _lastEditableWordIndex! < 0 ||
        _lastEditableWordIndex! >= _sentenceWords.length) {
      return;
    }

    final selected = _lastTopK.firstWhere(
      (item) => item.label == label,
      orElse: () => TopKPrediction(
        label: label,
        confidence: _lastPredictionConfidence ?? 0,
      ),
    );

    setState(() {
      _selectedTopChoiceLabel = label;
      _sentenceWords[_lastEditableWordIndex!] = label;
      _lastPredictionLabel = label;
      _lastPredictionConfidence = selected.confidence;
      _statusText = 'La opción elegida se actualizo para la ultima seña.';
    });
  }

  String _friendlySentenceProcessingError(Object error) {
    if (error is TimeoutException) {
      return 'La corrección demoro demasiado. Se uso la oración original.';
    }

    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'No se pudo autenticar el servicio de oraciones. Se uso la oración original.';
      }
      if (error.statusCode == 429) {
        return 'El servicio de oraciones esta ocupado. Se uso la oración original.';
      }
      if (error.statusCode >= 500) {
        return 'El servicio de oraciones no esta disponible. Se uso la oración original.';
      }
    }

    return 'No se pudo mejorar la oración. Se uso la oración original.';
  }

  String _friendlyCameraError(Object error) {
    final errorText = error.toString().toLowerCase();
    if (errorText.contains('frozen')) {
      return 'La cámara se quedó congelada. Apágala y enciéndela de nuevo.';
    }
    if (error is TimeoutException) {
      return 'La cámara tardo demasiado en iniciar. Intentalo de nuevo.';
    }
    return 'No se pudo activar la cámara. Revisa los permisos del navegador e intentalo de nuevo.';
  }

  String _friendlyFrameError(Object error) {
    return 'No se pudo analizar esta seña. Reinicia la cámara e intentalo de nuevo.';
  }

  String _friendlyPredictionError(Object error) {
    if (error is TimeoutException) {
      return 'El sistema tardo demasiado en responder. Intentalo de nuevo.';
    }

    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'No fue posible conectar. El sistema no esta disponible ahora.';
      }
      if (error.statusCode == 422) {
        return 'La seña fue muy corta o incompleta. Hazla de nuevo.';
      }
      if (error.statusCode == 429) {
        return 'El sistema esta ocupado. Espera un momento e intentalo de nuevo.';
      }
      if (error.statusCode == 503) {
        return 'El sistema esta ocupado o iniciando. Intenta de nuevo en breve.';
      }
      if (error.statusCode >= 500) {
        return 'El sistema no esta disponible por ahora. Intentalo mas tarde.';
      }
    }

    return 'La seña no se pudo traducir en este momento.';
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      unawaited(_confirmSentence());
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _removeLastWord();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = responsiveScale(context, min: 0.9, max: 1.3);
    final maxWidth = responsiveMaxWidth(context, base: 1100);
    final panelHeight = (520 * scale).clamp(460, 700).toDouble();
    final analyzingActive =
        widget.engineOn && _cameraOn && _captureState != _CaptureState.idle;
    final signDetectedActive = _captureState == _CaptureState.signing;
    final backendActive = _captureState == _CaptureState.predicting;

    return Focus(
      focusNode: _hotkeysFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: screenHeight),
        color: AppColors.bgAlt,
        padding: EdgeInsets.symmetric(
          horizontal: 24 * scale,
          vertical: 80 * scale,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Prueba de cámara',
                  style: GoogleFonts.lalezar(
                    fontSize: 44 * scale,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: 1.5 * scale,
                  ),
                ),
                SizedBox(height: 12 * scale),
                Text(
                  'Captura en vivo, extraccion de keypoints y prediccion por Seña.',
                  style: GoogleFonts.inter(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w400,
                    fontSize: 16 * scale,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48 * scale),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 980;

                    final previewBox = Container(
                      height: panelHeight,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16 * scale),
                        border: Border.all(
                          color: AppColors.muted.withOpacity(0.8),
                          width: 3 * scale,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14 * scale),
                        child: _buildPreview(),
                      ),
                    );

                    final controlPanel = Container(
                      height: panelHeight,
                      padding: EdgeInsets.symmetric(
                        horizontal: 28 * scale,
                        vertical: 24 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A23),
                        borderRadius: BorderRadius.circular(16 * scale),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panel de control',
                            style: GoogleFonts.lalezar(
                              color: AppColors.text,
                              fontSize: 20 * scale,
                              letterSpacing: 1.2 * scale,
                            ),
                          ),
                          SizedBox(height: 14 * scale),
                          Text(
                            _statusText,
                            style: GoogleFonts.inter(
                              color: AppColors.muted,
                              fontSize: 13 * scale,
                            ),
                          ),
                          SizedBox(height: 16 * scale),
                          SizedBox(
                            width: double.infinity,
                            height: 46 * scale,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _toggleCamera,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.text,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10 * scale),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20 * scale,
                                      height: 20 * scale,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        color: AppColors.text,
                                      ),
                                    )
                                  : Text(
                                      _cameraOn
                                          ? 'Apagar cámara'
                                          : 'Encender cámara',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14 * scale,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 10 * scale),
                          SizedBox(
                            width: double.infinity,
                            height: 42 * scale,
                            child: OutlinedButton(
                              onPressed: _isConfirmingSentence
                                  ? null
                                  : _confirmSentence,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.text,
                                side: BorderSide(
                                    color: Colors.white.withOpacity(0.2)),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10 * scale),
                                ),
                              ),
                              child: Text(
                                _isConfirmingSentence
                                    ? 'Confirmando'
                                    : 'Confirmar oración (Enter)',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13 * scale,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10 * scale),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: _removeLastWord,
                                  child: Text(
                                    'Borrar ultima (Backspace)',
                                    style: GoogleFonts.inter(
                                      color: AppColors.muted,
                                      fontSize: 12 * scale,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: _clearSentence,
                                  child: Text(
                                    'Limpiar',
                                    style: GoogleFonts.inter(
                                      color: AppColors.muted,
                                      fontSize: 12 * scale,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Divider(color: Colors.white.withOpacity(0.08)),
                          SizedBox(height: 8 * scale),
                          _StateLine(
                            isActive: analyzingActive,
                            color: AppColors.primary,
                            text: 'Analizando',
                            scale: scale,
                          ),
                          SizedBox(height: 8 * scale),
                          _StateLine(
                            isActive: signDetectedActive,
                            color: const Color(0xFF10B981),
                            text: 'Seña detectada',
                            scale: scale,
                          ),
                          SizedBox(height: 8 * scale),
                          _StateLine(
                            isActive: backendActive,
                            color: const Color(0xFFF59E0B),
                            text: 'Procesando',
                            scale: scale,
                          ),
                          SizedBox(height: 10 * scale),
                          if (_lastPredictionLabel != null)
                            Text(
                              'Ultima seña: $_lastPredictionLabel',
                              style: GoogleFonts.inter(
                                color: AppColors.text,
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (_lastLatencyMs != null)
                            Text(
                              'Tiempo: $_lastLatencyMs ms',
                              style: GoogleFonts.inter(
                                color: AppColors.muted,
                                fontSize: 11 * scale,
                              ),
                            ),
                          if (_lastTopK.length > 1 &&
                              _lastEditableWordIndex != null &&
                              _lastEditableWordIndex! < _sentenceWords.length)
                            Padding(
                              padding: EdgeInsets.only(top: 10 * scale),
                              child: Builder(
                                builder: (context) {
                                  final validSelection = _lastTopK.any(
                                    (item) =>
                                        item.label == _selectedTopChoiceLabel,
                                  );
                                  final selectedValue = validSelection
                                      ? _selectedTopChoiceLabel!
                                      : _lastTopK.first.label;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'No era esa? Elige la opción correcta',
                                        style: GoogleFonts.inter(
                                          color: AppColors.text,
                                          fontSize: 12 * scale,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 6 * scale),
                                      Wrap(
                                        spacing: 6 * scale,
                                        runSpacing: 6 * scale,
                                        children: _lastTopK.map((item) {
                                          final isSelected =
                                              item.label == selectedValue;
                                          return ChoiceChip(
                                            label: Text(
                                              '${item.label} (${(item.confidence * 100).toStringAsFixed(1)}%)',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            selected: isSelected,
                                            onSelected: (_) {
                                              _selectTopChoice(item.label);
                                            },
                                            labelStyle: GoogleFonts.inter(
                                              color: AppColors.text,
                                              fontSize: 11 * scale,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            backgroundColor:
                                                const Color(0xFF0F172A),
                                            selectedColor: AppColors.success,
                                            side: BorderSide(
                                              color: Colors.white.withOpacity(
                                                  isSelected ? 0.35 : 0.18),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8 * scale),
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          );
                                        }).toList(growable: false),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          if (_errorText != null)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12 * scale),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8 * scale),
                              ),
                              child: Text(
                                _errorText!,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFFCA5A5),
                                  fontSize: 12 * scale,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          previewBox,
                          SizedBox(height: 24 * scale),
                          controlPanel,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 8, child: previewBox),
                        SizedBox(width: 24 * scale),
                        Expanded(flex: 7, child: controlPanel),
                      ],
                    );
                  },
                ),
                SizedBox(height: 22 * scale),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(12 * scale),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buffer de oración',
                        style: GoogleFonts.inter(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 13 * scale,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Text(
                        _sentenceWords.isEmpty
                            ? 'Esperando señas'
                            : _sentenceWords.join(' '),
                        style: GoogleFonts.inter(
                          color: _sentenceWords.isEmpty
                              ? AppColors.muted
                              : AppColors.text,
                          fontSize: 15 * scale,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final scale = responsiveScale(context, min: 0.9, max: 1.3);
    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(
          key: ValueKey('camera-preview-$_previewVersion'),
          viewType: _viewType,
        ),
        if (!_cameraOn || _isLoading)
          Container(
            color: Colors.black.withOpacity(0.62),
            alignment: Alignment.center,
            child: _isLoading
                ? const CircularProgressIndicator(color: Color(0xFF3B82F6))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam_outlined,
                        color: AppColors.text.withOpacity(0.3),
                        size: 48 * scale,
                      ),
                      SizedBox(height: 12 * scale),
                      Text(
                        'Cámara en espera',
                        style: GoogleFonts.inter(
                          color: AppColors.text.withOpacity(0.4),
                          fontSize: 16 * scale,
                        ),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}

class _StateLine extends StatelessWidget {
  final bool isActive;
  final Color color;
  final String text;
  final double scale;

  const _StateLine({
    required this.isActive,
    required this.color,
    required this.text,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    final currentColor = isActive ? color : AppColors.text.withOpacity(0.15);
    return Row(
      children: [
        Container(
          width: 8 * scale,
          height: 8 * scale,
          decoration: BoxDecoration(
            color: currentColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 10 * scale),
        Text(
          text,
          style: GoogleFonts.inter(
            color: isActive ? AppColors.text : AppColors.text.withOpacity(0.4),
            fontSize: 12 * scale,
          ),
        ),
      ],
    );
  }
}
