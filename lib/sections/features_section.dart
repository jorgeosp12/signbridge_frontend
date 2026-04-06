import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/responsive_layout.dart';
import '../widgets/section_container.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = responsiveScale(context, min: 0.8, max: 1.3);
    final contentMax = responsiveMaxWidth(context, base: 1100);

    return SectionContainer(
      backgroundColor: AppColors.bgAlt.withOpacity(0.5),
      child: Container(
        constraints: BoxConstraints(minHeight: screenHeight),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 70 * scale,
          horizontal: 20 * scale,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Funciones principales',
              style: GoogleFonts.lalezar(
                fontSize: 45 * scale,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.2 * scale,
              ),
            ),
            SizedBox(height: 3 * scale),
            Text(
              'Diseñado para mejorar la comunicación inclusiva en Windows',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.text,
                fontWeight: FontWeight.w400,
                fontSize: 16 * scale,
              ),
            ),
            SizedBox(height: 50 * scale),
            Wrap(
              spacing: 12 * scale,
              runSpacing: 12 * scale,
              alignment: WrapAlignment.center,
              children: [
                _InfoChip(
                  icon: Icons.bolt_rounded,
                  title: 'Tiempo real',
                  subtitle: 'Respuesta',
                  scale: scale,
                ),
                _InfoChip(
                  icon: Icons.shield_outlined,
                  title: '100%',
                  subtitle: 'Privacidad',
                  scale: scale,
                ),
                _InfoChip(
                  icon: Icons.desktop_windows_outlined,
                  title: 'Windows',
                  subtitle: 'Plataforma',
                  scale: scale,
                ),
              ],
            ),
            SizedBox(height: 60 * scale),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMax),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 980;
                  final cards = [
                    _FeatureCard(
                      icon: Icons.mic_none_rounded,
                      title: 'Traducción',
                      description:
                          'Convierte lengua de señas en voz usando inteligencia artificial.',
                      scale: scale,
                    ),
                    _FeatureCard(
                      icon: Icons.subtitles_outlined,
                      title: 'Limitaciones',
                      description:
                          'Actualmente no soporta traducción ni reconocimiento de oraciones completas. El sistema traduce palabra por palabra',
                      scale: scale,
                    ),

                    _FeatureCard(
                      icon: Icons.video_call_outlined,
                      title: 'Integración con videollamadas',
                      description:
                          'Compatible con Zoom, Meet y Teams mediante cable virtual VB-Cable.',
                      scale: scale,
                    ),
                    _FeatureCard(
                      icon: Icons.accessibility_new_rounded,
                      title: 'Accesible e intuitivo',
                      description:
                          'Diseño inclusivo y fácil de usar, sin pasos complejos.',
                      scale: scale,
                    ),
                  ];

                  if (isNarrow) {
                    return Column(
                      children: cards
                          .map(
                            (card) => Padding(
                              padding: EdgeInsets.only(bottom: 16 * scale),
                              child: card,
                            ),
                          )
                          .toList(),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cards
                        .map(
                          (card) => Expanded(
                            child: Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 10 * scale),
                              child: card,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double scale;

  const _InfoChip({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: 160 * scale,
        maxWidth: 210 * scale,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 20 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 25 * scale, color: AppColors.success),
          SizedBox(height: 8 * scale),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14 * scale,
              letterSpacing: 0.5 * scale,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: 4 * scale),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
                fontSize: 12 * scale,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double scale;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 220 * scale),
      padding: EdgeInsets.all(24 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16 * scale),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.success,
              size: 16 * scale,
            ),
          ),
          SizedBox(height: 20 * scale),
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 15 * scale,
            ),
          ),
          SizedBox(height: 10 * scale),
          Text(
            description,
            style: GoogleFonts.inter(
              color: AppColors.text,
              fontWeight: FontWeight.w400,
              fontSize: 12 * scale,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
