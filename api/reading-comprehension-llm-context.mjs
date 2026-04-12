/**
 * Keep in sync with [../lambda/reading-comprehension-llm-context.mjs](../lambda/reading-comprehension-llm-context.mjs).
 * Copied into api/ for Lambda deployment bundles.
 */

import { readFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";
import { GetObjectCommand } from "@aws-sdk/client-s3";

const __dirname = dirname(fileURLToPath(import.meta.url));

export const META_SECTION_READING_COMPREHENSION = "Reading comprehension";

const DEFAULT_GUIDE_KEY =
  "english/hl/paper1/reading-comprehension/hl-reading-comprehension-llm-guide.md";
const DEFAULT_BRITISH_KEY =
  "english/hl/paper1/reading-comprehension/llm-british-english-convention.md";

export const READING_COMPREHENSION_S3_KEYS = Object.freeze({
  guide: DEFAULT_GUIDE_KEY,
  britishEnglish: DEFAULT_BRITISH_KEY,
});

export function loadReadingComprehensionS3KeysFromManifest(
  manifestPath = join(__dirname, "data", "reading-comprehension-exemplars-manifest.json")
) {
  try {
    const raw = readFileSync(manifestPath, "utf8");
    const j = JSON.parse(raw);
    return {
      guideKey: j.s3GuideKey || DEFAULT_GUIDE_KEY,
      britishEnglishKey: j.s3BritishEnglishConventionKey || DEFAULT_BRITISH_KEY,
      manifestKey: j.s3ManifestKey,
    };
  } catch {
    return {
      guideKey: DEFAULT_GUIDE_KEY,
      britishEnglishKey: DEFAULT_BRITISH_KEY,
    };
  }
}

async function bodyToUtf8(body) {
  if (!body) return "";
  const chunks = [];
  for await (const c of body) chunks.push(c);
  return Buffer.concat(chunks).toString("utf8");
}

export async function fetchReadingComprehensionKnowledge(s3Client, bucket, keys = loadReadingComprehensionS3KeysFromManifest()) {
  const guideKey = keys.guideKey || READING_COMPREHENSION_S3_KEYS.guide;
  const britishKey = keys.britishEnglishKey || READING_COMPREHENSION_S3_KEYS.britishEnglish;

  const [g1, g2] = await Promise.all([
    s3Client.send(new GetObjectCommand({ Bucket: bucket, Key: guideKey })),
    s3Client.send(new GetObjectCommand({ Bucket: bucket, Key: britishKey })),
  ]);

  const guide = await bodyToUtf8(g1.Body);
  const britishEnglish = await bodyToUtf8(g2.Body);
  return { guide, britishEnglish, guideKey, britishEnglishKey: britishKey };
}

export function isReadingComprehensionSection(meta) {
  if (!meta || typeof meta !== "object") return false;
  const s = meta.section;
  return typeof s === "string" && s === META_SECTION_READING_COMPREHENSION;
}

export function defaultReadingComprehensionSystemPrompt() {
  return [
    "You coach Irish Leaving Certificate English students.",
    "Use British English (en-GB) and LC terminology.",
    "Do not invent official marking schemes; align with the exam paper text the student provided.",
    "For Paper 1 Section I: treat Question A (Text A) as comprehension-style coaching; Question B (Text B) as functional writing, not a list of short answers.",
  ].join(" ");
}

export function buildReadingComprehensionUserMessages(p) {
  const knowledge = [
    "# HL reading comprehension — teaching guide",
    p.guide?.trim() || "",
    "",
    "# British English convention",
    p.britishEnglish?.trim() || "",
  ].join("\n");

  const taskParts = [];
  if (p.stimulus?.trim()) {
    taskParts.push("## Stimulus (passage)\n\n" + p.stimulus.trim());
  }
  if (p.taskPrompt?.trim()) {
    taskParts.push("## Exam questions / instructions\n\n" + p.taskPrompt.trim());
  }
  if (p.studentQuestion?.trim()) {
    taskParts.push("## Student request (question or focus)\n\n" + p.studentQuestion.trim());
  }
  if (p.studentDraft?.trim()) {
    taskParts.push("## Student draft to review\n\n" + p.studentDraft.trim());
  }

  const task = taskParts.length
    ? taskParts.join("\n\n---\n\n")
    : "(No stimulus or task text was supplied; ask the student to paste the passage and questions.)";

  return [
    { role: "user", content: knowledge },
    { role: "user", content: task },
  ];
}

export function buildReadingComprehensionMessages(p) {
  const system = p.systemPrompt?.trim() || defaultReadingComprehensionSystemPrompt();
  const users = buildReadingComprehensionUserMessages(p);
  return [{ role: "system", content: system }, ...users];
}
