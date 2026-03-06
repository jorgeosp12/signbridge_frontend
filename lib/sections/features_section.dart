import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/section_container.dart';
import 'package:google_fonts/google_fonts.dart';


class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return SectionContainer(
      backgroundColor: AppColors.surface.withOpacity(0.5),
      child: Container(
        constraints: BoxConstraints(minHeight: screenHeight),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Principal features',
              style: GoogleFonts.lalezar(fontSize: 45, fontWeight: FontWeight.w600, letterSpacing: 2.2),
            ),
            const SizedBox(height: 3),
            Text(
              'Designed to improve inclusive communication in Windows',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.text, fontWeight: FontWeight.w400, fontSize: 16),
            ),
            
            const SizedBox(height: 50), 

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: const [
                _InfoChip(icon: Icons.more_horiz, title: '...', subtitle: 'Processing'),
                _InfoChip(icon: Icons.shield_outlined, title: '100%', subtitle: 'Privacy'),
                _InfoChip(icon: Icons.desktop_windows_outlined, title: 'Windows', subtitle: 'Platform'),
              ],
            ),

            const SizedBox(height: 60),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: LayoutBuilder(
                builder: (context, c) {
                  final isNarrow = c.maxWidth < 900;
                  final cards = const [
                    _FeatureCard(
                      icon: Icons.mic_none_rounded,
                      title: 'Translation',
                      description: 'Convert sign language to speech using artificial intelligence.',
                    ),
                    _FeatureCard(
                      icon: Icons.video_call_outlined,
                      title: 'Integration with video calls',
                      description: 'Compatible with Zoom, Meet, Teams via VB-Cable virtual cable.',
                    ),
                    _FeatureCard(
                      icon: Icons.accessibility_new_rounded,
                      title: 'Accessible and intuitive',
                      description: 'Inclusive and easy-to-use design, without many steps involved.',
                    ),
                  ];

                  if (isNarrow) {
                    return Column(
                      children: cards.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: w,
                      )).toList(),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cards.map((w) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: w,
                      ),
                    )).toList(),
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

  const _InfoChip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 160, 
        maxWidth: 200,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 25, color: AppColors.success),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, 
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
                fontSize: 12,
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

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220), 
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: AppColors.success, 
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title, 
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.inter(
              color: AppColors.text,
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}