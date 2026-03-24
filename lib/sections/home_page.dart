import 'package:flutter/material.dart';
import '../widgets/nav_bar.dart';
import 'hero_section.dart';
import 'features_section.dart';
import 'how_it_works_section.dart';
import 'camera_test_section.dart';
import 'footer_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  String _currentSection = 'Inicio';
  bool _engineOn = false;

  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _tutorialKey = GlobalKey();
  final GlobalKey _demoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollSpy);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollSpy() {
    if (!mounted) return;

    final triggerPoint = MediaQuery.of(context).size.height * 0.3;
    String? activeSection;

    final Map<String, GlobalKey> sections = {
      'Inicio': _homeKey,
      'Funciones': _featuresKey,
      'Tutorial': _tutorialKey,
      'Demo': _demoKey,
    };

    for (var entry in sections.entries) {
      final key = entry.value;
      if (key.currentContext != null) {
        final RenderBox box =
            key.currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero).dy;

        if (position <= triggerPoint &&
            (position + box.size.height) > triggerPoint) {
          activeSection = entry.key;
          break;
        }
      }
    }
    if (activeSection != null && activeSection != _currentSection) {
      setState(() => _currentSection = activeSection!);
    }
  }

  void _scrollToSection(String sectionName) {
    GlobalKey? targetKey;

    switch (sectionName) {
      case 'Inicio':
        targetKey = _homeKey;
        break;
      case 'Funciones':
        targetKey = _featuresKey;
        break;
      case 'Tutorial':
        targetKey = _tutorialKey;
        break;
      case 'Demo':
        targetKey = _demoKey;
        break;
    }

    if (targetKey != null && targetKey.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey.currentContext!,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  void _toggleEngine() {
    setState(() => _engineOn = !_engineOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          NavBar(
            selected: _currentSection,
            systemOnline: _engineOn,
            onSelect: _scrollToSection,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  //ENVOLVEMOS CADA SECCIÓN EN UN CONTAINER CON SU LLAVE
                  Container(
                    key: _homeKey,
                    child: HeroSection(
                      engineOn: _engineOn,
                      engineBusy: false,
                      onToggleEngine: _toggleEngine,
                    ),
                  ),
                  Container(
                    key: _featuresKey,
                    child: const FeaturesSection(),
                  ),
                  Container(
                    key: _tutorialKey,
                    child: const HowItWorksSection(),
                  ),
                  Container(
                    key: _demoKey,
                    child: CameraTestSection(engineOn: _engineOn),
                  ),
                  // El Footer no lleva llave porque no está en el NavBar
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
