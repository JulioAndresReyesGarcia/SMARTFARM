import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartfarm_ai/main.dart';

void main() {
  testWidgets('SmartFarmAIApp construye MaterialApp', (tester) async {
    await tester.pumpWidget(const SmartFarmAIApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('muestra LoginScreen cuando no hay sesión', (tester) async {
    await tester.pumpWidget(const SmartFarmAIApp());
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
