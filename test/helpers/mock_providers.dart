import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/models/time_series.dart';
import 'package:smartfarm_ai/models/usuario.dart';
import 'package:smartfarm_ai/models/dashboard_stats.dart';
import 'package:smartfarm_ai/services/animals_provider.dart';
import 'package:smartfarm_ai/services/dashboard_provider.dart';
import 'package:smartfarm_ai/services/session_provider.dart';

// ── Fixtures ────────────────────────────────────────────────────────────────

const testUsuario = Usuario(id: 1, nombre: 'Administrador', email: 'admin@smartfarm.ai');

const testAnimalLuna = Animal(id: 1, nombre: 'Luna', peso: 280, edad: 18, tipo: 'Bovino');

const testAnimalToro = Animal(id: 2, nombre: 'ToroMax', peso: 450, edad: 36, tipo: 'Bovino');

final testAnimals = [testAnimalLuna, testAnimalToro];

const testDashboardStats = DashboardStats(
  animales: 2,
  raciones: 10,
  produccion: 15,
  costos: 8,
);

final testProductionSeries = [
  TimeSeriesPoint(date: DateTime(2026, 5, 1), value: 7.5),
  TimeSeriesPoint(date: DateTime(2026, 5, 2), value: 8.2),
];

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockSessionProvider extends Mock with ChangeNotifier implements SessionProvider {}

class MockAnimalsProvider extends Mock with ChangeNotifier implements AnimalsProvider {}

class MockDashboardProvider extends Mock with ChangeNotifier implements DashboardProvider {}

void registerMockFallbacks() {
  registerFallbackValue(const Animal(id: 0, nombre: '', peso: 0, edad: 0, tipo: 'Bovino'));
  registerFallbackValue(const Usuario(id: 0, nombre: '', email: ''));
  registerFallbackValue(const DashboardStats(animales: 0, raciones: 0, produccion: 0, costos: 0));
  registerFallbackValue(TimeSeriesPoint(date: DateTime(2026), value: 0));
  registerFallbackValue(DualTimeSeriesPoint(date: DateTime(2026), a: 0, b: 0));
}

