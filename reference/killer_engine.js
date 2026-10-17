function engineFactory() {
  const POP = new Uint8Array(512), SUM = new Uint8Array(512);
  for (let m = 0; m < 512; m++) {
    let p = 0, s = 0;
    for (let d = 1; d <= 9; d++) if ((m >> (d - 1)) & 1) { p++; s += d; }
    POP[m] = p; SUM[m] = s;
  }
  // ACH[avail*460 + k*46 + s] = 1 if some k-subset of avail sums to s
  const ACH = new Uint8Array(512 * 460);
  for (let a = 0; a < 512; a++) {
    let sub = a;
    while (true) {
      ACH[a * 460 + POP[sub] * 46 + SUM[sub]] = 1;
      if (sub === 0) break;
      sub = (sub - 1) & a;
    }
  }
  const R = [], C = [], B = [];
  for (let i = 0; i < 81; i++) { R[i] = (i / 9) | 0; C[i] = i % 9; B[i] = ((R[i] / 3) | 0) * 3 + ((C[i] / 3) | 0); }
  const NB = [];
  for (let i = 0; i < 81; i++) {
    const n = [];
    if (R[i] > 0) n.push(i - 9);
    if (R[i] < 8) n.push(i + 9);
    if (C[i] > 0) n.push(i - 1);
    if (C[i] < 8) n.push(i + 1);
    NB[i] = n;
  }
  function rng(seed) {
    let a = seed >>> 0;
    return function () {
      a = (a + 0x6D2B79F5) >>> 0;
      let t = a;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  function shuffle(a, rnd) {
    for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); const t = a[i]; a[i] = a[j]; a[j] = t; }
    return a;
  }
  function fullGrid(rnd) {
    const g = new Int8Array(81), rm = new Int16Array(9), cm = new Int16Array(9), bm = new Int16Array(9);
    function rec(i) {
      if (i === 81) return true;
      const ds = shuffle([1, 2, 3, 4, 5, 6, 7, 8, 9], rnd);
      for (const d of ds) {
        const b = 1 << (d - 1);
        if ((rm[R[i]] | cm[C[i]] | bm[B[i]]) & b) continue;
        g[i] = d; rm[R[i]] |= b; cm[C[i]] |= b; bm[B[i]] |= b;
        if (rec(i + 1)) return true;
        g[i] = 0; rm[R[i]] &= ~b; cm[C[i]] &= ~b; bm[B[i]] &= ~b;
      }
      return false;
    }
    rec(0);
    return Array.from(g);
  }
  function makeCages(sol, minS, maxS, rnd) {
    const cageOf = new Array(81).fill(-1);
    const cages = [];
    const order = shuffle([...Array(81).keys()], rnd);
    for (const start of order) {
      if (cageOf[start] >= 0) continue;
      const id = cages.length;
      const target = minS + Math.floor(rnd() * (maxS - minS + 1));
      const cells = [start];
      let used = 1 << (sol[start] - 1);
      cageOf[start] = id;
      while (cells.length < target) {
        const fr = [];
        for (const c of cells) for (const n of NB[c])
          if (cageOf[n] < 0 && !(used & (1 << (sol[n] - 1))) && fr.indexOf(n) < 0) fr.push(n);
        if (!fr.length) break;
        const n = fr[Math.floor(rnd() * fr.length)];
        cells.push(n); cageOf[n] = id; used |= 1 << (sol[n] - 1);
      }
      cages.push({ cells, mask: used });
    }
    for (let id = 0; id < cages.length; id++) {
      const cg = cages[id];
      if (!cg || cg.cells.length !== 1) continue;
      const c = cg.cells[0], b = 1 << (sol[c] - 1);
      const opts = shuffle(NB[c].map(n => cageOf[n]).filter(k => k !== id && cages[k] && !(cages[k].mask & b) && cages[k].cells.length <= maxS), rnd);
      if (opts.length) {
        const k = opts[0];
        cages[k].cells.push(c); cages[k].mask |= b; cageOf[c] = k; cages[id] = null;
      }
    }
    const out = [], map = {};
    cages.forEach((cg, i) => {
      if (cg) {
        map[i] = out.length;
        cg.cells.sort((a, b) => a - b);
        out.push({ cells: cg.cells, sum: cg.cells.reduce((s, c) => s + sol[c], 0) });
      }
    });
    return { cages: out, cageOf: cageOf.map(k => map[k]) };
  }
  const HOUSES = [];
  for (let r = 0; r < 9; r++) HOUSES.push([...Array(9).keys()].map(c => r * 9 + c));
  for (let c = 0; c < 9; c++) HOUSES.push([...Array(9).keys()].map(r => r * 9 + c));
  for (let b = 0; b < 9; b++) { const h = []; for (let i = 0; i < 81; i++) if (B[i] === b) h.push(i); HOUSES.push(h); }
  const COMBOS = [];
  for (let i = 0; i < 460; i++) COMBOS.push([]);
  for (let m = 1; m < 512; m++) COMBOS[POP[m] * 46 + SUM[m]].push(m);
  // full cage consistency: for cage cells `e` with allowed masks `al`, digits used `used`, remaining sum `rs`
  // returns per-cell masks of digits that appear in some valid completion (or null if none)
  function canMatch(al, idx, n, skip, rem) {
    let best = -1, bc = 99;
    for (let j = 0; j < n; j++) {
      if (j === skip || (idx >> j) & 1) continue;
      const c = POP[al[j] & rem];
      if (c === 0) return false;
      if (c < bc) { bc = c; best = j; }
    }
    if (best < 0) return true;
    let a = al[best] & rem;
    const nidx = idx | (1 << best);
    while (a) { const b = a & -a; a ^= b; if (canMatch(al, nidx, n, skip, rem ^ b)) return true; }
    return false;
  }
  function cageMasks(e, al, used, rs) {
    const n = e.length, out = new Int16Array(n);
    if (rs > 45) return null;
    const list = COMBOS[n * 46 + rs];
    let any = false;
    for (const m of list) {
      if (m & used) continue;
      let un = 0, okc = true;
      for (let j = 0; j < n; j++) { const a = al[j] & m; if (!a) { okc = false; break; } un |= a; }
      if (!okc || un !== m) continue;
      for (let j = 0; j < n; j++) {
        let a = al[j] & m & ~out[j];
        while (a) {
          const b = a & -a; a ^= b;
          if (canMatch(al, 0, n, j, m ^ b)) { out[j] |= b; any = true; }
        }
      }
    }
    return any ? out : null;
  }
  function virtualCages(cages, cageOf) {
    const v = [];
    for (let h = 0; h < 27; h++) {
      const H = HOUSES[h], inH = new Set(H);
      let inside = 0; const covered = new Set();
      const ks = new Set(H.map(c => cageOf[c]));
      for (const k of ks) if (cages[k].cells.every(c => inH.has(c))) { inside += cages[k].sum; cages[k].cells.forEach(c => covered.add(c)); }
      const inn = H.filter(c => !covered.has(c));
      if (inn.length >= 1 && inn.length <= 6) v.push({ cells: inn, sum: 45 - inside });
    }
    return v;
  }
  function propagate(cages, cageOf, g) {
    // returns Int16Array masks for empty cells, or null on contradiction
    const rm = new Int16Array(9), cm = new Int16Array(9), bm = new Int16Array(9);
    for (let i = 0; i < 81; i++) if (g[i]) { const b = 1 << (g[i] - 1); rm[R[i]] |= b; cm[C[i]] |= b; bm[B[i]] |= b; }
    const mask = new Int16Array(81);
    for (let i = 0; i < 81; i++) if (!g[i]) { mask[i] = 511 & ~(rm[R[i]] | cm[C[i]] | bm[B[i]]); if (!mask[i]) return null; }
    // iterate cage consistency + naked singles elimination a couple of rounds
    for (let round = 0; round < 3; round++) {
      let changed = false;
      for (let k = 0; k < cages.length; k++) {
        const cells = cages[k].cells;
        let used = 0, rs = cages[k].sum;
        const e = [];
        for (const c of cells) { if (g[c]) { used |= 1 << (g[c] - 1); rs -= g[c]; } else e.push(c); }
        if (!e.length) { if (rs !== 0) return null; continue; }
        if (rs <= 0) return null;
        const al = e.map(c => mask[c] & ~used);
        const res = cageMasks(e, al, used, rs);
        if (!res) return null;
        for (let j = 0; j < e.length; j++) if (res[j] !== mask[e[j]]) { mask[e[j]] = res[j]; changed = true; }
      }
      // hidden singles
      for (let h = 0; h < 27; h++) {
        const H = HOUSES[h];
        let placed = 0;
        for (let j = 0; j < 9; j++) if (g[H[j]]) placed |= 1 << (g[H[j]] - 1);
        for (let d = 1; d <= 9; d++) {
          const b = 1 << (d - 1);
          if (placed & b) continue;
          let n = 0, at = -1;
          for (let j = 0; j < 9; j++) { const x = H[j]; if (!g[x] && (mask[x] & b)) { n++; at = x; } }
          if (n === 0) return null;
          if (n === 1 && mask[at] !== b) { mask[at] = b; changed = true; }
        }
      }
      // naked singles: remove from peers
      for (let h = 0; h < 27; h++) {
        const H = HOUSES[h];
        for (let j = 0; j < 9; j++) {
          const x = H[j];
          if (g[x] || POP[mask[x]] !== 1) continue;
          for (let t = 0; t < 9; t++) { const y = H[t]; if (y !== x && !g[y] && (mask[y] & mask[x])) { mask[y] &= ~mask[x]; if (!mask[y]) return null; changed = true; } }
        }
      }
      if (!changed) break;
    }
    return mask;
  }
  function solve(cages, cageOf, vals, limit, nodeLimit) {
    const g = new Int8Array(81);
    if (vals) for (let i = 0; i < 81; i++) g[i] = vals[i] || 0;
    const allC = cages.concat(virtualCages(cages, cageOf));
    let count = 0, nodes = 0, aborted = false;
    const sols = [];
    function rec() {
      if (++nodes > nodeLimit) { aborted = true; return true; }
      const mask = propagate(allC, cageOf, g);
      if (!mask) return false;
      let best = -1, bc = 0, bn = 10, empty = 0;
      for (let i = 0; i < 81; i++) {
        if (g[i]) continue;
        empty++;
        const n = POP[mask[i]];
        if (n < bn) { bn = n; best = i; bc = mask[i]; }
      }
      if (!empty) { count++; sols.push(Array.from(g)); return count >= limit; }
      if (bn > 1) {
        let hb = 10, hd = 0, hcells = null;
        for (let h = 0; h < 27; h++) {
          const H = HOUSES[h];
          let placed = 0;
          for (let j = 0; j < 9; j++) if (g[H[j]]) placed |= 1 << (g[H[j]] - 1);
          for (let d = 1; d <= 9; d++) {
            const b = 1 << (d - 1);
            if (placed & b) continue;
            let n = 0;
            for (let j = 0; j < 9; j++) { const x = H[j]; if (!g[x] && (mask[x] & b)) n++; }
            if (n === 0) return false;
            if (n < hb) { hb = n; hd = d; hcells = H; }
          }
        }
        if (hb < bn) {
          const b = 1 << (hd - 1);
          for (let j = 0; j < 9; j++) {
            const x = hcells[j];
            if (g[x] || !(mask[x] & b)) continue;
            g[x] = hd;
            if (rec()) { g[x] = 0; return true; }
            g[x] = 0;
          }
          return false;
        }
      }
      for (let d = 1; d <= 9; d++) {
        if (!(bc & (1 << (d - 1)))) continue;
        g[best] = d;
        if (rec()) { g[best] = 0; return true; }
        g[best] = 0;
      }
      return false;
    }
    rec();
    return { count, aborted, nodes, first: sols[0] || null, sols };
  }
  // candidates for every empty cell given current values (houses + cage arithmetic)
  function candidates(cages, cageOf, vals) {
    const rm = new Int16Array(9), cm = new Int16Array(9), bm = new Int16Array(9);
    const nc = cages.length, cu = new Int16Array(nc), cs = new Int16Array(nc), cc = new Int8Array(nc);
    for (let k = 0; k < nc; k++) { cs[k] = cages[k].sum; cc[k] = cages[k].cells.length; }
    for (let i = 0; i < 81; i++) if (vals[i]) {
      const b = 1 << (vals[i] - 1), k = cageOf[i];
      rm[R[i]] |= b; cm[C[i]] |= b; bm[B[i]] |= b; cu[k] |= b; cs[k] -= vals[i]; cc[k]--;
    }
    const out = new Array(81).fill(0), houseMask = new Array(81).fill(0), cageMask = new Array(81).fill(0);
    for (let i = 0; i < 81; i++) {
      if (vals[i]) continue;
      const k = cageOf[i], used = cu[k];
      houseMask[i] = rm[R[i]] | cm[C[i]] | bm[B[i]];
      const avail = 511 & ~used, base = (cc[k] - 1) * 46;
      let cmask = 0;
      for (let d = 1; d <= 9; d++) {
        const b = 1 << (d - 1);
        if (used & b) continue;
        const rs = cs[k] - d;
        if (rs < 0 || cc[k] < 1) continue;
        if (ACH[(avail & ~b) * 460 + base + rs]) cmask |= b;
      }
      cageMask[i] = cmask;
      out[i] = cmask & ~houseMask[i] & 511;
    }
    return { cand: out, houseMask, cageMask };
  }
  function growRegion(region, sol, minS, maxS, rnd, cages, cageOf) {
    // re-cage the given cells (cageOf already -1 for them)
    const inR = new Set(region);
    const order = shuffle(region.slice(), rnd);
    const made = [];
    for (const start of order) {
      if (cageOf[start] >= 0) continue;
      const id = cages.length;
      const target = minS + Math.floor(rnd() * (maxS - minS + 1));
      const cells = [start];
      let used = 1 << (sol[start] - 1);
      cageOf[start] = id;
      while (cells.length < target) {
        const fr = [];
        for (const c of cells) for (const n of NB[c])
          if (inR.has(n) && cageOf[n] < 0 && !(used & (1 << (sol[n] - 1))) && fr.indexOf(n) < 0) fr.push(n);
        if (!fr.length) break;
        const n = fr[Math.floor(rnd() * fr.length)];
        cells.push(n); cageOf[n] = id; used |= 1 << (sol[n] - 1);
      }
      cages.push({ cells, mask: used });
      made.push(id);
    }
    // merge singletons into any neighbouring cage (anywhere) without repeating a digit
    for (const id of made) {
      const cg = cages[id];
      if (!cg || cg.cells.length !== 1) continue;
      const c = cg.cells[0], b = 1 << (sol[c] - 1);
      const opts = shuffle(NB[c].map(n => cageOf[n]).filter(k => k !== id && cages[k] && !(cages[k].mask & b) && cages[k].cells.length < maxS + 1), rnd);
      if (opts.length) { const k = opts[0]; cages[k].cells.push(c); cages[k].mask |= b; cageOf[c] = k; cages[id] = null; }
    }
  }
  function finalize(cages, cageOf, sol) {
    const out = [], map = {};
    cages.forEach((cg, i) => {
      if (cg) {
        map[i] = out.length;
        const cells = cg.cells.slice().sort((a, b) => a - b);
        out.push({ cells, sum: cells.reduce((s, c) => s + sol[c], 0) });
      }
    });
    return { cages: out, cageOf: cageOf.map(k => map[k]) };
  }
  const LV = {
    hard: { min: 2, max: 4, pick: 1, singles: 1 },
    expert: { min: 2, max: 5, pick: 1, singles: 0 },
    devil: { min: 2, max: 6, pick: 1, singles: 0 }
  };
  function generate(level, seed) {
    const rnd = rng(seed), cfg = LV[level] || LV.expert;
    const found = [];
    let tries = 0, solves = 0;
    while (found.length < cfg.pick && tries < 30) {
      tries++;
      const sol = fullGrid(rnd);
      const raw = [], cageOf = new Array(81).fill(-1);
      growRegion([...Array(81).keys()], sol, cfg.min, cfg.max, rnd, raw, cageOf);
      let ok = false, nodes = 0;
      for (let fix = 0; fix < 40; fix++) {
        const P = finalize(raw, cageOf, sol);
        const r = solve(P.cages, P.cageOf, null, 2, 700);
        solves++;
        nodes = r.nodes;
        if (!r.aborted && r.count === 1) {
          const singles = P.cages.filter(c => c.cells.length === 1).length;
          if (singles <= cfg.singles) { ok = true; found.push({ sol, cages: P.cages, cageOf: P.cageOf, nodes }); }
          break;
        }
        // pick a differing cell, dissolve its cage plus one neighbouring cage, regrow
        let x;
        if (r.aborted || r.sols.length < 2) x = Math.floor(rnd() * 81);
        else {
          const [s1, s2] = r.sols;
          const diff = [];
          for (let i = 0; i < 81; i++) if (s1[i] !== s2[i]) diff.push(i);
          x = diff[Math.floor(rnd() * diff.length)];
        }
        const k = cageOf[x];
        const nbK = shuffle([...new Set(raw[k].cells.flatMap(c => NB[c]).map(n => cageOf[n]).filter(q => q !== k))], rnd);
        const region = raw[k].cells.slice();
        raw[k] = null;
        if (nbK.length) { const q = nbK[0]; region.push(...raw[q].cells); raw[q] = null; }
        for (const c of region) cageOf[c] = -1;
        growRegion(region, sol, cfg.min, cfg.max, rnd, raw, cageOf);
      }
    }
    if (!found.length) return null;
    found.sort((a, b) => b.nodes - a.nodes);
    const p = found[0];
    return { level, sol: p.sol, cages: p.cages, cageOf: p.cageOf, nodes: p.nodes, tries, solves };
  }
  return { LV, POP, SUM, R, C, B, NB, HOUSES, COMBOS, rng, generate, solve, candidates };
}
if (typeof module !== 'undefined') module.exports = engineFactory;
