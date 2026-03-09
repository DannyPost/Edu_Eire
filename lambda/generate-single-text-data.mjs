// generate-single-text-data.mjs
// Generates meta.json, themes.txt, key-quotes.txt, structure.txt for LC English Paper 2:
//   - Single text: prescribed list for 2026/2027 (7 texts) → english/{hl|ol}/paper2/single-text/
//   - Comparative: full list for comparative study → english/{hl|ol}/paper2/comparative/
// Run: EXEMPLAR_BUCKET=studybot-knowledge-dev node generate-single-text-data.mjs

import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const bedrock = new BedrockRuntimeClient({ region: "eu-west-1" });
const s3 = new S3Client({ region: "eu-west-1" });

const BUCKET = process.env.EXEMPLAR_BUCKET || "studybot-knowledge-dev";
const SONNET = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0";
const HAIKU = "eu.anthropic.claude-haiku-4-5-20251001-v1:0";

const SYS = "You are an expert Leaving Certificate English teacher. Be accurate, specific, and practical.";

// ── Single text (prescribed 2026/2027) ────────────────────────────────────────
// Years when the text is prescribed: 2026 and/or 2027

const SINGLE_TEXTS = [
  { id: "a-dolls-house", title: "A Doll's House", author: "Henrik Ibsen", type: "play", years: [2027] },
  { id: "all-the-light-we-cannot-see", title: "All the Light We Cannot See", author: "Anthony Doerr", type: "novel", years: [2026] },
  { id: "pride-and-prejudice", title: "Pride & Prejudice", author: "Jane Austen", type: "novel", years: [2026] },
  { id: "the-crucible", title: "The Crucible", author: "Arthur Miller", type: "play", years: [2026] },
  { id: "the-great-gatsby", title: "The Great Gatsby", author: "F. Scott Fitzgerald", type: "novel", years: [2027] },
  { id: "the-tenant-of-wildfell-hall", title: "The Tenant of Wildfell Hall", author: "Anne Brontë", type: "novel", years: [2026, 2027] },
  { id: "wuthering-heights", title: "Wuthering Heights", author: "Emily Brontë", type: "novel", years: [2027] },
];

// ── Comparative (full list for comparative study) ───────────────────────────────

const COMPARATIVE_TEXTS = [
  { id: "a-dolls-house", title: "A Doll's House", author: "Henrik Ibsen", type: "play" },
  { id: "all-my-sons", title: "All My Sons", author: "Arthur Miller", type: "play" },
  { id: "a-raisin-in-the-sun", title: "A Raisin in the Sun", author: "Lorraine Hansberry", type: "play" },
  { id: "big-maggie", title: "Big Maggie", author: "John B. Keane", type: "play" },
  { id: "educated", title: "Educated", author: "Tara Westover", type: "memoir" },
  { id: "foster", title: "Foster", author: "Claire Keegan", type: "novel" },
  { id: "juno", title: "Juno and the Paycock", author: "Sean O'Casey", type: "play" },
  { id: "im-not-scared", title: "I'm Not Scared", author: "Niccolò Ammaniti", type: "novel" },
  { id: "ladybird", title: "Lady Bird", author: "Greta Gerwig", type: "film" },
  { id: "never-let-me-go", title: "Never Let Me Go", author: "Kazuo Ishiguro", type: "novel" },
  { id: "philadelphia-here-i-come", title: "Philadelphia, Here I Come!", author: "Brian Friel", type: "play" },
  { id: "rear-window", title: "Rear Window", author: "Alfred Hitchcock", type: "film" },
  { id: "room", title: "Room", author: "Emma Donoghue", type: "novel" },
  { id: "stop-at-nothing", title: "Stop at Nothing: The Lance Armstrong Story", author: "Documentary", type: "documentary" },
  { id: "silas-marner", title: "Silas Marner", author: "George Eliot", type: "novel" },
  { id: "the-crucible", title: "The Crucible", author: "Arthur Miller", type: "play" },
  { id: "the-great-gatsby", title: "The Great Gatsby", author: "F. Scott Fitzgerald", type: "novel" },
  { id: "the-playboy-of-the-western-world", title: "The Playboy of the Western World", author: "J.M. Synge", type: "play" },
  { id: "the-shawshank-redemption", title: "The Shawshank Redemption", author: "Frank Darabont", type: "film" },
  { id: "unforgiven", title: "Unforgiven", author: "Clint Eastwood", type: "film" },
  { id: "where-the-crawdads-sing", title: "Where the Crawdads Sing", author: "Delia Owens", type: "novel" },
  { id: "wuthering-heights", title: "Wuthering Heights", author: "Emily Brontë", type: "novel" },
  { id: "1984", title: "1984", author: "George Orwell", type: "novel" },
];

// ── Bedrock & S3 ─────────────────────────────────────────────────────────────

async function callBedrock(system, user, maxTokens, modelId = SONNET) {
  const res = await bedrock.send(new InvokeModelCommand({
    modelId,
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify({
      anthropic_version: "bedrock-2023-05-31",
      max_tokens: maxTokens,
      temperature: 0,
      system: system,
      messages: [{ role: "user", content: [{ type: "text", text: user }] }],
    }),
  }));
  const body = JSON.parse(new TextDecoder().decode(res.body));
  return body?.content?.[0]?.text ?? "";
}

async function upload(key, content, contentType = "text/plain") {
  await s3.send(new PutObjectCommand({
    Bucket: BUCKET,
    Key: key,
    Body: content,
    ContentType: contentType,
  }));
  console.log(`  ✅ ${key}`);
}

