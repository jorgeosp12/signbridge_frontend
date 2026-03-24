import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/responsive_layout.dart';
import '../widgets/section_container.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = responsiveScale(context, min: 0.9, max: 1.3);
    final maxWidth = responsiveMaxWidth(context, base: 1000);

    return SectionContainer(
      backgroundColor: AppColors.bg.withOpacity(0.5),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 30 * scale,
          vertical: 60 * scale,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 840;

                    final brandColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Sign',
                                    style: GoogleFonts.lalezar(
                                      fontSize: 24 * scale,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 1.5 * scale,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Bridge',
                                    style: GoogleFonts.lalezar(
                                      fontSize: 24 * scale,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      letterSpacing: 1.5 * scale,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16 * scale),
                        Text(
                          'Tecnologia de traduccion de se\u00f1as a voz '
                          'dise\u00f1ada para entornos digitales inclusivos.\n'
                          'Dirigida a personas con dificultades del habla.',
                          style: GoogleFonts.inter(
                            color: AppColors.text,
                            fontWeight: FontWeight.w400,
                            height: 1.6,
                            fontSize: 14 * scale,
                          ),
                        ),
                      ],
                    );

                    final contactColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Autores y contacto',
                          style: GoogleFonts.inter(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5 * scale,
                          ),
                        ),
                        SizedBox(height: 20 * scale),
                        _ContactInfo(
                          name: 'Gissel Vanessa Quitian Rojas',
                          email: 'gvquitianr@correo.usbcali.edu.co',
                          scale: scale,
                        ),
                        SizedBox(height: 16 * scale),
                        _ContactInfo(
                          name: 'Jorge Eduardo Ospina Sanchez',
                          email: 'jeospinas@correo.usbcali.edu.co',
                          scale: scale,
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          brandColumn,
                          SizedBox(height: 50 * scale),
                          contactColumn,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: brandColumn),
                        SizedBox(width: 80 * scale),
                        contactColumn,
                      ],
                    );
                  },
                ),
                SizedBox(height: 48 * scale),
                Divider(color: Colors.white.withOpacity(0.1)),
                SizedBox(height: 24 * scale),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 16 * scale,
                  children: [
                    Text(
                      '(c) 2026 SignBridge. Proyecto de grado. Todos los derechos reservados.',
                      style: GoogleFonts.inter(
                        color: AppColors.muted.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 13 * scale,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
  final double scale;

  const _ContactInfo({
    required this.name,
    required this.email,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline,
                size: 16 * scale, color: AppColors.muted),
            SizedBox(width: 8 * scale),
            Text(
              name,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w400,
                fontSize: 14 * scale,
              ),
            ),
          ],
        ),
        SizedBox(height: 4 * scale),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.email_outlined,
                size: 16 * scale, color: AppColors.primary),
            SizedBox(width: 8 * scale),
            Text(
              email,
              style: GoogleFonts.inter(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
                fontSize: 13 * scale,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
