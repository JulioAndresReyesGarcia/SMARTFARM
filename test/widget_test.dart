import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartfarm_ai/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartFarmAIApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