// ── Generators ───────────────────────────────────────────────────────────────

async function generateThemes(text) {
  const { title, author, type } = text;
  return callBedrock(
    SYS,
    `Write a detailed themes.txt study file for "${title}" by ${author} (${type}) for Leaving Certificate.

Include:
MAJOR THEMES — each with 2-3 sentences and specific examples from the text (act/scene/chapter).
CHARACTER AND CONFLICT — key relationships and tensions.
TONE AND STYLE — how the ${type} creates effect (dialogue, imagery, structure).
EXAMINER'S LANGUAGE — phrases mark schemes use that students should mirror.
Be specific to this text.`,
    3500,
    HAIKU
  );
}

async function generateKeyQuotes(text) {
  const { title, author, type } = text;
  const structure = type === "play" ? "act and scene" : type === "film" ? "scene and moment" : "chapter";
  return callBedrock(
    SYS,
    `Create an EXHAUSTIVE key-quotes study guide for "${title}" by ${author} (${type}) for LC Higher Level.

We need ENOUGH quoted material that a model answer can be written from this file alone. Include a LOT of quotes.

Requirements:
- Minimum 50-80 key quotations (or more for long texts). Cover the whole ${type} by ${structure}.
- For each quote: give ${structure} location, the exact quoted line(s), then → Device/Technique, → Effect, → Theme.
- Work through the text in order. Do not summarise; quote and analyse.
- HL students quote widely; we need near-complete coverage in quote+commentary form.
- If long, output in Part 1 / Part 2 (and Part 3 if needed) so nothing is cut.

Format:

[ACT/CHAPTER/SCENE X]
"[exact quotation]"
→ Device:
→ Effect:
→ Theme:

Then next quote. Start from the opening. Use exact words from the text.`,
    12000,
    SONNET
  );
}

async function generateStructure(text) {
  const { title, author, type } = text;
  return callBedrock(
    SYS,
    `Write a structure.txt essay-writing guide for LC single-text questions on "${title}" by ${author}.

Include:
OPENING PARAGRAPH — how to name text, author, state argument, reference theme.
PARAGRAPH STRUCTURE — Point, Embed Quote, Analyse, Link to Theme (with example from this text).
LINKING PHRASES — 8-10 transitions for single-text essays.
CLOSING PARAGRAPH — synthesis, no new quotes, evaluative statement.
COMMON MISTAKES — 5 errors students make on this text.
WHAT GETS FULL MARKS — what examiners reward.
SAMPLE TOPIC SENTENCES — 6 adaptable topic sentences for different aspects of "${title}".`,
    3000,
    HAIKU
  );
}

// ── Process one text (generate once, upload to HL and OL) ─────────────────────

async function processSingleText(text) {
  console.log(`  Themes...`);
  const themes = await generateThemes(text);
  console.log(`  Structure...`);
  const structure = await generateStructure(text);
  console.log(`  Key-quotes (exhaustive)...`);
  const keyQuotes = await generateKeyQuotes(text);

  const meta = { title: text.title, author: text.author, type: text.type };
  if (text.years) meta.years = text.years;
  const metaJson = JSON.stringify(meta, null, 2);

  for (const level of ["hl", "ol"]) {
    const base = `english/${level}/paper2/single-text/${text.id}`;
    await upload(`${base}/meta.json`, metaJson, "application/json");
    await upload(`${base}/themes.txt`, themes);
    await upload(`${base}/structure.txt`, structure);
    await upload(`${base}/key-quotes.txt`, keyQuotes);
  }
}

async function processComparativeText(text) {
  console.log(`  Themes...`);
  const themes = await generateThemes(text);
  console.log(`  Structure...`);
  const structure = await generateStructure(text);
  console.log(`  Key-quotes (exhaustive)...`);
  const keyQuotes = await generateKeyQuotes(text);

  const meta = { title: text.title, author: text.author, type: text.type };
  const metaJson = JSON.stringify(meta, null, 2);

  for (const level of ["hl", "ol"]) {
    const base = `english/${level}/paper2/comparative/${text.id}`;
    await upload(`${base}/meta.json`, metaJson, "application/json");
    await upload(`${base}/themes.txt`, themes);
    await upload(`${base}/structure.txt`, structure);
    await upload(`${base}/key-quotes.txt`, keyQuotes);
  }
}

// ── Main ────────────────────────────────────────────────────────────────────

function parseArgs() {
  const args = process.argv.slice(2);
  const singleOnly = args.includes("--single-only");
  const comparativeOnly = args.includes("--comparative-only");
  return { singleOnly, comparativeOnly };
}

async function main() {
  const { singleOnly, comparativeOnly } = parseArgs();
  console.log("🚀 Generating LC English Paper 2 data...\n");
  console.log(`   Bucket: ${BUCKET}\n`);

  if (!comparativeOnly) {
    console.log("── Single text (prescribed 2026/2027) ──");
    for (const text of SINGLE_TEXTS) {
      const yearLabel = text.years ? ` [${text.years.join(", ")}]` : "";
      console.log(`\n📖 ${text.title} (${text.author})${yearLabel}...`);
      await processSingleText(text);
    }
  }

  if (!singleOnly) {
    console.log("\n── Comparative (full list) ──");
    for (const text of COMPARATIVE_TEXTS) {
      console.log(`\n📖 ${text.title} (${text.author})...`);
      await processComparativeText(text);
    }
  }

  console.log("\n✅ Done.");
}

main().catch((err) => {
  console.error("❌", err.message || err);
  process.exit(1);
});
