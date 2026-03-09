// generate-poetry-data.mjs
// Generates meta.json, poems.txt, themes.txt, key-quotes.txt, structure.txt
// for all 2027 LC English prescribed poets (HL + OL).
// Run: EXEMPLAR_BUCKET=studybot-knowledge-dev node generate-poetry-data.mjs

import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const bedrock = new BedrockRuntimeClient({ region: "eu-west-1" });
const s3      = new S3Client({ region: "eu-west-1" });

const BUCKET = process.env.EXEMPLAR_BUCKET || "studybot-knowledge-dev";

// Sonnet 4.5 for accuracy-critical poem text; Haiku 4.5 for fast structured files
const SONNET = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0";
const HAIKU  = "eu.anthropic.claude-haiku-4-5-20251001-v1:0";

// ── Copyright status ──────────────────────────────────────────────────────────
// public_domain: true  → full poem text generated
// public_domain: false → line-by-line annotation file generated instead

// ── 2027 Poet Data ────────────────────────────────────────────────────────────

const POETS_HL = [
  {
    id: "elizabeth-bishop",
    name: "Elizabeth Bishop",
    public_domain: false,
    hl_poems: [
      "The Fish",
      "The Bight",
      "At the Fishhouses",
      "The Prodigal",
      "Questions of Travel",
      "The Armadillo",
      "Sestina",
      "First Death in Nova Scotia",
      "Filling Station",
      "In the Waiting Room",
    ],
    ol_poems: ["The Fish", "The Prodigal", "Filling Station"],
  },
  {
    id: "emily-dickinson",
    name: "Emily Dickinson",
    public_domain: true,
    hl_poems: [
      "'Hope' is the thing with feathers",
      "There's a certain Slant of light",
      "I felt a Funeral, in my Brain",
      "A Bird came down the Walk",
      "I Heard a fly buzz – when I died",
      "The Soul has Bandaged moments",
      "I could bring You Jewels – had I a mind to",
      "A narrow Fellow in the Grass",
      "I taste a liquor never brewed",
      "After great pain, a formal feeling comes",
    ],
    ol_poems: [
      "I felt a Funeral, in my Brain",
      "I Heard a fly buzz – when I died",
    ],
  },
  {
    id: "john-donne",
    name: "John Donne",
    public_domain: true,
    hl_poems: [
      "The Sunne Rising",
      "Song: Go, and catch a falling star",
      "The Anniversarie",
      "Song: Sweetest love, I do not goe",
      "The Dreame (Deare love, for nothing less than thee)",
      "A Valediction Forbidding Mourning",
      "The Flea",
      "Batter my heart",
      "At the round earth's imagined corners",
      "Thou hast made me",
    ],
    ol_poems: ["The Flea", "Song: Go and catch a falling star"],
  },
  {
    id: "patrick-kavanagh",
    name: "Patrick Kavanagh",
    public_domain: false,
    hl_poems: [
      "Inniskeen Road: July Evening",
      "Shancoduff",
      "from The Great Hunger Section I",
      "Advent",
      "A Christmas Childhood",
      "Epic",
      "Canal Bank Walk",
      "Lines Written on a Seat on the Grand Canal",
      "The Hospital",
      "On Raglan Road",
    ],
    ol_poems: ["Shancoduff", "A Christmas Childhood"],
  },
  {
    id: "derek-mahon",
    name: "Derek Mahon",
    public_domain: false,
    hl_poems: [
      "Grandfather",
      "Day Trip to Donegal",
      "Ecclesiastes",
      "After the Titanic",
      "As It Should Be",
      "A Disused Shed in Co. Wexford",
      "Rathlin",
      "The Chinese Restaurant in Portrush",
      "Kinsale",
      "Antarctica",
    ],
    ol_poems: ["Grandfather", "After the Titanic", "Antarctica"],
  },
  {
    id: "paula-meehan",
    name: "Paula Meehan",
    public_domain: false,
    hl_poems: [
      "Buying Winkles",
      "The Pattern",
      "The Statue of the Virgin at Granard Speaks",
      "Cora, Auntie",
      "The Exact Moment I Became a Poet",
      "My Father Perceived as a Vision of St. Francis",
      "Hearth Lesson",
      "Prayer for the Children of Longing",
      "Death of a Field",
      "Them Ducks Died for Ireland",
    ],
    ol_poems: [
      "Buying Winkles",
      "Hearth Lesson",
      "Prayer for the Children of Longing",
    ],
  },
  {
    id: "adrienne-rich",
    name: "Adrienne Rich",
    public_domain: false,
    hl_poems: [
      "Aunt Jennifer's Tigers",
      "Uncle Speaks in the Drawing Room",
      "Power",
      "Storm Warnings",
      "Living in Sin",
      "The Roofwalker",
      "Our Whole Life",
      "Trying to Talk with a Man",
      "Diving Into the Wreck",
      "From a Survivor",
    ],
    ol_poems: ["Aunt Jennifer's Tigers", "Uncle Speaks in the Drawing Room"],
  },
  {
    id: "wb-yeats",
    name: "W.B. Yeats",
    public_domain: true,
    hl_poems: [
      "The Lake Isle of Innisfree",
      "September 1913",
      "The Wild Swans at Coole",
      "An Irish Airman Foresees his Death",
      "Easter 1916",
      "The Second Coming",
      "Sailing to Byzantium",
      "from Meditations in Time of Civil War: VI, The Stare's Nest by My Window",
      "In Memory of Eva Gore-Booth and Con Markiewicz",
      "Swift's Epitaph",
      "An Acre of Grass",
      "from Under Ben Bulben: V and VI",
      "Politics",
    ],
    ol_poems: [
      "The Lake Isle of Innisfree",
      "The Wild Swans at Coole",
      "An Irish Airman Foresees his Death",
    ],
  },
];

