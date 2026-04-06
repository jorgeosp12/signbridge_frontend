import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/responsive_layout.dart';

class CameraTestSection extends StatelessWidget {
  final bool engineOn;

  const CameraTestSection({
    super.key,
    required this.engineOn,
  });

  @override
  Widget build(BuildContext context) {
    final scale = responsiveScale(context, min: 0.9, max: 1.3);
    final maxWidth = responsiveMaxWidth(context, base: 900);
    final statusColor = engineOn ? AppColors.success : const Color(0xFFEF4444);
    final statusText = engineOn ? 'Motor de IA activo' : 'Motor de IA inactivo';

    return Container(
      width: double.infinity,
      color: AppColors.bgAlt,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: EdgeInsets.all(28 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFF141A23),
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEMO',
                  style: GoogleFonts.lalezar(
                    fontSize: 40 * scale,
                    color: AppColors.text,
                    letterSpacing: 1.2 * scale,
                  ),
                ),
                SizedBox(height: 10 * scale),
                Text(
                  'Este modulo de captura en vivo se ejecuta actualmente en Flutter Web.',
                  style: GoogleFonts.inter(
                    color: AppColors.muted,
                    fontSize: 15 * scale,
                  ),
                ),
                SizedBox(height: 18 * scale),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10 * scale,
                      height: 10 * scale,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14 * scale,
                      ),
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
