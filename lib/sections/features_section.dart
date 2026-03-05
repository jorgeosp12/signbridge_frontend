import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/section_container.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      backgroundColor: AppColors.surface.withOpacity(0.75),
      child: Column(
        children: [
          const Text(
            'Principal features',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Designed to improve inclusive communication in Windows',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 22),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: const [
              _InfoChip(icon: Icons.more_horiz, title: '...', subtitle: ''),
              _InfoChip(icon: Icons.shield_outlined, title: '100%', subtitle: 'Privacy'),
              _InfoChip(icon: Icons.desktop_windows_outlined, title: 'Windows', subtitle: 'Platform'),
            ],
          ),

          const SizedBox(height: 22),

          LayoutBuilder(
            builder: (context, c) {
              final isNarrow = c.maxWidth < 900;
              final cards = const [
                _FeatureCard(
                  icon: Icons.mic_none_rounded,
                  title: 'Translation',
                  description:
                      'Convert sign language to speech\nusing artificial intelligence.',
                ),
                _FeatureCard(
                  icon: Icons.video_call_outlined,
                  title: 'Integration with video calls',
                  description:
                      'Compatible with Zoom, Meet, Teams\nvia VB-Cable virtual cable.',
                ),
                _FeatureCard(
                  icon: Icons.accessibility_new_rounded,
                  title: 'Accessible and intuitive',
                  description:
                      'Inclusive and easy-to-use design,\nwithout many steps involved.',
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: cards
                      .map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: w,
                          ))
                      .toList(),
                );
              }

              return Row(
                children: cards
                    .map((w) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: w,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
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
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 70),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.success, size: 18),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}