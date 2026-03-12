import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_layout.dart';

class SectionContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const SectionContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = responsiveMaxWidth(context, base: 1100);
    return Container(
      width: double.infinity,
      color: backgroundColor ?? AppColors.bg,
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
