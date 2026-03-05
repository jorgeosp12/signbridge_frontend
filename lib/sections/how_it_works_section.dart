import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/section_container.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      backgroundColor: AppColors.bg,
      child: Column(
        children: [
          const Text(
            'See how it works',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Explanation in Sign Language (LSC)',
            style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 720),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  Icon(Icons.play_circle_outline_rounded, size: 74, color: Color(0xFF111827)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}