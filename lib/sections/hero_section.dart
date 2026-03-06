import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final double screenHeight = MediaQuery.of(context).size.height;
    const buttonRadius = 12.0;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: screenHeight,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg,
        gradient: RadialGradient(
          center: const Alignment(0.0, -2.0),
          radius: 0.77,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.bg,
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Etiqueta superior
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Text(
                    'THESIS PROJECT 2026',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                // Título Principal
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.text,
                      AppColors.muted,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Your voice in meetings,\npowered by your hands.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lalezar(
                      fontSize: 76,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Subtítulo
                Text(
                  'American Sign Language (ASL) to speech translation.\n'
                  'Natively compatible with Zoom, Teams, and Google Meet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    height: 1.6,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 34),
                // Botones (Acciones)
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onToggleEngine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
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
                        style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.18)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(buttonRadius),
                        ),
                      ),
                      child: Text(
                        'View Demo',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}