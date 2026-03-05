import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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

    // Registrar el VideoElement para usarlo como widget
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

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      // Pedir cámara con el mínimo de constraints para máxima compatibilidad
      final stream = await html.window.navigator.mediaDevices!
          .getUserMedia({'video': true, 'audio': false});

      // Pequeña pausa para evitar carreras raras justo después del popup
      await Future<void>.delayed(const Duration(milliseconds: 120));

      _stream = stream;
      _video.srcObject = stream;

      setState(() {
        _cameraOn = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _cameraOn = false;
        _stopStream();

        _errorText =
            'Camera error (Web): $e\n\n'
            'If you have more than 1 camera, pick the real webcam in the popup.\n'
            'Also close apps that may use the camera (Meet/Teams/OBS).';
      });
    }
  }

  Future<void> _turnOffCamera() async {
    setState(() => _isLoading = true);
    _stopStream();
    setState(() {
      _cameraOn = false;
      _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    const buttonRadius = 16.0;

    final analyzingActive = widget.engineOn && _cameraOn;
    final signActive = widget.engineOn && _cameraOn;

    return Container(
      width: double.infinity,
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text(
                'Camera test',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Verify the system understands you before joining a meeting.',
                style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              if (_errorText != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1D1D).withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.8)),
                    ),
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),

              if (_errorText != null) const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, c) {
                  final isNarrow = c.maxWidth < 850;

                  final preview = Container(
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _cameraOn
                            ? AppColors.primary.withOpacity(0.95)
                            : Colors.white.withOpacity(0.25),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildPreview(),
                    ),
                  );

                  final panel = Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Control panel', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _toggleCamera,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.text,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(buttonRadius),
                              ),
                            ),
                            child: Text(
                              _cameraOn ? 'Turn Of Camera' : 'Turn On Camera',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Estado:', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(
                          _isLoading ? 'Starting...' : 'Press the button to start',
                          style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        _StateLine(
                          color: analyzingActive ? AppColors.primary : AppColors.muted,
                          text: 'Analyzing',
                        ),
                        const SizedBox(height: 8),
                        _StateLine(
                          color: signActive ? AppColors.success : AppColors.muted,
                          text: 'Sign Detected',
                        ),
                      ],
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        preview,
                        const SizedBox(height: 14),
                        panel,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: preview),
                      const SizedBox(width: 18),
                      Expanded(flex: 2, child: panel),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_cameraOn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.videocam_off_outlined, color: AppColors.muted, size: 26),
            SizedBox(height: 8),
            Text('Camera standby', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return HtmlElementView(viewType: _viewType);
  }
}

class _StateLine extends StatelessWidget {
  final Color color;
  final String text;

  const _StateLine({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
      ],
    );
  }
}