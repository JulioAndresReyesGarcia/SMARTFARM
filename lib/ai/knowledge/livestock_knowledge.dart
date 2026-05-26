/// Condición ganadera común con síntomas asociados.
class LivestockCondition {
  final String id;
  final String name;
  final List<String> species; // bovino, porcino, aves, etc.
  final List<String> symptoms;
  final String careAdvice;
  final String prevention;
  final String vetWhen;

  const LivestockCondition({
    required this.id,
    required this.name,
    required this.species,
    required this.symptoms,
    required this.careAdvice,
    required this.prevention,
    required this.vetWhen,
  });
}

/// Base de conocimiento básica mantenible (orientativa, no clínica).
class LivestockKnowledge {
  LivestockKnowledge._();

  static const disclaimer =
      'Información orientativa para ganadería. No constituye diagnóstico veterinario.';

  static const conditions = <LivestockCondition>[
    LivestockCondition(
      id: 'mastitis',
      name: 'Posible mastitis',
      species: ['bovino', 'caprino'],
      symptoms: ['ubres', 'leche', 'coagulos', 'inflamacion', 'fiebre', 'dolor ubre', 'no come'],
      careAdvice: 'Ordeñe con higiene, aplique compresas tibias y aísle al animal.',
      prevention: 'Higiene en ordeño, desinfección de pezones, camas secas.',
      vetWhen: 'Si hay fiebre, leche con pus o empeora en 24 h.',
    ),
    LivestockCondition(
      id: 'diarrea',
      name: 'Posible trastorno digestivo / diarrea',
      species: ['bovino', 'porcino', 'ovino', 'caprino', 'aves'],
      symptoms: ['diarrea', 'heces', 'liquidas', 'deshidrat', 'deposiciones', 'vomit', 'no come'],
      careAdvice: 'Agua limpia, electrolitos si está disponible, dieta blanda temporal.',
      prevention: 'Agua fresca, limpieza de bebederos, transición gradual de ración.',
      vetWhen: 'Diarrea con sangre, letargo severo o más de 24–48 h sin mejoría.',
    ),
    LivestockCondition(
      id: 'respiratorio',
      name: 'Posible afectación respiratoria',
      species: ['bovino', 'porcino', 'aves', 'ovino'],
      symptoms: ['tos', 'estornud', 'respir', 'nasal', 'moco', 'dificultad', 'fiebre'],
      careAdvice: 'Mejor ventilación, reducir polvo, aislar al animal afectado.',
      prevention: 'Bioseguridad, vacunación según calendario local, densidad adecuada.',
      vetWhen: 'Dificultad respiratoria visible, fiebre alta o varios animales afectados.',
    ),
    LivestockCondition(
      id: 'cojera',
      name: 'Posible cojera / afectación locomotora',
      species: ['bovino', 'ovino', 'caprino', 'porcino'],
      symptoms: ['cojera', 'pata', 'camin', 'apoya', 'pezuña', 'claudic'],
      careAdvice: 'Revisar pezuñas, limpiar corral, evitar superficies resbalosas.',
      prevention: 'Recorte de pezuñas, camas cómodas, control de humedad.',
      vetWhen: 'No apoya la pata, hinchazón severa o cojera que empeora rápido.',
    ),
    LivestockCondition(
      id: 'parasitos',
      name: 'Posible parasitosis interna',
      species: ['bovino', 'ovino', 'caprino', 'porcino'],
      symptoms: ['parasito', 'lombrices', 'anemia', 'pelaje', 'bajo peso', 'barba sucia'],
      careAdvice: 'Muestras de heces si es posible; mejorar rotación de potreros.',
      prevention: 'Desparasitación programada según veterinario y rotación de pastos.',
      vetWhen: 'Pérdida de peso rápida, anemia visible o debilidad marcada.',
    ),
    LivestockCondition(
      id: 'metabolic',
      name: 'Posible desbalance metabólico (cetosis/acidosis ruminal)',
      species: ['bovino'],
      symptoms: ['no come', 'apetito', 'decaid', 'rumia', 'aliento', 'acetona'],
      careAdvice: 'Evaluar ración; asegurar fibra (forraje) y acceso a agua.',
      prevention: 'Transiciones graduales de dieta, fibra adecuada, evitar exceso de concentrado.',
      vetWhen: 'Animal no come >24 h, debilidad extrema o convulsiones.',
    ),
    LivestockCondition(
      id: 'aviar',
      name: 'Posible enfermedad aviar',
      species: ['aves', 'pollo', 'gallina', 'pato'],
      symptoms: ['aves', 'pollo', 'gallina', 'plumas', 'produccion huevos', 'cascos'],
      careAdvice: 'Aislar aves enfermas, limpiar galpón, revisar ventilación.',
      prevention: 'Bioseguridad, vacunas según programa avícola, control de densidad.',
      vetWhen: 'Mortalidad súbita, caída brusca de producción o síntomas neurológicos.',
    ),
  ];

