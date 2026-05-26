import 'package:smartfarm_ai/ai/knowledge/veterinarian_directory.dart';
import 'package:smartfarm_ai/ai/models/risk_level.dart';
import 'package:smartfarm_ai/ai/models/user_intent.dart';
import 'package:smartfarm_ai/ai/models/veterinarian_suggestion.dart';

/// Recomienda veterinarios según especie, intención y nivel de riesgo.
class VeterinarianRecommender {
  const VeterinarianRecommender();

  List<VeterinarianSuggestion> recommend({
    required String species,
    required UserIntent intent,
    required RiskLevel risk,
    String? locationHint,
  }) {
    final results = <VeterinarianSuggestion>[];

    if (risk == RiskLevel.emergencia || intent == UserIntent.emergencia) {
      results.addAll(VeterinarianDirectory.emergencies());
    }

    if (intent == UserIntent.veterinario ||
        intent == UserIntent.sintomas ||
        intent == UserIntent.emergencia ||
        risk.index >= RiskLevel.alto.index) {
      results.addAll(VeterinarianDirectory.bySpecies(species));
    }

    if (results.isEmpty && (intent == UserIntent.vacunacion || intent == UserIntent.reproduccion)) {
      results.addAll(VeterinarianDirectory.bySpecies(species).take(2));
    }

    // Deduplicar por nombre
    final seen = <String>{};
    final unique = <VeterinarianSuggestion>[];
    for (final v in results) {
      if (seen.add(v.name)) unique.add(v);
    }
    return unique.take(3).toList();
  }
}
