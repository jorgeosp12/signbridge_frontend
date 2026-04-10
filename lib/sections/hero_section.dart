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
    final isNarrow = MediaQuery.of(context).size.width < 900;
    final scale = responsiveScale(context, min: 0.9, max: 1.35);
    final maxWidth = responsiveMaxWidth(context, base: 1100);
    final headlineSize = isNarrow
        ? (56 * scale).clamp(38, 66).toDouble()
        : (74 * scale).clamp(52, 96).toDouble();

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
                    'UNDERGRADUATE PROJECT 2026',
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
                    'Your voice in meetings,\npowered by your hands.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lalezar(
                      fontSize: headlineSize,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5 * scale,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),
                Text(
                  'American Sign Language (ASL) to speech translation.\n'
                  'Built to work natively with Zoom, Teams, and Google Meet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: (18 * scale).clamp(15, 22).toDouble(),
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
                            ? 'Starting...'
                            : engineOn
                                ? 'Turn Off AI Engine'
                                : 'Start AI Engine',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
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
