import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartfarm_ai/ai/models/ai_assistant_response.dart';
import 'package:smartfarm_ai/ai/models/chat_message.dart';
import 'package:smartfarm_ai/ai/config/ai_config.dart';
import 'package:smartfarm_ai/ai/services/ai_settings_store.dart';
import 'package:smartfarm_ai/ai/widgets/ai_settings_dialog.dart';
import 'package:smartfarm_ai/ai/models/user_intent.dart';
import 'package:smartfarm_ai/ai/widgets/ai_quick_categories.dart';
import 'package:smartfarm_ai/ai/widgets/ai_structured_response_card.dart';
import 'package:smartfarm_ai/ai/utils/animal_context_formatter.dart';
import 'package:smartfarm_ai/services/animals_provider.dart';
import 'package:smartfarm_ai/services/ai_chat_service.dart';
import 'package:smartfarm_ai/services/recomendaciones_service.dart';
import 'package:smartfarm_ai/widgets/empty_state.dart';
import 'package:smartfarm_ai/utils/formatters.dart';

class _ChatEntry {
  final bool isUser;
  final String? userText;
  final AiAssistantResponse? assistantResponse;

  const _ChatEntry.user(this.userText)
      : isUser = true,
        assistantResponse = null;

  const _ChatEntry.assistant(this.assistantResponse)
      : isUser = false,
        userText = null;
}

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> with SingleTickerProviderStateMixin {
  final RecomendacionesService _service = RecomendacionesService();
  final AiChatService _chat = AiChatService();
  final ScrollController _chatScroll = ScrollController();

  bool _busy = false;
  String? _error;
  List<Map<String, Object?>> _items = const [];

  TabController? _tabs;
  final TextEditingController _chatInput = TextEditingController();
  int? _selectedAnimalId;
  bool _chatBusy = false;
  String? _chatError;
  final List<_ChatEntry> _entries = [];
  final List<ChatMessage> _history = [];
  bool _aiConfigured = false;
  int? _historyAnimalId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _refreshAiConfigured();
    _load();
  }

  Future<void> _refreshAiConfigured() async {
    if (!AiSettingsStore.instance.isLoaded) {
      await AiSettingsStore.instance.load();
    }
    if (mounted) setState(() => _aiConfigured = AiConfig.hasCloudAi);
  }

  @override
  void dispose() {
    _tabs?.dispose();
    _chatInput.dispose();
    _chatScroll.dispose();
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

  Future<void> _openAiSettings() async {
    final saved = await AiSettingsDialog.show(context);
    if (saved == true && mounted) {
      setState(() => _aiConfigured = AiConfig.hasCloudAi);
    }
  }

  void _clearChat() {
    setState(() {
      _entries.clear();
      _history.clear();
      _historyAnimalId = null;
      _chatError = null;
    });
  }

  void _onAnimalChanged(int? newId) {
    if (newId == null || newId == _selectedAnimalId) return;
    setState(() {
      _selectedAnimalId = newId;
      _entries.clear();
      _history.clear();
      _historyAnimalId = null;
      _chatError = null;
    });
  }

  String _tagForAnimal(int animalId, String text) {
    final animal = context.read<AnimalsProvider>().items.firstWhere(
          (a) => a.id == animalId,
          orElse: () => context.read<AnimalsProvider>().items.first,
        );
    return AnimalContextFormatter.tagHistoryMessage(
      nombre: animal.nombre,
      tipo: animal.tipo,
      content: text,
    );
  }

  /// Historial enriquecido para que la IA recuerde el contexto en preguntas de seguimiento.
  String _historyContentForAi(AiAssistantResponse answer) {
    final buf = StringBuffer(answer.summary);
    if (answer.probableAssessment != null) {
      buf.write('\nEvaluación: ${answer.probableAssessment}');
    }
    if (answer.recommendations.isNotEmpty) {
      buf.write('\nRecomendé: ${answer.recommendations.take(3).join("; ")}');
    }
    final text = buf.toString();
    return text.length > 600 ? answer.summary : text;
  }

  Future<void> _scrollChatToBottom() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!_chatScroll.hasClients) return;
    await _chatScroll.animateTo(
      _chatScroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendChat([String? preset, UserIntent? forcedIntent]) async {
    final animals = context.read<AnimalsProvider>().items;
    if (animals.isEmpty) return;
    final animalId = _selectedAnimalId ?? animals.first.id;
    final text = (preset ?? _chatInput.text).trim();
    if (text.isEmpty || _chatBusy) return;

    setState(() {
      _chatBusy = true;
      _chatError = null;
      _historyAnimalId = animalId;
      _entries.add(_ChatEntry.user(text));
      _history.add(ChatMessage(
        role: 'user',
        content: _tagForAnimal(animalId, text),
        timestamp: DateTime.now(),
      ));
      _chatInput.clear();
    });
    await _scrollChatToBottom();

    final intent = forcedIntent;

    try {
      final answer = await _chat.askStructured(
        animalId: animalId,
        question: text,
        history: _history.length > 1 ? _history.sublist(0, _history.length - 1) : null,
        forcedIntent: intent,
      );
      if (!mounted) return;
      setState(() {
        _entries.add(_ChatEntry.assistant(answer));
        if (answer.cloudFallbackReason != null) {
          _chatError = answer.cloudFallbackReason;
        }
        _history.add(ChatMessage(
          role: 'assistant',
          content: _tagForAnimal(animalId, _historyContentForAi(answer)),
          timestamp: DateTime.now(),
        ));
      });
      await _scrollChatToBottom();
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
    final selectedAnimal = animals.firstWhere(
      (a) => a.id == _selectedAnimalId,
      orElse: () => animals.first,
    );

    return Column(
      children: [
        Material(
          color: cs.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Orientación informativa. No sustituye diagnóstico veterinario profesional.',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                      onChanged: _chatBusy ? null : _onAnimalChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _chatBusy ? null : _clearChat,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Limpiar historial',
              ),
            ],
          ),
        ),
        if (!_aiConfigured)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Material(
              color: cs.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _openAiSettings,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.key, color: cs.onTertiaryContainer, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Activa la IA inteligente — toca aquí para pegar tu API key de OpenAI',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onTertiaryContainer),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: cs.onTertiaryContainer),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        AiQuickCategories(
          onSelected: (sel) => _sendChat(sel.prompt, sel.intent),
          enabled: !_chatBusy,
          species: selectedAnimal.tipo,
          animalName: selectedAnimal.nombre,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: _chatScroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: _entries.length + (_chatError == null ? 0 : 1) + (_chatBusy ? 1 : 0),
            itemBuilder: (context, i) {
              if (_chatError != null && i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_chatError!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error)),
                );
              }
              final offset = (_chatError == null ? 0 : 1);
              if (_chatBusy && i == _entries.length + offset) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Text('IA escribiendo…', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                );
              }

              final entry = _entries[i - offset];
              if (entry.isUser) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      entry.userText ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onPrimaryContainer),
                    ),
                  ),
                );
              }
              return AiStructuredResponseCard(response: entry.assistantResponse!);
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
                    prefixIcon: Icon(Icons.chat_outlined),
                  ),
                  onSubmitted: (_) => _sendChat(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _chatBusy ? null : () => _sendChat(),
                icon: _chatBusy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                tooltip: 'Enviar',
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
            Tab(icon: Icon(Icons.auto_awesome), text: 'Recomendaciones'),
            Tab(icon: Icon(Icons.smart_toy_outlined), text: 'Chat'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openAiSettings,
            icon: Icon(_aiConfigured ? Icons.cloud_done : Icons.key_outlined),
            tooltip: 'Configurar IA',
          ),
          IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Actualizar'),
          IconButton(onPressed: _busy ? null : _regenerateAll, icon: const Icon(Icons.auto_awesome), tooltip: 'Generar'),
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
                              if (_error != null && i == 0) ...[
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
