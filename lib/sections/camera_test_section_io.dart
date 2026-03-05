import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CameraTestSection extends StatefulWidget {
  final bool engineOn;

  const CameraTestSection({
    super.key,
    required this.engineOn,
  });

  @override
  State<CameraTestSection> createState() => _CameraTestSectionState();
}

class _CameraTestSectionState extends State<CameraTestSection> {
  CameraController? _controller;
  bool _cameraOn = false;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
      final cameras = await availableCameras();
      final selected = cameras.isNotEmpty ? cameras.first : null;
      if (selected == null) throw Exception('No cameras found.');

      final controller = CameraController(
        selected,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return;
      await _controller?.dispose();

      setState(() {
        _controller = controller;
        _cameraOn = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _cameraOn = false;
        _controller = null;
        _errorText = 'Camera error: $e';
      });
    }
  }

  Future<void> _turnOffCamera() async {
    setState(() => _isLoading = true);
    await _controller?.dispose();
    if (!mounted) return;
    setState(() {
      _controller = null;
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

    return Container(
      width: double.infinity,
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text('Camera test', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              if (_errorText != null) Text(_errorText!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _toggleCamera,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
                ),
                child: Text(_cameraOn ? 'Turn Of Camera' : 'Turn On Camera'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 260,
                child: _controller != null && _controller!.value.isInitialized
                    ? CameraPreview(_controller!)
                    : const Center(child: Text('Camera standby')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}