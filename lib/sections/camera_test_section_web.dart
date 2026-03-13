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

  late final String _viewType;
  late final html.VideoElement _video;
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
  String _statusText = 'Press "Turn On Camera" to start.';
  String? _lastPredictionLabel;
  double? _lastPredictionConfidence;
  List<TopKPrediction> _lastTopK = const <TopKPrediction>[];
  int? _lastLatencyMs;

  @override
  void initState() {
    super.initState();

    _viewType = 'signbridge-webcam-view-${_viewIdCounter++}';
    _video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..controls = false
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.border = 'none'
      ..style.backgroundColor = 'black';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _video,
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
      unawaited(_turnOffCamera());
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
    _video.srcObject = null;
  }

  Future<void> _turnOnCamera() async {
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
      _statusText = 'Starting camera and MediaPipe...';
    });

    try {
      await _initializeMediaPipe();
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw StateError('Media devices are not available in this browser.');
      }

      final stream = await mediaDevices.getUserMedia(<String, Object>{
        'video': <String, Object>{'facingMode': 'user'},
        'audio': false,
      });

      _stream = stream;
      _video.srcObject = stream;
      await _video.play();

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
        _statusText = 'Camera active. Waiting for hands...';
      });

      _hotkeysFocusNode.requestFocus();
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint('Camera initialization failed: $error');
      setState(() {
        _isLoading = false;
        _cameraOn = false;
        _stopStream();
        _errorText = _friendlyCameraError(error);
        _statusText = 'Camera is off.';
      });
    }
  }

  Future<void> _turnOffCamera() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Shutting down camera...';
    });

    _frameTimer?.cancel();
    _frameTimer = null;
    _stopStream();
    await _disposeMediaPipeSession();

    if (!mounted) {
      return;
    }

    setState(() {
      _cameraOn = false;
      _isLoading = false;
      _captureState = _CaptureState.idle;
      _isPredicting = false;
      _signFrames.clear();
      _noHandCounter = 0;
      _cooldownRemaining = 0;
      _statusText = 'Camera is off.';
      _errorText = null;
    });
  }

  Future<void> _toggleCamera() async {
    if (_cameraOn) {
      await _turnOffCamera();
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
        _statusText = 'Recording sign...';
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
          _statusText = 'Sending sign to backend...';
        });

        unawaited(_predictCurrentSign(framesForPrediction));
      }
    }
  }

  Future<void> _predictCurrentSign(List<List<double>> frames) async {
    if (frames.length < _minFramesPerSign) {
      if (mounted) {
        setState(() {
          _statusText = 'Sign skipped: too short (${frames.length} frames).';
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

      setState(() {
        _lastPredictionLabel = prediction.label;
        _lastPredictionConfidence = prediction.confidence;
        _lastTopK = prediction.topK.take(3).toList(growable: false);
        _lastLatencyMs = stopwatch.elapsedMilliseconds;
        _sentenceWords.add(prediction.label);
        _statusText = 'Sign recognized. Keep signing to build a sentence.';
        _errorText = null;
      });
    } on ApiException catch (error) {
      if (mounted) {
        debugPrint(
            'Prediction request failed [${error.statusCode}]: ${error.message}');
        setState(() {
          _errorText = _friendlyPredictionError(error);
          _statusText = 'No se pudo completar la prediccion.';
        });
      }
    } catch (error) {
      if (mounted) {
        debugPrint('Prediction failed: $error');
        setState(() {
          _errorText = _friendlyPredictionError(error);
          _statusText = 'No se pudo completar la prediccion.';
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
        _statusText = 'No words captured yet.';
      });
      return;
    }

    final sentence = _sentenceWords.join(' ');
    setState(() {
      _isConfirmingSentence = true;
      _statusText = 'Sentence confirmed.';
    });

    try {
      if (RuntimeConfig.enableBrowserTts) {
        final bridge = _mediaPipeBridge;
        if (bridge != null) {
          bridge.callMethod('speakText', <Object?>[sentence]);
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _sentenceWords.clear();
        _errorText = null;
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
      _sentenceWords.removeLast();
      _statusText = 'Last word removed.';
    });
  }

  void _clearSentence() {
    setState(() {
      _sentenceWords.clear();
      _statusText = 'Sentence cleared.';
    });
  }

  String _friendlyCameraError(Object error) {
    if (error is TimeoutException) {
      return 'La camara tardo demasiado en iniciar. Intentalo de nuevo.';
    }
    return 'No se pudo activar la camara. Revisa permisos del navegador y vuelve a intentar.';
  }

  String _friendlyFrameError(Object error) {
    return 'No pudimos analizar esta sena. Reinicia la camara e intenta otra vez.';
  }

  String _friendlyPredictionError(Object error) {
    if (error is TimeoutException) {
      return 'El servidor tardo demasiado en responder. Intentalo de nuevo.';
    }

    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'La app no pudo autenticarse con el servidor.';
      }
      if (error.statusCode == 422) {
        return 'La sena fue muy corta o incompleta. Hazla de nuevo.';
      }
      if (error.statusCode == 429) {
        return 'Hay muchas solicitudes seguidas. Espera unos segundos.';
      }
      if (error.statusCode == 503) {
        return 'El servidor esta ocupado o iniciando. Intenta nuevamente en breve.';
      }
      if (error.statusCode >= 500) {
        return 'El servicio no esta disponible por ahora. Intentalo mas tarde.';
      }
    }

    return 'No se pudo traducir la sena en este momento.';
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
    final panelHeight = (420 * scale).clamp(360, 620).toDouble();
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
                  'Camera test',
                  style: GoogleFonts.lalezar(
                    fontSize: 44 * scale,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: 1.5 * scale,
                  ),
                ),
                SizedBox(height: 12 * scale),
                Text(
                  'Live sign capture, keypoint extraction and per-sign prediction.',
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
                            'Control panel',
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
                                backgroundColor: const Color(0xFF3B82F6),
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
                                          ? 'Turn Off Camera'
                                          : 'Turn On Camera',
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
                                    ? 'Confirming...'
                                    : 'Confirm Sentence (Enter)',
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
                                    'Delete Last (Backspace)',
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
                                    'Clear',
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
                            color: const Color(0xFF3B82F6),
                            text: 'Analyzing',
                            scale: scale,
                          ),
                          SizedBox(height: 8 * scale),
                          _StateLine(
                            isActive: signDetectedActive,
                            color: const Color(0xFF10B981),
                            text: 'Sign detected',
                            scale: scale,
                          ),
                          SizedBox(height: 8 * scale),
                          _StateLine(
                            isActive: backendActive,
                            color: const Color(0xFFF59E0B),
                            text: 'Backend request',
                            scale: scale,
                          ),
                          SizedBox(height: 10 * scale),
                          if (_lastPredictionLabel != null)
                            Text(
                              'Last sign: $_lastPredictionLabel (${((_lastPredictionConfidence ?? 0) * 100).toStringAsFixed(1)}%)',
                              style: GoogleFonts.inter(
                                color: AppColors.text,
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (_lastLatencyMs != null)
                            Text(
                              'Latency: $_lastLatencyMs ms',
                              style: GoogleFonts.inter(
                                color: AppColors.muted,
                                fontSize: 11 * scale,
                              ),
                            ),
                          if (_lastTopK.isNotEmpty)
                            Text(
                              'Top-K: ${_lastTopK.map((item) => '${item.label} ${(item.confidence * 100).toStringAsFixed(1)}%').join(' | ')}',
                              style: GoogleFonts.inter(
                                color: AppColors.muted,
                                fontSize: 11 * scale,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const Spacer(),
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
                        'Sentence buffer',
                        style: GoogleFonts.inter(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 13 * scale,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Text(
                        _sentenceWords.isEmpty
                            ? 'Waiting signs...'
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    if (!_cameraOn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_outlined,
              color: AppColors.text.withOpacity(0.3),
              size: 48 * scale,
            ),
            SizedBox(height: 12 * scale),
            Text(
              'Camera standby',
              style: GoogleFonts.inter(
                color: AppColors.text.withOpacity(0.4),
                fontSize: 16 * scale,
              ),
            ),
          ],
        ),
      );
    }

    return HtmlElementView(viewType: _viewType);
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
