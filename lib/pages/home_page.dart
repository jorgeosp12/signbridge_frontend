import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../config/runtime_config.dart';
import '../sections/camera_test_section.dart';
import '../sections/features_section.dart';
import '../sections/footer_section.dart';
import '../sections/hero_section.dart';
import '../sections/how_it_works_section.dart';
import '../services/signbridge_api_client.dart';
import '../widgets/nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scroll = ScrollController();

  final _homeKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _tutorialKey = GlobalKey();
  final _demoKey = GlobalKey();

  String _selected = 'Home';

  bool _engineOn = false;
  bool _engineStarting = false;
  late final SignBridgeApiClient _apiClient;
  bool _backendPrimed = false;
  Future<void>? _backendWarmupFuture;

  bool get _systemOnline => _engineOn;

  @override
  void initState() {
    super.initState();
    _apiClient = SignBridgeApiClient(
      baseUrl: RuntimeConfig.apiBaseUrl,
      apiKey: RuntimeConfig.apiKey,
    );
    _scroll.addListener(_updateSelectedSectionFromScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedSectionFromScroll();
    });
    _startBackendWarmup();
  }

  @override
  void dispose() {
    _scroll.removeListener(_updateSelectedSectionFromScroll);
    _scroll.dispose();
    _apiClient.close();
    super.dispose();
  }

  void _scrollTo(GlobalKey key, String label) {
    setState(() => _selected = label);
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  void _updateSelectedSectionFromScroll() {
    if (!_scroll.hasClients || !mounted) return;

    const activationOffset = 140.0;
    final currentOffset = _scroll.offset + activationOffset;
    final sections = <({String label, GlobalKey key})>[
      (label: 'Home', key: _homeKey),
      (label: 'Features', key: _featuresKey),
      (label: 'Tutorial', key: _tutorialKey),
      (label: 'Demo', key: _demoKey),
    ];

    var activeLabel = _selected;
    for (final section in sections) {
      final top = _sectionTopOffset(section.key);
      if (top == null) continue;
      if (currentOffset >= top) {
        activeLabel = section.label;
      } else {
        break;
      }
    }

    if (activeLabel != _selected) {
      setState(() => _selected = activeLabel);
    }
  }

  double? _sectionTopOffset(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;

    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return null;

    final viewport = RenderAbstractViewport.of(renderObject);
    final reveal = viewport.getOffsetToReveal(renderObject, 0).offset;
    if (!_scroll.hasClients) return reveal;

    final maxExtent = _scroll.position.maxScrollExtent;
    return reveal.clamp(0.0, maxExtent).toDouble();
  }

  Future<void> _toggleEngine() async {
    if (_engineOn) {
      setState(() => _engineOn = false);
      _showEngineMessage('AI engine turned off.', isError: false);
      return;
    }

    if (_engineStarting) return;

    setState(() => _engineStarting = true);

    try {
      if (RuntimeConfig.apiKey.isEmpty) {
        throw const ApiException(
          statusCode: 403,
          message:
              'Missing SIGNBRIDGE_API_KEY. Use --dart-define to set it in frontend.',
        );
      }

      _startBackendWarmup();
      if (_backendWarmupFuture != null) {
        await _backendWarmupFuture;
      }
      if (!_backendPrimed) {
        await _waitForBackendReady();
        _backendPrimed = true;
      }

      if (!mounted) return;

      setState(() => _engineOn = true);
      _showEngineMessage('AI engine powered on and ready.', isError: false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _engineOn = false);
      _backendPrimed = false;
      _startBackendWarmup();
      debugPrint('Engine start error: $error');
      _showEngineMessage(_friendlyEngineError(error), isError: true);
    } finally {
      if (mounted) setState(() => _engineStarting = false);
    }
  }

  void _startBackendWarmup() {
    if (_backendPrimed || _backendWarmupFuture != null) {
      return;
    }

    _backendWarmupFuture = _waitForBackendReady(
      maxWarmupTime: const Duration(seconds: 60),
      requestTimeout: const Duration(seconds: 8),
      pollInterval: const Duration(seconds: 1),
    ).then((_) {
      _backendPrimed = true;
    }).catchError((Object error) {
      debugPrint('Background backend warm-up incomplete: $error');
    }).whenComplete(() {
      _backendWarmupFuture = null;
    });
  }

  Future<void> _waitForBackendReady({
    Duration maxWarmupTime = const Duration(seconds: 75),
    Duration requestTimeout = const Duration(seconds: 8),
    Duration pollInterval = const Duration(seconds: 1),
  }) async {
    final startedAt = DateTime.now();

    while (DateTime.now().difference(startedAt) < maxWarmupTime) {
      try {
        final health = await _apiClient.healthCheck(
          maxAttempts: 1,
          requestTimeout: requestTimeout,
        );
        if (health.isReady) return;
      } on TimeoutException {
        // Backend cold start in progress.
      } on ApiException catch (error) {
        final isTransient = error.statusCode == 502 ||
            error.statusCode == 503 ||
            error.statusCode == 504;
        if (!isTransient) rethrow;
      }

      await Future<void>.delayed(pollInterval);
    }

    throw TimeoutException('Backend warm-up timed out.');
  }

  void _showEngineMessage(String message, {required bool isError}) {
    final bgColor = isError
        ? const Color(0xFF7F1D1D) // rojo oscuro
        : const Color(0xFF14532D); // verde oscuro

    final icon = isError
        ? const Icon(Icons.error_outline, color: Colors.white, size: 20)
        : const Icon(Icons.check_circle_outline, color: Colors.white, size: 20);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: bgColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              icon,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  String _friendlyEngineError(Object error) {
    if (error is TimeoutException) {
      return 'The AI server is still waking up. Please try again in a few seconds.';
    }
    if (error is ApiException) {
      if (error.statusCode == 403) {
        return 'The connection to the system needs to be configured.';
      }
      if (error.statusCode == 503) {
        return 'The system is starting up. Please try again in a few seconds.';
      }
      if (error.statusCode == 404) {
        return 'The AI service could not be found. Please check the backend URL.';
      }
      return 'The AI engine could not be started at this time.';
    }
    return 'We were unable to connect to the system at this time.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          NavBar(
            selected: _selected,
            systemOnline: _systemOnline,
            onSelect: (label) {
              switch (label) {
                case 'Home':
                  _scrollTo(_homeKey, 'Home');
                  break;
                case 'Features':
                  _scrollTo(_featuresKey, 'Features');
                  break;
                case 'Tutorial':
                  _scrollTo(_tutorialKey, 'Tutorial');
                  break;
                case 'Demo':
                  _scrollTo(_demoKey, 'Demo');
                  break;
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(
                children: [
                  Container(key: _homeKey),
                  HeroSection(
                    engineOn: _engineOn,
                    engineBusy: _engineStarting,
                    onToggleEngine: () => unawaited(_toggleEngine()),
                  ),
                  Container(key: _featuresKey),
                  const FeaturesSection(),
                  Container(key: _tutorialKey),
                  const HowItWorksSection(),
                  Container(key: _demoKey),
                  CameraTestSection(engineOn: _engineOn),
                  const FooterSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
