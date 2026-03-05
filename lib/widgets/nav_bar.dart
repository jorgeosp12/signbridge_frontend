import 'package:flutter/material.dart';
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
    Widget navItem(String label) {
      final isActive = selected == label;
      return TextButton(
        onPressed: () => onSelect(label),
        style: TextButton.styleFrom(
          foregroundColor: isActive ? AppColors.text : AppColors.muted,
          textStyle: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        child: Text(label),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bg.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(text: 'Sign', style: TextStyle(color: AppColors.text)),
                    TextSpan(text: 'Bridge', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
              const Spacer(),
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