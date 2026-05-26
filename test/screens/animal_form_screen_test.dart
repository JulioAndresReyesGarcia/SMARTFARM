import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/screens/animal_form_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockAnimalsProvider mockAnimals;

  setUpAll(registerMockFallbacks);

  setUp(() {
    mockAnimals = MockAnimalsProvider();
    stubAnimalsEmpty(mockAnimals);
  });

  group('AnimalFormScreen —', () {
    Future<void> mount(WidgetTester tester, {Animal? initial}) async {
      await pumpScreenWithNavigator(
        tester,
        AnimalFormScreen(initial: initial),
        animals: mockAnimals,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('muestra la pantalla de registro sin errores', (tester) async {
      await mount(tester);
      expect(find.byType(AnimalFormScreen), findsOneWidget);
      expect(find.text('Registrar animal'), findsOneWidget);
    });

    testWidgets('muestra todos los campos del formulario', (tester) async {
      await mount(tester);
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Tipo'), findsOneWidget);
      expect(find.text('Peso (kg)'), findsOneWidget);
      expect(find.text('Edad (meses)'), findsOneWidget);
      expect(find.text('Crear'), findsOneWidget);
    });

    testWidgets('modo edición muestra título y datos iniciales', (tester) async {
      await mount(tester, initial: testAnimalLuna);
      expect(find.text('Editar animal'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Luna'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('valida nombre vacío', (tester) async {
      await mount(tester);
      await enterText(tester, find.byType(TextFormField).at(0), ' ');
      await tapAndSettle(tester, find.text('Crear'));
      expect(find.text('Ingresa un nombre'), findsOneWidget);
      verifyNever(
        () => mockAnimals.create(
          nombre: any(named: 'nombre'),
          peso: any(named: 'peso'),
          edad: any(named: 'edad'),
          tipo: any(named: 'tipo'),
        ),
      );
    });

    testWidgets('valida peso inválido', (tester) async {
      await mount(tester);
      await enterText(tester, find.byType(TextFormField).at(0), 'Bovino Test');
      await enterText(tester, find.byType(TextFormField).at(1), '0');
      await enterText(tester, find.byType(TextFormField).at(2), '12');
      await tapAndSettle(tester, find.text('Crear'));
      expect(find.text('Peso inválido'), findsOneWidget);
    });

    testWidgets('valida edad inválida', (tester) async {
      await mount(tester);
      await enterText(tester, find.byType(TextFormField).at(0), 'Nuevo Animal');
      await enterText(tester, find.byType(TextFormField).at(1), '300');
      await enterText(tester, find.byType(TextFormField).at(2), '-1');
      await tapAndSettle(tester, find.text('Crear'));
      expect(find.text('Edad inválida'), findsOneWidget);
    });

    testWidgets('submit válido llama create y cierra pantalla', (tester) async {
      await mount(tester);
      await enterText(tester, find.byType(TextFormField).at(0), 'Estrella');
      await enterText(tester, find.byType(TextFormField).at(1), '320');
      await enterText(tester, find.byType(TextFormField).at(2), '24');
      await tapAndSettle(tester, find.text('Crear'));
      verify(
        () => mockAnimals.create(nombre: 'Estrella', peso: 320, edad: 24, tipo: 'Bovino'),
      ).called(1);
      expect(find.byType(AnimalFormScreen), findsNothing);
    });

    testWidgets('submit en edición llama update', (tester) async {
      await mount(tester, initial: testAnimalLuna);
      await enterText(tester, find.byType(TextFormField).at(0), 'Luna Actualizada');
      await tapAndSettle(tester, find.text('Guardar'));
      verify(() => mockAnimals.update(any(that: isA<Animal>().having((a) => a.nombre, 'nombre', 'Luna Actualizada')))).called(1);
    });

    testWidgets('cumple reglas básicas de accesibilidad', (tester) async {
      await mount(tester);
      await verifyAccessibility(tester);
    });
  });
}
