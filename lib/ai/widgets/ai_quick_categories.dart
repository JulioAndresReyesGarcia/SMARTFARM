import 'package:flutter/material.dart';
import 'package:smartfarm_ai/ai/knowledge/livestock_knowledge.dart';
import 'package:smartfarm_ai/ai/models/user_intent.dart';

/// Selección de categoría rápida con intención explícita.
class QuickCategorySelection {
  const QuickCategorySelection({
    required this.intent,
    required this.prompt,
    required this.label,
  });

  final UserIntent intent;
  final String prompt;
  final String label;
}

/// Categorías rápidas adaptadas a la especie del animal seleccionado.
class AiQuickCategories extends StatelessWidget {
  const AiQuickCategories({
    super.key,
    required this.onSelected,
    required this.species,
    this.animalName = '',
    this.enabled = true,
  });

  final ValueChanged<QuickCategorySelection> onSelected;
  final String species;
  final String animalName;
  final bool enabled;

  List<(String, IconData, UserIntent, String)> _buildCategories() {
    final sp = species.trim().isEmpty ? 'ganado' : species;
    final name = animalName.trim();
    final subject = name.isNotEmpty ? name : 'mi animal';
    final prod = LivestockKnowledge.productionLabel(sp);

    return [
      (
        'Síntomas',
        Icons.healing_outlined,
        UserIntent.sintomas,
        '$subject tiene fiebre y no come bien, ¿qué debo hacer?',
      ),
      (
        'Alimentación',
        Icons.restaurant_outlined,
        UserIntent.nutricion,
        '¿Cuánta ración diaria recomiendas para $subject según su peso de $sp?',
      ),
      (
        'Producción',
        Icons.water_drop_outlined,
        UserIntent.produccion,
        '¿Cómo puedo mejorar la $prod de $subject?',
      ),
      (
        'Vacunas',
        Icons.vaccines_outlined,
        UserIntent.vacunacion,
        '¿Qué vacunas necesita $subject ($sp) y cuándo aplicarlas?',
      ),
      (
        'Veterinario',
        Icons.local_hospital_outlined,
        UserIntent.veterinario,
        'Necesito un veterinario especialista en $sp para $subject',
      ),
      (
        'Emergencia',
        Icons.emergency_outlined,
        UserIntent.emergencia,
        'Emergencia: $subject está muy débil, no se levanta y necesita ayuda urgente',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final categories = _buildCategories();
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, icon, intent, prompt) = categories[i];
          final isEmergency = intent == UserIntent.emergencia;
          return ActionChip(
            avatar: Icon(icon, size: 18),
            label: Text(label),
            onPressed: enabled
                ? () => onSelected(QuickCategorySelection(intent: intent, prompt: prompt, label: label))
                : null,
            backgroundColor: isEmergency
                ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5)
                : null,
          );
        },
      ),
    );
  }
}
