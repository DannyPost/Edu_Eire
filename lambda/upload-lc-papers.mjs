#!/usr/bin/env node
/**
 * Upload LC English papers to the knowledge bucket under english/hl/papers/ or english/ol/papers/.
 *
 * Usage:
 *   node upload-lc-papers.mjs [--dir=./papers/English] [--level=hl]
 *   node upload-lc-papers.mjs --dir=./papers/EnglishOL --level=ol
 *
 * Env:
 *   EXEMPLAR_BUCKET  S3 bucket (default studybot-knowledge-dev)
 *   PAPERS_DIR       Local folder (default ./papers/English for hl, ./papers/EnglishOL for ol)
 *   PAPERS_LEVEL     hl (default) or ol
 */

import { readdirSync, readFileSync, statSync } from "fs";
import { join, relative } from "path";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const BUCKET = process.env.EXEMPLAR_BUCKET || "studybot-knowledge-dev";
const s3 = new S3Client({ region: process.env.AWS_REGION || "eu-west-1" });

function parseArgs() {
  const args = process.argv.slice(2);
  let level = (process.env.PAPERS_LEVEL || "hl").toLowerCase();
  let dir = process.env.PAPERS_DIR;
  for (const a of args) {
    if (a.startsWith("--level=")) level = a.slice(7).toLowerCase().trim();
    if (a.startsWith("--dir=")) dir = a.slice(6).trim();
  }
  const defaultDir = level === "ol" ? join(process.cwd(), "papers", "EnglishOL") : join(process.cwd(), "papers", "English");
  if (!dir) dir = defaultDir;
  const resolvedDir = join(process.cwd(), dir);
  if (resolvedDir.includes("EnglishOL") && level === "hl") level = "ol";
  const prefix = level === "ol" ? "english/ol/papers" : "english/hl/papers";
  return { dir, prefix };
}

function* walkFiles(dir, base = dir) {
  const entries = readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = join(dir, e.name);
    if (e.isDirectory()) {
      yield* walkFiles(full, base);
    } else {
      yield relative(base, full);
    }
  }
}

async function main() {
  const { dir, prefix: S3_PREFIX } = parseArgs();
  console.log("Upload LC English papers to S3");
  console.log("  Bucket:", BUCKET);
  console.log("  Prefix:", S3_PREFIX + "/");
  console.log("  Local: ", dir);
  console.log("");

  let count = 0;
  for (const rel of walkFiles(dir)) {
    const fullPath = join(dir, rel);
    const key = `${S3_PREFIX}/${rel}`.replace(/\\/g, "/");
    const body = readFileSync(fullPath);
    const contentType = rel.toLowerCase().endsWith(".pdf") ? "application/pdf" : "application/octet-stream";
    await s3.send(new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: body,
      ContentType: contentType,
    }));
    console.log("  ✅", key);
    count++;
  }

  const manifestPath = join(dir, "..", "manifest.json");
  try {
    if (statSync(manifestPath).isFile()) {
      const key = `${S3_PREFIX}/manifest.json`;
      const body = readFileSync(manifestPath);
      await s3.send(new PutObjectCommand({
        Bucket: BUCKET,
        Key: key,
        Body: body,
        ContentType: "application/json",
      }));
      console.log("  ✅", key);
      count++;
    }
  } catch (_) {}

  console.log("");
  console.log("Uploaded:", count);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
