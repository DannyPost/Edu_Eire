#!/usr/bin/env node
/**
 * Fetch Leaving Certificate past papers via StudyClix using Puppeteer.
 *
 * Opens the StudyClix papers page in a headless browser, waits for the
 * client-side paper list to load, extracts PDF links, and downloads them.
 *
 * Optional: --classify extracts text from the first page of each PDF and
 * asks a cheap LLM (Bedrock Haiku) to classify Paper 1 vs Paper 2 for correct placement.
 *
 * Usage:
 *   node fetch-lc-papers.mjs [--out=./papers] [--subject=1042687] [--no-headless] [--classify]
 *
 * Env:
 *   PAPERS_OUT_DIR  default ./papers
 *   AWS_REGION      for --classify (default eu-west-1); AWS credentials must be set
 */

import { writeFileSync, mkdirSync, existsSync } from "fs";
import { join } from "path";
import { get as httpsGet } from "https";

const STUDYCLIX_PAPERS = "https://www.studyclix.ie/papers";

// Subject IDs: open studyclix.ie/papers, pick a subject, copy #subject= value from URL
const SUBJECT_IDS = {
  English: "1042687",      // HL
  EnglishOL: "1042686",   // Ordinary Level
};

const DEFAULT_OUT = process.env.PAPERS_OUT_DIR || "./papers";
const WAIT_FOR_PAPERS_MS = 12000;
const DOWNLOAD_DELAY_MS = 500;
const CLASSIFY_DELAY_MS = Number(process.env.CLASSIFY_DELAY_MS) || 2000;
const CLASSIFY_RETRY_MS = Number(process.env.CLASSIFY_RETRY_MS) || 8000;
const FIRST_PAGE_MAX_CHARS = 3500;

function parseArgs() {
  const args = process.argv.slice(2);
  let outDir = DEFAULT_OUT;
  let subjectFilter = null;
  let headless = true;
  let classify = false;

  for (const a of args) {
    if (a.startsWith("--out=")) outDir = a.slice(6);
    if (a.startsWith("--subject=")) subjectFilter = a.slice(10).trim();
    if (a === "--no-headless") headless = false;
    if (a === "--classify") classify = true;
  }

  const subjects = subjectFilter
    ? Object.entries(SUBJECT_IDS).filter(([, id]) => id === subjectFilter)
    : Object.entries(SUBJECT_IDS);

  return { outDir, subjects: Object.fromEntries(subjects), subjectFilter, headless, classify };
}

function ensureDir(p) {
  if (!existsSync(p)) mkdirSync(p, { recursive: true });
}

function safeFilename(s) {
  return (s || "file")
    .replace(/[^a-zA-Z0-9.-]/g, "_")
    .replace(/_+/g, "_")
    .slice(0, 120);
}

function downloadPdf(url) {
  return new Promise((resolve, reject) => {
    httpsGet(
      url,
      { headers: { "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" } },
      (res) => {
        const redirect = res.headers.location;
        if (redirect && res.statusCode >= 300 && res.statusCode < 400) {
          downloadPdf(redirect.startsWith("http") ? redirect : new URL(redirect, url).href)
            .then(resolve)
            .catch(reject);
          return;
        }
        const chunks = [];
        res.on("data", (c) => chunks.push(c));
        res.on("end", () => {
          const isPdf =
            (res.headers["content-type"] || "").toLowerCase().includes("pdf") ||
            (chunks.length > 4 && chunks[0][0] === 0x25 && chunks[0][1] === 0x50);
          if (isPdf && chunks.length > 0) resolve(Buffer.concat(chunks));
          else reject(new Error(`Not a PDF (${res.statusCode}, ${(res.headers["content-type"] || "").slice(0, 30)})`));
        });
      }
    ).on("error", reject);
  });
}

/** Extract text from the first page of a PDF buffer for LLM classification. Returns at most FIRST_PAGE_MAX_CHARS. */
async function extractFirstPageText(pdfBuffer) {
  const { PDFParse } = await import("pdf-parse");
  const parser = new PDFParse({ data: new Uint8Array(pdfBuffer) });
  try {
    const result = await parser.getText({ first: 1 });
    await parser.destroy();
    const text = result.pages?.[0]?.text ?? result.text ?? "";
    return text.slice(0, FIRST_PAGE_MAX_CHARS).replace(/\s+/g, " ").trim();
  } catch (e) {
    await parser.destroy().catch(() => {});
    throw e;
  }
}

