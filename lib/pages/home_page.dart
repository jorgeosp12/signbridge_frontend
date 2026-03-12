import 'dart:async';

import 'package:flutter/material.dart';

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
  }

  @override
  void dispose() {
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

  Future<void> _toggleEngine() async {
    if (_engineOn) {
      setState(() {
        _engineOn = false;
      });
      _showEngineMessage('AI engine stopped.');
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

      final health = await _apiClient.healthCheck();
      if (!health.isReady) {
        throw ApiException(
          statusCode: 503,
          message:
              'Backend not ready yet (status: ${health.status}, model_loaded: ${health.modelLoaded}).',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _engineOn = true;
      });
      _showEngineMessage('AI engine online (${health.device}).');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _engineOn = false;
      });
      _showEngineMessage('Could not start AI engine: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _engineStarting = false;
        });
      }
    }
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
