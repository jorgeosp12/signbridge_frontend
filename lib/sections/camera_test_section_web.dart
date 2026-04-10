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
  static const _sentenceProcessingTimeout = Duration(seconds: 12);
  static const _bufferPreviewBeforeSpeak = Duration(milliseconds: 700);
  static const _bufferHoldMin = Duration(seconds: 4);
  static const _bufferHoldMax = Duration(seconds: 9);
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
  String _statusText = 'Press "Turn On Camera" to begin.';
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
      _errorText = 'Missing service connection key.';
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
        _errorText = 'Turn on the AI engine first.';
      });
      return;
    }

    if (RuntimeConfig.apiKey.isEmpty) {
      setState(() {
        _errorText = 'Missing service connection key.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
      _statusText = 'Starting camera and MediaPipe';
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
        _statusText = 'Camera active. Waiting for hands';
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
        _statusText = 'Camera is off.';
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
      _statusText = 'Turning off camera';
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
      _statusText = 'Camera is off.';
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
          _statusText = 'Capture paused due to a temporary issue.';
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
        _statusText = 'Recording sign';
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
          _statusText = 'Sending sign to backend';
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

      final topChoices = _buildTopChoices(prediction);
      setState(() {
        _lastPredictionLabel = prediction.label;
        _lastPredictionConfidence = prediction.confidence;
        _lastTopK = topChoices;
        _selectedTopChoiceLabel = prediction.label;
        _lastLatencyMs = stopwatch.elapsedMilliseconds;
        _sentenceWords.add(prediction.label);
        _lastEditableWordIndex = _sentenceWords.length - 1;
        _statusText = 'Sign recognized. Keep signing to build a sentence.';
        _errorText = null;
      });
    } on ApiException catch (error) {
      if (mounted) {
        debugPrint(
            'Prediction request failed [${error.statusCode}]: ${error.message}');
        setState(() {
          _errorText = _friendlyPredictionError(error);
          _statusText = 'Prediction could not be completed.';
        });
      }
    } catch (error) {
      if (mounted) {
        debugPrint('Prediction failed: $error');
        setState(() {
          _errorText = _friendlyPredictionError(error);
          _statusText = 'Prediction could not be completed.';
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

  Duration _bufferHoldDuration(String sentence) {
    final words = sentence
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final estimatedMs = 2200 + (words * 450);
    return Duration(
      milliseconds: estimatedMs.clamp(
        _bufferHoldMin.inMilliseconds,
        _bufferHoldMax.inMilliseconds,
      ),
    );
  }

  Future<void> _confirmSentence() async {
    if (_sentenceWords.isEmpty) {
      setState(() {
        _statusText = 'No captured words yet.';
      });
      return;
    }

    final rawSentence = _sentenceWords.join(' ');
    setState(() {
      _isConfirmingSentence = true;
      _statusText = 'Processing sentence';
      _errorText = null;
    });

    var sentenceForOutput = rawSentence;
    var usedGrammarEndpoint = false;
    String? sentenceProcessingNotice;
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
          sentenceProcessingNotice = _friendlySentenceProcessingError(error);
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
        if (sentenceProcessingNotice != null) {
          _statusText =
              'Could not improve sentence. Playing original sentence.';
        } else {
          _statusText = usedGrammarEndpoint
              ? 'Sentence improved. Playing voice output.'
              : 'Sentence confirmed. Playing voice output.';
        }
      });

      await Future<void>.delayed(_bufferPreviewBeforeSpeak);
      if (!mounted) {
        return;
      }

      if (RuntimeConfig.enableBrowserTts) {
        final didSpeak = TtsService.speak(
          sentenceForOutput,
          preferredLanguage: RuntimeConfig.ttsLanguage,
        );
        if (!didSpeak && mounted) {
          setState(() {
            _errorText = 'Voice output is not available in this browser.';
          });
        }
      }

      await Future<void>.delayed(_bufferHoldDuration(sentenceForOutput));
      if (!mounted) {
        return;
      }

      setState(() {
        _sentenceWords.clear();
        _lastTopK = const <TopKPrediction>[];
        _selectedTopChoiceLabel = null;
        _lastEditableWordIndex = null;
        if (sentenceProcessingNotice != null) {
          _statusText = 'Original sentence sent. You can start the next one.';
        } else {
          _statusText = usedGrammarEndpoint
              ? 'Improved sentence sent. You can start the next one.'
              : 'Sentence sent. You can start the next one.';
        }
      });
    } catch (error) {
      if (mounted) {
        debugPrint('Voice output failed: $error');
        setState(() {
          _errorText = 'Voice output failed. Please try again.';
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
      _statusText = 'Last word removed.';
    });
  }

  void _clearSentence() {
    setState(() {
      _sentenceWords.clear();
      _lastTopK = const <TopKPrediction>[];
      _selectedTopChoiceLabel = null;
      _lastEditableWordIndex = null;
      _statusText = 'Sentence cleared.';
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
      _statusText = 'Selected option applied to the latest sign.';
    });
  }

  String _friendlySentenceProcessingError(Object error) {
    if (error is TimeoutException) {
      return 'Sentence correction timed out. Original sentence was used.';
    }

    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'Could not authenticate sentence service. Original sentence was used.';
      }
      if (error.statusCode == 429) {
        return 'Sentence service is busy. Original sentence was used.';
      }
      if (error.statusCode >= 500) {
        return 'Sentence service is unavailable. Original sentence was used.';
      }
    }

    return 'Could not improve sentence. Original sentence was used.';
  }

  String _friendlyCameraError(Object error) {
    final errorText = error.toString().toLowerCase();
    if (errorText.contains('frozen')) {
      return 'Camera froze. Turn it off and on again.';
    }
    if (error is TimeoutException) {
      return 'Camera took too long to start. Please try again.';
    }
    return 'Could not start camera. Check browser permissions and try again.';
  }

  String _friendlyFrameError(Object error) {
    return 'Could not analyze this sign. Restart camera and try again.';
  }

  String _friendlyPredictionError(Object error) {
    if (error is TimeoutException) {
      return 'System response took too long. Please try again.';
    }

    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'Could not connect. System is unavailable right now.';
      }
      if (error.statusCode == 422) {
        return 'The sign was too short or incomplete. Try it again.';
      }
      if (error.statusCode == 429) {
        return 'System is busy. Wait a moment and try again.';
      }
      if (error.statusCode == 503) {
        return 'System is busy or starting up. Try again shortly.';
      }
      if (error.statusCode >= 500) {
        return 'System is unavailable right now. Please try later.';
      }
    }

    return 'This sign could not be translated right now.';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = responsiveScale(context, min: 0.9, max: 1.3);
    final maxWidth = responsiveMaxWidth(context, base: 1100);
    final panelHeight = screenWidth < 700
        ? (460 * scale).clamp(380, 580).toDouble()
        : (520 * scale).clamp(440, 700).toDouble();
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
                  'DEMO',
                  style: GoogleFonts.lalezar(
                    fontSize: 44 * scale,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: 1.5 * scale,
                  ),
                ),
                SizedBox(height: 12 * scale),
                Text(
                  'Live capture, keypoint extraction, and sign-by-sign prediction.',
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
                      child: SingleChildScrollView(
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
                                      : 'Confirm and send sentence (Enter)',
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
                                      'Delete last (Backspace)',
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
                              color: AppColors.primary,
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
                              text: 'Processing',
                              scale: scale,
                            ),
                            SizedBox(height: 10 * scale),
                            if (_lastPredictionLabel != null)
                              Text(
                                'Latest sign: $_lastPredictionLabel',
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
                                          'Not the right one? Choose the correct option',
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
                                  borderRadius:
                                      BorderRadius.circular(8 * scale),
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
                            ? 'Waiting for signs'
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
                        'Camera idle',
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
