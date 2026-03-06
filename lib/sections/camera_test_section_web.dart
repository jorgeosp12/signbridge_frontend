import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class CameraTestSection extends StatefulWidget {
  final bool engineOn;
  const CameraTestSection({super.key, required this.engineOn});

  @override
  State<CameraTestSection> createState() => _CameraTestSectionWebState();
}

class _CameraTestSectionWebState extends State<CameraTestSection> {
  static int _viewIdCounter = 0;
  late final String _viewType;
  late final html.VideoElement _video;
  html.MediaStream? _stream;

  bool _cameraOn = false;
  bool _isLoading = false;
  String? _errorText;

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

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => _video);
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  void _stopStream() {
    final s = _stream;
    if (s != null) {
      for (final t in s.getTracks()) {
        t.stop();
      }
    }
    _stream = null;
    _video.srcObject = null;
  }

  Future<void> _turnOnCamera() async {
    if (!widget.engineOn) {
      setState(() => _errorText = 'First, Turn On The AI Engine');
      return;
    }
    setState(() { _errorText = null; _isLoading = true; });

    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({'video': true, 'audio': false});
      await Future<void>.delayed(const Duration(milliseconds: 120));
      _stream = stream;
      _video.srcObject = stream;
      setState(() { _cameraOn = true; _isLoading = false; });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _cameraOn = false;
        _stopStream();
        _errorText = 'Camera error (Web): $e';
      });
    }
  }

  Future<void> _turnOffCamera() async {
    setState(() => _isLoading = true);
    _stopStream();
    setState(() { _cameraOn = false; _isLoading = false; _errorText = null; });
  }

  Future<void> _toggleCamera() async {
    if (_cameraOn) {
      await _turnOffCamera();
    } else {
      await _turnOnCamera();
    }
  }

@override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final analyzingActive = widget.engineOn && _cameraOn;
    final signActive = widget.engineOn && _cameraOn;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenHeight),
      color: AppColors.bgAlt, 
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Camera test',
                style: GoogleFonts.lalezar(fontSize: 44, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Verify the system understands you before joining a meeting.',
                style: GoogleFonts.inter(color: AppColors.muted, fontWeight: FontWeight.w400, fontSize: 16),
              ),
              const SizedBox(height: 48),

              LayoutBuilder(
                builder: (context, c) {
                  final isNarrow = c.maxWidth < 800;

                  final previewBox = Container(
                    height: 420, // Altura fija
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.muted.withOpacity(0.8), width: 4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildPreview(),
                    ),
                  );

                    final controlPanel = Container(
                    height: 420,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141A23),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Control panel', style: GoogleFonts.lalezar(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 1.2)),
                        const SizedBox(height: 24),
                        
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _toggleCamera,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: AppColors.text,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.text))
                              : Text(_cameraOn ? 'Turn Off Camera' : 'Turn On Camera', style: GoogleFonts.inter(fontWeight: FontWeight.w400)),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        Divider(color: Colors.white.withOpacity(0.05)),
                        
                        const SizedBox(height: 24), 
                        
                        Text('Estado:', style: GoogleFonts.lalezar(color: AppColors.text, fontWeight: FontWeight.w500, fontSize: 16, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Text(
                          _isLoading ? 'Starting...' : 'Press the button to start',
                          style: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        
                        _StateLine(isActive: analyzingActive, color: const Color(0xFF3B82F6), text: 'Analyzing'),
                        const SizedBox(height: 12),
                        _StateLine(isActive: signActive, color: const Color(0xFF10B981), text: 'Sign Detected'),

                        const Spacer(),

                        if (_errorText != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(_errorText!, style: const TextStyle(color: Color.fromARGB(255, 254, 89, 89), fontSize: 12)),
                          )
                        ],
                      ],
                    ),
                  );

                  if (isNarrow) {
                    return Column(children: [previewBox, const SizedBox(height: 24), controlPanel]);
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Expanded(flex: 8, child: previewBox),
                      const SizedBox(width: 24),
                      Expanded(flex: 5, child: controlPanel),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));

    if (!_cameraOn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_outlined, color: AppColors.text.withOpacity(0.3), size: 48),
            const SizedBox(height: 12),
            Text('Camera standby', style: GoogleFonts.inter(color: AppColors.text.withOpacity(0.4), fontSize: 16)),
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

  const _StateLine({required this.isActive, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final currentColor = isActive ? color : AppColors.text.withOpacity(0.15);
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: currentColor, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(text, style: GoogleFonts.inter(color: isActive ? AppColors.text : AppColors.text.withOpacity(0.4), fontSize: 13)),
      ],
    );
  }
}