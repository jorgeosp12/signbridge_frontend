import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Asegúrate de importarlo
import '../theme/app_colors.dart';
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
    // Detectamos si la pantalla es estrecha (celular/tablet pequeña)
    final isNarrow = MediaQuery.of(context).size.width < 800;

    // --- DISEÑO MEJORADO DEL BOTÓN ---
    Widget navItem(String label) {
      final isActive = selected == label;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: TextButton(
          onPressed: () => onSelect(label),
          style: TextButton.styleFrom(
            // El texto se pinta del color principal si está activo
            foregroundColor: isActive ? AppColors.text : AppColors.muted,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter( // Usamos la fuente de tu proyecto
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bg.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            children: [
              // LOGO
              RichText(
                text: TextSpan(
                  style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900),
                  children: [
                    TextSpan(text: 'Sign', style: GoogleFonts.lalezar(color: Colors.white, letterSpacing: 1.5, fontSize: 25)),
                    TextSpan(text: 'Bridge', style: GoogleFonts.lalezar(color: AppColors.primary, letterSpacing: 1.5, fontSize: 25)),
                  ],
                ),
              ),
              
              const Spacer(),

              if (!isNarrow)
                Row(
                  children: [
                    navItem('Home'),
                    navItem('Features'),
                    navItem('Tutorial'),
                    navItem('Demo'),
                  ],
                ),

              const Spacer(),

              StatusPill(isOnline: systemOnline),
            ],
          ),
        ),
      ),
    );
  }
}