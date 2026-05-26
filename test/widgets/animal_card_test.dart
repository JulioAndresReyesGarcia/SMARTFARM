import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartfarm_ai/widgets/animal_card.dart';
import '../helpers/mock_providers.dart';

void main() {
  group('AnimalCard —', () {
    testWidgets('muestra nombre y datos del animal', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimalCard(
              animal: testAnimalLuna,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Luna'), findsOneWidget);
      expect(find.textContaining('Bovino'), findsOneWidget);
      expect(find.textContaining('18 meses'), findsOneWidget);
      expect(find.textContaining('280'), findsOneWidget);
    });

    testWidgets('muestra badge de recomendación cuando se proporciona', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimalCard(
              animal: testAnimalLuna,
              recommendationBadge: 'Dieta balanceada',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Dieta balanceada'), findsOneWidget);
    });

    testWidgets('no muestra badge cuando es null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimalCard(
              animal: testAnimalLuna,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Dieta balanceada'), findsNothing);
    });

    testWidgets('ejecuta onTap al presionar la tarjeta', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimalCard(
              animal: testAnimalLuna,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AnimalCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
