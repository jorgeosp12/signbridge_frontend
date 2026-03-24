import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/responsive_layout.dart';
import 'status_pill.dart';

class NavBar extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  final bool systemOnline;

  const NavBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.systemOnline,
  });

  @override
  Widget build(BuildContext context) {
    final scale = responsiveScale(context, min: 0.9, max: 1.3);
    final maxWidth = responsiveMaxWidth(context, base: 1100);
    final isNarrow = MediaQuery.of(context).size.width < 860;

    Widget navItem(String label) {
      final isActive = selected == label;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 4 * scale),
        child: TextButton(
          onPressed: () => onSelect(label),
          style: TextButton.styleFrom(
            foregroundColor: isActive ? AppColors.text : AppColors.muted,
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 12 * scale,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12 * scale),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24 * scale,
        vertical: 14 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.montserrat(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w900,
                  ),
                  children: [
                    TextSpan(
                      text: 'Sign',
                      style: GoogleFonts.lalezar(
                        color: Colors.white,
                        letterSpacing: 1.5 * scale,
                        fontSize: 25 * scale,
                      ),
                    ),
                    TextSpan(
                      text: 'Bridge',
                      style: GoogleFonts.lalezar(
                        color: AppColors.primary,
                        letterSpacing: 1.5 * scale,
                        fontSize: 25 * scale,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!isNarrow)
                Row(
                  children: [
                    navItem('Inicio'),
                    navItem('Funciones'),
                    navItem('Tutorial'),
                    navItem('Demo'),
                  ],
                ),
              const Spacer(),
              StatusPill(isOnline: systemOnline, scale: scale),
            ],
          ),
        ),
      ),
    );
  }
}
