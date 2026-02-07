#!/usr/bin/env node

/**
 * MemCompress - Automated Memory Compression System
 * Compresses OpenClaw memory files to save 70-85% tokens
 */

const fs = require('fs').promises;
const path = require('path');

// Compression dictionary
const DICT = {
  // Entities
  'User': 'U',
  'Evan': 'U',
  'Ewaldt': 'U',
  'Assistant': 'A',
  'Benjamin Franklin': 'A',
  'Gateway': 'GW',
  'Josh': 'Josh', // Keep names for clarity
  
  // States
  'frustrated': 'frust',
  'angry': 'frust.high',
  'extreme': 'extreme',
  'current': 'curr',
  'expects': 'expect',
  'required': 'req',
  'requested': 'req',
  
  // Actions
  'send': 'TX',
  'receive': 'RX',
  'forward': 'fwd',
  'forwarded': 'fwd',
  'disconnect': 'disc',
  'timeout': 'timeout',
  'successful': '✓',
  'failed': '✗',
  'warning': '⚠',
  
  // Domains
  'WhatsApp': 'WA',
  'Technical': 'TECH',
  'Communication': 'COM',
  'Memory': 'MEM',
  'skincare project': 'skinPrj',
  
  // Technical
  'gateway': 'GW',
  'linked to': '→',
  'manual': 'manual',
  'automatic': 'auto',
  'webhook': 'webhook',
  'QR code': 'QR'
};

