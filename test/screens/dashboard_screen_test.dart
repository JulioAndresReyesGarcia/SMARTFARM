import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smartfarm_ai/screens/dashboard_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockDashboardProvider mockDashboard;

  setUpAll(registerMockFallbacks);

  setUp(() {
    mockDashboard = MockDashboardProvider();
  });

  group('DashboardScreen —', () {
    Widget buildScreen() => const DashboardScreen();

    Future<void> mount(WidgetTester tester, {MockDashboardProvider? dashboard}) async {
      await pumpScreen(tester, buildScreen(), dashboard: dashboard ?? mockDashboard);
      await tester.pumpAndSettle();
    }

    testWidgets('muestra la pantalla sin errores', (tester) async {
      stubDashboardEmpty(mockDashboard);
      await mount(tester);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('muestra el título Dashboard', (tester) async {
      stubDashboardEmpty(mockDashboard);
      await mount(tester);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('estado inicial sin datos muestra empty state', (tester) async {
      stubDashboardEmpty(mockDashboard);
      await mount(tester);
      expect(find.text('SmartFarm AI'), findsOneWidget);
      expect(find.text('Listo para gestionar tu ganado y nutrición.'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);
    });

    testWidgets('estado de carga muestra mensaje Cargando datos', (tester) async {
      stubDashboardLoading(mockDashboard);
      await pumpScreen(tester, buildScreen(), dashboard: mockDashboard);
      await tester.pump();
      expect(find.text('Cargando datos…'), findsOneWidget);
    });

    testWidgets('muestra estadísticas cuando hay datos', (tester) async {
      stubDashboardWithData(mockDashboard);
      await mount(tester);
      expect(find.text('Animales'), findsOneWidget);
      expect(find.text('Raciones'), findsOneWidget);
      expect(find.text('Producción'), findsOneWidget);
      expect(find.text('Costos'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('muestra mensaje de error cuando falla la carga', (tester) async {
      stubDashboardWithData(mockDashboard, error: 'Error de conexión');
      await mount(tester);
      expect(find.text('Error de conexión'), findsOneWidget);
    });

    testWidgets('botón refresh llama al provider', (tester) async {
      stubDashboardEmpty(mockDashboard);
      await mount(tester);
      clearInteractions(mockDashboard);
      await tapAndSettle(tester, find.byIcon(Icons.refresh));
      verify(() => mockDashboard.refresh()).called(1);
    });

    testWidgets('botón Actualizar en empty state llama refresh', (tester) async {
      stubDashboardEmpty(mockDashboard);
      await mount(tester);
      clearInteractions(mockDashboard);
      await tapAndSettle(tester, find.text('Actualizar'));
      verify(() => mockDashboard.refresh()).called(1);
    });

    testWidgets('muestra gráficos de producción cuando hay datos', (tester) async {
      stubDashboardWithData(mockDashboard);
      await mount(tester);
      expect(find.text('Producción (últimos días)'), findsOneWidget);
    });

    testWidgets('cumple reglas básicas de accesibilidad', (tester) async {
      stubDashboardWithData(mockDashboard);
      await mount(tester);
      await verifyAccessibility(tester);
    });
  });
}
