import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  final bool isOnline;
  final String onlineText;
  final String offlineText;
  final double scale;

  const StatusPill({
    super.key,
    required this.isOnline,
    this.onlineText = 'System Online',
    this.offlineText = 'System Offline',
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isOnline ? AppColors.success : const Color(0xFFEF4444);
    final text = isOnline ? onlineText : offlineText;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8 * scale,
            height: 8 * scale,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: 10 * scale),
          Text(
            text,
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
