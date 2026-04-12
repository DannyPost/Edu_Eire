# HL English — Paper 1 Section I: Text A & Text B (LLM knowledge)

**Language:** When you generate or coach student-facing English, use **British English (en-GB)** and Irish LC terminology. See companion file `llm-british-english-convention.md` on the same bucket prefix.

Use when students work on **Leaving Certificate English, Higher Level, Paper 1, Section I (Comprehending)**. This section has two parts: **Question A (Text A)** and **Question B (Text B)**. They are different task types; do not answer Question B as if it were short comprehension.

**S3 prefix:** `english/hl/paper1/reading-comprehension/`  
**Upload:** `npm run upload-reading-comprehension-knowledge` from `lambda/`.

---

## Paper layout (typical HL)

| Part | Stimulus | Task type | Marks (typical) |
|------|----------|-----------|-----------------|
| **Question A** | **Text A** (unseen: non-fiction, fiction extract, or mixed) | **Short responses** — comprehension, style, inference, comparison within/between passages as asked | ~50 |
| **Question B** | **Text B** (unseen: article, speech extract, blog-style piece, etc.) | **Functional writing** — produce a specified genre (e.g. article, letter, blog, speech) **using ideas from Text B** as stimulus, not a series of comprehension answers | ~50 |

**Critical distinction for the LLM:** For **Text A**, you coach **analysis and evidence-based short answers**. For **Text B**, you coach **a single coherent piece of writing** in the genre named in the paper, **informed by** Text B (themes, arguments, tone) without copying it.

---

## Question A — Text A (comprehension)

### What examiners reward (PCLM-aligned habits)

- **Purpose:** Every sentence answers the **exact** question asked (including command words: *how*, *why*, *what impression*, *in your own words*, *give two…*).
- **Coherence:** Logical order; for multi-part questions, **mirror the paper’s structure** (i, ii, iii). Small paragraphs or clear bullets if allowed by the question.
- **Language:** Formal register; literary/linguistic terms used **accurately** (tone, imagery, contrast, rhetorical question, etc.).
- **Mechanics:** Spelling, punctuation, grammar — especially in own-words and longer parts.

### Method (coach students step-by-step)

1. **Read all parts of Question A** before deep-reading Text A, so reading is **purposeful**.
2. **Annotate** Text A lightly: tone shifts, key images, contrasts, topic sentences, any statistics or dialogue.
3. **Per sub-question:** plan 1–2 points → **embed brief quotation or tight paraphrase** → **explain the effect / implication** in the student’s own words.
4. **Inference:** Only what the passage **supports**; label uncertainty if the text is ambiguous.
5. **Style / language questions:** Name **feature + effect** (on reader / on meaning / on argument). Avoid feature-dropping without effect.
6. **Comparison (if asked):** Same criterion for both extracts (e.g. how each writer engages the reader); **balanced** treatment.
7. **Visual / multimodal (if present):** Link image, caption, layout to **purpose** and **relationship to** the written text.

### What “good” looks like

- **Precision:** Word count and mark weight respected; no essay padding.
- **Evidence:** Claim → proof from Text A → explanation.
- **Range:** Different quotations for different parts where possible.

### What to avoid

- Long uncredited copying from Text A.
- Generic praise (“effective”, “powerful”) with no textual proof.
- Inventing author biography or context not in the passage.
- Answering Question B while pretending it is Question A.

---

## Question B — Text B (functional writing from stimulus)

### What examiners reward

- **Genre:** The piece **is** the form named (e.g. opinion article, formal letter, blog, talk/speech) with appropriate **layout**, **salutation/closing** if relevant, and **register** (audience).
- **Stimulus use:** Clear engagement with **ideas, arguments, or situations** in Text B — development, reaction, extension — **not** a précis of Text B.
- **Originality and control:** Own structure, examples where appropriate, and consistent voice.
- **Same PCLM lens:** purpose (task fit), coherence, language, mechanics.

### Method (coach students step-by-step)

1. **Underline the genre and audience** in the question (e.g. “Write a blog post for young adults…”).
2. **List 3–5 sparks from Text B** (themes, claims, tensions) the student will **respond to**, not reproduce.
3. **Plan:** opening hook → 2–4 body paragraphs (each with a clear job) → conclusion with a deliberate final emphasis.
4. **Draft** in the required persona; **weave** reference to Text B **conceptually** (paraphrase / allude) unless the task asks for direct reference.
5. **Revise** for genre conventions (headline? greeting? sign-off?) and word limit if stated.

### What to avoid

- Writing another set of comprehension answers.
- Copying sentences from Text B without transformation.
- Wrong genre (e.g. essay when a speech was asked).
- Ignoring the specified audience.

---

## Quick command-word cheat sheet (Text A)

| Phrasing | Coach the student to |
|----------|----------------------|
| In your own words | Paraphrase the idea; no verbatim lift beyond necessary terms. |
| Give two effects / examples | Two **distinct** points, each evidenced. |
| How does the writer…? | Technique + effect + reference. |
| What impression…? | Trait of subject/tone + evidence. |
| Compare… | Same aspect for both texts; balanced length. |

---

## Optional exemplars on S3

If you add curated exemplars, use `reading-comprehension-exemplars-manifest.json` and keys under `english/hl/paper1/reading-comprehension/exemplars/{exemplarId}/` (only **original** or **permitted** material; respect copyright).

---

## Disclaimer

Exam papers and marking schemes change by year; always align coaching with the **exact** paper in front of the student and the **official** marking scheme where available (`english/hl/papers/` in this project where applicable).
