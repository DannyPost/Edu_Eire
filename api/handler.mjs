/**
 * Studybot HTTP API — single Lambda for API Gateway HTTP API (payload v2.0).
 * Routes: GET|POST /health, POST /chat, POST /grade, POST /exemplar
 *
 * Env:
 *   OPENAI_API_KEY (required for LLM routes)
 *   OPENAI_MODEL (default gpt-4o-mini)
 *   EXEMPLAR_BUCKET (default studybot-knowledge-dev)
 *   AWS_REGION (default eu-west-1)
 *   FIREBASE_SERVICE_ACCOUNT_JSON — optional; if set, verifies Bearer Firebase ID tokens
 */

import { S3Client } from "@aws-sdk/client-s3";
import {
  fetchReadingComprehensionKnowledge,
  buildReadingComprehensionMessages,
  isReadingComprehensionSection,
} from "./reading-comprehension-llm-context.mjs";
import {
  fetchUnseenPoetryKnowledge,
  buildUnseenPoetryMessages,
  isUnseenPoetrySection,
} from "./poetry-llm-context.mjs";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "content-type,authorization,x-api-version,x-client,x-request-id",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
};

let firebaseInitialized = false;

async function maybeVerifyAuth(headers) {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw || raw === "") return;

  if (!firebaseInitialized) {
    const { cert, initializeApp, getApps } = await import("firebase-admin/app");
    if (!getApps().length) {
      initializeApp({ credential: cert(JSON.parse(raw)) });
    }
    firebaseInitialized = true;
  }

  const h = headers.authorization || headers.Authorization;
  if (!h?.startsWith("Bearer ")) {
    const e = new Error("Unauthorized");
    e.statusCode = 401;
    throw e;
  }
  const { getAuth } = await import("firebase-admin/auth");
  await getAuth().verifyIdToken(h.slice(7));
}

function jsonResponse(statusCode, obj) {
  return {
    statusCode,
    headers: { "Content-Type": "application/json", ...CORS },
    body: JSON.stringify(obj),
  };
}

function textResponse(statusCode, text) {
  return {
    statusCode,
    headers: { "Content-Type": "text/plain; charset=utf-8", ...CORS },
    body: text,
  };
}

function normalizePath(event) {
  let p = event.rawPath || event.path || "/";
  const stage = event.requestContext?.stage;
  if (stage && p.startsWith(`/${stage}/`)) {
    p = "/" + p.slice(stage.length + 2);
  } else if (stage && p === `/${stage}`) {
    p = "/";
  }
  const segments = p.split("/").filter(Boolean);
  const last = segments[segments.length - 1] || "";
  const lower = last.toLowerCase();
  if (lower === "health") return "/health";
  if (lower === "chat") return "/chat";
  if (lower === "grade") return "/grade";
  if (lower === "exemplar") return "/exemplar";
  return p;
}

