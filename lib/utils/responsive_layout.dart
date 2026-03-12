import 'package:flutter/widgets.dart';

double responsiveScale(
  BuildContext context, {
  double baseWidth = 1366,
  double min = 0.88,
  double max = 1.45,
}) {
  final width = MediaQuery.of(context).size.width;
  final raw = width / baseWidth;
  return raw.clamp(min, max);
}

double responsiveMaxWidth(
  BuildContext context, {
  double base = 1100,
}) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 2400) return base * 1.65;
  if (width >= 2000) return base * 1.45;
  if (width >= 1700) return base * 1.3;
  if (width >= 1450) return base * 1.15;
  return base;
}
