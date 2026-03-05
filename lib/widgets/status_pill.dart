import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  final bool isOnline;
  final String onlineText;
  final String offlineText;

  const StatusPill({
    super.key,
    required this.isOnline,
    this.onlineText = 'System Online',
    this.offlineText = 'System Offline',
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isOnline ? AppColors.success : const Color(0xFFEF4444);
    final text = isOnline ? onlineText : offlineText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}