#!/usr/bin/env node
/**
 * Upload HL unseen poetry knowledge files to S3:
 *   english/hl/paper1/unseen-poetry/...
 *
 * Sources (under lambda/data/):
 *   - hl-unseen-poetry-llm-guide.md
 *   - llm-british-english-convention.md
 *   - unseen-poetry-exemplars-manifest.json
 *   - studyclix-snapshots/* (if present; optional public page snapshots)
 *
 * Usage:
 *   EXEMPLAR_BUCKET=studybot-knowledge-dev node upload-unseen-poetry-knowledge.mjs
 *
 * Env:
 *   EXEMPLAR_BUCKET  (default studybot-knowledge-dev)
 *   AWS_REGION       (default eu-west-1)
 */

import { existsSync, readFileSync, readdirSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const __dirname = dirname(fileURLToPath(import.meta.url));

const BUCKET = process.env.EXEMPLAR_BUCKET || "studybot-knowledge-dev";
const s3 = new S3Client({ region: process.env.AWS_REGION || "eu-west-1" });

const PREFIX = "english/hl/paper1/unseen-poetry";

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
  console.log("Upload HL unseen poetry knowledge");
  console.log("  Bucket:", BUCKET);
  console.log("  Prefix:", PREFIX + "/");
  console.log("");

  const uploads = [
    ["hl-unseen-poetry-llm-guide.md", `${PREFIX}/hl-unseen-poetry-llm-guide.md`],
    ["llm-british-english-convention.md", `${PREFIX}/llm-british-english-convention.md`],
    ["unseen-poetry-exemplars-manifest.json", `${PREFIX}/unseen-poetry-exemplars-manifest.json`],
  ];

  for (const [file, key] of uploads) {
    const p = join(dataDir, file);
    if (!existsSync(p)) {
      console.error(`  Missing: ${p}`);
      process.exit(1);
    }
    await put(key, readFileSync(p));
  }

  const snapDir = join(dataDir, "studyclix-snapshots");
  if (existsSync(snapDir)) {
    const names = readdirSync(snapDir).filter((n) => !n.startsWith("."));
    for (const name of names) {
      const p = join(snapDir, name);
      await put(`${PREFIX}/studyclix-snapshots/${name}`, readFileSync(p));
    }
  } else {
    console.log("  (no data/studyclix-snapshots/ — skipped optional snapshots)");
  }

  const readme = `HL English Paper 1 — unseen poetry knowledge (S3 keys)

This folder holds methodology and manifest for unseen poetry coaching, not exam PDFs.
Exam PDFs remain under english/hl/papers/.

Files:
  ${PREFIX}/hl-unseen-poetry-llm-guide.md
  ${PREFIX}/llm-british-english-convention.md
  ${PREFIX}/unseen-poetry-exemplars-manifest.json
  ${PREFIX}/studyclix-snapshots/snapshot.html   (optional)
  ${PREFIX}/studyclix-snapshots/snapshot.txt
  ${PREFIX}/studyclix-snapshots/snapshot-meta.json
`;
  await put(`${PREFIX}/README.txt`, Buffer.from(readme, "utf8"));

  console.log("\nDone.");
}

main().catch((e) => {
  console.error("❌", e.message || e);
  process.exit(1);
});