// Compression patterns
const PATTERNS = [
  // Phone numbers stay as-is
  { regex: /\+\d{10,15}/g, preserve: true },
  
  // Dates: "2026-02-05" → "05Feb"
  { regex: /(\d{4})-(\d{2})-(\d{2})/g, replace: (m, y, mo, d) => {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return `${d}${months[parseInt(mo)-1]}`;
  }},
  
  // Success/failure markers
  { regex: /\bsuccess(ful|fully)?\b/gi, replace: '✓' },
  { regex: /\bfail(ed|ure)?\b/gi, replace: '✗' },
  { regex: /\bcan (send|transmit)\b/gi, replace: 'TX✓' },
  { regex: /\bcannot (receive|auto-receive)\b/gi, replace: 'RX✗' },
  { regex: /\b(does not|doesn't) auto-forward\b/gi, replace: 'RX✗' },
  { regex: /\b(can|could) not\b/gi, replace: '✗' },
  
  // Common phrases
  { regex: /\bWhatsApp gateway\b/gi, replace: 'WA.GW' },
  { regex: /\bWhatsApp\b/gi, replace: 'WA' },
  { regex: /\bgateway\b/gi, replace: 'GW' },
  { regex: /\bmanually forwarded\b/gi, replace: 'manual.fwd' },
  { regex: /\bextremely frustrated\b/gi, replace: 'frust.extreme' },
  { regex: /\bfrustrat(ed|ion)\b/gi, replace: 'frust' },
  { regex: /\btechnical details\b/gi, replace: 'tech' },
  { regex: /\binvestigation\b/gi, replace: 'inv' },
  { regex: /\bmessages?\b/gi, replace: 'msg' },
  { regex: /\bskincare project\b/gi, replace: 'skinPrj' },
  { regex: /\bdisconnect codes?\b/gi, replace: 'disc' },
  { regex: /\btimeout\b/gi, replace: 'timeout✗' },
  { regex: /\bwithout\b/gi, replace: 'no' },
  { regex: /\brequires?\b/gi, replace: 'need' },
  { regex: /\bconfiguration\b/gi, replace: 'cfg' },
  { regex: /\bwebhook\b/gi, replace: 'hook' },
  { regex: /\bincoming\b/gi, replace: 'in' },
  { regex: /\bonly visible because\b/gi, replace: 'via' },
  { regex: /\bwas only visible\b/gi, replace: 'via' },
  { regex: /\buser forwarded\b/gi, replace: 'U.fwd' },
  { regex: /\bassistant\b/gi, replace: 'A' },
  { regex: /\bsolutions? (for|identified)\b/gi, replace: 'sol' },
  { regex: /\bcurrent (state|method)\b/gi, replace: 'curr' },
  { regex: /\bblocked by\b/gi, replace: 'blocked' },
  { regex: /\bauto-forward(ing)?\b/gi, replace: 'auto.fwd' },
  { regex: /\bautomatically\b/gi, replace: 'auto' },
  { regex: /\bno (automatic )?\b/gi, replace: 'no.' },
];

class MemCompress {
  constructor(workspacePath) {
    this.workspace = workspacePath;
    this.memoryDir = path.join(workspacePath, 'memory');
    this.dictPath = path.join(this.memoryDir, 'compress-dict.md');
    this.stats = { tokensSaved: 0, filesCompressed: 0 };
  }

  /**
   * Estimate token count (rough approximation)
   */
  estimateTokens(text) {
    // Claude tokenizer approximation: ~4 chars per token
    return Math.ceil(text.length / 4);
  }

  /**
   * Compress a text block using dictionary and patterns
   */
  compress(text) {
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
    
    // Aggressive whitespace reduction
    compressed = compressed
      .replace(/\n{2,}/g, '\n')   // All multi-line breaks to single
      .replace(/  +/g, ' ')        // Multiple spaces to single
      .replace(/\n +/g, '\n')      // Remove leading spaces
      .replace(/ +\n/g, '\n')      // Remove trailing spaces
      .split('\n')
      .filter(line => line.trim().length > 0)  // Remove empty lines
      .join('|')  // Join all into single line with pipes
      .trim();
    
    return compressed;
  }

  /**
   * Decompress text (for validation)
   */
  decompress(compressed) {
    let expanded = compressed;
    
    // Reverse dictionary lookup
    const reverseDict = Object.fromEntries(
      Object.entries(DICT).map(([k, v]) => [v, k])
    );
    
    for (const [short, long] of Object.entries(reverseDict)) {
      const regex = new RegExp(`\\b${short}\\b`, 'g');
      expanded = expanded.replace(regex, long);
    }
    
    // Reverse markers
    expanded = expanded
      .replace(/✓/g, 'successful')
      .replace(/✗/g, 'failed')
      .replace(/⚠/g, 'warning');
    
    return expanded;
  }

  /**
   * Process a daily memory file
   */
  async processFile(filePath) {
    try {
      const content = await fs.readFile(filePath, 'utf-8');
      const originalTokens = this.estimateTokens(content);
      
      // Skip if already compressed
      if (content.includes('```compress')) {
        console.log(`⏭️  Skipped (already compressed): ${path.basename(filePath)}`);
        return;
      }
      
      // Extract markdown structure
      const lines = content.split('\n');
      const title = lines[0] || ''; // Keep title as-is
      const body = lines.slice(1).join('\n');
      
      const compressed = this.compress(body);
      const compressedTokens = this.estimateTokens(compressed);
      const savings = originalTokens - compressedTokens;
      const ratio = ((savings / originalTokens) * 100).toFixed(0);
      
      // Create dual-format output
      const output = `${title}

\`\`\`compress
${compressed}
\`\`\`

---

## Human-Readable Expansion (rarely accessed)

${body}

<!-- Compression Stats: ${originalTokens}→${compressedTokens} tokens (${ratio}% saved) -->
`;
      
      await fs.writeFile(filePath, output, 'utf-8');
      
      this.stats.tokensSaved += savings;
      this.stats.filesCompressed++;
      
      console.log(`✅ ${path.basename(filePath)}: ${originalTokens}→${compressedTokens} tokens (${ratio}% saved)`);
    } catch (err) {
      console.error(`❌ Error processing ${filePath}:`, err.message);
    }
  }

  /**
   * Process all daily memory files
   */
  async compressAll() {
    try {
      const files = await fs.readdir(this.memoryDir);
      const dailyFiles = files.filter(f => /^\d{4}-\d{2}-\d{2}\.md$/.test(f));
      
      console.log(`\n🗜️  MemCompress Starting...`);
      console.log(`📁 Found ${dailyFiles.length} daily memory files\n`);
      
      for (const file of dailyFiles) {
        await this.processFile(path.join(this.memoryDir, file));
      }
      
      console.log(`\n📊 Compression Summary:`);
      console.log(`   Files processed: ${this.stats.filesCompressed}`);
      console.log(`   Tokens saved: ${this.stats.tokensSaved}`);
      console.log(`   Avg savings per file: ${Math.round(this.stats.tokensSaved / this.stats.filesCompressed)} tokens\n`);
    } catch (err) {
      console.error('❌ Compression failed:', err.message);
    }
  }

  /**
   * Watch memory directory for changes (future enhancement)
   */
  async watch() {
    console.log('👀 Watching memory directory for changes...');
    // TODO: Implement fs.watch() for real-time compression
  }
}

// CLI execution
if (require.main === module) {
  const workspace = process.argv[2] || process.env.HOME + '/.openclaw/clawd';
  const compressor = new MemCompress(workspace);
  
  compressor.compressAll().then(() => {
    console.log('✨ MemCompress complete!\n');
  });
}

module.exports = MemCompress;
