// test_router.mjs — Automated router test suite
// Run: node test_router.mjs
// Hits: https://57u97hpdwi.execute-api.eu-west-1.amazonaws.com/dev/chat

const BASE  = "https://57u97hpdwi.execute-api.eu-west-1.amazonaws.com/dev/chat";
// Pass your Firebase ID token as first CLI arg:  node test_router.mjs <token>
const TOKEN = process.argv[2] ?? "";

// Mirrors Flutter StudyBotService._looksLikeEssay — pre-signals meta.answer
// exactly as the real app does before sending to the router.
function looksLikeEssay(text) {
  if (!text) return false;
  if (text.length > 600) return true;
  if ((text.match(/\n/g) || []).length >= 6) return true;
  return /(in conclusion|furthermore|moreover|therefore|this essay|i will argue|analysis)/i.test(text);
}

function enrichBody(body) {
  const msg = body.message ?? "";
  const meta = { ...(body.meta ?? {}) };
  if (looksLikeEssay(msg) && !meta.answer) {
    meta.answer = msg;
  }
  return { ...body, meta };
}

const RESET  = "\x1b[0m";
const GREEN  = "\x1b[32m";
const RED    = "\x1b[31m";
const YELLOW = "\x1b[33m";
const CYAN   = "\x1b[36m";
const BOLD   = "\x1b[1m";

const cases = [
  // ── GRADE ───────────────────────────────────────────────────────────────
  {
    id: "G1",
    label: "Grade — explicit keyword + short essay",
    expected: "grade",
    body: {
      message: "Grade my answer please.\n\nThe theme of power in Ozymandias is conveyed through Shelley's use of irony. The inscription \"Look on my Works, ye Mighty, and despair!\" is undercut by the surrounding desert, showing that even the greatest rulers are forgotten by time.",
      meta: { subject: "English", level: "HL" },
    },
  },
  {
    id: "G2",
    label: "Grade — no keyword, pure essay (essay heuristic must fire)",
    expected: "grade",
    body: {
      message: "The causes of World War One were complex and interconnected. Furthermore, the alliance system meant that a local conflict could rapidly escalate. Historians have argued that imperialism created the conditions for rivalry between great powers. In conclusion, no single cause was solely responsible.",
      meta: { subject: "History", level: "HL" },
    },
  },
  {
    id: "G3",
    label: "Grade — student pastes answer with question context",
    expected: "grade",
    body: {
      message: "Question: Explain the role of mitochondria in the cell.\n\nMitochondria are known as the powerhouse of the cell. They produce ATP through a process called cellular respiration, which involves breaking down glucose in the presence of oxygen. This energy in the form of ATP is then used by the cell to carry out all of its essential functions, including muscle contraction, protein synthesis, and active transport. The mitochondria have a double membrane structure — the inner membrane is folded into cristae which increases surface area for ATP production. Without mitochondria, the cell could not produce enough energy to survive and would die.",
      meta: { subject: "Biology", level: "OL" },
    },
  },
  {
    id: "G4",
    label: "Grade — hardgate stress test (must NOT route to exemplar)",
    expected: "grade",
    body: {
      message: "Mark this and give me feedback:\n\nLet f(x) = x² + 3x - 4. I found the roots by factoring: (x+4)(x-1) = 0, so x = -4 and x = 1. Therefore the vertex is at x = -1.5 and y = -6.25.",
      meta: { subject: "Maths", level: "HL" },
    },
  },

  // ── EXEMPLAR ─────────────────────────────────────────────────────────────
  {
    id: "E1",
    label: "Exemplar — explicit model answer request",
    expected: "exemplar",
    body: {
      message: "Write me a model answer for: Compare how power is presented in Ozymandias and My Last Duchess.",
      meta: { subject: "English", level: "HL" },
    },
  },
  {
    id: "E2",
    label: "Exemplar — essay plan request",
    expected: "exemplar",
    body: {
      message: "Give me an essay plan for the causes of World War One.",
      meta: { subject: "History", level: "HL" },
    },
  },
  {
    id: "E3",
    label: "Exemplar — how would you answer",
    expected: "exemplar",
    body: {
      message: "How would you answer the question: Describe a character who changed throughout the novel?",
      meta: { subject: "English", level: "OL" },
    },
  },

  // ── PAPER ────────────────────────────────────────────────────────────────
  {
    id: "P1",
    label: "Paper — practice paper request",
    expected: "paper",
    body: {
      message: "Generate a practice paper for me on genetics and inheritance.",
      meta: { subject: "Biology", level: "HL" },
    },
  },
  {
    id: "P2",
    label: "Paper — quiz / question set",
    expected: "paper",
    body: {
      message: "Create 5 questions on algebra for me to practice.",
      meta: { subject: "Maths", level: "OL" },
    },
  },
  {
    id: "P3",
    label: "Paper — mock exam",
    expected: "paper",
    body: {
      message: "Give me a mock exam on organic chemistry.",
      meta: { subject: "Chemistry", level: "HL" },
    },
  },

  // ── ADVICE ───────────────────────────────────────────────────────────────
  {
    id: "A1",
    label: "Advice — study plan",
    expected: "advice",
    body: {
      message: "How should I study for my Leaving Cert English exam? I have 3 weeks left.",
      meta: { subject: "English", level: "HL" },
    },
  },
  {
    id: "A2",
    label: "Advice — revision tips",
    expected: "advice",
    body: {
      message: "What are the best revision tips for biology?",
      meta: { subject: "Biology", level: "OL" },
    },
  },
  {
    id: "A3",
    label: "Advice — study schedule",
    expected: "advice",
    body: {
      message: "Can you make me a study schedule for the next 2 weeks before my exams?",
      meta: { subject: "All", level: "HL" },
    },
  },

  // ── PREDICTION ───────────────────────────────────────────────────────────
  {
    id: "PR1",
    label: "Prediction — grade forecast",
    expected: "prediction",
    body: {
      message: "Based on H1 in my mocks, what grade am I likely to get in the Leaving Cert?",
      meta: { subject: "Maths", level: "HL" },
    },
  },
  {
    id: "PR2",
    label: "Prediction — CAO points estimate",
    expected: "prediction",
    body: {
      message: "I'm getting B2s and B3s across my subjects. What CAO points can I expect?",
      meta: { subject: "All", level: "HL" },
    },
  },

  // ── AMBIGUOUS / EDGE ─────────────────────────────────────────────────────
  {
    id: "AM1",
    label: "Ambiguous — single word (router must decide sensibly)",
    expected: null, // any route is acceptable, just log what it picks
    body: {
      message: "Ozymandias",
      meta: { subject: "English", level: "HL" },
    },
  },
  {
    id: "AM2",
    label: "Ambiguous — grade vs exemplar (grade must win by priority)",
    expected: "grade",
    body: {
      message: "Here is my answer on Ozymandias — can you check it and also show me a model answer?\n\nPower is explored through irony in Ozymandias. Shelley presents the collapse of the statue as deeply symbolic of the inevitable decline of all rulers, no matter how mighty they once were. Furthermore, the use of the word 'despair' addressed to other powerful figures reinforces this sense of futility. The sculptor who carved the statue captured the king's 'passions' perfectly, yet even that artistic legacy crumbles. In conclusion, Shelley argues that power is always temporary and self-deception is the true legacy of tyranny.",
      meta: { subject: "English", level: "HL" },
    },
  },
  {
    id: "AM3",
    label: "Ambiguous — vague help request",
    expected: "advice",
    body: {
      message: "Help me with Irish.",
      meta: { subject: "Irish", level: "OL" },
    },
  },
];

