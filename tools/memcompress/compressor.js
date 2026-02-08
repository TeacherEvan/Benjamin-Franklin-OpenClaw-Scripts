/**
 * Core Compressor
 * Applies dictionary and pattern transformations for memory compression
 * 
 * @module compressor
 */

const DICT = require('./dictionary');
const PATTERNS = require('./patterns');

class Compressor {
  /**
   * Compress text using dictionary and pattern transformations
   * @param {string} text - Text to compress
   * @returns {string} Compressed text
   */
  static compress(text) {
    let compressed = text;
    
    // Strip markdown headers, keep content
    compressed = compressed
      .replace(/^##+ /gm, '')  // Remove header markers
      .replace(/^\*\*(.+?)\*\*$/gm, '$1:')  // Bold headers to colon
      .replace(/^- /gm, '|')  // List items to pipes
      .replace(/\*\*/g, '');  // Remove bold markers
    
    // Apply regex patterns
    for (const pattern of PATTERNS) {
      if (pattern.preserve) continue;
      if (typeof pattern.replace === 'function') {
        compressed = compressed.replace(pattern.regex, pattern.replace);
      } else {
        compressed = compressed.replace(pattern.regex, pattern.replace);
      }
    }
    
    // Apply dictionary replacements
    for (const [long, short] of Object.entries(DICT)) {
      const regex = new RegExp(`\\b${long}\\b`, 'gi');
      compressed = compressed.replace(regex, short);
    }
    
    // Clean up excessive whitespace
    compressed = compressed
      .replace(/\n\n\n+/g, '\n\n')  // Max 2 newlines
      .replace(/ {2,}/g, ' ')  // Single spaces
      .trim();
    
    return compressed;
  }

  /**
   * Decompress text (reverse transformations)
   * Note: Pattern reversal is lossy - some context may be lost
   * @param {string} text - Compressed text
   * @returns {string} Decompressed text
   */
  static decompress(text) {
    let decompressed = text;
    
    // Reverse dictionary
    for (const [long, short] of Object.entries(DICT)) {
      const regex = new RegExp(`\\b${short}\\b`, 'g');
      decompressed = decompressed.replace(regex, long);
    }
    
    // Note: Pattern reversal is lossy - some context is lost
    // This is acceptable for memory compression use case
    
    return decompressed;
  }
}

module.exports = Compressor;