const POETS_OL_ONLY = [
  // public domain = died before 1926
  { id: "gwendolyn-brooks",         name: "Gwendolyn Brooks",         public_domain: false, ol_poems: ["kitchenette building"] },
  { id: "colette-bryce",            name: "Colette Bryce",            public_domain: false, ol_poems: ["Mammy Dozes"] },
  { id: "carol-ann-duffy",          name: "Carol Ann Duffy",          public_domain: false, ol_poems: ["Valentine"] },
  { id: "linda-france",             name: "Linda France",             public_domain: false, ol_poems: ["If Love Was Jazz"] },
  { id: "alison-joseph",            name: "Alison Joseph",            public_domain: false, ol_poems: ["My Father's Kites"] },
  { id: "rachel-loden",             name: "Rachel Loden",             public_domain: false, ol_poems: ["Memo from the Benefits Department"] },
  { id: "sinead-morrissey",         name: "Sinéad Morrissey",         public_domain: false, ol_poems: ["Genetics"] },
  { id: "paul-muldoon",             name: "Paul Muldoon",             public_domain: false, ol_poems: ["The Loaf"] },
  { id: "alden-nowlan",             name: "Alden Nowlan",             public_domain: false, ol_poems: ["In Praise of the Great Bull Walrus"] },
  { id: "felicia-olusanya",         name: "Felicia Olusanya",         public_domain: false, ol_poems: ["For Our Mothers"] },
  { id: "billy-ramsell",            name: "Billy Ramsell",            public_domain: false, ol_poems: ["Lament for Christy Ring"] },
  { id: "edwin-arlington-robinson", name: "Edwin Arlington Robinson",  public_domain: true,  ol_poems: ["Reuben Bright"] },
  { id: "tim-seibles",              name: "Tim Seibles",              public_domain: false, ol_poems: ["Commercial Break: Roadrunner, Uneasy"] },
  { id: "percy-shelley",            name: "Percy Bysshe Shelley",     public_domain: true,  ol_poems: ["Ozymandias"] },
  { id: "degna-stone",              name: "Degna Stone",              public_domain: false, ol_poems: ["Swimming"] },
  { id: "shakespeare-sonnets",      name: "William Shakespeare",      public_domain: true,  ol_poems: ["Sonnet XVIII: Shall I Compare Thee"] },
];

