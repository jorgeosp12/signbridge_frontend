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
    final scale = responsiveScale(context, min: 0.88, max: 1.3);
    final maxWidth = responsiveMaxWidth(context, base: 1120);

    return SectionContainer(
      backgroundColor: AppColors.bg,
      child: Container(
        constraints: BoxConstraints(minHeight: screenHeight),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 80 * scale,
          horizontal: 24 * scale,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'How It Works',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lalezar(
                      fontSize: (46 * scale).clamp(34, 58).toDouble(),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4 * scale,
                      color: AppColors.text,
                    ),
                  ),
                ),
                SizedBox(height: 8 * scale),
                Center(
                  child: Text(
                    'Set up virtual audio cable once, then use SignBridge in live meetings.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w400,
                      fontSize: (16 * scale).clamp(14, 20).toDouble(),
                    ),
                  ),
                ),
                SizedBox(height: 34 * scale),
                _StepCard(
                  index: '1',
                  title: 'Download VB-CABLE',
                  body:
                      'Go to the official VB-Audio website and download VB-CABLE for Windows. Run the installer as administrator and reboot if Windows asks you to.',
                  scale: scale,
                ),
                SizedBox(height: 14 * scale),
                _StepCard(
                  index: '2',
                  title: 'Set Windows Output to CABLE Input',
                  body:
                      'Open Windows Sound settings and select CABLE Input (VB-Audio Virtual Cable) as your default output device. This routes app audio into the virtual cable.',
                  scale: scale,
                ),
                SizedBox(height: 14 * scale),
                _StepCard(
                  index: '3',
                  title: 'Set Meeting Microphone to CABLE Output',
                  body:
                      'In Zoom, Meet, or Teams, open Audio settings and set the microphone/input device to CABLE Output (VB-Audio Virtual Cable). This lets others hear the generated speech.',
                  scale: scale,
                ),
                SizedBox(height: 14 * scale),
                _StepCard(
                  index: '4',
                  title: 'Start SignBridge',
                  body:
                      'Turn on the AI engine, then turn on the camera. Sign word by word, confirm the sentence, and SignBridge sends the spoken output through the cable.',
                  scale: scale,
                ),
                SizedBox(height: 14 * scale),
                _StepCard(
                  index: '5',
                  title: 'Quick Validation',
                  body:
                      'Run a short meeting test. If teammates do not hear audio, re-check both settings: Windows output = CABLE Input and meeting microphone = CABLE Output.',
                  scale: scale,
                ),
                SizedBox(height: 26 * scale),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 900;
                    final placeholderA = _ImagePlaceholder(
                      title: 'Image Placeholder #1',
                      caption:
                          'Show Windows output set to CABLE Input (VB-Audio Virtual Cable).',
                      scale: scale,
                    );
                    final placeholderB = _ImagePlaceholder(
                      title: 'Image Placeholder #2',
                      caption:
                          'Show Zoom/Meet/Teams microphone set to CABLE Output.',
                      scale: scale,
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          placeholderA,
                          SizedBox(height: 16 * scale),
                          placeholderB,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: placeholderA),
                        SizedBox(width: 16 * scale),
                        Expanded(child: placeholderB),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String index;
  final String title;
  final String body;
  final double scale;

  const _StepCard({
    required this.index,
    required this.title,
    required this.body,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF141A23),
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30 * scale,
            height: 30 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              index,
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13 * scale,
              ),
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: (15 * scale).clamp(13, 19).toDouble(),
                  ),
                ),
                SizedBox(height: 6 * scale),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w400,
                    fontSize: (13 * scale).clamp(12, 16).toDouble(),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final String title;
  final String caption;
  final double scale;

  const _ImagePlaceholder({
    required this.title,
    required this.caption,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (220 * scale).clamp(180, 300).toDouble(),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
          width: 1.3,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(14 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              color: AppColors.muted,
              size: 26 * scale,
            ),
            SizedBox(height: 8 * scale),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 14 * scale,
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.muted,
                fontWeight: FontWeight.w400,
                fontSize: 12 * scale,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