/** Call Bedrock Haiku to classify Paper 1 vs Paper 2 from first-page text. Returns "paper1" or "paper2" or null. Retries on throttle. */
async function classifyPaperWithLLM(firstPageText) {
  if (!firstPageText || firstPageText.length < 20) return null;
  const { BedrockRuntimeClient, InvokeModelCommand } = await import("@aws-sdk/client-bedrock-runtime");
  const bedrock = new BedrockRuntimeClient({ region: process.env.AWS_REGION || "eu-west-1" });
  const modelId = "eu.anthropic.claude-haiku-4-5-20251001-v1:0";
  const system = "You classify Irish Leaving Certificate English exam documents. Reply with only either \"Paper 1\" or \"Paper 2\". Paper 1 is composition and comprehension. Paper 2 is literature (prescribed texts, poetry, drama, film). Marking schemes match the paper type they refer to.";
  const user = `Here is text from the first page of a PDF. Is this document Paper 1 or Paper 2? Reply with only the words "Paper 1" or "Paper 2".\n\n${firstPageText}`;
  const isThrottle = (e) => (e.name === "ThrottlingException" || e.name === "TooManyRequestsException" || (e.message && /too many requests|throttl/i.test(e.message)));
  let lastErr;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const res = await bedrock.send(new InvokeModelCommand({
        modelId,
        contentType: "application/json",
        accept: "application/json",
        body: JSON.stringify({
          anthropic_version: "bedrock-2023-05-31",
          max_tokens: 32,
          temperature: 0,
          system,
          messages: [{ role: "user", content: [{ type: "text", text: user }] }],
        }),
      }));
      const body = JSON.parse(new TextDecoder().decode(res.body));
      const raw = (body?.content?.[0]?.text ?? "").trim();
      const lower = raw.toLowerCase();
      if (lower.includes("paper 2") || lower.includes("paper ii")) return "paper2";
      if (lower.includes("paper 1") || lower.includes("paper i")) return "paper1";
      return null;
    } catch (e) {
      lastErr = e;
      if (attempt < 2 && isThrottle(e)) {
        console.log(`    ⏳ Throttled, waiting ${CLASSIFY_RETRY_MS / 1000}s before retry...`);
        await new Promise((r) => setTimeout(r, CLASSIFY_RETRY_MS));
      } else {
        throw e;
      }
    }
  }
  throw lastErr;
}