// ── Bedrock helper ────────────────────────────────────────────────────────────

async function callBedrock(system, user, maxTokens, modelId) {
  const res = await bedrock.send(new InvokeModelCommand({
    modelId,
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify({
      anthropic_version: "bedrock-2023-05-31",
      max_tokens: maxTokens,
      temperature: 0,
      system,
      messages: [{ role: "user", content: [{ type: "text", text: user }] }],
    }),
  }));
  const body = JSON.parse(new TextDecoder().decode(res.body));
  return body?.content?.[0]?.text ?? "";
}

// ── S3 upload ─────────────────────────────────────────────────────────────────

async function upload(key, content) {
  await s3.send(new PutObjectCommand({
    Bucket: BUCKET,
    Key: key,
    Body: content,
    ContentType: "text/plain",
  }));
  console.log(`  ✅ ${key}`);
}

// ── File generators ───────────────────────────────────────────────────────────

const SYS = "You are an expert Leaving Certificate English teacher and literary scholar. Be accurate, specific, and practical.";

// ── Full poem text (public domain only) ──────────────────────────────────────

async function generateOnePoemFull(poetName, poemTitle) {
  return callBedrock(
    SYS,
    `Write the complete, accurate, verbatim text of the poem "${poemTitle}" by ${poetName}.

Write every stanza and every line in full, preserving:
- Exact line breaks
- Original punctuation and capitalisation
- Stanza spacing

Do not include any commentary, introduction, or notes. Just the poem text.`,
    2000,
    SONNET
  );
}

// ── Line-by-line annotation (copyrighted poems) ───────────────────────────────
// Stores every quoted line alongside its analysis.
// The exemplar Lambda gets full quoting coverage without storing the poem verbatim.

async function generateOnePoemAnnotated(poetName, poemTitle) {
  return callBedrock(
    SYS,
    `Create a complete line-by-line annotation of "${poemTitle}" by ${poetName} for LC study.

For EVERY line of the poem (in order), write:

LINE: "[exact quoted line]"
→ Context: [what is happening at this point in the poem]
→ Device: [poetic/literary device used]
→ Effect: [the emotional or intellectual effect on the reader]
→ Theme: [which major theme this line connects to]

Include all lines. Do not skip or summarise any. This is a study reference — completeness is essential.
Do not include a title header or introduction. Start directly with LINE 1.`,
    3500,
    SONNET
  );
}

async function generatePoemsFile(poetName, poems, publicDomain) {
  const parts = [];
  for (const poem of poems) {
    console.log(`     📝 ${poem}...`);
    let content;
    if (publicDomain) {
      content = await generateOnePoemFull(poetName, poem);
    } else {
      content = await generateOnePoemAnnotated(poetName, poem);
    }
    const label = publicDomain ? poem : `${poem} [line-by-line annotation]`;
    parts.push(
      `════════════════════════════════════════\n${label}\n════════════════════════════════════════\n\n${content.trim()}`
    );
  }
  return parts.join("\n\n\n");
}

async function generateThemes(poetName, poems) {
  return callBedrock(
    SYS,
    `Write a detailed themes.txt study file for ${poetName} covering these prescribed LC poems:
${poems.join(", ")}

Format exactly as:

MAJOR THEMES
─────────────
[Theme name]: [2-3 sentences explaining how this theme runs through the prescribed poems, with specific poem examples]

(List all major themes)

TONE AND ATTITUDE
──────────────────
[Describe the poet's emotional register, voice, shifts in tone across the poems. Reference specific poems.]

KEY LITERARY DEVICES
──────────────────────
[Device name]: [How ${poetName} uses this device, with a specific example from the poems and its effect]

(List 5-6 key devices)

EXAMINER'S LANGUAGE
─────────────────────
[Key critical phrases examiners and mark schemes use about ${poetName} that students should mirror in their answers]

POEM-BY-POEM SUMMARY
──────────────────────
[For each poem: one sentence on its central concern/theme]

Be specific to ${poetName}. Do not be generic.`,
    3000,
    HAIKU
  );
}

