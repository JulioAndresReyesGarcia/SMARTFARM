import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smartfarm_ai/screens/recommendations_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockAnimalsProvider mockAnimals;
  late MockDashboardProvider mockDashboard;

  setUpAll(registerMockFallbacks);

  setUp(() {
    mockAnimals = MockAnimalsProvider();
    mockDashboard = MockDashboardProvider();
    stubDashboardEmpty(mockDashboard);
  });

  group('RecommendationsScreen —', () {
    Widget buildScreen() => const RecommendationsScreen();

    Future<void> mount(WidgetTester tester) async {
      await pumpScreen(
        tester,
        buildScreen(),
        animals: mockAnimals,
        dashboard: mockDashboard,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    testWidgets('muestra la pantalla sin errores', (tester) async {
      stubAnimalsWithData(mockAnimals);
      await mount(tester);
      expect(find.byType(RecommendationsScreen), findsOneWidget);
    });

    testWidgets('muestra título y pestañas', (tester) async {
      stubAnimalsWithData(mockAnimals);
      await mount(tester);
      expect(find.text('IA Nutricional'), findsOneWidget);
      expect(find.text('Recomendaciones'), findsWidgets);
      expect(find.text('Chat'), findsOneWidget);
    });

    testWidgets('sin datos muestra empty state con botón Generar', (tester) async {
      stubAnimalsEmpty(mockAnimals);
      await mount(tester);
      expect(find.text('Recomendaciones'), findsWidgets);
      expect(find.text('Generar'), findsOneWidget);
    });

    testWidgets('sin animales en chat muestra empty state', (tester) async {
      stubAnimalsEmpty(mockAnimals);
      await mount(tester);
      await tapAndSettle(tester, find.text('Chat'));
      expect(find.text('Chat IA'), findsOneWidget);
      expect(find.text('Crea al menos un animal para pedir recomendaciones.'), findsOneWidget);
    });

    testWidgets('pestaña chat con animales muestra selector y campo de texto', (tester) async {
      stubAnimalsWithData(mockAnimals);
      await mount(tester);
      await tapAndSettle(tester, find.text('Chat'));
      expect(find.text('Animal'), findsOneWidget);
      expect(find.text('Escribe tu pregunta…'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('muestra acciones de recarga y generación', (tester) async {
      stubAnimalsWithData(mockAnimals);
      await mount(tester);
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.refresh)),
        findsOneWidget,
      );
      expect(
        find.byTooltip('Generar'),
        findsOneWidget,
      );
    });

    testWidgets('cumple reglas básicas de accesibilidad', (tester) async {
      stubAnimalsWithData(mockAnimals);
      await mount(tester);
      await verifyAccessibility(tester);
    });
  });
}
