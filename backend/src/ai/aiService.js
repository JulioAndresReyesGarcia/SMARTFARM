/**
 * Servicio principal de IA conversacional — orquesta proveedores y fallback local.
 */
const AppError = require('../utils/AppError');
const promptManager = require('./promptManager');
const conversationManager = require('./conversationManager');
const recommendationEngine = require('./recommendationEngine');
const veterinaryAssistant = require('./veterinaryAssistant');

function resolveProvider() {
  const preferred = (process.env.AI_PROVIDER || 'auto').toLowerCase();
  if (preferred === 'gemini' && process.env.GEMINI_API_KEY) return 'gemini';
  if (preferred === 'openai' && process.env.OPENAI_API_KEY) return 'openai';
  if (process.env.OPENAI_API_KEY) return 'openai';
  if (process.env.GEMINI_API_KEY) return 'gemini';
  return null;
}

async function callOpenAi(messages) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) throw new AppError('OPENAI_API_KEY no configurada', 503, 'AI_NOT_CONFIGURED');

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
      temperature: 0.4,
      max_tokens: 900,
      response_format: { type: 'json_object' },
      messages,
    }),
  });

  if (response.status === 429) {
    throw new AppError('Límite de OpenAI alcanzado', 429, 'AI_RATE_LIMIT');
  }
  if (!response.ok) {
    throw new AppError('Error al consultar OpenAI', 502, 'AI_UPSTREAM_ERROR');
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content?.trim();
  if (!content) throw new AppError('Respuesta vacía de OpenAI', 502, 'AI_EMPTY');

  return { parsed: JSON.parse(extractJson(content)), provider: 'openai' };
}

async function callGemini(messages) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new AppError('GEMINI_API_KEY no configurada', 503, 'AI_NOT_CONFIGURED');

  const model = process.env.GEMINI_MODEL || 'gemini-1.5-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  let systemText = null;
  const contents = [];
  for (const m of messages) {
    if (m.role === 'system') {
      systemText = m.content;
      continue;
    }
    contents.push({
      role: m.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: m.content }],
    });
  }

  const payload = {
    ...(systemText ? { systemInstruction: { parts: [{ text: systemText }] } } : {}),
    contents,
    generationConfig: {
      temperature: 0.4,
      maxOutputTokens: 900,
      responseMimeType: 'application/json',
    },
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (response.status === 429) {
    throw new AppError('Límite de Gemini alcanzado', 429, 'AI_RATE_LIMIT');
  }
  if (!response.ok) {
    throw new AppError('Error al consultar Gemini', 502, 'AI_UPSTREAM_ERROR');
  }

  const data = await response.json();
  const parts = data.candidates?.[0]?.content?.parts;
  const text = parts?.[0]?.text?.trim();
  if (!text) throw new AppError('Respuesta vacía de Gemini', 502, 'AI_EMPTY');

  return { parsed: JSON.parse(text), provider: 'gemini' };
}

function extractJson(text) {
  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return text;
  return text.substring(start, end + 1);
}

function mergeCloudWithAnalysis(cloud, analysis) {
  const riskOrder = { bajo: 0, medio: 1, alto: 2, emergencia: 3 };
  const cloudRisk = cloud.riskLevel || 'bajo';
  const localRisk = analysis.riskLevel;
  const effectiveRisk = riskOrder[localRisk] > riskOrder[cloudRisk] ? localRisk : cloudRisk;

  const detected = [...new Set([
    ...(Array.isArray(cloud.detectedSymptoms) ? cloud.detectedSymptoms : []),
    ...analysis.detectedSymptoms,
  ])];

  return {
    summary: cloud.summary || 'Consulta procesada.',
    probableAssessment: cloud.probableAssessment || null,
    detectedSymptoms: detected,
    riskLevel: effectiveRisk,
    recommendations: Array.isArray(cloud.recommendations) ? cloud.recommendations : [],
    prevention: Array.isArray(cloud.prevention) ? cloud.prevention : [],
    whenToSeeVet: cloud.whenToSeeVet || 'Consulte a un veterinario si los síntomas persisten.',
  };
}

async function chat({ animal, message, history }) {
  if (!message || !String(message).trim()) {
    throw new AppError('Mensaje vacío', 400, 'VALIDATION_ERROR');
  }

  const trimmedHistory = conversationManager.trimHistory(history);
  const analysis = recommendationEngine.analyzeSymptoms(message, animal.tipo);
  const knowledgeSnippets = recommendationEngine.knowledgeSnippetsForAnalysis(analysis);

  const provider = resolveProvider();
  let responseBody;

  if (provider) {
    try {
      const messages = promptManager.buildMessages({
        animal,
        message: String(message).trim().slice(0, 2000),
        history: trimmedHistory,
        knowledgeSnippets,
        intent: analysis.intent,
        preAnalysis: {
          riskLevel: analysis.riskLevel,
          detectedSymptoms: analysis.detectedSymptoms,
          possibleConditions: analysis.matches.map((m) => m.name),
        },
      });

      const { parsed, provider: usedProvider } = provider === 'gemini'
        ? await callGemini(messages)
        : await callOpenAi(messages);

      responseBody = {
        ...mergeCloudWithAnalysis(parsed, analysis),
        source: usedProvider,
        intent: analysis.intent,
      };
    } catch (err) {
      if (err instanceof AppError && err.code === 'AI_RATE_LIMIT') throw err;
      responseBody = {
        ...recommendationEngine.buildLocalChatResponse({ animal, message, analysis }),
        intent: analysis.intent,
      };
    }
  } else {
    responseBody = {
      ...recommendationEngine.buildLocalChatResponse({ animal, message, analysis }),
      intent: analysis.intent,
    };
  }

  const veterinarians = veterinaryAssistant.recommendVeterinarians({
    species: animal.tipo,
    riskLevel: responseBody.riskLevel,
    intent: analysis.intent,
  });

  return {
    ...responseBody,
    veterinarians,
    disclaimer: 'Orientación informativa. No sustituye diagnóstico ni tratamiento veterinario profesional.',
    usedCloudAi: responseBody.source === 'openai' || responseBody.source === 'gemini',
  };
}

async function generateRecommendation({ animal, context }) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    return {
      source: 'local-rules',
      recomendacion: recommendationEngine.buildLocalRecommendation(animal, context),
      fecha: new Date().toISOString(),
    };
  }

  const userContent = [
    `Animal: ${JSON.stringify(animal)}`,
    context ? `Consulta/contexto: ${context}` : '',
    'Genera recomendación estructurada breve para ganadero (máx. 200 palabras).',
    'Incluye disclaimer de que no es diagnóstico definitivo.',
  ]
    .filter(Boolean)
    .join('\n');

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
        temperature: 0.35,
        messages: [
          { role: 'system', content: promptManager.RECOMMENDATION_PROMPT },
          { role: 'user', content: userContent },
        ],
        max_tokens: 400,
      }),
    });

    if (!response.ok) throw new AppError('Error al consultar servicio de IA', 502, 'AI_UPSTREAM_ERROR');

    const data = await response.json();
    const text = data.choices?.[0]?.message?.content?.trim() || 'Sin respuesta del modelo';

    return {
      source: 'openai',
      recomendacion: `${text}\n\n(Orientación informativa — consulte a un veterinario para diagnóstico.)`,
      fecha: new Date().toISOString(),
    };
  } catch {
    return {
      source: 'local-rules',
      recomendacion: recommendationEngine.buildLocalRecommendation(animal, context),
      fecha: new Date().toISOString(),
    };
  }
}

module.exports = { chat, generateRecommendation, resolveProvider };
