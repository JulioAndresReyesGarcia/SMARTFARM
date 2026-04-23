import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartfarm_ai/services/animals_provider.dart';
import 'package:smartfarm_ai/services/recomendaciones_service.dart';
import 'package:smartfarm_ai/widgets/empty_state.dart';
import 'package:smartfarm_ai/utils/formatters.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final RecomendacionesService _service = RecomendacionesService();
  bool _busy = false;
  List<Map<String, Object?>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final animals = context.read<AnimalsProvider>().items;
    setState(() => _busy = true);
    try {
      final recs = await _service.getLatest(limit: 30);
      final byId = {for (final a in animals) a.id: a.nombre};
      _items = recs
          .map((r) => {
                'animalId': r.animalId,
                'animalNombre': byId[r.animalId] ?? 'Animal #${r.animalId}',
                'fecha': r.fecha,
                'text': r.recomendacion,
              })
          .toList(growable: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _regenerateAll() async {
    final animals = context.read<AnimalsProvider>().items;
    setState(() => _busy = true);
    try {
      for (final a in animals) {
        await _service.generateForAnimal(animalId: a.id);
      }
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('IA Nutricional'),
        actions: [
          IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _busy ? null : _regenerateAll, icon: const Icon(Icons.auto_awesome)),
        ],
      ),
      body: _items.isEmpty
          ? EmptyState(
              icon: Icons.auto_awesome,
              title: 'Recomendaciones',
              message: _busy ? 'Generando…' : 'Registra animales y peso para obtener recomendaciones.',
              action: FilledButton.icon(
                onPressed: _busy ? null : _regenerateAll,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generar'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final it = _items[i];
                  final fecha = it['fecha'] as DateTime;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  it['animalNombre'] as String,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                Formatters.date.format(fecha),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(it['text'] as String),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

