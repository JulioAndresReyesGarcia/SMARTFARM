import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smartfarm_ai/screens/dashboard_screen.dart';
import 'package:smartfarm_ai/screens/home_shell.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockSessionProvider mockSession;
  late MockAnimalsProvider mockAnimals;
  late MockDashboardProvider mockDashboard;

  setUpAll(registerMockFallbacks);

  setUp(() {
    mockSession = MockSessionProvider();
    mockAnimals = MockAnimalsProvider();
    mockDashboard = MockDashboardProvider();
    stubSessionLoggedIn(mockSession);
    stubAnimalsEmpty(mockAnimals);
    stubDashboardEmpty(mockDashboard);
  });

  group('HomeShell —', () {
    Widget buildScreen() => const HomeShell();

    Future<void> mount(WidgetTester tester) async {
      await pumpScreen(
        tester,
        buildScreen(),
        session: mockSession,
        animals: mockAnimals,
        dashboard: mockDashboard,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('muestra la pantalla sin errores', (tester) async {
      await mount(tester);
      expect(find.byType(HomeShell), findsOneWidget);
    });

    testWidgets('muestra dashboard como pestaña inicial', (tester) async {
      await mount(tester);
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('muestra barra de navegación con tres destinos', (tester) async {
      await mount(tester);
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Ganado'), findsOneWidget);
      expect(find.text('IA'), findsOneWidget);
    });

    testWidgets('llama refresh de providers al iniciar', (tester) async {
      await mount(tester);
      verify(() => mockAnimals.refresh()).called(1);
      verify(() => mockDashboard.refresh()).called(1);
    });

    testWidgets('navega a pestaña Ganado al seleccionar destino', (tester) async {
      await mount(tester);
      await tapAndSettle(tester, find.text('Ganado'));
      expect(find.text('Ganado', skipOffstage: false), findsWidgets);
      expect(find.text('Sin animales'), findsOneWidget);
    });

    testWidgets('navega a pestaña IA al seleccionar destino', (tester) async {
      await mount(tester);
      await tapAndSettle(tester, find.text('IA'));
      expect(find.text('IA Nutricional'), findsOneWidget);
    });

    testWidgets('muestra botón Salir solo en pestaña Inicio', (tester) async {
      await mount(tester);
      expect(find.text('Salir'), findsOneWidget);
      await tapAndSettle(tester, find.text('Ganado'));
      expect(find.text('Salir'), findsNothing);
    });

    testWidgets('botón Salir ejecuta logout', (tester) async {
      await mount(tester);
      await tapAndSettle(tester, find.text('Salir'));
      verify(() => mockSession.logout()).called(1);
    });

    testWidgets('cumple reglas básicas de accesibilidad', (tester) async {
      await mount(tester);
      await verifyAccessibility(tester);
    });
  });
}