async function runCase(tc) {
  const start = Date.now();
  try {
    const headers = { "Content-Type": "application/json" };
    if (TOKEN) headers["Authorization"] = `Bearer ${TOKEN}`;

    const res = await fetch(BASE, {
      method: "POST",
      headers,
      body: JSON.stringify(enrichBody(tc.body)),
    });

    const elapsed = Date.now() - start;
    const json = await res.json();
    const route = (json.type ?? json.route ?? "unknown").toLowerCase();
    const confidence = json.decision?.confidence ?? "?";
    const reasons = json.decision?.reasons ?? "";

    const pass = tc.expected === null || route === tc.expected;

    const status = pass
      ? `${GREEN}✓ PASS${RESET}`
      : `${RED}✗ FAIL${RESET}`;

    const expected = tc.expected ?? "(any)";
    const routeColour = pass ? GREEN : RED;

    console.log(
      `${status} [${CYAN}${tc.id}${RESET}] ${tc.label}\n` +
      `       Got: ${routeColour}${route}${RESET} | Expected: ${expected} | Confidence: ${confidence} | ${elapsed}ms\n` +
      `       Reason: ${YELLOW}${reasons}${RESET}\n`
    );

    return { id: tc.id, pass, route, expected: tc.expected, confidence, elapsed };
  } catch (err) {
    const elapsed = Date.now() - start;
    console.log(`${RED}✗ ERROR${RESET} [${CYAN}${tc.id}${RESET}] ${tc.label}\n       ${err.message}\n`);
    return { id: tc.id, pass: false, route: "error", expected: tc.expected, confidence: 0, elapsed };
  }
}

async function main() {
  console.log(`\n${BOLD}═══════════════════════════════════════════════════${RESET}`);
  console.log(`${BOLD}  StudyBot Router Test Suite — ${cases.length} cases${RESET}`);
  console.log(`${BOLD}  Target: ${BASE}${RESET}`);
  if (!TOKEN) {
    console.log(`${RED}  ⚠ No auth token — requests will return 401 Unauthorized${RESET}`);
    console.log(`${YELLOW}  Usage: node test_router.mjs <firebase-id-token>${RESET}`);
  } else {
    console.log(`${GREEN}  Auth token: present (${TOKEN.slice(0, 20)}...)${RESET}`);
  }
  console.log(`${BOLD}═══════════════════════════════════════════════════${RESET}\n`);

  const results = [];

  // Run sequentially to avoid hammering Lambda cold starts
  for (const tc of cases) {
    const r = await runCase(tc);
    results.push(r);
  }

  // Summary
  const passed  = results.filter(r => r.pass).length;
  const failed  = results.filter(r => !r.pass).length;
  const avgMs   = Math.round(results.reduce((s, r) => s + r.elapsed, 0) / results.length);

  console.log(`${BOLD}═══════════════════════════════════════════════════${RESET}`);
  console.log(`${BOLD}  Results: ${GREEN}${passed} passed${RESET}  ${failed > 0 ? RED : ""}${failed} failed${RESET}  |  Avg latency: ${avgMs}ms`);

  if (failed > 0) {
    console.log(`\n${RED}  Failed cases:${RESET}`);
    results.filter(r => !r.pass).forEach(r => {
      console.log(`    [${r.id}]  got "${r.route}"  expected "${r.expected}"`);
    });
  }
  console.log(`${BOLD}═══════════════════════════════════════════════════${RESET}\n`);
}

main();
