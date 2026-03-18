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
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
  }

  void _updateSelectedSectionFromScroll() {
    if (!_scroll.hasClients || !mounted) {
      return;
    }

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
      if (top == null) {
        continue;
      }
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
    if (context == null) {
      return null;
    }

    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) {
      return null;
    }

    final viewport = RenderAbstractViewport.of(renderObject);
    final reveal = viewport.getOffsetToReveal(renderObject, 0).offset;
    if (!_scroll.hasClients) {
      return reveal;
    }

    final maxExtent = _scroll.position.maxScrollExtent;
    return reveal.clamp(0.0, maxExtent).toDouble();
  }

  Future<void> _toggleEngine() async {
    if (_engineOn) {
      setState(() {
        _engineOn = false;
      });
      _showEngineMessage('Motor de IA apagado.');
      return;
    }

    if (_engineStarting) {
      return;
    }

    setState(() {
      _engineStarting = true;
    });

    try {
      if (RuntimeConfig.apiKey.isEmpty) {
        throw const ApiException(
          statusCode: 403,
          message:
              'Missing SIGNBRIDGE_API_KEY. Use --dart-define to set it in frontend.',
        );
      }

      await _waitForBackendReady();

      if (!mounted) {
        return;
      }

      setState(() {
        _engineOn = true;
      });
      _showEngineMessage('Motor de IA encendido y listo.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _engineOn = false;
      });
      debugPrint('Engine start error: $error');
      _showEngineMessage(_friendlyEngineError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _engineStarting = false;
        });
      }
    }
  }

  Future<void> _waitForBackendReady() async {
    final startedAt = DateTime.now();
    const maxWarmupTime = Duration(seconds: 75);

    while (DateTime.now().difference(startedAt) < maxWarmupTime) {
      try {
        final health = await _apiClient.healthCheck(
          maxAttempts: 1,
          requestTimeout: const Duration(seconds: 15),
        );
        if (health.isReady) {
          return;
        }
      } on TimeoutException {
        // Backend cold start in progress.
      } on ApiException catch (error) {
        final isTransient = error.statusCode == 502 ||
            error.statusCode == 503 ||
            error.statusCode == 504;
        if (!isTransient) {
          rethrow;
        }
      }

      await Future<void>.delayed(const Duration(seconds: 2));
    }

    throw TimeoutException('Backend warm-up timed out.');
  }

  void _showEngineMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            isError ? const Color(0xFF7F1D1D) : const Color(0xFF0F172A),
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _friendlyEngineError(Object error) {
    if (error is TimeoutException) {
      return 'El servidor tardo demasiado en responder. Intentalo de nuevo.';
    }

    if (error is ApiException) {
      if (error.statusCode == 403) {
        return 'Falta configurar la conexion con el servidor.';
      }
      if (error.statusCode == 503) {
        return 'El servidor se esta iniciando. Intentalo en unos segundos.';
      }
      if (error.statusCode == 404) {
        return 'No se encontro el servicio de IA. Revisa la URL del backend.';
      }
      return 'No se pudo iniciar el motor de IA en este momento.';
    }

    return 'No se pudo conectar con el servidor en este momento.';
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
                    onToggleEngine: () {
                      unawaited(_toggleEngine());
                    },
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
