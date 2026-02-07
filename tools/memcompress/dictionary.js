/**
 * Compression Dictionary
 * Maps verbose terms to compact equivalents
 */

module.exports = {
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
