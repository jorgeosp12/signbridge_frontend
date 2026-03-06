import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/section_container.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      backgroundColor: AppColors.surface.withOpacity(0.5),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 750;

                    final brandColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sign_language, color: AppColors.primary, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'SignBridge',
                              style: GoogleFonts.lalezar(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sign-to-speech translation technology'
                          'designed for inclusive digital environments.\n'
                          'Aimed at people with speech difficulties.',
                          style: GoogleFonts.inter(
                            color: AppColors.text,
                            fontWeight: FontWeight.w400,
                            height: 1.6, 
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );

                    final contactColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Authors & Contact',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Autor 1
                        _ContactInfo(
                          name: 'Gissel Vanessa Quitián Rojas',
                          email: 'gvquitianr@correo.usbcali.edu.co',
                        ),
                        const SizedBox(height: 16),
                        
                        _ContactInfo(
                          name: 'Jorge Eduardo Ospina Sánchez',
                          email: 'jeospinas@correo.usbcali.edu.co',
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          brandColumn,
                          const SizedBox(height: 50),
                          contactColumn,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: brandColumn), 
                        const SizedBox(width: 80),
                        contactColumn,
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 48),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 24),
 
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 16,
                  children: [
                    Text(
                      '© 2026 SignBridge. Thesis Project. All rights reserved.',
                      style: GoogleFonts.inter(
                        color: AppColors.muted.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                          child: const Text('Privacy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                          child: const Text('Terms', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ],
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

class _ContactInfo extends StatelessWidget {
  final String name;
  final String email;

  const _ContactInfo({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 16, color: AppColors.muted),
            const SizedBox(width: 8),
            Text(
              name,
              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w400, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.email_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              email,
              style: GoogleFonts.inter(color: AppColors.muted, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}