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
    final scale = responsiveScale(context, min: 0.82, max: 1.3);
    final contentMax = responsiveMaxWidth(context, base: 1120);

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
              'Main Features',
              textAlign: TextAlign.center,
              style: GoogleFonts.lalezar(
                fontSize: (44 * scale).clamp(34, 56).toDouble(),
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0 * scale,
              ),
            ),
            SizedBox(height: 4 * scale),
            Text(
              'Built to improve inclusive communication on Windows.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.text,
                fontWeight: FontWeight.w400,
                fontSize: (16 * scale).clamp(14, 20).toDouble(),
              ),
            ),
            SizedBox(height: 44 * scale),
            Wrap(
              spacing: 12 * scale,
              runSpacing: 12 * scale,
              alignment: WrapAlignment.center,
              children: [
                _InfoChip(
                  icon: Icons.bolt_rounded,
                  title: 'Real-time',
                  subtitle: 'Responses',
                  scale: scale,
                ),
                _InfoChip(
                  icon: Icons.shield_outlined,
                  title: 'Privacy-first',
                  subtitle: 'No conversations stored',
                  scale: scale,
                ),
                _InfoChip(
                  icon: Icons.desktop_windows_outlined,
                  title: 'Windows',
                  subtitle: 'Ready',
                  scale: scale,
                ),
              ],
            ),
            SizedBox(height: 50 * scale),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMax),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 1200
                      ? 265.0 * scale
                      : constraints.maxWidth >= 900
                          ? 300.0 * scale
                          : constraints.maxWidth;

                  return Wrap(
                    spacing: 16 * scale,
                    runSpacing: 16 * scale,
                    alignment: WrapAlignment.center,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _FeatureCard(
                          icon: Icons.mic_none_rounded,
                          title: 'Sign-to-Speech',
                          description:
                              'Converts ASL signs into spoken output with AI-driven inference. The system translates word by word.',
                          scale: scale,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _FeatureCard(
                          icon: Icons.auto_fix_high_outlined,
                          title: 'Sentence Cleanup',
                          description:
                              'It uses Gemini to reorder the detected words and convert them into natural text.',
                          scale: scale,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _FeatureCard(
                          icon: Icons.video_call_outlined,
                          title: 'Meeting Integration',
                          description:
                              'Works with Zoom, Google Meet, and Teams through virtual cable routing.',
                          scale: scale,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _FeatureCard(
                          icon: Icons.accessibility_new_rounded,
                          title: 'Accessible UX',
                          description:
                              'Simple interaction flow and clear controls for practical, daily use.',
                          scale: scale,
                        ),
                      ),
                    ],
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
        maxWidth: 235 * scale,
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
              letterSpacing: 0.3 * scale,
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
            padding: EdgeInsets.all(14 * scale),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.success,
              size: 18 * scale,
            ),
          ),
          SizedBox(height: 18 * scale),
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16 * scale,
            ),
          ),
          SizedBox(height: 10 * scale),
          Text(
            description,
            style: GoogleFonts.inter(
              color: AppColors.text,
              fontWeight: FontWeight.w400,
              fontSize: 13 * scale,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
