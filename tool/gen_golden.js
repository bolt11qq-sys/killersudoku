// Generates JS reference fixtures for the Dart engine port (TZ §4.3).
// Usage: node tool/gen_golden.js > test/engine/fixtures/js_golden.json
const E = require('../reference/killer_engine.js')();
// Levels the web version does not have; same shape as the Dart config.
E.LV.easy = { min: 2, max: 3, pick: 1, singles: 1 };
E.LV.medium = { min: 2, max: 3, pick: 1, singles: 1 };

const reseed = s => (s * 1103515245 + 12345) >>> 0;

const out = { rng: [], reseed: [], generate: [], retry: [], candidates: [], solve: [] };

for (const seed of [0, 1, 42, 20261017, 4294967295]) {
  const r = E.rng(seed);
  out.rng.push({ seed, values: Array.from({ length: 8 }, () => r()) });
}
for (const s of [0, 1, 12345, 2147483647, 4294967295, 3000000000]) out.reseed.push({ s, next: reseed(s) });

for (const level of ['easy', 'medium', 'hard', 'expert', 'devil']) {
  for (let seed = 1; seed <= 20; seed++) {
    const p = E.generate(level, seed);
    out.generate.push(p ? { level, seed, sol: p.sol, cages: p.cages, cageOf: p.cageOf, nodes: p.nodes, tries: p.tries, solves: p.solves } : { level, seed, none: true });
  }
  // worker loop from killer-sudoku.html: up to 6 seeds
  for (const seed of [7, 99]) {
    let p = null, s = seed, attempts = 0;
    for (let t = 0; t < 6 && !p; t++) { attempts++; p = E.generate(level, s); s = reseed(s); }
    out.retry.push({ level, seed, attempts, sol: p && p.sol });
  }
}

// candidates + solver on partially filled boards
for (const g of out.generate.filter(g => !g.none && g.seed <= 3)) {
  const vals = g.sol.map((v, i) => (i * 7 + g.seed) % 3 === 0 ? v : 0);
  const c = E.candidates(g.cages, g.cageOf, vals);
  out.candidates.push({ level: g.level, seed: g.seed, vals, cand: c.cand, houseMask: c.houseMask, cageMask: c.cageMask });
  const r = E.solve(g.cages, g.cageOf, null, 2, 100000);
  out.solve.push({ level: g.level, seed: g.seed, count: r.count, nodes: r.nodes, aborted: r.aborted });
}
process.stdout.write(JSON.stringify(out));