function parseBody(event) {
  if (!event.body) return {};
  const raw = event.isBase64Encoded
    ? Buffer.from(event.body, "base64").toString("utf8")
    : event.body;
  try {
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

function routeChat(message) {
  const m = (message || "").toLowerCase();
  if (/\b(grade|mark|marks|rubric|feedback|correct my)\b/.test(m)) {
    return { type: "grade", confidence: 0.82, routeMeta: {} };
  }
  return { type: "exemplar", confidence: 0.78, routeMeta: {} };
}

async function openaiComplete(messages, { jsonMode = false } = {}) {
  const key = process.env.OPENAI_API_KEY;
  if (!key) {
    const e = new Error("OPENAI_API_KEY is not configured");
    e.statusCode = 503;
    throw e;
  }
  const body = {
    model: process.env.OPENAI_MODEL || "gpt-4o-mini",
    messages,
    temperature: jsonMode ? 0.2 : 0.5,
  };
  if (jsonMode) body.response_format = { type: "json_object" };

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const t = await res.text();
    const e = new Error(`OpenAI error ${res.status}: ${t.slice(0, 500)}`);
    e.statusCode = 502;
    throw e;
  }
  const data = await res.json();
  return data.choices[0]?.message?.content ?? "";
}

function registeredContextLine(meta) {
  const subject = meta.subject || "Unknown subject";
  const paper = meta.paper || "";
  const section = meta.section || "";
  const level = meta.level || "";
  const bits = [subject, paper, section].filter(Boolean).join(" ");
  const lvl = level ? ` (${level})` : "";
  return `Registered context: ${bits}${lvl}. Prefer this framing unless the student message clearly asks for something else.`;
}

function buildGenericMessages(kind, body) {
  const meta = body.meta || {};
  const ctx = registeredContextLine(meta);
  const sys = [
    "You help Irish Leaving Certificate English students.",
    "Use British English (en-GB).",
  ].join(" ");
  if (kind === "exemplar") {
    const u = [
      ctx,
      body.question || "",
      body.stimulus ? `Stimulus:\n${body.stimulus}` : "",
      body.taskPrompt ? `Task:\n${body.taskPrompt}` : "",
    ]
      .filter(Boolean)
      .join("\n\n");
    return [
      { role: "system", content: sys },
      { role: "user", content: u || "No question provided." },
    ];
  }
  const u = [
    ctx,
    "Grade the following student work.",
    body.answer ? `Student answer:\n${body.answer}` : "",
    body.stimulus ? `Stimulus:\n${body.stimulus}` : "",
    body.taskPrompt ? `Task:\n${body.taskPrompt}` : "",
    `Meta: ${JSON.stringify(meta)}`,
  ]
    .filter(Boolean)
    .join("\n\n");
  return [
    { role: "system", content: sys },
    { role: "user", content: u },
  ];
}

async function buildLlmMessages(kind, body) {
  const bucket = process.env.EXEMPLAR_BUCKET || "studybot-knowledge-dev";
  const s3 = new S3Client({ region: process.env.AWS_REGION || "eu-west-1" });
  const meta = body.meta || {};

  if (isReadingComprehensionSection(meta)) {
    const { guide, britishEnglish } = await fetchReadingComprehensionKnowledge(s3, bucket);
    return buildReadingComprehensionMessages({
      guide,
      britishEnglish,
      stimulus: body.stimulus,
      taskPrompt: body.taskPrompt,
      studentQuestion: kind === "exemplar" ? body.question : undefined,
      studentDraft: kind === "grade" ? body.answer : undefined,
    });
  }

  if (isUnseenPoetrySection(meta)) {
    const { guide, britishEnglish } = await fetchUnseenPoetryKnowledge(s3, bucket);
    return buildUnseenPoetryMessages({
      guide,
      britishEnglish,
      stimulus: body.stimulus,
      taskPrompt: body.taskPrompt,
      studentQuestion: kind === "exemplar" ? body.question : undefined,
      studentDraft: kind === "grade" ? body.answer : undefined,
    });
  }

  return buildGenericMessages(kind, body);
}

export async function handler(event) {
  const method = (event.requestContext?.http?.method || event.httpMethod || "GET").toUpperCase();
  const path = normalizePath(event);
  const headers = event.headers || {};

  if (method === "OPTIONS") {
    return { statusCode: 204, headers: { ...CORS }, body: "" };
  }

  try {
    if (path === "/health") {
      return jsonResponse(200, {
        ok: true,
        service: "studybot-api",
        hasOpenAi: Boolean(process.env.OPENAI_API_KEY),
        bucket: process.env.EXEMPLAR_BUCKET || "studybot-knowledge-dev",
      });
    }

    if (path === "/chat" && method === "POST") {
      await maybeVerifyAuth(headers);
      const body = parseBody(event);
      const out = routeChat(body.message);
      return jsonResponse(200, {
        type: out.type,
        confidence: out.confidence,
        routeMeta: out.routeMeta,
      });
    }

    if (path === "/exemplar" && method === "POST") {
      await maybeVerifyAuth(headers);
      const body = parseBody(event);
      const messages = await buildLlmMessages("exemplar", body);
      const text = await openaiComplete(messages, { jsonMode: false });
      return jsonResponse(200, { text, meta: {} });
    }

    if (path === "/grade" && method === "POST") {
      await maybeVerifyAuth(headers);
      const body = parseBody(event);
      const base = await buildLlmMessages("grade", body);
      const messages = [
        ...base,
        {
          role: "user",
          content:
            'Respond with JSON only in this shape: {"score": <integer 0-100>, "bullets": [<string>, ...] } with 2 to 5 short feedback bullets.',
        },
      ];
      const raw = await openaiComplete(messages, { jsonMode: true });
      let score = 0;
      let bullets = [];
      try {
        const j = JSON.parse(raw);
        score = Math.round(Number(j.score)) || 0;
        score = Math.max(0, Math.min(100, score));
        bullets = Array.isArray(j.bullets) ? j.bullets.map((x) => String(x)) : [];
      } catch {
        bullets = [raw.slice(0, 500)];
      }
      return jsonResponse(200, { score, bullets, meta: {} });
    }

    return jsonResponse(404, { error: "not_found", path });
  } catch (err) {
    const code = err.statusCode || 500;
    const msg = err.message || String(err);
    if (code === 401) return jsonResponse(401, { error: "unauthorized" });
    console.error("studybot-api error", msg);
    return jsonResponse(code >= 400 && code < 600 ? code : 500, {
      error: "internal_error",
      message: msg,
    });
  }
}