  static const emergencyKeywords = [
    'sangre',
    'convulsion',
    'no respira',
    'inconsciente',
    'colapso',
    'hemorragia',
    'paralisis',
    'moribundo',
    'emergencia',
    'urgente',
    'morir',
  ];

  static const vaccinationTips = [
    'Consulta el calendario sanitario local con tu veterinario.',
    'Registra fecha, lote y tipo de vacuna por animal o lote.',
    'Aplica refuerzos según especie (IBR, clostridiales, etc.).',
    'Vacuna en animales sanos, no bajo estrés extremo.',
  ];

  static const speciesAliases = {
    'bov': 'bovino',
    'vaca': 'bovino',
    'toro': 'bovino',
    'porc': 'porcino',
    'cerdo': 'porcino',
    'ovin': 'ovino',
    'oveja': 'ovino',
    'capr': 'caprino',
    'cabra': 'caprino',
    'avi': 'aves',
    'pollo': 'aves',
    'gallina': 'aves',
  };

  static String normalizeSpecies(String tipo) {
    final t = tipo.toLowerCase();
    for (final entry in speciesAliases.entries) {
      if (t.contains(entry.key)) return entry.value;
    }
    return t;
  }

  /// Orientación específica por especie para prompts y respuestas locales.
  static String speciesGuidance(String tipo) {
    switch (normalizeSpecies(tipo)) {
      case 'caprino':
        return 'Caprino/cabra: forraje de calidad + concentrado según producción; '
            'comunes: parásitos internos, pododermitis, mastitis, deficiencias minerales. '
            'Evitar alimentos de bovino sin adaptar (copper toxicity).';
      case 'bovino':
        return 'Bovino: pastoreo o TMR; comunes: mastitis, acidosis ruminal, cojera, '
            'problemas respiratorios en confinamiento.';
      case 'porcino':
        return 'Porcino: bioseguridad estricta; comunes: diarrea neonatal, PRRS, '
            'problemas respiratorios; ración por fase de crecimiento.';
      case 'ovino':
        return 'Ovino: pastoreo y desparasitación; comunes: parásitos pulmonares, '
            'pododermitis, deficiencia de cobalto/selenio.';
      case 'aves':
        return 'Aves: ventilación y densidad adecuada; comunes: Newcastle, IB, '
            'coccidiosis; vacunación según programa avícola.';
      default:
        return 'Ajuste recomendaciones a la especie registrada en el sistema.';
    }
  }

  static String productionLabel(String tipo) {
    switch (normalizeSpecies(tipo)) {
      case 'caprino':
        return 'producción de leche de cabra';
      case 'aves':
        return 'producción de huevos';
      case 'porcino':
        return 'ganancia de peso';
      case 'ovino':
        return 'producción de lana/carne';
      default:
        return 'producción de leche';
    }
  }
}
