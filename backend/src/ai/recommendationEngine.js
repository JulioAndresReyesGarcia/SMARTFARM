/**
 * Motor de recomendaciones y análisis orientativo (base de conocimiento local).
 */
const KNOWLEDGE = [
  {
    id: 'mastitis',
    name: 'Posible mastitis',
    species: ['bovino', 'caprino'],
    symptoms: ['ubres', 'leche', 'coagulos', 'inflamacion', 'fiebre'],
    careAdvice: 'Ordeñe con higiene, compresas tibias y aislamiento.',
    prevention: 'Higiene en ordeño y camas secas.',
    vetWhen: 'Fiebre, leche con pus o empeora en 24 h.',
  },
  {
    id: 'diarrea',
    name: 'Posible trastorno digestivo',
    species: ['bovino', 'porcino', 'ovino', 'caprino', 'aves'],
    symptoms: ['diarrea', 'heces', 'liquidas', 'deshidrat'],
    careAdvice: 'Agua limpia, electrolitos, dieta blanda temporal.',
    prevention: 'Agua fresca y limpieza de bebederos.',
    vetWhen: 'Diarrea con sangre o más de 24–48 h sin mejoría.',
  },
  {
    id: 'respiratorio',
    name: 'Posible afectación respiratoria',
    species: ['bovino', 'porcino', 'aves', 'ovino'],
    symptoms: ['tos', 'estornud', 'respir', 'nasal', 'moco'],
    careAdvice: 'Mejor ventilación, reducir polvo, aislar al animal.',
    prevention: 'Bioseguridad y vacunación según calendario local.',
    vetWhen: 'Dificultad respiratoria visible o fiebre alta.',
  },
  {
    id: 'emergencia',
    name: 'Posible emergencia veterinaria',
    species: ['bovino', 'porcino', 'aves', 'ovino', 'caprino'],
    symptoms: ['sangre', 'convulsion', 'colapso', 'inconsciente', 'no respira', 'hemorragia'],
    careAdvice: 'Contacte urgencias veterinarias de inmediato. Mantenga al animal seguro y quieto.',
    prevention: 'Protocolos de bioseguridad y revisiones periódicas.',
    vetWhen: 'Atención veterinaria INMEDIATA.',
  },
];

const EMERGENCY_KEYWORDS = ['sangre', 'convulsion', 'colapso', 'inconsciente', 'no respira', 'hemorragia', 'emergencia', 'urgente'];

function normalize(text) {
  return String(text || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
}

function detectIntent(message) {
  const q = normalize(message);
  if (EMERGENCY_KEYWORDS.some((k) => q.includes(k))) return 'emergencia';
  if (/sintoma|fiebre|diarrea|tos|cojera|dolor|enferm/.test(q)) return 'sintomas';
  if (/vacuna|inmuniz/.test(q)) return 'vacunacion';
  if (/aliment|racion|comida|nutric/.test(q)) return 'nutricion';
  if (/produccion|leche|huevo/.test(q)) return 'produccion';
  if (/veterin|doctor|clinica/.test(q)) return 'veterinario';
  return 'general';
}

function analyzeSymptoms(message, species) {
  const q = normalize(message);
  const sp = normalize(species);
  const detectedSymptoms = [];
  const matches = [];

  for (const cond of KNOWLEDGE) {
    const speciesMatch = cond.species.some((s) => sp.includes(s) || s.includes(sp));
    if (!speciesMatch && sp.length > 0) continue;

    const hitSymptoms = cond.symptoms.filter((s) => q.includes(s));
    if (hitSymptoms.length > 0) {
      detectedSymptoms.push(...hitSymptoms);
      matches.push(cond);
    }
  }

  const isEmergency = EMERGENCY_KEYWORDS.some((k) => q.includes(k))
    || matches.some((m) => m.id === 'emergencia');

  let riskLevel = 'bajo';
  if (isEmergency) riskLevel = 'emergencia';
  else if (matches.length >= 2) riskLevel = 'alto';
  else if (matches.length === 1) riskLevel = 'medio';

  return {
    detectedSymptoms: [...new Set(detectedSymptoms)],
    matches,
    riskLevel,
    intent: detectIntent(message),
  };
}

function knowledgeSnippetsForAnalysis(analysis) {
  const snippets = ['Información orientativa. No constituye diagnóstico veterinario.'];
  for (const m of analysis.matches.slice(0, 3)) {
    snippets.push(`${m.name}: ${m.careAdvice} | Prevención: ${m.prevention} | Vet: ${m.vetWhen}`);
  }
  return snippets;
}

function buildLocalChatResponse({ animal, message, analysis }) {
  const risk = analysis.riskLevel;
  const summary = risk === 'emergencia'
    ? `Detectamos signos que podrían requerir atención urgente en ${animal.nombre} (${animal.tipo}). Contacte a un veterinario de inmediato.`
    : `Analicé su consulta sobre ${animal.nombre} (${animal.tipo}, ${animal.peso} kg). Le comparto orientación de manejo.`;

  const recommendations = analysis.matches.slice(0, 2).map((m) => m.careAdvice);
  if (recommendations.length === 0) {
    recommendations.push('Registre apetito, heces y temperatura las próximas 24 h.');
    recommendations.push(`Ajuste ración según peso (${animal.peso} kg) y edad (${animal.edad} meses).`);
  }

  const prevention = analysis.matches.slice(0, 2).map((m) => m.prevention);
  if (prevention.length === 0) prevention.push('Revisiones periódicas y registro de producción.');

  const whenToSeeVet = {
    emergencia: 'Atención veterinaria inmediata.',
    alto: 'Visita veterinaria en las próximas horas.',
    medio: 'Consulte si persiste más de 24–48 h.',
    bajo: 'Control rutinario.',
  }[risk];

  return {
    summary,
    probableAssessment: analysis.matches.length
      ? `Posibles causas orientativas: ${analysis.matches.map((m) => m.name).join('; ')}. Requiere confirmación veterinaria.`
      : null,
    detectedSymptoms: analysis.detectedSymptoms,
    riskLevel: risk,
    recommendations,
    prevention,
    whenToSeeVet,
    source: 'local-rules',
  };
}

function buildLocalRecommendation(animal, context) {
  const lines = [
    `Revisión orientativa para ${animal.nombre} (${animal.tipo}, ${animal.peso} kg).`,
    'Verificar apetito, hidratación, heces y temperatura en las próximas 24 h.',
    `Ajustar ración según peso (${animal.peso} kg) y edad (${animal.edad} meses).`,
  ];
  if (context) lines.push(`Contexto: ${context}`);
  lines.push('Si hay fiebre, letargo severo o no come >24 h, contacte a un veterinario.');
  lines.push('(Orientación informativa — no sustituye diagnóstico profesional.)');
  return lines.join('\n');
}

module.exports = {
  analyzeSymptoms,
  knowledgeSnippetsForAnalysis,
  buildLocalChatResponse,
  buildLocalRecommendation,
  detectIntent,
};
