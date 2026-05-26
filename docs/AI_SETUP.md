# Configuración de IA conversacional — SmartFarm

Guía para activar el asistente ganadero con OpenAI GPT o Google Gemini.

## Proveedor recomendado

**OpenAI GPT-4o-mini** — estable, económico y ya integrado con respuestas JSON estructuradas.

Alternativa: **Google Gemini 1.5 Flash** (similar costo, buena calidad en español).

## Opción A — Cliente Flutter (desarrollo / demo)

Las claves se pasan en tiempo de compilación (no se guardan en el código):

```bash
# OpenAI (recomendado)
flutter run --dart-define=OPENAI_API_KEY=sk-tu-clave-aqui

# Gemini (alternativa)
flutter run --dart-define=GEMINI_API_KEY=tu-clave --dart-define=AI_PROVIDER=gemini

# Modelo personalizado (opcional)
flutter run --dart-define=OPENAI_API_KEY=sk-... --dart-define=OPENAI_MODEL=gpt-4o-mini
```

### Obtener API Key — OpenAI

1. Crear cuenta en [platform.openai.com](https://platform.openai.com)
2. Ir a **API keys** → **Create new secret key**
3. Copiar la clave (solo se muestra una vez)
4. Configurar límite de gasto en **Billing** para evitar sorpresas

### Obtener API Key — Google Gemini

1. Ir a [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Crear API key del proyecto
3. Usar con `--dart-define=GEMINI_API_KEY=...`

## Opción B — Backend (producción recomendada)

Las claves permanecen en el servidor; la app móvil nunca las ve.

```bash
cd backend
cp .env.example .env
# Editar .env:
OPENAI_API_KEY=sk-tu-clave
OPENAI_MODEL=gpt-4o-mini
AI_PROVIDER=auto
```

Iniciar backend y app en modo remoto:

```bash
# Terminal 1 — API
cd backend && npm start

# Terminal 2 — Flutter
flutter run --dart-define=USE_REMOTE_BACKEND=true --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Endpoint de chat: `POST /api/ia/chat` (requiere JWT).

## Variables disponibles

| Variable | Dónde | Descripción |
|----------|-------|-------------|
| `OPENAI_API_KEY` | Flutter / Backend | Clave OpenAI |
| `OPENAI_MODEL` | Flutter / Backend | Modelo (default: gpt-4o-mini) |
| `GEMINI_API_KEY` | Flutter / Backend | Clave Google Gemini |
| `GEMINI_MODEL` | Flutter / Backend | Modelo (default: gemini-1.5-flash) |
| `AI_PROVIDER` | Flutter / Backend | auto, openai, gemini, backend |
| `USE_REMOTE_BACKEND` | Flutter | true = IA vía backend |

## Arquitectura IA

```
Flutter (lib/ai/)
├── config/ai_config.dart          → resuelve proveedor
├── services/
│   ├── openai_chat_provider.dart  → GPT REST
│   ├── gemini_chat_provider.dart  → Gemini REST
│   ├── backend_chat_provider.dart → POST /api/ia/chat
│   ├── conversation_manager.dart  → historial (max 12 msgs)
│   ├── prompt_builder.dart        → system prompt profesional
│   └── livestock_assistant_service.dart → orquestador

Backend (src/ai/)
├── aiService.js           → orquestador principal
├── promptManager.js       → prompts del sistema
├── conversationManager.js → trim historial
├── recommendationEngine.js→ base conocimiento + síntomas
└── veterinaryAssistant.js → sugerencias veterinarios
```

## Flujo conversacional

1. Usuario envía mensaje → se guarda en historial local
2. Se carga contexto del animal (peso, raciones, producción)
3. Se detecta intención y síntomas (motor local)
4. Se envía a OpenAI/Gemini/Backend con historial reciente
5. Respuesta JSON estructurada → UI con riesgo, recomendaciones, vets
6. Si falla API o no hay clave → fallback local con base de conocimiento

## Seguridad

- Nunca commitear `.env` ni claves en el repositorio
- Usar `--dart-define` solo en desarrollo
- En producción: claves solo en backend
- Disclaimer visible: orientación informativa, no diagnóstico
- Validación de entrada (max 2000 caracteres)

## Fallback sin API

Sin clave configurada, el asistente funciona con:
- Base de conocimiento local (`livestock_knowledge.dart`)
- Análisis de síntomas por palabras clave
- Recomendaciones nutricionales (`AiService`)
- Directorio demo de veterinarios

La app **no deja de funcionar** si no hay IA en la nube.

## Costos orientativos (OpenAI gpt-4o-mini)

- ~USD 0.15 / 1M tokens entrada
- ~USD 0.60 / 1M tokens salida
- Una consulta típica: ~500–1500 tokens → fracción de centavo

Consultar precios actuales en [openai.com/pricing](https://openai.com/pricing).
