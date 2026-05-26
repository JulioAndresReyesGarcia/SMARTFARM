import 'package:flutter/material.dart';

import 'package:smartfarm_ai/ai/config/ai_config.dart';
import 'package:smartfarm_ai/ai/services/ai_settings_store.dart';

/// Diálogo para configurar la clave OpenAI / Gemini desde la app.
class AiSettingsDialog extends StatefulWidget {
  const AiSettingsDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const AiSettingsDialog(),
    );
  }

  @override
  State<AiSettingsDialog> createState() => _AiSettingsDialogState();
}

class _AiSettingsDialogState extends State<AiSettingsDialog> {
  late final TextEditingController _openAi;
  late final TextEditingController _gemini;
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _openAi = TextEditingController(text: AiSettingsStore.instance.openAiKey);
    _gemini = TextEditingController(text: AiSettingsStore.instance.geminiKey);
  }

  @override
  void dispose() {
    _openAi.dispose();
    _gemini.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AiSettingsStore.instance.saveOpenAiKey(_openAi.text);
      await AiSettingsStore.instance.saveGeminiKey(_gemini.text);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.key_outlined),
          SizedBox(width: 8),
          Text('Configurar IA'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pega tu API key de OpenAI para activar respuestas inteligentes. '
              'Se guarda solo en este dispositivo.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _openAi,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'OpenAI API Key',
                hintText: 'sk-...',
                prefixIcon: const Icon(Icons.auto_awesome),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gemini,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key (opcional)',
                hintText: 'AIza...',
                prefixIcon: Icon(Icons.psychology_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (AiConfig.hasCloudAi)
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text('IA en la nube activa', style: tt.labelSmall?.copyWith(color: cs.primary)),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              'Obtén tu clave en platform.openai.com → API keys',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
