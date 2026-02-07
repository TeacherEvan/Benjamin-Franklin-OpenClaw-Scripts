#!/usr/bin/env node

/**
 * MemCompress - Automated Memory Compression System
 * Refactored modular version
 */

const fs = require('fs').promises;
const path = require('path');
const Compressor = require('./memcompress/compressor');
const { estimateTokens, compressionRatio } = require('./memcompress/analyzer');

const WORKSPACE = process.env.OPENCLAW_WORKSPACE || '/home/ubuntu/.openclaw/clawd';
const MEMORY_DIR = path.join(WORKSPACE, 'memory');

async function compressFile(filePath) {
  try {
    const content = await fs.readFile(filePath, 'utf8');
    
    // Skip already compressed files
    if (content.includes('<!-- COMPRESSED -->')) {
      return null;
    }
    
    const originalTokens = estimateTokens(content);
    const compressed = Compressor.compress(content);
    const compressedTokens = estimateTokens(compressed);
    const savedPercentage = compressionRatio(content, compressed);
    
    // Add compression marker
    const output = `<!-- COMPRESSED -->\n${compressed}`;
    
    await fs.writeFile(filePath, output, 'utf8');
    
    return {
      file: path.basename(filePath),
      originalTokens,
      compressedTokens,
      saved: originalTokens - compressedTokens,
      percentage: savedPercentage
    };
  } catch (error) {
    console.error(`Error compressing ${filePath}:`, error.message);
    return null;
  }
}

async function main() {
  try {
    // Find all daily memory files
    const files = await fs.readdir(MEMORY_DIR);
    const dailyFiles = files
      .filter(f => /^\d{4}-\d{2}-\d{2}\.md$/.test(f))
      .map(f => path.join(MEMORY_DIR, f));
    
    const results = [];
    
    for (const file of dailyFiles) {
      const result = await compressFile(file);
      if (result) {
        console.log(`✅ ${result.file}: ${result.originalTokens}→${result.compressedTokens} tokens (${result.percentage}% saved)`);
        results.push(result);
      }
    }
    
    if (results.length === 0) {
      console.log('ℹ️  No uncompressed files found.');
      return;
    }
    
    // Summary
    const totalSaved = results.reduce((sum, r) => sum + r.saved, 0);
    const avgSaved = Math.round(totalSaved / results.length);
    
    console.log('');
    console.log('📊 Compression Summary:');
    console.log(`   Files processed: ${results.length}`);
    console.log(`   Tokens saved: ${totalSaved}`);
    console.log(`   Avg savings per file: ${avgSaved} tokens`);
    console.log('');
    console.log('✨ MemCompress complete!');
    
  } catch (error) {
    console.error('Fatal error:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { compressFile, Compressor };
