#!/usr/bin/env node
/**
 * Voice Transcription Tool
 * Uses AssemblyAI API to transcribe audio files
 * 
 * Usage: node tools/transcribe.js <audio-file>
 * 
 * Setup:
 * 1. Sign up at https://www.assemblyai.com/dashboard/signup (free tier)
 * 2. Get API key from dashboard
 * 3. Store key:
 *    mkdir -p ~/.config/assemblyai
 *    echo '{"api_key": "YOUR_KEY"}' > ~/.config/assemblyai/config.json
 * 
 * Or set environment variable:
 *    export ASSEMBLYAI_API_KEY='your-key-here'
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Get API key from config or env
function getApiKey() {
  const homeDir = require('os').homedir();
  const configPath = path.join(homeDir, '.config', 'assemblyai', 'config.json');
  
  // Try env var first
  if (process.env.ASSEMBLYAI_API_KEY) {
    return process.env.ASSEMBLYAI_API_KEY;
  }
  
  // Try config file
  if (fs.existsSync(configPath)) {
    try {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      if (config.api_key) return config.api_key;
    } catch (e) {
      console.error('⚠️  Failed to read config:', e.message);
    }
  }
  
  return null;
}

async function transcribe(audioFile) {
  const apiKey = getApiKey();
  
  if (!apiKey) {
    console.error('❌ No API key found!');
    console.error('\nSetup instructions:');
    console.error('1. Sign up: https://www.assemblyai.com/dashboard/signup');
    console.error('2. Get your API key from the dashboard');
    console.error('3. Store it:');
    console.error('   mkdir -p ~/.config/assemblyai');
    console.error('   echo \'{"api_key": "YOUR_KEY"}\' > ~/.config/assemblyai/config.json');
    process.exit(1);
  }
  
  if (!audioFile || !fs.existsSync(audioFile)) {
    console.error('❌ Audio file not found:', audioFile);
    process.exit(1);
  }
  
  console.log('🎤 Transcribing:', path.basename(audioFile));
  console.log('📁 Full path:', audioFile);
  
  // Upload file to AssemblyAI
  console.log('\n📤 Uploading audio...');
  const fileData = fs.readFileSync(audioFile);
  const uploadResponse = await fetch('https://api.assemblyai.com/v2/upload', {
    method: 'POST',
    headers: {
      'authorization': apiKey,
      'content-type': 'application/octet-stream'
    },
    body: fileData
  });
  
  const uploadData = await uploadResponse.json();
  if (!uploadResponse.ok || !uploadData.upload_url) {
    console.error('❌ Upload failed:', uploadData);
    process.exit(1);
  }
  
  console.log('✅ Upload complete');
  
  // Submit transcription request
  console.log('🔄 Submitting transcription...');
  const transcriptResponse = await fetch('https://api.assemblyai.com/v2/transcript', {
    method: 'POST',
    headers: {
      'authorization': apiKey,
      'content-type': 'application/json'
    },
    body: JSON.stringify({
      audio_url: uploadData.upload_url,
      speech_model: 'best'
    })
  });
  
  const transcriptData = await transcriptResponse.json();
  if (!transcriptResponse.ok || !transcriptData.id) {
    console.error('❌ Transcription request failed:', transcriptData);
    process.exit(1);
  }
  
  const transcriptId = transcriptData.id;
  console.log('✅ Transcription started (ID:', transcriptId + ')');
  
  // Poll for completion
  console.log('⏳ Waiting for transcription...');
  let result;
  while (true) {
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    const statusResponse = await fetch(`https://api.assemblyai.com/v2/transcript/${transcriptId}`, {
      headers: { 'authorization': apiKey }
    });
    
    result = await statusResponse.json();
    
    if (result.status === 'completed') {
      break;
    } else if (result.status === 'error') {
      console.error('❌ Transcription failed:', result.error);
      process.exit(1);
    }
    
    process.stdout.write('.');
  }
  
  console.log('\n\n✅ Transcription complete!\n');
  console.log('═══════════════════════════════════════════════════════');
  console.log(result.text);
  console.log('═══════════════════════════════════════════════════════');
  
  // Save to file
  const outputFile = audioFile.replace(/\.(ogg|oga|opus|mp3|m4a|wav)$/, '.txt');
  fs.writeFileSync(outputFile, result.text);
  console.log('\n💾 Saved to:', outputFile);
  
  return result.text;
}

// Run if called directly
if (require.main === module) {
  const audioFile = process.argv[2];
  if (!audioFile) {
    console.error('Usage: node transcribe.js <audio-file>');
    process.exit(1);
  }
  
  transcribe(audioFile).catch(err => {
    console.error('❌ Error:', err.message);
    process.exit(1);
  });
}

module.exports = { transcribe };
