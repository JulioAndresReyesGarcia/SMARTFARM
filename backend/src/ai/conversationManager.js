/**
 * Gestión de historial conversacional (memoria temporal, optimización de tokens).
 */
const MAX_MESSAGES = 12;

function trimHistory(history) {
  if (!Array.isArray(history) || history.length === 0) return [];
  const sanitized = history
    .filter((m) => m && (m.role === 'user' || m.role === 'assistant') && m.content)
    .map((m) => ({
      role: m.role,
      content: String(m.content).trim().slice(0, 2000),
    }))
    .filter((m) => m.content.length > 0);

  if (sanitized.length <= MAX_MESSAGES) return sanitized;
  return sanitized.slice(sanitized.length - MAX_MESSAGES);
}

function buildContextSummary(history) {
  const trimmed = trimHistory(history);
  if (trimmed.length === 0) return '';
  return trimmed
    .map((m) => `${m.role === 'user' ? 'Usuario' : 'Asistente'}: ${m.content}`)
    .join('\n');
}

module.exports = { trimHistory, buildContextSummary, MAX_MESSAGES };
