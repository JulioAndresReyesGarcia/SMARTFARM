import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/services/animals_provider.dart';
import 'package:smartfarm_ai/services/dashboard_provider.dart';
import 'package:smartfarm_ai/services/session_provider.dart';
import 'package:smartfarm_ai/theme/app_theme.dart';

import 'mock_providers.dart';

export 'mock_providers.dart';

// ── DB setup (sqflite FFI para tests) ───────────────────────────────────────

bool _dbInitialized = false;
bool _pathProviderMocked = false;

class _FakePathProvider extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = Directory.systemTemp.createTempSync('smartfarm_test_');
    return dir.path;
  }
}

void _setupPathProviderMock() {
  if (_pathProviderMocked) return;
  PathProviderPlatform.instance = _FakePathProvider();
  _pathProviderMocked = true;
}

Future<void> initTestDatabase() async {
  _setupPathProviderMock();
  if (!_dbInitialized) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _dbInitialized = true;
  }
  await AppDatabase.instance.close();
  await AppDatabase.instance.initialize();
}

Future<void> closeTestDatabase() async {
  await AppDatabase.instance.close();
}

// ── Widget helpers ──────────────────────────────────────────────────────────

Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  SessionProvider? session,
  AnimalsProvider? animals,
  DashboardProvider? dashboard,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionProvider>.value(value: session ?? MockSessionProvider()),
        ChangeNotifierProvider<AnimalsProvider>.value(value: animals ?? MockAnimalsProvider()),
        ChangeNotifierProvider<DashboardProvider>.value(value: dashboard ?? MockDashboardProvider()),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );
}

Future<void> pumpScreenWithNavigator(
  WidgetTester tester,
  Widget child, {
  SessionProvider? session,
  AnimalsProvider? animals,
  DashboardProvider? dashboard,
  List<NavigatorObserver>? observers,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionProvider>.value(value: session ?? MockSessionProvider()),
        ChangeNotifierProvider<AnimalsProvider>.value(value: animals ?? MockAnimalsProvider()),
        ChangeNotifierProvider<DashboardProvider>.value(value: dashboard ?? MockDashboardProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: child,
        navigatorObservers: observers ?? [],
      ),
    ),
  );
}

Future<void> enterText(WidgetTester tester, Finder finder, String text) async {
  await tester.enterText(finder, text);
  await tester.pump();
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> verifyAccessibility(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
}