void stubSessionLoggedOut(MockSessionProvider mock) {
  when(() => mock.user).thenReturn(null);
  when(() => mock.isLoggedIn).thenReturn(false);
  when(() => mock.busy).thenReturn(false);
  when(() => mock.error).thenReturn(null);
  when(() => mock.login(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer((_) async => false);
  when(() => mock.logout()).thenReturn(null);
}

void stubSessionLoggedIn(MockSessionProvider mock, {Usuario? user}) {
  when(() => mock.user).thenReturn(user ?? testUsuario);
  when(() => mock.isLoggedIn).thenReturn(true);
  when(() => mock.busy).thenReturn(false);
  when(() => mock.error).thenReturn(null);
  when(() => mock.login(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer((_) async => true);
  when(() => mock.logout()).thenReturn(null);
}

void stubSessionBusy(MockSessionProvider mock) {
  when(() => mock.user).thenReturn(null);
  when(() => mock.isLoggedIn).thenReturn(false);
  when(() => mock.busy).thenReturn(true);
  when(() => mock.error).thenReturn(null);
  when(() => mock.login(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer((_) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return true;
  });
  when(() => mock.logout()).thenReturn(null);
}

void stubAnimalsEmpty(MockAnimalsProvider mock) {
  when(() => mock.items).thenReturn([]);
  when(() => mock.recommendationBadges).thenReturn({});
  when(() => mock.busy).thenReturn(false);
  when(() => mock.error).thenReturn(null);
  when(() => mock.refresh()).thenAnswer((_) async {});
  when(
    () => mock.create(
      nombre: any(named: 'nombre'),
      peso: any(named: 'peso'),
      edad: any(named: 'edad'),
      tipo: any(named: 'tipo'),
    ),
  ).thenAnswer((_) async => testAnimalLuna);
  when(() => mock.update(any())).thenAnswer((_) async {});
  when(() => mock.delete(any())).thenAnswer((_) async {});
  when(() => mock.getAnimalProductionSeries(any(), days: any(named: 'days'))).thenAnswer((_) async => []);
  when(() => mock.getAnimalFeedingVsProductionPoint(any(), days: any(named: 'days'))).thenAnswer((_) async => null);
}

void stubAnimalsWithData(MockAnimalsProvider mock, {List<Animal>? animals, bool busy = false, String? error}) {
  final list = animals ?? testAnimals;
  when(() => mock.items).thenReturn(list);
  when(() => mock.recommendationBadges).thenReturn({1: 'Dieta balanceada'});
  when(() => mock.busy).thenReturn(busy);
  when(() => mock.error).thenReturn(error);
  when(() => mock.refresh()).thenAnswer((_) async {});
  when(
    () => mock.create(
      nombre: any(named: 'nombre'),
      peso: any(named: 'peso'),
      edad: any(named: 'edad'),
      tipo: any(named: 'tipo'),
    ),
  ).thenAnswer((_) async => testAnimalLuna);
  when(() => mock.update(any())).thenAnswer((_) async {});
  when(() => mock.delete(any())).thenAnswer((_) async {});
  when(() => mock.getAnimalProductionSeries(any(), days: any(named: 'days'))).thenAnswer((_) async => testProductionSeries);
  when(() => mock.getAnimalFeedingVsProductionPoint(any(), days: any(named: 'days'))).thenAnswer(
    (_) async => DualTimeSeriesPoint(date: DateTime(2026, 5, 1), a: 5.2, b: 7.8),
  );
}

void stubAnimalsLoading(MockAnimalsProvider mock) {
  when(() => mock.items).thenReturn([]);
  when(() => mock.recommendationBadges).thenReturn({});
  when(() => mock.busy).thenReturn(true);
  when(() => mock.error).thenReturn(null);
  when(() => mock.refresh()).thenAnswer((_) async {});
  when(
    () => mock.create(
      nombre: any(named: 'nombre'),
      peso: any(named: 'peso'),
      edad: any(named: 'edad'),
      tipo: any(named: 'tipo'),
    ),
  ).thenAnswer((_) async => testAnimalLuna);
  when(() => mock.update(any())).thenAnswer((_) async {});
  when(() => mock.delete(any())).thenAnswer((_) async {});
  when(() => mock.getAnimalProductionSeries(any(), days: any(named: 'days'))).thenAnswer((_) async => []);
  when(() => mock.getAnimalFeedingVsProductionPoint(any(), days: any(named: 'days'))).thenAnswer((_) async => null);
}

void stubDashboardEmpty(MockDashboardProvider mock) {
  when(() => mock.stats).thenReturn(null);
  when(() => mock.productionOverTime).thenReturn([]);
  when(() => mock.costsVsProduction).thenReturn([]);
  when(() => mock.busy).thenReturn(false);
  when(() => mock.error).thenReturn(null);
  when(() => mock.refresh()).thenAnswer((_) async {});
}

void stubDashboardWithData(MockDashboardProvider mock, {bool busy = false, String? error}) {
  when(() => mock.stats).thenReturn(testDashboardStats);
  when(() => mock.productionOverTime).thenReturn(testProductionSeries);
  when(() => mock.costsVsProduction).thenReturn([]);
  when(() => mock.busy).thenReturn(busy);
  when(() => mock.error).thenReturn(error);
  when(() => mock.refresh()).thenAnswer((_) async {});
}

void stubDashboardLoading(MockDashboardProvider mock) {
  when(() => mock.stats).thenReturn(null);
  when(() => mock.productionOverTime).thenReturn([]);
  when(() => mock.costsVsProduction).thenReturn([]);
  when(() => mock.busy).thenReturn(true);
  when(() => mock.error).thenReturn(null);
  when(() => mock.refresh()).thenAnswer((_) async {});
}

/// Crea mocks con valores por defecto listos para usar.
(MockSessionProvider, MockAnimalsProvider, MockDashboardProvider) createDefaultMocks({
  bool loggedIn = false,
  bool animalsEmpty = true,
  bool dashboardEmpty = true,
}) {
  final session = MockSessionProvider();
  final animals = MockAnimalsProvider();
  final dashboard = MockDashboardProvider();

  if (loggedIn) {
    stubSessionLoggedIn(session);
  } else {
    stubSessionLoggedOut(session);
  }

  if (animalsEmpty) {
    stubAnimalsEmpty(animals);
  } else {
    stubAnimalsWithData(animals);
  }

  if (dashboardEmpty) {
    stubDashboardEmpty(dashboard);
  } else {
    stubDashboardWithData(dashboard);
  }

  return (session, animals, dashboard);
}
