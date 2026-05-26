import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/screens/animal_detail_screen.dart';
import 'package:smartfarm_ai/screens/animal_form_screen.dart';
import 'package:smartfarm_ai/services/animals_provider.dart';
import 'package:smartfarm_ai/services/dashboard_provider.dart';
import 'package:smartfarm_ai/widgets/animal_card.dart';
import 'package:smartfarm_ai/widgets/empty_state.dart';

class AnimalsScreen extends StatelessWidget {
  const AnimalsScreen({super.key});

  Future<void> _openCreate(BuildContext context) async {
    final animalsProvider = context.read<AnimalsProvider>();
    final dashProvider = context.read<DashboardProvider>();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnimalFormScreen()));
    await animalsProvider.refresh();
    await dashProvider.refresh();
  }

  Future<void> _openDetail(BuildContext context, Animal animal) async {
    final animalsProvider = context.read<AnimalsProvider>();
    final dashProvider = context.read<DashboardProvider>();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AnimalDetailScreen(animalId: animal.id)));
    await animalsProvider.refresh();
    await dashProvider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnimalsProvider>();
    final items = provider.items;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganado'),
        actions: [
          IconButton(
            onPressed: provider.busy ? null : () => provider.refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.pets,
              title: 'Sin animales',
              message: provider.busy
                  ? 'Cargando…'
                  : (provider.error ?? 'Registra tu primer animal para empezar.'),
              action: FilledButton.icon(
                onPressed: provider.busy ? null : () => _openCreate(context),
                icon: const Icon(Icons.add),
                label: const Text('Registrar animal'),
              ),
            )
          : Column(
              children: [
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      provider.error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: provider.refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 96),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final a = items[i];
                        return AnimalCard(
                          animal: a,
                          recommendationBadge: provider.recommendationBadges[a.id],
                          onTap: () => _openDetail(context, a),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.busy ? null : () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }
}