async function runWithBrowser(outDir, subjectName, subjectId, headless, classify) {
  const puppeteer = await import("puppeteer");
  const browser = await puppeteer.default.launch({
    headless,
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"],
  });

  const manifest = { subjectName, subjectId, papersUrl: `${STUDYCLIX_PAPERS}#subject=${subjectId}`, links: [], downloaded: [], failed: [] };

  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 800 });
    await page.setUserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");

    const url = `${STUDYCLIX_PAPERS}#subject=${subjectId}`;
    console.log(`  Loading ${url} ...`);
    await page.goto(url, { waitUntil: "networkidle2", timeout: 20000 });

    // Wait for client-side paper list to load
    await new Promise((r) => setTimeout(r, WAIT_FOR_PAPERS_MS));

    const links = await page.evaluate(() => {
      const out = [];
      const seen = new Set();
      for (const a of document.querySelectorAll("a[href]")) {
        const href = a.href;
        if (!href || seen.has(href)) continue;
        const isPdf = href.toLowerCase().includes(".pdf") || href.includes("blob-static.studyclix.ie") || href.includes("/file/attachments/") || href.includes("/file/uploads/");
        if (!isPdf) continue;
        seen.add(href);
        const text = (a.textContent || "").trim().replace(/\s+/g, " ");
        let paperType = null;
        const cell = a.closest("td") || a.closest("[role='cell']");
        if (cell) {
          const row = cell.closest("tr") || cell.closest("[role='row']");
          const table = row?.closest("table") || row?.closest("[role='table']");
          const rowCells = row ? Array.from(row.children).filter((c) => /td|th|cell/i.test(c.tagName || c.getAttribute?.("role") || "")) : [];
          const colIdx = row ? rowCells.indexOf(cell) : -1;
          const headerRow = table?.querySelector("thead tr") || table?.querySelector("tr");
          let headerCell = null;
          if (headerRow && colIdx >= 0) {
            const numHeaders = headerRow.children.length;
            const numCols = rowCells.length;
            // If body has more columns than header (e.g. Year | P1 Exam | P1 Marking | P2 Exam | P2 Marking vs Year | Paper 1 | Paper 2), map col to header
            let headerColIdx = colIdx;
            if (numCols > numHeaders && numHeaders >= 2) {
              if (numHeaders >= 3) {
                headerColIdx = colIdx === 0 ? 0 : (colIdx <= (numCols - 1) / 2 ? 1 : 2);
              } else {
                headerColIdx = colIdx < numCols / 2 ? 0 : 1;
              }
            }
            headerCell = headerRow.children[headerColIdx];
          }
          const headerText = (headerCell?.innerText || "").toLowerCase();
          // Check Paper 2 before Paper 1 so "paper ii" / "paper 2" aren't matched as "paper i" / "paper 1"
          if (headerText.includes("paper 2") || headerText.includes("paper ii")) paperType = "paper2";
          else if (headerText.includes("paper 1") || headerText.includes("paper i")) paperType = "paper1";
        }
        if (!paperType) {
          let el = a;
          for (let up = 0; up < 12 && el; up++) {
            const parentText = (el.closest("tr") || el.closest("[role='row']") || el.parentElement)?.innerText || "";
            const lower = parentText.toLowerCase();
            // Check Paper 2 first so we don't match "paper 1" in "Paper 1 & Paper 2" or "paper i" in "paper ii"
            if (lower.includes("paper 2") || lower.includes("paper ii")) {
              paperType = "paper2";
              break;
            }
            if (lower.includes("paper 1") || lower.includes("paper i")) {
              paperType = "paper1";
              break;
            }
            el = el.parentElement;
          }
        }
        // Fallback: table/section might have separate blocks for Paper 1 vs Paper 2 with only "Exam"/"Marking" in header. Look for preceding heading or table caption.
        if (!paperType) {
          const tbl = a.closest("table") || a.closest("[role='table']");
          if (tbl) {
            let prev = tbl.previousElementSibling;
            for (let i = 0; i < 5 && prev; i++) {
              const prevText = (prev.innerText || "").toLowerCase();
              if (prevText.includes("paper 2") || prevText.includes("paper ii")) {
                paperType = "paper2";
                break;
              }
              if (prevText.includes("paper 1") || prevText.includes("paper i")) {
                paperType = "paper1";
                break;
              }
              prev = prev.previousElementSibling;
            }
            if (!paperType && tbl.caption) {
              const cap = (tbl.caption.innerText || "").toLowerCase();
              if (cap.includes("paper 2") || cap.includes("paper ii")) paperType = "paper2";
              else if (cap.includes("paper 1") || cap.includes("paper i")) paperType = "paper1";
            }
          }
        }
        // Fallback: link text or surrounding context (e.g. "Paper 2 2024")
        if (!paperType && text) {
          const t = text.toLowerCase();
          if (t.includes("paper 2") || t.includes("paper ii")) paperType = "paper2";
          else if (t.includes("paper 1") || t.includes("paper i")) paperType = "paper1";
        }
        const isMarking = text.toLowerCase().includes("marking") || href.toLowerCase().includes("marking");
        const docType = isMarking ? "marking" : "exam";
        out.push({ href, text: text.slice(0, 80), paperType: paperType || "unknown", docType });
      }
      return out;
    });

    const byType = { paper1: [], paper2: [], unknown: [] };
    for (const l of links) byType[l.paperType].push(l);
    const examCount = links.filter((l) => l.docType === "exam").length;
    const markingCount = links.filter((l) => l.docType === "marking").length;
    console.log(`  Found ${links.length} links: Paper 1: ${byType.paper1.length}, Paper 2: ${byType.paper2.length} | Exam: ${examCount}, Marking: ${markingCount}`);
    manifest.links = links.map((l) => ({ href: l.href, text: l.text, paperType: l.paperType, docType: l.docType }));

    const subjectDir = join(outDir, safeFilename(subjectName));
    ensureDir(subjectDir);
    const paper1ExamDir = join(subjectDir, "Paper1", "Exam");
    const paper1MarkingDir = join(subjectDir, "Paper1", "MarkingScheme");
    const paper2ExamDir = join(subjectDir, "Paper2", "Exam");
    const paper2MarkingDir = join(subjectDir, "Paper2", "MarkingScheme");
    const otherExamDir = join(subjectDir, "Other", "Exam");
    const otherMarkingDir = join(subjectDir, "Other", "MarkingScheme");
    ensureDir(paper1ExamDir);
    ensureDir(paper1MarkingDir);
    ensureDir(paper2ExamDir);
    ensureDir(paper2MarkingDir);
    ensureDir(otherExamDir);
    ensureDir(otherMarkingDir);

    const usedByKey = {};
    function getDir(paperType, docType) {
      if (paperType === "paper1") return docType === "marking" ? paper1MarkingDir : paper1ExamDir;
      if (paperType === "paper2") return docType === "marking" ? paper2MarkingDir : paper2ExamDir;
      return docType === "marking" ? otherMarkingDir : otherExamDir;
    }
    function usedSet(paperType, docType) {
      const k = `${paperType}-${docType}`;
      if (!usedByKey[k]) usedByKey[k] = new Set();
      return usedByKey[k];
    }

    for (let i = 0; i < links.length; i++) {
      let { href, text, paperType: domPaperType, docType } = links[i];
      let paperType = domPaperType;
      let base = (text || href.split("/").pop() || "").trim();
      if (!base) base = docType === "marking" ? `marking-${i + 1}` : `paper-${i + 1}`;
      base = safeFilename(base);
      if (!base.endsWith(".pdf")) base += ".pdf";

      try {
        const buf = await downloadPdf(href);
        if (classify) {
          try {
            const firstPageText = await extractFirstPageText(buf);
            const llmType = await classifyPaperWithLLM(firstPageText);
            if (llmType) {
              paperType = llmType;
              console.log(`    🤖 LLM classified as ${paperType.toUpperCase()}`);
            }
          } catch (classifyErr) {
            console.log(`    ⚠️  Classify failed, using DOM: ${classifyErr.message}`);
          }
          await new Promise((r) => setTimeout(r, CLASSIFY_DELAY_MS));
        }
        const delayAfterItem = classify ? Math.max(DOWNLOAD_DELAY_MS, CLASSIFY_DELAY_MS) : DOWNLOAD_DELAY_MS;
        await new Promise((r) => setTimeout(r, delayAfterItem));
        const dir = getDir(paperType, docType);
        const used = usedSet(paperType, docType);
        let filename = base;
        let n = 0;
        while (used.has(filename)) {
          n++;
          filename = base.replace(".pdf", `_${n}.pdf`);
        }
        used.add(filename);
        const filepath = join(dir, filename);
        writeFileSync(filepath, buf);
        const folder = paperType === "paper1" ? "Paper1" : paperType === "paper2" ? "Paper2" : "Other";
        const sub = docType === "marking" ? "MarkingScheme" : "Exam";
        manifest.downloaded.push({ href, filename, paperType, docType, folder: `${folder}/${sub}` });
        console.log(`    ✅ ${folder}/${sub}/${filename}`);
      } catch (e) {
        manifest.failed.push({ href, error: e.message });
        console.log(`    ⚠️  ${base}: ${e.message}`);
      }
      const tailDelay = classify ? 0 : DOWNLOAD_DELAY_MS;
      if (tailDelay) await new Promise((r) => setTimeout(r, tailDelay));
    }
  } finally {
    await browser.close();
  }

  return manifest;
}

