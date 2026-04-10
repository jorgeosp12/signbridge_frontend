import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:signbridge_frontend/main.dart';

void main() {
  testWidgets('SignBridge landing renders', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const SignBridgeApp());

    expect(find.text('UNDERGRADUATE PROJECT 2026'), findsOneWidget);
    expect(find.text('Start AI engine'), findsOneWidget);
  });
}
