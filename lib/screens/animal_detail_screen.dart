import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/screens/animal_form_screen.dart';
import 'package:smartfarm_ai/services/animals_provider.dart';
import 'package:smartfarm_ai/services/animales_service.dart';
import 'package:smartfarm_ai/services/costos_service.dart';
import 'package:smartfarm_ai/services/produccion_service.dart';
import 'package:smartfarm_ai/services/raciones_service.dart';
import 'package:smartfarm_ai/services/recomendaciones_service.dart';
import 'package:smartfarm_ai/services/dashboard_provider.dart';
import 'package:smartfarm_ai/utils/formatters.dart';
import 'package:smartfarm_ai/widgets/empty_state.dart';

class AnimalDetailScreen extends StatefulWidget {
  final int animalId;

  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> with SingleTickerProviderStateMixin {
  final AnimalesService _animalesService = AnimalesService();
  final RacionesService _raciones = RacionesService();
  final ProduccionService _produccion = ProduccionService();
  final CostosService _costos = CostosService();
  final RecomendacionesService _recs = RecomendacionesService();

  TabController? _tabs;
  Animal? _animal;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      _animal = await _animalesService.getById(widget.animalId);
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final a = _animal;
    if (a == null) return;
    final animalsProvider = context.read<AnimalsProvider>();
    final dashProvider = context.read<DashboardProvider>();
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AnimalFormScreen(initial: a)),
    );
    if (res == true) {
      await animalsProvider.refresh();
      await dashProvider.refresh();
      await _load();
    }
  }

  Future<void> _delete() async {
    final a = _animal;
    if (a == null) return;
    final animalsProvider = context.read<AnimalsProvider>();
    final dashProvider = context.read<DashboardProvider>();
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar animal'),
        content: Text('Se eliminará "${a.nombre}" y su historial asociado.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    await animalsProvider.delete(a.id);
    if (!mounted) return;
    await dashProvider.refresh();
    nav.pop();
  }

  Future<void> _addRacion() async {
    final a = _animal;
    if (a == null) return;
    final dashProvider = context.read<DashboardProvider>();
    final res = await _showTwoFieldsDialog(
      title: 'Registrar alimentación',
      field1Label: 'Cantidad (kg)',
      field2Label: 'Tipo de alimento',
      keyboard1: const TextInputType.numberWithOptions(decimal: true),
    );
    if (res == null) return;
    final cantidad = double.tryParse(res.$1.replaceAll(',', '.')) ?? 0;
    final tipo = res.$2.trim();
    if (cantidad <= 0 || tipo.isEmpty) return;
    await _raciones.create(animalId: a.id, fecha: DateTime.now(), cantidad: cantidad, tipoAlimento: tipo);
    await dashProvider.refresh();
    setState(() {});
  }

  Future<void> _addProduccion() async {
    final a = _animal;
    if (a == null) return;
    final dashProvider = context.read<DashboardProvider>();
    final res = await _showOneFieldDialog(
      title: 'Registrar producción',
      fieldLabel: 'Producción',
      keyboard: const TextInputType.numberWithOptions(decimal: true),
    );
    if (res == null) return;
    final prod = double.tryParse(res.replaceAll(',', '.')) ?? 0;
    if (prod <= 0) return;
    await _produccion.create(animalId: a.id, fecha: DateTime.now(), produccion: prod);
    await dashProvider.refresh();
    setState(() {});
  }

  Future<void> _addCosto() async {
    final a = _animal;
    if (a == null) return;
    final dashProvider = context.read<DashboardProvider>();
    final res = await _showOneFieldDialog(
      title: 'Registrar costo',
      fieldLabel: 'Costo',
      keyboard: const TextInputType.numberWithOptions(decimal: true),
    );
    if (res == null) return;
    final costo = double.tryParse(res.replaceAll(',', '.')) ?? 0;
    if (costo <= 0) return;
    await _costos.create(animalId: a.id, fecha: DateTime.now(), costo: costo);
    await dashProvider.refresh();
    setState(() {});
  }

  Future<(String, String)?> _showTwoFieldsDialog({
    required String title,
    required String field1Label,
    required String field2Label,
    TextInputType? keyboard1,
  }) async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final res = await showDialog<(String, String)?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: c1,
              keyboardType: keyboard1,
              decoration: InputDecoration(labelText: field1Label),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: c2,
              decoration: InputDecoration(labelText: field2Label),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop((c1.text, c2.text)), child: const Text('Guardar')),
        ],
      ),
    );
    c1.dispose();
    c2.dispose();
    return res;
  }

  Future<String?> _showOneFieldDialog({
    required String title,
    required String fieldLabel,
    TextInputType? keyboard,
  }) async {
    final c = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: fieldLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(c.text), child: const Text('Guardar')),
        ],
      ),
    );
    c.dispose();
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final a = _animal;
    if (a == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Animal')),
        body: EmptyState(
          icon: Icons.pets,
          title: 'Detalle',
          message: _busy ? 'Cargando…' : 'No se encontró el animal.',
          action: FilledButton(onPressed: _busy ? null : _load, child: const Text('Reintentar')),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(a.nombre),
        actions: [
          IconButton(onPressed: _busy ? null : _edit, icon: const Icon(Icons.edit)),
          IconButton(onPressed: _busy ? null : _delete, icon: const Icon(Icons.delete_outline)),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Alimentación'),
            Tab(text: 'Producción'),
            Tab(text: 'Costos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ResumenTab(animalId: a.id, tipo: a.tipo, edad: a.edad, peso: a.peso),
          _RacionesTab(animalId: a.id, service: _raciones),
          _ProduccionTab(animalId: a.id, service: _produccion),
          _CostosTab(animalId: a.id, service: _costos),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final i = _tabs?.index ?? 0;
          if (i == 1) return _addRacion();
          if (i == 2) return _addProduccion();
          if (i == 3) return _addCosto();
          await _recs.generateForAnimal(animalId: a.id);
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: const Text('Recomendación generada'),
              backgroundColor: cs.primary,
            ),
          );
          setState(() {});
        },
        icon: const Icon(Icons.add),
        label: Text((_tabs?.index ?? 0) == 0 ? 'Generar IA' : 'Registrar'),
      ),
    );
  }
}

