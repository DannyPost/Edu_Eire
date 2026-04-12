# HL English — Unseen poetry: what the assistant should prioritise

**Language:** Use **British English (en-GB)** and Irish LC terminology in all coached or modelled answers. See `llm-british-english-convention.md` on the same bucket prefix.

Use this as system-context when students ask about **Paper 2 Section B (Unseen Poetry)** at **Higher Level**. It does not reproduce any third-party site text; pair it with your own exemplar answers in `unseen-poetry/exemplars/` if you add them.

## Exam task (typical shape)

Students read one unseen poem and answer **one** question (often with parts). They must show **close reading**: language, imagery, tone, form/structure, and **personal response** where the question asks for it.

## Recommended answer method (teach this order)

1. **Orient** — title, speaker/voice, situation in one or two sentences (no long plot summary).
2. **Thesis / line of argument** — what the poem is *doing* (emotion, idea, tension), not a list of techniques.
3. **Body paragraphs** — each centred on **one** coherent idea, supported by **short quotations** (phrase or line), with **analysis** (connotation, sound, pattern, contrast).
4. **Technique** — name devices only when they *earn marks*: imagery, metaphor/simile, sound (alliteration, rhythm, caesura), enjambment, form (stanza, sonnet, free verse), punctuation, tense, pronouns.
5. **Tone & atmosphere** — track shifts (e.g. opening vs closing stanza).
6. **Structure** — how the poem moves (turn, volta, circular return, question→answer).
7. **Personal response** (if asked) — justified reaction linked to the text, not generic praise.
8. **Conclusion** — one tight synthesis, no new quotation.

## What “good” looks like (for the model to reinforce)

- **Integration**: quote embedded in analytical sentences, not lists of quotes with bolt-on comment.
- **Specificity**: refer to *this* poem’s words, not textbook definitions only.
- **Range**: several aspects (imagery + sound + structure), not one technique repeated.
- **Clarity**: coherent paragraphs, topic sentences, logical progression.

## What to avoid

- Paraphrasing the whole poem without analysis.
- Feature-spotting (“there is a simile on line 3”) with no effect on meaning.
- Generic phrases (“creates a vivid image”) without saying *how* and *why*.
- Inventing biographical facts about the poet.

## Suggested output shapes for the LLM

- **Coaching**: checklist + paragraph plan + sample opening paragraph (original wording, not copying past papers).
- **Practice**: give a short unseen-style poem in the public domain or user-supplied, then mark-style feedback using the checklist.
- **Compare to exemplar**: if `exemplars/` contains your own notes, align student drafts to that *structure*, not to copyrighted text from commercial sites.

## Official orientation

Align skills with the **Leaving Certificate English syllabus** and SEC examination descriptors; use past papers and marking schemes you have rights to (e.g. PDFs you already store under `english/hl/papers/`).

## Knowledge bucket (Studybot)

When uploaded, this guide and related files live under **`english/hl/paper1/unseen-poetry/`** on the exemplar bucket (not under `paper2/`). Run: `npm run upload-unseen-poetry-knowledge` from `lambda/`.
