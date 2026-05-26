import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartfarm_ai/widgets/empty_state.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('EmptyState —', () {
    Widget buildWidget({String message = 'Mensaje de prueba', Widget? action}) {
      return MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.pets,
            title: 'Título prueba',
            message: message,
            action: action,
          ),
        ),
      );
    }

    testWidgets('muestra título e icono', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Título prueba'), findsOneWidget);
      expect(find.text('Mensaje de prueba'), findsOneWidget);
      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('muestra acción opcional cuando se proporciona', (tester) async {
      await tester.pumpWidget(
        buildWidget(action: FilledButton(onPressed: () {}, child: const Text('Acción'))),
      );
      expect(find.text('Acción'), findsOneWidget);
    });

    testWidgets('no muestra acción cuando es null', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('cumple reglas básicas de accesibilidad', (tester) async {
      await tester.pumpWidget(
        buildWidget(action: FilledButton(onPressed: () {}, child: const Text('Acción'))),
      );
      await verifyAccessibility(tester);
    });
  });
}