// Public domain: strong set of quotes per poem (HL needs plenty to choose from)
async function generateKeyQuotes(poetName, poems) {
  return callBedrock(
    SYS,
    `Generate a key-quotes.txt study file for ${poetName} for Leaving Certificate HIGHER LEVEL.

For each poem, provide 15-25 of the most quotable, analytically rich lines or short extracts. HL essays need very wide quotation. Cover every stanza: opening, development, climax, and closing.

After each quote, write:
→ Device: [name the poetic device]
→ Effect: [what effect it creates on the reader]
→ Theme link: [which major theme it connects to]

Format:

════════════════════════════════════════
[POEM TITLE]
════════════════════════════════════════

"[quote]"
→ Device:
→ Effect:
→ Theme link:

Poems: ${poems.join(", ")}

Only include lines you are certain appear in these poems. Accuracy is essential. More quotes = better for HL. Aim for 15-25 per poem minimum.`,
    8000,
    HAIKU
  );
}

// Copyrighted poets: exhaustive quote coverage so exemplar has enough context without full poem.
// One poem per call; very high quote count so HL can answer any question.
async function generateKeyQuotesFullPoem(poetName, poems) {
  const parts = [];
  for (const poem of poems) {
    console.log(`     📌 key-quotes (exhaustive): ${poem}...`);
    const block = await callBedrock(
      SYS,
      `Create an EXHAUSTIVE key-quotes study guide for "${poem}" by ${poetName} for Leaving Certificate HIGHER LEVEL.

We need ENOUGH quoted material that a model answer can be written from this file alone (the full poem text is not available). So you must include a LOT of quotes.

Requirements:
- Minimum 40-60 quoted lines per poem (or more for long poems). Cover EVERY stanza.
- For short poems (under 20 lines), quote at least 25 lines. For medium (20-50 lines), 50-70 quotes. For long (50+), 70-100+ quotes.
- Work through the poem in order. Each entry: the exact line(s) in quotes, then analysis.
- After each quote write: → Device: [technique] → Effect: [on reader] → Theme: [link to theme]
- Do not summarise or skip lines. HL students quote widely; we need near-complete coverage in quote+commentary form.
- If the poem is long, output Part 1 then Part 2 (and Part 3 if needed) in the same response so nothing is cut. We need maximum coverage.

Format each quote as:

"[exact line from the poem]"
→ Device:
→ Effect:
→ Theme:

Then the next quote. No preamble; start with the first line of the poem.`,
      12000,
      SONNET
    );
    parts.push(
      `════════════════════════════════════════\n${poem}\n════════════════════════════════════════\n\n${block.trim()}`
    );
  }
  return parts.join("\n\n\n");
}

async function generateStructure(poetName, poems) {
  return callBedrock(
    SYS,
    `Write a structure.txt essay-writing guide for LC Higher Level questions on ${poetName}.

Include:

OPENING PARAGRAPH TEMPLATE
────────────────────────────
[Template for opening a ${poetName} essay — name the poet, state a clear argument, reference a key theme in 3-5 sentences]

PARAGRAPH STRUCTURE (P-E-A)
─────────────────────────────
Point → Embed Quote → Analyse Device → Link to Theme
[Show a worked example using one of ${poetName}'s poems]

LINKING PHRASES
────────────────
[8-10 transition phrases appropriate for writing about this poet's specific themes]

CLOSING PARAGRAPH
──────────────────
[What makes a strong conclusion — synthesis of argument, no new quotes, final evaluative statement]

COMMON STUDENT MISTAKES
─────────────────────────
[5 specific mistakes students make when writing about ${poetName}]

WHAT GETS FULL MARKS
──────────────────────
[What examiners specifically reward in top answers about ${poetName}]

SAMPLE TOPIC SENTENCES
────────────────────────
[6 ready-to-use topic sentences covering different aspects of ${poetName}'s poetry]

Poems covered: ${poems.join(", ")}`,
    3000,
    HAIKU
  );
}

