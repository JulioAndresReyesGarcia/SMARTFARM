import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartfarm_ai/services/animals_provider.dart';
import 'package:smartfarm_ai/services/ai_chat_service.dart';
import 'package:smartfarm_ai/services/recomendaciones_service.dart';
import 'package:smartfarm_ai/widgets/empty_state.dart';
import 'package:smartfarm_ai/utils/formatters.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> with SingleTickerProviderStateMixin {
  final RecomendacionesService _service = RecomendacionesService();
  final AiChatService _chat = AiChatService();
  bool _busy = false;
  String? _error;
  List<Map<String, Object?>> _items = const [];

  TabController? _tabs;
  final TextEditingController _chatInput = TextEditingController();
  int? _selectedAnimalId;
  bool _chatBusy = false;
  String? _chatError;
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs?.dispose();
    _chatInput.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final animals = context.read<AnimalsProvider>().items;
    setState(() => _busy = true);
    try {
      _error = null;
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
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _regenerateAll() async {
    final animals = context.read<AnimalsProvider>().items;
    setState(() => _busy = true);
    try {
      _error = null;
      for (final a in animals) {
        await _service.generateForAnimal(animalId: a.id);
      }
      await _load();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendChat() async {
    final animals = context.read<AnimalsProvider>().items;
    if (animals.isEmpty) return;
    final animalId = _selectedAnimalId ?? animals.first.id;
    final text = _chatInput.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatBusy = true;
      _chatError = null;
      _messages.add({'role': 'user', 'text': text});
      _chatInput.clear();
    });

    try {
      final answer = await _chat.ask(animalId: animalId, question: text);
      if (!mounted) return;
      setState(() => _messages.add({'role': 'assistant', 'text': answer}));
    } catch (e) {
      if (!mounted) return;
      setState(() => _chatError = e.toString());
    } finally {
      if (mounted) setState(() => _chatBusy = false);
    }
  }

  Widget _buildChatTab() {
    final cs = Theme.of(context).colorScheme;
    final animals = context.watch<AnimalsProvider>().items;
    if (animals.isEmpty) {
      return EmptyState(
        icon: Icons.pets,
        title: 'Chat IA',
        message: 'Crea al menos un animal para pedir recomendaciones.',
        action: const SizedBox.shrink(),
      );
    }

    _selectedAnimalId ??= animals.first.id;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Animal', isDense: true),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedAnimalId,
                      items: [for (final a in animals) DropdownMenuItem(value: a.id, child: Text(a.nombre))],
                      onChanged: _chatBusy ? null : (v) => setState(() => _selectedAnimalId = v),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _chatBusy ? null : () => setState(() => _messages.clear()),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Limpiar',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: _messages.length + (_chatError == null ? 0 : 1),
            itemBuilder: (context, i) {
              if (_chatError != null && i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_chatError!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error)),
                );
              }
              final idx = i - (_chatError == null ? 0 : 1);
              final m = _messages[idx];
              final isUser = m['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? cs.primaryContainer : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    m['text'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isUser ? cs.onPrimaryContainer : cs.onSurface,
                        ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatInput,
                  minLines: 1,
                  maxLines: 4,
                  enabled: !_chatBusy,
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu pregunta…',
                  ),
                  onSubmitted: (_) => _sendChat(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _chatBusy ? null : _sendChat,
                icon: _chatBusy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('IA Nutricional'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Recomendaciones'),
            Tab(text: 'Chat'),
          ],
        ),
        actions: [
          IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _busy ? null : _regenerateAll, icon: const Icon(Icons.auto_awesome)),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _items.isEmpty
              ? EmptyState(
                  icon: Icons.auto_awesome,
                  title: 'Recomendaciones',
                  message: _busy
                      ? 'Generando…'
                      : (_error == null ? 'Registra animales y peso para obtener recomendaciones.' : 'Ocurrió un error al cargar.'),
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
                              if (_error != null) ...[
                                Text(
                                  _error!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error),
                                ),
                                const SizedBox(height: 10),
                              ],
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
          _buildChatTab(),
        ],
      ),
    );
  }
}

