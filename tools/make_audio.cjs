// Deterministic, original placeholder audio. No downloads or external dependencies.
const fs = require('fs');
const rate = 22050;
let seed = 811;
function noise() { seed = (1664525 * seed + 1013904223) >>> 0; return seed / 2147483648 - 1; }
function tone(t, f) { return Math.sin(2 * Math.PI * t * f); }
function write(name, seconds, fn) {
  const count = Math.floor(rate * seconds), b = Buffer.alloc(44 + count * 2);
  b.write('RIFF'); b.writeUInt32LE(36 + count * 2, 4); b.write('WAVE', 8);
  b.write('fmt ', 12); b.writeUInt32LE(16, 16); b.writeUInt16LE(1, 20); b.writeUInt16LE(1, 22);
  b.writeUInt32LE(rate, 24); b.writeUInt32LE(rate * 2, 28); b.writeUInt16LE(2, 32); b.writeUInt16LE(16, 34);
  b.write('data', 36); b.writeUInt32LE(count * 2, 40);
  for (let i = 0; i < count; i++) b.writeInt16LE(Math.round(Math.max(-1, Math.min(1, fn(i / rate))) * 24000), 44 + i * 2);
  fs.writeFileSync(`assets/audio/${name}.wav`, b);
}
write('bell', 2.5, t => (tone(t, 880) + 0.43 * tone(t, 1327) + 0.2 * tone(t, 2310)) * Math.exp(-3 * t) * 0.5);
write('step', 0.22, t => (noise() * 0.6 + tone(t, 83) * 0.4) * Math.exp(-28 * t));
write('knock', 0.85, t => { const p = t % 0.27; return (noise() * 0.25 + tone(p, 130) * 0.7) * Math.exp(-38 * p); });
write('water', 1.3, t => noise() * 0.25 * (0.6 + tone(t, 9) * 0.2) * Math.sin(Math.PI * t / 1.3));
write('fail', 1.4, t => (tone(t, 70 - t * 9) + noise() * 0.25) * Math.exp(-2.5 * t) * 0.6);
write('success', 1.4, t => (tone(t, 440) + tone(t, 660) * 0.5) * Math.exp(-3 * t) * 0.4);
write('hum', 6, t => (tone(t, 50) * 0.3 + tone(t, 100) * 0.15 + tone(t, 151) * 0.05) * (0.8 + tone(t, 0.5) * 0.15));
console.log('Generated 7 original placeholder WAVs.');
