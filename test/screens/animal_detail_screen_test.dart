import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smartfarm_ai/screens/animal_detail_screen.dart';
import 'package:smartfarm_ai/widgets/empty_state.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockAnimalsProvider mockAnimals;
  late MockDashboardProvider mockDashboard;

  setUpAll(registerMockFallbacks);

  setUp(() {
    mockAnimals = MockAnimalsProvider();
    mockDashboard = MockDashboardProvider();
    stubAnimalsWithData(mockAnimals);
    stubDashboardWithData(mockDashboard);
  });

  group('AnimalDetailScreen —', () {
    Future<void> mount(WidgetTester tester, {int animalId = 9999}) async {
      await pumpScreenWithNavigator(
        tester,
        AnimalDetailScreen(animalId: animalId),
        animals: mockAnimals,
        dashboard: mockDashboard,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    testWidgets('muestra la pantalla sin errores', (tester) async {
      await mount(tester);
      expect(find.byType(AnimalDetailScreen), findsOneWidget);
    });

    testWidgets('animal inexistente muestra empty state', (tester) async {
      await mount(tester);
      expect(find.text('Detalle'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('estado de carga inicial muestra mensaje Cargando', (tester) async {
      await pumpScreenWithNavigator(
        tester,
        const AnimalDetailScreen(animalId: 9999),
        animals: mockAnimals,
        dashboard: mockDashboard,
      );
      await tester.pump();
      expect(find.text('Cargando…'), findsOneWidget);
    });

    testWidgets('botón Reintentar vuelve a intentar cargar', (tester) async {
      await mount(tester);
      await tapAndSettle(tester, find.text('Reintentar'));
      expect(find.byType(AnimalDetailScreen), findsOneWidget);
    });

    testWidgets('cumple reglas básicas de accesibilidad', (tester) async {
      await mount(tester);
      await verifyAccessibility(tester);
    });
  });
}
