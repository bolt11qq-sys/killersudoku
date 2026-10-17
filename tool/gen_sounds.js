// Synthesises the app's short UI sounds as 16-bit mono WAV files, so no
// third-party audio is bundled. Usage: node tool/gen_sounds.js
const fs = require('fs');
const path = require('path');

const RATE = 44100;
const out = path.join(__dirname, '..', 'assets', 'sounds');
fs.mkdirSync(out, { recursive: true });

// tones: [freqHz, startSec, durSec, gain]; soft attack, exponential decay.
function render(tones, total) {
  const n = Math.round(total * RATE);
  const buf = new Float32Array(n);
  for (const [f, start, dur, gain] of tones) {
    const s0 = Math.round(start * RATE), len = Math.round(dur * RATE);
    for (let i = 0; i < len && s0 + i < n; i++) {
      const t = i / RATE;
      const attack = Math.min(1, t / 0.004);
      const decay = Math.exp((-5 * t) / dur);
      // Fundamental plus a quiet octave for a rounder, marimba-like tone.
      const v = Math.sin(2 * Math.PI * f * t) + 0.25 * Math.sin(4 * Math.PI * f * t);
      buf[s0 + i] += gain * attack * decay * v;
    }
  }
  return buf;
}

function wav(samples) {
  const data = Buffer.alloc(samples.length * 2);
  for (let i = 0; i < samples.length; i++) {
    const v = Math.max(-1, Math.min(1, samples[i]));
    data.writeInt16LE(Math.round(v * 32767), i * 2);
  }
  const h = Buffer.alloc(44);
  h.write('RIFF', 0); h.writeUInt32LE(36 + data.length, 4); h.write('WAVE', 8);
  h.write('fmt ', 12); h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22);
  h.writeUInt32LE(RATE, 24); h.writeUInt32LE(RATE * 2, 28); h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34);
  h.write('data', 36); h.writeUInt32LE(data.length, 40);
  return Buffer.concat([h, data]);
}

const sounds = {
  // Short soft click for placing a digit.
  tap: render([[880, 0, 0.06, 0.25]], 0.08),
  // Two low descending notes for a mistake.
  mistake: render([[311, 0, 0.12, 0.35], [233, 0.09, 0.18, 0.35]], 0.3),
  // Rising pair when a row / column / block / cage is completed.
  unit: render([[659, 0, 0.12, 0.3], [988, 0.07, 0.2, 0.3]], 0.3),
  // C major arpeggio for a win.
  win: render([
    [523, 0, 0.25, 0.3], [659, 0.12, 0.25, 0.3], [784, 0.24, 0.3, 0.3], [1047, 0.38, 0.6, 0.3],
  ], 1.0),
};
for (const [name, s] of Object.entries(sounds)) {
  fs.writeFileSync(path.join(out, `${name}.wav`), wav(s));
  console.log(`${name}.wav ${(s.length / RATE).toFixed(2)}s`);
}
