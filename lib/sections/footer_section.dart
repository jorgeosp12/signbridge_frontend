import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/section_container.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      backgroundColor: AppColors.surface.withOpacity(0.75),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('SignBridge', style: TextStyle(fontWeight: FontWeight.w900)),
                    SizedBox(height: 10),
                    Text(
                      'Sign-to-speech translation technology designed for inclusive digital environments.\n'
                      'Aimed at people with speech difficulties.',
                      style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Contacto', style: TextStyle(fontWeight: FontWeight.w900)),
                    SizedBox(height: 10),
                    Text('Gissel Vanessa Quitian Rojas', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Correo: gisselvanessa@example.com', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                    SizedBox(height: 14),
                    Text('Jorge Eduardo Ospina Sanchez', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Correo: jorgeospina@example.com', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Text('© 2026 SignBridge. All rights reserved.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('Privacy')),
              TextButton(onPressed: () {}, child: const Text('Terms')),
            ],
          ),
        ],
      ),
    );
  }
}