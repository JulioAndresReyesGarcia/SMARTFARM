import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartfarm_ai/services/dashboard_provider.dart';
import 'package:smartfarm_ai/widgets/empty_state.dart';
import 'package:smartfarm_ai/widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final stats = provider.stats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: provider.busy ? null : () => provider.refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: stats == null
          ? EmptyState(
              icon: Icons.grass,
              title: 'SmartFarm AI',
              message: provider.busy ? 'Cargando datos…' : 'Listo para gestionar tu ganado y nutrición.',
              action: FilledButton(
                onPressed: provider.busy ? null : () => provider.refresh(),
                child: const Text('Actualizar'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                StatCard(icon: Icons.pets, label: 'Animales', value: '${stats.animales}'),
                StatCard(icon: Icons.restaurant, label: 'Raciones', value: '${stats.raciones}'),
                StatCard(icon: Icons.water_drop, label: 'Producción', value: '${stats.produccion}'),
                StatCard(icon: Icons.payments, label: 'Costos', value: '${stats.costos}'),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resumen', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Mantén actualizados los pesos y registra alimentación, producción y costos para obtener recomendaciones más precisas.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

