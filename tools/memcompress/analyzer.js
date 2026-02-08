/**
 * Token Counter and Analyzer
 * Estimates token count using character-based approximation
 * 
 * @module analyzer
 */

/**
 * Estimate token count (rough approximation)
 * Claude tokenizer: ~4 chars per token
 * @param {string} text - Text to analyze
 * @returns {number} Estimated token count
 */
function estimateTokens(text) {
  return Math.ceil(text.length / 4);
}

/**
 * Calculate compression ratio
 * @param {string} original - Original text
 * @param {string} compressed - Compressed text
 * @returns {number} Compression ratio as percentage (0-100)
 */
function compressionRatio(original, compressed) {
  const origTokens = estimateTokens(original);
  const compTokens = estimateTokens(compressed);
  return Math.round((1 - compTokens / origTokens) * 100);
}

module.exports = {
  estimateTokens,
  compressionRatio
};
