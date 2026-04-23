import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/services/animals_provider.dart';
import 'package:smartfarm_ai/utils/formatters.dart';

class AnimalFormScreen extends StatefulWidget {
  final Animal? initial;

  const AnimalFormScreen({super.key, this.initial});

  @override
  State<AnimalFormScreen> createState() => _AnimalFormScreenState();
}

class _AnimalFormScreenState extends State<AnimalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _peso;
  late final TextEditingController _edad;
  String _tipo = 'Bovino';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _nombre = TextEditingController(text: i?.nombre ?? '');
    _peso = TextEditingController(text: i == null ? '' : Formatters.number.format(i.peso));
    _edad = TextEditingController(text: i?.edad.toString() ?? '');
    _tipo = i?.tipo ?? 'Bovino';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _peso.dispose();
    _edad.dispose();
    super.dispose();
  }

  double? _parseDouble(String raw) {
    final normalized = raw.replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final provider = context.read<AnimalsProvider>();
      final nombre = _nombre.text.trim();
      final peso = _parseDouble(_peso.text) ?? 0;
      final edad = int.parse(_edad.text.trim());
      if (widget.initial == null) {
        await provider.create(nombre: nombre, peso: peso, edad: edad, tipo: _tipo);
      } else {
        final current = widget.initial!;
        await provider.update(
          Animal(id: current.id, nombre: nombre, peso: peso, edad: edad, tipo: _tipo),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar animal' : 'Registrar animal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nombre,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return 'Ingresa un nombre';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _tipo,
                        items: const [
                          DropdownMenuItem(value: 'Bovino', child: Text('Bovino')),
                          DropdownMenuItem(value: 'Caprino', child: Text('Caprino')),
                          DropdownMenuItem(value: 'Ovino', child: Text('Ovino')),
                          DropdownMenuItem(value: 'Porcino', child: Text('Porcino')),
                        ],
                        onChanged: _busy ? null : (v) => setState(() => _tipo = v ?? 'Bovino'),
                        decoration: const InputDecoration(labelText: 'Tipo'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _peso,
                        decoration: const InputDecoration(labelText: 'Peso (kg)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          final d = _parseDouble(v ?? '');
                          if (d == null || d <= 0) return 'Peso inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _edad,
                        decoration: const InputDecoration(labelText: 'Edad (meses)'),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n < 0) return 'Edad inválida';
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: Text(isEdit ? 'Guardar' : 'Crear'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

