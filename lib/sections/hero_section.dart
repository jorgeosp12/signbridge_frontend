import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HeroSection extends StatelessWidget {
  final bool engineOn;
  final VoidCallback onToggleEngine;

  const HeroSection({
    super.key,
    required this.engineOn,
    required this.onToggleEngine,
  });

  @override
  Widget build(BuildContext context) {
    // Botones menos redondos
    const buttonRadius = 16.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      decoration: BoxDecoration(
        // ✅ El gradiente cubre TODA la sección (como tu imagen 2)
        gradient: RadialGradient(
          center: const Alignment(0.0, -1.35),
          radius: 1.25,
          colors: [
            AppColors.primary.withOpacity(0.28),
            AppColors.bg,
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const Text(
                  'TESIS PROJECT 2026',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your voice in meetings,\npowered by your hands.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 56,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'American Sign Language (ASL) to speech translation.\n'
                'Natively compatible with Zoom, Teams, and Google Meet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 34),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onToggleEngine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.text,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonRadius),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      engineOn ? Icons.stop_circle_outlined : Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    label: Text(
                      engineOn ? 'Stop AI engine' : 'Start AI engine',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: BorderSide(color: Colors.white.withOpacity(0.18)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonRadius),
                      ),
                    ),
                    child: const Text(
                      'View Demo',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}