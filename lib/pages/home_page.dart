import 'package:flutter/material.dart';
import '../sections/camera_test_section.dart';
import '../sections/features_section.dart';
import '../sections/footer_section.dart';
import '../sections/hero_section.dart';
import '../sections/how_it_works_section.dart';
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

  bool get _systemOnline => _engineOn;

  void _scrollTo(GlobalKey key, String label) {
    setState(() => _selected = label);
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
  }

  void _toggleEngine() {
    setState(() {
      _engineOn = !_engineOn;
    });
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
                  HeroSection(engineOn: _engineOn, onToggleEngine: _toggleEngine),

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