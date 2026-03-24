import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/responsive_layout.dart';
import '../widgets/section_container.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = responsiveScale(context, min: 0.9, max: 1.3);
    final maxVideoWidth = responsiveMaxWidth(context, base: 900);

    return SectionContainer(
      backgroundColor: AppColors.bg,
      child: Container(
        constraints: BoxConstraints(minHeight: screenHeight),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 80 * scale,
          horizontal: 24 * scale,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mira como funciona',
              textAlign: TextAlign.center,
              style: GoogleFonts.lalezar(
                fontSize: 48 * scale,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5 * scale,
                color: AppColors.text,
              ),
            ),
            Text(
              'Explicacion en Lengua de Senas Colombiana (LSC)',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.muted,
                fontWeight: FontWeight.w400,
                fontSize: 16 * scale,
                letterSpacing: 0.5 * scale,
              ),
            ),
            SizedBox(height: 50 * scale),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxVideoWidth),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 40 * scale,
                      spreadRadius: -10 * scale,
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24 * scale),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        Container(color: const Color(0xFF1A1A1A)),
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(16 * scale),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 50 * scale,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60 * scale,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
