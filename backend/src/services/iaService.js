/**
 * Fachada legacy — delega al módulo IA modular en src/ai/.
 */
const aiService = require('../ai/aiService');

module.exports = {
  generateRecommendation: aiService.generateRecommendation,
  chat: aiService.chat,
};