// ── Process a poet ────────────────────────────────────────────────────────────

// Stub for copyrighted poets: no LLM call, so no refusal written into poems.txt
const POEMS_TXT_STUB_COPYRIGHTED = `Poem content for this prescribed poet is not reproduced here (copyright).
Use key-quotes.txt for the full poem in quote-and-commentary form: each line quoted with analysis, in order.`;

async function processPoet(poetId, poetName, poems, level, publicDomain = false) {
  const base = `english/${level}/paper2/prescribed-poetry/${poetId}`;

  // poems.txt — for copyrighted poets the LLM refuses, so we write a stub and rely on key-quotes.txt
  if (publicDomain) {
    console.log(`\n  Poems (full text):`);
    const poemsText = await generatePoemsFile(poetName, poems, true);
    await upload(`${base}/poems.txt`, poemsText);
  } else {
    console.log(`\n  Poems: stub (copyrighted; see key-quotes.txt)`);
    await upload(`${base}/poems.txt`, POEMS_TXT_STUB_COPYRIGHTED);
  }

  // themes + structure in parallel
  console.log(`  Generating themes, structure...`);
  const [themes, structure] = await Promise.all([
    generateThemes(poetName, poems),
    generateStructure(poetName, poems),
  ]);
  await upload(`${base}/themes.txt`, themes);
  await upload(`${base}/structure.txt`, structure);

  // Key-quotes: public domain = 8-12 strong quotes per poem; copyrighted = exhaustive (25-80+ per poem) for HL context
  console.log(`  Generating key-quotes (${publicDomain ? "8-12 per poem" : "exhaustive for HL"})...`);
  const quotes = publicDomain
    ? await generateKeyQuotes(poetName, poems)
    : await generateKeyQuotesFullPoem(poetName, poems);
  await upload(`${base}/key-quotes.txt`, quotes);
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  console.log("🚀 Generating 2027 LC English poetry data...");
  console.log(`   Bucket: ${BUCKET}\n`);

  // HL poets (sequential between poets, so we can see progress clearly)
  for (const poet of POETS_HL) {
    console.log(`\n📚 ${poet.name} (HL)...`);
    const hlBase = `english/hl/paper2/prescribed-poetry/${poet.id}`;

    const meta = {
      name: poet.name,
      years_hl: [2027],
      years_ol: [2027],
      hl_poems: poet.hl_poems,
      ol_poems: poet.ol_poems || [],
    };
    const pd = poet.public_domain ?? false;
    await upload(`${hlBase}/meta.json`, JSON.stringify(meta, null, 2));
    await processPoet(poet.id, poet.name, poet.hl_poems, "hl", pd);

    // OL subset
    if (poet.ol_poems?.length) {
      console.log(`\n  └─ ${poet.name} (OL)...`);
      const olBase = `english/ol/paper2/prescribed-poetry/${poet.id}`;
      await upload(`${olBase}/meta.json`, JSON.stringify(meta, null, 2));
      await processPoet(poet.id, poet.name, poet.ol_poems, "ol", pd);
    }
  }

  // OL-only poets
  for (const poet of POETS_OL_ONLY) {
    console.log(`\n📖 ${poet.name} (OL only)...`);
    const olBase = `english/ol/paper2/prescribed-poetry/${poet.id}`;

    const meta = {
      name: poet.name,
      years_hl: [],
      years_ol: [2027],
      hl_poems: [],
      ol_poems: poet.ol_poems,
    };
    const pd = poet.public_domain ?? false;
    await upload(`${olBase}/meta.json`, JSON.stringify(meta, null, 2));
    await processPoet(poet.id, poet.name, poet.ol_poems, "ol", pd);
  }

  console.log("\n✅ All done.");
  console.log("\n⚠️  Files NOT generated (must be written by hand):");
  console.log("   - */sample-h1.txt  (real H1 exemplar essays)");
  console.log("   - */sample-ol.txt  (real OL exemplar essays)");
}

main().catch(err => {
  console.error("❌ Fatal error:", err.message || err);
  process.exit(1);
});
