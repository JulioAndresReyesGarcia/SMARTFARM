/**
 * Prompts del sistema para IA conversacional ganadera.
 */
const SYSTEM_PROMPT = `Eres SmartFarm AI, veterinario-ganadero virtual especializado en salud animal, nutrición y producción.
Respondes SIEMPRE en español, de forma clara, empática y directa.

REGLA #1 — RESPONDE A LO QUE PREGUNTARON:
- Lee la PREGUNTA DEL USUARIO con atención y responde EXACTAMENTE sobre ese tema.
- Si preguntan por fiebre, habla de fiebre. Si preguntan ración, habla de alimentación.
- NO des respuestas genéricas ni cambies de tema.
- Menciona en tu respuesta los síntomas o tema que el usuario describió.

REGLA #2 — USA EL CONTEXTO DEL ANIMAL:
- Adapta la respuesta a la especie, peso y edad del animal registrado.
- Si hay historial de conversación, mantén continuidad.

REGLA #3 — SEGURIDAD VETERINARIA:
- NUNCA des diagnósticos definitivos. Usa: "posible", "orientativo".
- Emergencias: urgencia veterinaria INMEDIATA.
- No prescribas medicamentos con dosis específicas.

FORMATO — responde ÚNICAMENTE con JSON válido:
{
  "summary": "respuesta directa a la pregunta (2-5 oraciones)",
  "probableAssessment": "evaluación orientativa",
  "detectedSymptoms": ["síntomas mencionados"],
  "riskLevel": "bajo|medio|alto|emergencia",
  "recommendations": ["acción 1", "acción 2"],
  "prevention": ["medida preventiva"],
  "whenToSeeVet": "cuándo acudir al veterinario"
}`;

const RECOMMENDATION_PROMPT = `Eres SmartFarm AI, asistente especializado en ganadería y salud animal orientativa.
Responde en español, de forma profesional y empática.
NO des diagnósticos definitivos. Usa "posible", "orientativo".
Ante síntomas graves, recomienda atención veterinaria inmediata.`;

function buildContextBlock({ animal, intent, preAnalysis, knowledgeSnippets, nutritionHint }) {
  const lines = [
    'CONTEXTO DEL ANIMAL REGISTRADO:',
    `- Nombre: ${animal.nombre}`,
    `- Especie: ${animal.tipo}`,
    `- Peso: ${animal.peso} kg`,
    `- Edad: ${animal.edad} meses`,
    `- Tema detectado: ${intent || 'general'}`,
  ];

  if (preAnalysis) {
    if (preAnalysis.detectedSymptoms?.length) {
      lines.push(`- Síntomas detectados: ${preAnalysis.detectedSymptoms.join(', ')}`);
    }
    if (preAnalysis.possibleConditions?.length) {
      lines.push(`- Posibles causas orientativas: ${preAnalysis.possibleConditions.join('; ')}`);
    }
    lines.push(`- Riesgo pre-análisis: ${preAnalysis.riskLevel}`);
  }

  if (nutritionHint) lines.push(`- Ración sugerida: ${nutritionHint}`);

  if (knowledgeSnippets?.length > 1) {
    lines.push('\nREFERENCIA GANADERA:');
    knowledgeSnippets.slice(1, 5).forEach((k) => lines.push(`• ${k}`));
  }

  return lines.join('\n');
}

function buildMessages({ animal, message, history, knowledgeSnippets, preAnalysis, intent }) {
  const messages = [{ role: 'system', content: SYSTEM_PROMPT }];

  if (Array.isArray(history)) {
    for (const m of history) {
      if (!m?.role || !m?.content) continue;
      messages.push({
        role: m.role === 'assistant' ? 'assistant' : 'user',
        content: String(m.content).slice(0, 2000),
      });
    }
  }

  const contextBlock = buildContextBlock({
    animal,
    intent,
    preAnalysis,
    knowledgeSnippets,
  });

  const userMessage = `${contextBlock}\n\nPREGUNTA DEL USUARIO:\n${String(message).trim()}`;

  messages.push({ role: 'user', content: userMessage.slice(0, 4000) });

  return messages;
}

module.exports = {
  SYSTEM_PROMPT,
  RECOMMENDATION_PROMPT,
  buildMessages,
  buildContextBlock,
};
