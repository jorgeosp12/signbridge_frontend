import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/responsive_layout.dart';

class HeroSection extends StatelessWidget {
  final bool engineOn;
  final bool engineBusy;
  final VoidCallback onToggleEngine;

  const HeroSection({
    super.key,
    required this.engineOn,
    required this.engineBusy,
    required this.onToggleEngine,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = responsiveScale(context, min: 0.9, max: 1.35);
    final maxWidth = responsiveMaxWidth(context, base: 1100);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenHeight),
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
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20 * scale,
              vertical: 40 * scale,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24 * scale,
                    vertical: 10 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Text(
                    'PROYECTO DE GRADO 2026',
                    style: GoogleFonts.inter(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 0.4 * scale,
                    ),
                  ),
                ),
                SizedBox(height: 25 * scale),
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
                    'Tu voz en reuniones,\nimpulsada por tus manos.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lalezar(
                      fontSize: 76 * scale,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5 * scale,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),
                Text(
                  'Traduccion de Lengua de Se\u00f1as Americana (ASL) a voz.\n'
                  'Compatible de forma nativa con Zoom, Teams y Google Meet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18 * scale,
                    height: 1.6,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 34 * scale),
                Wrap(
                  spacing: 14 * scale,
                  runSpacing: 12 * scale,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: engineBusy ? null : onToggleEngine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 22 * scale,
                          vertical: 20 * scale,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12 * scale),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(
                        engineBusy
                            ? Icons.hourglass_top_rounded
                            : engineOn
                                ? Icons.stop_circle_outlined
                                : Icons.play_arrow_rounded,
                        size: 18 * scale,
                      ),
                      label: Text(
                        engineBusy
                            ? 'Iniciando...'
                            : engineOn
                                ? 'Apagar motor de IA'
                                : 'Encender motor de IA',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w400,
                          fontSize: 14 * scale,
                        ),
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
