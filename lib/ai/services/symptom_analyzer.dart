import 'package:smartfarm_ai/ai/knowledge/livestock_knowledge.dart';
import 'package:smartfarm_ai/ai/models/risk_level.dart';
import 'package:smartfarm_ai/ai/utils/text_normalize.dart';

/// Resultado del análisis orientativo de síntomas.
class SymptomAnalysis {
  final List<LivestockCondition> matches;
  final RiskLevel riskLevel;
  final List<String> detectedSymptoms;

  const SymptomAnalysis({
    required this.matches,
    required this.riskLevel,
    required this.detectedSymptoms,
  });
}

class SymptomAnalyzer {
  const SymptomAnalyzer();

  SymptomAnalysis analyze({
    required String question,
    required String species,
  }) {
    final q = normalizeForMatch(question);
    final normalizedSpecies = LivestockKnowledge.normalizeSpecies(species);

    if (LivestockKnowledge.emergencyKeywords.any((k) => q.contains(normalizeForMatch(k)))) {
      return SymptomAnalysis(
        matches: const [],
        riskLevel: RiskLevel.emergencia,
        detectedSymptoms: ['signos de posible emergencia'],
      );
    }

    final detected = <String>[];
    final matches = <LivestockCondition>[];

    for (final condition in LivestockKnowledge.conditions) {
      final speciesMatch = condition.species.any(
        (s) => normalizedSpecies.contains(s) || s.contains(normalizedSpecies),
      );
      if (!speciesMatch && normalizedSpecies.isNotEmpty) continue;

      var hitCount = 0;
      for (final symptom in condition.symptoms) {
        if (q.contains(normalizeForMatch(symptom))) {
          hitCount++;
          detected.add(symptom);
        }
      }
      if (hitCount >= 1) matches.add(condition);
    }

    matches.sort((a, b) {
      int score(LivestockCondition c) {
        var s = 0;
        for (final sym in c.symptoms) {
          if (q.contains(sym)) s++;
        }
        return s;
      }
      return score(b).compareTo(score(a));
    });

    final risk = _assessRisk(q, matches);
    return SymptomAnalysis(
      matches: matches.take(3).toList(),
      riskLevel: risk,
      detectedSymptoms: detected.toSet().toList(),
    );
  }

  RiskLevel _assessRisk(String q, List<LivestockCondition> matches) {
    if (textContainsAny(q, ['sangre', 'convulsion', 'colapso', 'no respira', 'inconsciente'])) {
      return RiskLevel.emergencia;
    }
    if (textContainsAny(q, ['fiebre alta', 'severa', 'empeora', 'varios animales', 'no come', 'dehidrat'])) {
      return RiskLevel.alto;
    }
    if (matches.isNotEmpty || textContainsAny(q, ['fiebre', 'diarrea', 'tos', 'cojera'])) {
      return RiskLevel.medio;
    }
    return RiskLevel.bajo;
  }
}
