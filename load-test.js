/**
 * load-test.js
 * Multi-device network traffic generator
 * Target: GitHub Codespaces public URL
 *
 * Run on ANY device:  node load-test.js
 * Run heavy mode:     node load-test.js heavy
 * Run stress mode:    node load-test.js stress
 */

const https = require("https");
const http  = require("http");

// ── TARGET URL ────────────────────────────────────────────
const TARGET_HOST = "potential-palm-tree-4j95449wrq62pwx-3001.app.github.dev";
const USE_HTTPS   = true;   // Codespaces uses HTTPS
const PORT        = 443;
// ──────────────────────────────────────────────────────────

// ── Traffic modes ─────────────────────────────────────────
const MODES = {
  light:  { concurrent: 5,  intervalMs: 500,  label: "🟢 Light"  },
  normal: { concurrent: 10, intervalMs: 200,  label: "🟡 Normal" },
  heavy:  { concurrent: 30, intervalMs: 100,  label: "🔴 Heavy"  },
  stress: { concurrent: 50, intervalMs: 50,   label: "🔴🔴 Stress" },
};

const arg  = process.argv[2] || "normal";
const MODE = MODES[arg] || MODES.normal;
// ──────────────────────────────────────────────────────────

let totalSent = 0;
let totalOk   = 0;
let totalErr  = 0;
let totalBytes = 0;

// ── Helper: fire one HTTPS request ───────────────────────
function fireRequest(path, method = "GET", body = null) {
  return new Promise((resolve) => {
    const bodyStr = body ? JSON.stringify(body) : null;

    const options = {
      hostname: TARGET_HOST,
      port:     PORT,
      path,
      method,
      headers: {
        "Content-Type":   "application/json",
        "User-Agent":     "MediQueue-LoadTest/1.0",
        "Cache-Control":  "no-cache",
        ...(bodyStr ? { "Content-Length": Buffer.byteLength(bodyStr) } : {})
      }
    };

    const lib = USE_HTTPS ? https : http;

    const req = lib.request(options, (res) => {
      let size = 0;
      res.on("data", (chunk) => { size += chunk.length; });
      res.on("end", () => {
        totalOk++;
        totalBytes += size;
        resolve();
      });
    });

    req.on("error", () => { totalErr++; resolve(); });
    req.setTimeout(10000, () => { req.destroy(); totalErr++; resolve(); });

    if (bodyStr) req.write(bodyStr);
    req.end();
    totalSent++;
  });
}

// ── Random student data ───────────────────────────────────
const names  = ["Aravindhan","Ravi","Priya","Kumar","Sana","Dev","Anbu","Nisha","Kiran","Divya"];
const rand   = (arr) => arr[Math.floor(Math.random() * arr.length)];
const randNum = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

function randomStudent() {
  return {
    name:       rand(names) + " " + rand(["T","R","K","M","S","V","P"]),
    rollNumber: "R" + randNum(1000, 9999),
    marks:      randNum(40, 100)
  };
}

// ── Routes with weights ───────────────────────────────────
// Higher weight = more frequently hit
const routes = [
  { path: "/",             method: "GET",  body: null,            weight: 5 },
  { path: "/health",       method: "GET",  body: null,            weight: 4 },
  { path: "/api/students", method: "GET",  body: null,            weight: 3 },
  { path: "/metrics",      method: "GET",  body: null,            weight: 2 },
  { path: "/student",      method: "POST", body: "dynamic",       weight: 1 },
];

const routePool = [];
routes.forEach(r => {
  for (let i = 0; i < r.weight; i++) routePool.push(r);
});

function pickRoute() {
  const r = routePool[Math.floor(Math.random() * routePool.length)];
  return {
    path:   r.path,
    method: r.method,
    body:   r.body === "dynamic" ? randomStudent() : r.body
  };
}

// ── Startup banner ────────────────────────────────────────
console.log("╔══════════════════════════════════════════════════╗");
console.log("║     🌐 NETWORK TRAFFIC GENERATOR                ║");
console.log("╠══════════════════════════════════════════════════╣");
console.log(`║  Target : https://${TARGET_HOST.slice(0, 30)}...`);
console.log(`║  Mode   : ${MODE.label}`);
console.log(`║  Load   : ${MODE.concurrent} requests every ${MODE.intervalMs}ms`);
console.log("║  Press  : Ctrl+C to stop                        ║");
console.log("╚══════════════════════════════════════════════════╝\n");

// ── Main traffic loop ─────────────────────────────────────
setInterval(async () => {
  const batch = Array.from({ length: MODE.concurrent }, () => {
    const route = pickRoute();
    return fireRequest(route.path, route.method, route.body);
  });
  await Promise.all(batch);
}, MODE.intervalMs);

// ── Live stats every 5 seconds ────────────────────────────
let elapsed = 0;
setInterval(() => {
  elapsed += 5;
  const rps   = (totalSent / 5).toFixed(1);
  const mbRx  = (totalBytes / 1024 / 1024).toFixed(2);
  const errPct= totalSent > 0 ? ((totalErr / totalSent) * 100).toFixed(1) : "0.0";

  console.log(`[${String(elapsed).padStart(4)}s] 📊 Requests: ${String(totalOk).padStart(5)} OK  |  ${String(totalErr).padStart(4)} Err (${errPct}%)  |  ${String(rps).padStart(6)} req/s  |  ↓ ${mbRx} MB received`);

  // Reset counters for next window
  totalSent  = 0;
  totalOk    = 0;
  totalErr   = 0;
  totalBytes = 0;
}, 5000);