async function main() {
  const { outDir, subjects, subjectFilter, headless, classify } = parseArgs();
  const subjectEntries = Object.entries(subjects);

  console.log("StudyClix LC papers (Puppeteer)");
  console.log("  Subjects:", subjectEntries.length, subjectFilter ? `(filter: ${subjectFilter})` : "");
  console.log("  Out:", outDir);
  if (classify) console.log("  Classify: ON (first-page text → Bedrock Haiku for Paper 1/2)");
  console.log("");

  ensureDir(outDir);
  const allManifests = { source: "StudyClix", fetchedAt: new Date().toISOString(), subjects: {} };

  for (const [name, id] of subjectEntries) {
    console.log(`\n📖 ${name} (${id})`);
    try {
      const manifest = await runWithBrowser(outDir, name, id, headless, classify);
      allManifests.subjects[name] = { subjectId: id, ...manifest };
    } catch (e) {
      console.error(`  ❌ ${e.message}`);
      allManifests.subjects[name] = { subjectId: id, error: e.message };
    }
  }

  const manifestPath = join(outDir, "manifest.json");
  writeFileSync(manifestPath, JSON.stringify(allManifests, null, 2));
  console.log("\nManifest:", manifestPath);

  const totalDown = Object.values(allManifests.subjects).reduce((n, s) => n + (s.downloaded?.length || 0), 0);
  const totalFail = Object.values(allManifests.subjects).reduce((n, s) => n + (s.failed?.length || 0), 0);
  console.log("Downloaded:", totalDown, "| Failed:", totalFail);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