class _ResumenTab extends StatelessWidget {
  final int animalId;
  final String tipo;
  final int edad;
  final double peso;

  const _ResumenTab({
    required this.animalId,
    required this.tipo,
    required this.edad,
    required this.peso,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.pets, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tipo, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Edad: $edad meses · Peso: ${Formatters.number.format(peso)} kg',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _RecsPreview(animalId: animalId),
      ],
    );
  }
}

class _RecsPreview extends StatefulWidget {
  final int animalId;

  const _RecsPreview({required this.animalId});

  @override
  State<_RecsPreview> createState() => _RecsPreviewState();
}

class _RecsPreviewState extends State<_RecsPreview> {
  final RecomendacionesService _service = RecomendacionesService();
  bool _busy = false;
  String? _text;
  DateTime? _fecha;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final items = await _service.getForAnimal(widget.animalId);
      if (items.isEmpty) {
        _text = null;
        _fecha = null;
      } else {
        _text = items.first.recomendacion;
        _fecha = items.first.fecha;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Recomendación', style: Theme.of(context).textTheme.titleMedium)),
                IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 8),
            if (_text == null)
              Text(
                _busy ? 'Cargando…' : 'Aún no hay recomendaciones.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              )
            else ...[
              Text(_text!),
              const SizedBox(height: 10),
              Text(
                Formatters.date.format(_fecha!),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RacionesTab extends StatefulWidget {
  final int animalId;
  final RacionesService service;

  const _RacionesTab({required this.animalId, required this.service});

  @override
  State<_RacionesTab> createState() => _RacionesTabState();
}

class _RacionesTabState extends State<_RacionesTab> {
  bool _busy = false;
  List<Map<String, Object?>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final rows = await widget.service.getForAnimal(widget.animalId);
      _items = rows
          .map((r) => {
                'id': r.id,
                'fecha': r.fecha,
                'cantidad': r.cantidad,
                'tipo': r.tipoAlimento,
              })
          .toList(growable: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(int id) async {
    final dashProvider = context.read<DashboardProvider>();
    await widget.service.delete(id);
    await dashProvider.refresh();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.restaurant,
        title: 'Alimentación',
        message: _busy ? 'Cargando…' : 'Sin registros aún.',
        action: FilledButton(onPressed: _busy ? null : _load, child: const Text('Actualizar')),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 96),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final it = _items[i];
          final fecha = it['fecha'] as DateTime;
          final cantidad = it['cantidad'] as double;
          final tipo = it['tipo'] as String;
          return Card(
            child: ListTile(
              title: Text('${Formatters.number.format(cantidad)} kg'),
              subtitle: Text('$tipo · ${Formatters.date.format(fecha)}'),
              trailing: IconButton(
                onPressed: () => _delete(it['id'] as int),
                icon: Icon(Icons.delete_outline, color: cs.error),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProduccionTab extends StatefulWidget {
  final int animalId;
  final ProduccionService service;

  const _ProduccionTab({required this.animalId, required this.service});

  @override
  State<_ProduccionTab> createState() => _ProduccionTabState();
}

class _ProduccionTabState extends State<_ProduccionTab> {
  bool _busy = false;
  List<Map<String, Object?>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final rows = await widget.service.getForAnimal(widget.animalId);
      _items = rows
          .map((r) => {
                'id': r.id,
                'fecha': r.fecha,
                'produccion': r.produccion,
              })
          .toList(growable: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(int id) async {
    final dashProvider = context.read<DashboardProvider>();
    await widget.service.delete(id);
    await dashProvider.refresh();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.water_drop,
        title: 'Producción',
        message: _busy ? 'Cargando…' : 'Sin registros aún.',
        action: FilledButton(onPressed: _busy ? null : _load, child: const Text('Actualizar')),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 96),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final it = _items[i];
          final fecha = it['fecha'] as DateTime;
          final prod = it['produccion'] as double;
          return Card(
            child: ListTile(
              title: Text(Formatters.number.format(prod)),
              subtitle: Text(Formatters.date.format(fecha)),
              trailing: IconButton(
                onPressed: () => _delete(it['id'] as int),
                icon: Icon(Icons.delete_outline, color: cs.error),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CostosTab extends StatefulWidget {
  final int animalId;
  final CostosService service;

  const _CostosTab({required this.animalId, required this.service});

  @override
  State<_CostosTab> createState() => _CostosTabState();
}

class _CostosTabState extends State<_CostosTab> {
  bool _busy = false;
  List<Map<String, Object?>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final rows = await widget.service.getForAnimal(widget.animalId);
      _items = rows
          .map((r) => {
                'id': r.id,
                'fecha': r.fecha,
                'costo': r.costo,
              })
          .toList(growable: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(int id) async {
    final dashProvider = context.read<DashboardProvider>();
    await widget.service.delete(id);
    await dashProvider.refresh();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.payments,
        title: 'Costos',
        message: _busy ? 'Cargando…' : 'Sin registros aún.',
        action: FilledButton(onPressed: _busy ? null : _load, child: const Text('Actualizar')),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 96),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final it = _items[i];
          final fecha = it['fecha'] as DateTime;
          final costo = it['costo'] as double;
          return Card(
            child: ListTile(
              title: Text(Formatters.money.format(costo)),
              subtitle: Text(Formatters.date.format(fecha)),
              trailing: IconButton(
                onPressed: () => _delete(it['id'] as int),
                icon: Icon(Icons.delete_outline, color: cs.error),
              ),
            ),
          );
        },
      ),
    );
  }
}

