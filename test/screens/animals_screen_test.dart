import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smartfarm_ai/screens/animal_form_screen.dart';
import 'package:smartfarm_ai/screens/animals_screen.dart';
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

  group('AnimalsScreen —', () {
    Widget buildScreen() => const AnimalsScreen();

    Future<void> mount(WidgetTester tester) async {
      await pumpScreenWithNavigator(
        tester,
        buildScreen(),
        animals: mockAnimals,
        dashboard: mockDashboard,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('muestra la pantalla sin errores', (tester) async {
      stubAnimalsEmpty(mockAnimals);
      await mount(tester);
      expect(find.byType(AnimalsScreen), findsOneWidget);
    });

    testWidgets('muestra el título Ganado', (tester) async {
      stubAnimalsEmpty(mockAnimals);
      await mount(tester);
      expect(find.text('Ganado'), findsOneWidget);
    });

    testWidgets('lista vacía muestra empty state', (tester) async {
      stubAnimalsEmpty(mockAnimals);
      await mount(tester);
      expect(find.text('Sin animales'), findsOneWidget);
      expect(find.text('Registra tu primer animal para empezar.'), findsOneWidget);
      expect(find.text('Registrar animal'), findsOneWidget);
    });

    testWidgets('estado de carga muestra mensaje Cargando', (tester) async {
      stubAnimalsLoading(mockAnimals);
      await pumpScreenWithNavigator(tester, buildScreen(), animals: mockAnimals, dashboard: mockDashboard);
      await tester.pump();
      expect(find.text('Cargando…'), findsOneWidget);
    });

    testWidgets('muestra lista con el número correcto de animales', (tester) async {
      stubAnimalsWithData(mockAnimals);
      await mount(tester);
      expect(find.text('Luna'), findsOneWidget);
      expect(find.text('ToroMax'), findsOneWidget);
      expect(find.text('Dieta balanceada'), findsOneWidget);
    });

    testWidgets('muestra mensaje de error del provider', (tester) async {
      stubAnimalsWithData(mockAnimals, animals: [], error: 'Error al listar animales');
      when(() => mockAnimals.items).thenReturn([]);
      await mount(tester);
      expect(find.text('Error al listar animales'), findsOneWidget);
    });

    testWidgets('botón refresh llama al provider', (tester) async {
      stubAnimalsEmpty(mockAnimals);
      await mount(tester);
      clearInteractions(mockAnimals);
      await tapAndSettle(tester, find.byIcon(Icons.refresh));
      verify(() => mockAnimals.refresh()).called(1);
    });

    testWidgets('FAB Nuevo navega al formulario de registro', (tester) async {
      stubAnimalsEmpty(mockAnimals);
      await mount(tester);
      await tapAndSettle(tester, find.text('Nuevo'));
      expect(find.byType(AnimalFormScreen), findsOneWidget);
      expect(find.text('Registrar animal'), findsOneWidget);
    });

    testWidgets('tap en animal navega al detalle', (tester) async {
      stubAnimalsWithData(mockAnimals);
      await mount(tester);
      await tapAndSettle(tester, find.text('Luna'));
      expect(find.text('Animal'), findsOneWidget);
    });

    testWidgets('pull to refresh llama refresh del provider', (tester) async {
      stubAnimalsWithData(mockAnimals);
      await mount(tester);
      clearInteractions(mockAnimals);
      await tester.drag(find.text('Luna'), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      verify(() => mockAnimals.refresh()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('cumple reglas básicas de accesibilidad', (tester) async {
      stubAnimalsWithData(mockAnimals);
      await mount(tester);
      await verifyAccessibility(tester);
    });
  });
}
