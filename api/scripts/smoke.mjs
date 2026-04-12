#!/usr/bin/env node
/**
 * Quick connectivity check. Usage:
 *   API_BASE_URL=https://xxx.execute-api.../dev node api/scripts/smoke.mjs
 * Optional: FIREBASE_BEARER=eyJ... for authenticated routes
 */
const base = (process.env.API_BASE_URL || "").replace(/\/$/, "");
if (!base) {
  console.error("Set API_BASE_URL to your API Gateway stage URL (no trailing slash).");
  process.exit(1);
}

const auth = process.env.FIREBASE_BEARER;
const headers = { "Content-Type": "application/json" };
if (auth) headers.Authorization = `Bearer ${auth}`;

const healthUrl = `${base}/health`;
const r = await fetch(healthUrl);
console.log("GET", healthUrl, "->", r.status, await r.text());

if (auth) {
  const chat = await fetch(`${base}/chat`, {
    method: "POST",
    headers,
    body: JSON.stringify({ message: "Give me feedback on my answer", meta: { section: "Reading comprehension" } }),
  });
  console.log("POST /chat ->", chat.status, await chat.text());
}
