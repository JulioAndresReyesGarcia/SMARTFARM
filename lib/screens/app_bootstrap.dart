import 'package:flutter/material.dart';

import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/database/database_seeder.dart';
import 'package:smartfarm_ai/ai/services/ai_settings_store.dart';
import 'package:smartfarm_ai/main.dart' show SmartFarmAIApp;

/// Inicializa SQLite sin bloquear [main]. Muestra carga o error con reintento.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _ready = false;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await AppDatabase.instance.close();
      await AppDatabase.instance.initialize().timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Tiempo de espera agotado al abrir la base de datos'),
      );
      // Usuario demo debe existir ANTES de mostrar el login.
      await DatabaseSeeder.instance.ensureDemoUser();
      await AiSettingsStore.instance.load();
      // Resto de datos demo en background (animales, historial).
      AppDatabase.instance.seedInBackground();
      if (!mounted) return;
      setState(() {
        _ready = true;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const SmartFarmAIApp();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _error == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          'Iniciando SmartFarm AI…',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preparando base de datos local',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text('No se pudo iniciar la app', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _busy ? null : _initDatabase,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
