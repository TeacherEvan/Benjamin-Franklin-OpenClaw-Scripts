/**
 * Token Counter
 * Estimates token count using character-based approximation
 */

/**
 * Estimate token count (rough approximation)
 * Claude tokenizer: ~4 chars per token
 */
function estimateTokens(text) {
  return Math.ceil(text.length / 4);
}

/**
 * Calculate compression ratio
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
