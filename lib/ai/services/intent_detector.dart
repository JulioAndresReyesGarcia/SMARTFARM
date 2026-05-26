import 'package:smartfarm_ai/ai/knowledge/livestock_knowledge.dart';
import 'package:smartfarm_ai/ai/models/user_intent.dart';
import 'package:smartfarm_ai/ai/utils/text_normalize.dart';

/// Detecta la intención principal del mensaje del usuario.
class IntentDetector {
  const IntentDetector();

  static const _healthKeywords = [
    'fiebre', 'enferm', 'sintoma', 'dolor', 'diarrea', 'tos', 'cojera',
    'herida', 'inflam', 'vomit', 'no come', 'decaid', 'decaido', 'debil', 'triste',
    'pata', 'ojos', 'lagrima', 'secrecion', 'supur', 'absceso', 'infecc', 'parasit',
    'anemia', 'respir', 'estornud', 'tremor', 'convulsion', 'sangre', 'hinch',
    'bulto', 'magro', 'pierde peso', 'letarg', 'apetito', 'heces', 'orina',
  ];

  UserIntent detect(String question) {
    final q = normalizeForMatch(question);

    if (textContainsAny(q, LivestockKnowledge.emergencyKeywords)) return UserIntent.emergencia;
    if (textContainsAny(q, ['veterinario', 'vet ', 'doctor', 'especialista', 'clinica'])) {
      return UserIntent.veterinario;
    }
    if (hasHealthKeywords(question)) return UserIntent.sintomas;
    if (textContainsAny(q, ['vacuna', 'vacunacion', 'inmuniz', 'refuerzo', 'antigeno'])) {
      return UserIntent.vacunacion;
    }
    if (textContainsAny(q, ['celo', 'preñ', 'parto', 'reprodu', 'insemin', 'monta', 'gestacion'])) {
      return UserIntent.reproduccion;
    }
    if (textContainsAny(q, ['produc', 'leche', 'huevo', 'rendimiento', 'ganancia', 'litros'])) {
      return UserIntent.produccion;
    }
    if (textContainsAny(q, ['comport', 'agresiv', 'estres', 'ansiedad', 'aisl', 'nervios', 'inquiet'])) {
      return UserIntent.comportamiento;
    }
    if (textContainsAny(q, ['clima', 'calor', 'frio', 'humedad', 'temporada', 'lluvia', 'sequia'])) {
      return UserIntent.clima;
    }
    if (textContainsAny(q, [
      'racion', 'aliment', 'comida', 'dieta', 'forraje', 'concentrado',
      'nutri', ' kg', 'costo', 'comer', 'pasto', 'suplemento', 'maiz', 'sal', 'racion diaria',
    ])) {
      return UserIntent.nutricion;
    }
    return UserIntent.general;
  }

  bool hasHealthKeywords(String q) => textContainsAny(q, _healthKeywords);
}
