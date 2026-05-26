import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smartfarm_ai/screens/login_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockSessionProvider mockSession;

  setUpAll(registerMockFallbacks);

  setUp(() {
    mockSession = MockSessionProvider();
    stubSessionLoggedOut(mockSession);
  });

  group('LoginScreen —', () {
    Widget buildScreen() => LoginScreen();

    Future<void> mount(WidgetTester tester) async {
      await pumpScreen(tester, buildScreen(), session: mockSession);
      await tester.pumpAndSettle();
    }

    testWidgets('muestra la pantalla sin errores', (tester) async {
      await mount(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('muestra el título y elementos visuales clave', (tester) async {
      await mount(tester);
      expect(find.text('SmartFarm AI'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Gestión local con recomendaciones'), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Demo: admin@smartfarm.ai / 1234'), findsOneWidget);
    });

    testWidgets('estado inicial muestra credenciales demo precargadas', (tester) async {
      await mount(tester);
      expect(find.byType(TextFormField), findsNWidgets(2));
      final emailField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(emailField.controller?.text, 'admin@smartfarm.ai');
    });

    testWidgets('valida email vacío', (tester) async {
      await mount(tester);
      await enterText(tester, find.byType(TextFormField).first, '');
      await tapAndSettle(tester, find.text('Entrar'));
      expect(find.text('Ingresa tu email'), findsOneWidget);
      verifyNever(() => mockSession.login(email: any(named: 'email'), password: any(named: 'password')));
    });

    testWidgets('valida email inválido sin @', (tester) async {
      await mount(tester);
      await enterText(tester, find.byType(TextFormField).first, 'correo-invalido');
      await tapAndSettle(tester, find.text('Entrar'));
      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('valida password vacío', (tester) async {
      await mount(tester);
      await enterText(tester, find.byType(TextFormField).last, '');
      await tapAndSettle(tester, find.text('Entrar'));
      expect(find.text('Ingresa tu password'), findsOneWidget);
    });

    testWidgets('botón Entrar llama a login con credenciales válidas', (tester) async {
      when(() => mockSession.login(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer((_) async => true);
      await mount(tester);
      await tapAndSettle(tester, find.text('Entrar'));
      verify(() => mockSession.login(email: 'admin@smartfarm.ai', password: '1234')).called(1);
    });

    testWidgets('muestra snackbar cuando las credenciales son inválidas', (tester) async {
      when(() => mockSession.login(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer((_) async => false);
      await mount(tester);
      await tapAndSettle(tester, find.text('Entrar'));
      expect(find.text('Credenciales inválidas'), findsOneWidget);
    });

    testWidgets('muestra indicador de carga mientras login está en progreso', (tester) async {
      stubSessionBusy(mockSession);
      await pumpScreen(tester, buildScreen(), session: mockSession);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Entrar'), findsNothing);
    });

    testWidgets('deshabilita botón Entrar mientras está ocupado', (tester) async {
      stubSessionBusy(mockSession);
      await pumpScreen(tester, buildScreen(), session: mockSession);
      await tester.pump();
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('cumple reglas básicas de accesibilidad', (tester) async {
      await mount(tester);
      await verifyAccessibility(tester);
    });
  });
}
