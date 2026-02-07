/**
 * Compression Patterns
 * Regex-based transformations for common phrases
 */

module.exports = [
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
