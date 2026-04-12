#!/usr/bin/env node
/**
 * Upload HL Paper 1 reading comprehension knowledge to S3:
 *   english/hl/paper1/reading-comprehension/...
 *
 * Sources (under lambda/data/):
 *   - hl-reading-comprehension-llm-guide.md
 *   - llm-british-english-convention.md
 *   - reading-comprehension-exemplars-manifest.json
 *
 * API Lambda IAM: grant s3:GetObject on
 *   arn:aws:s3:::<EXEMPLAR_BUCKET>/english/hl/paper1/reading-comprehension/*
 * so handlers can load guides via reading-comprehension-llm-context.mjs.
 *
 * Usage:
 *   node upload-reading-comprehension-knowledge.mjs
 */

import { existsSync, readFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const __dirname = dirname(fileURLToPath(import.meta.url));

const BUCKET = process.env.EXEMPLAR_BUCKET || "studybot-knowledge-dev";
const s3 = new S3Client({ region: process.env.AWS_REGION || "eu-west-1" });

const PREFIX = "english/hl/paper1/reading-comprehension";

function contentTypeFor(name) {
  const lower = name.toLowerCase();
  if (lower.endsWith(".md")) return "text/markdown; charset=utf-8";
  if (lower.endsWith(".json")) return "application/json; charset=utf-8";
  if (lower.endsWith(".html")) return "text/html; charset=utf-8";
  if (lower.endsWith(".txt")) return "text/plain; charset=utf-8";
  return "application/octet-stream";
}

async function put(key, body) {
  await s3.send(
    new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: body,
      ContentType: contentTypeFor(key),
    })
  );
  console.log(`  ✅ ${key}`);
}

async function main() {
  const dataDir = join(__dirname, "data");
  console.log("Upload HL reading comprehension knowledge");
  console.log("  Bucket:", BUCKET);
  console.log("  Prefix:", PREFIX + "/");
  console.log("");

  const uploads = [
    ["hl-reading-comprehension-llm-guide.md", `${PREFIX}/hl-reading-comprehension-llm-guide.md`],
    ["llm-british-english-convention.md", `${PREFIX}/llm-british-english-convention.md`],
    ["reading-comprehension-exemplars-manifest.json", `${PREFIX}/reading-comprehension-exemplars-manifest.json`],
  ];

  for (const [file, key] of uploads) {
    const p = join(dataDir, file);
    if (!existsSync(p)) {
      console.error(`  Missing: ${p}`);
      process.exit(1);
    }
    await put(key, readFileSync(p));
  }

  const readme = `HL English Paper 1 — reading comprehension knowledge (S3 keys)

LLM guide + exemplar manifest. Exam PDFs remain under english/hl/papers/.

Files:
  ${PREFIX}/hl-reading-comprehension-llm-guide.md
  ${PREFIX}/llm-british-english-convention.md
  ${PREFIX}/reading-comprehension-exemplars-manifest.json
`;
  await put(`${PREFIX}/README.txt`, Buffer.from(readme, "utf8"));

  console.log("\nDone.");
}

main().catch((e) => {
  console.error("❌", e.message || e);
  process.exit(1);
});
