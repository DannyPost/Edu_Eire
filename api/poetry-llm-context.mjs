/**
 * HL unseen poetry — S3 knowledge + message assembly.
 * Must match Flutter [Constants.metaSectionUnseenPoetry].
 * IAM: s3:GetObject on english/hl/paper1/unseen-poetry/*
 */

import { GetObjectCommand } from "@aws-sdk/client-s3";

export const META_SECTION_UNSEEN_POETRY = "Unseen poetry";

const GUIDE_KEY = "english/hl/paper1/unseen-poetry/hl-unseen-poetry-llm-guide.md";
const BRITISH_KEY = "english/hl/paper1/unseen-poetry/llm-british-english-convention.md";

async function bodyToUtf8(body) {
  if (!body) return "";
  const chunks = [];
  for await (const c of body) chunks.push(c);
  return Buffer.concat(chunks).toString("utf8");
}

export async function fetchUnseenPoetryKnowledge(s3Client, bucket) {
  const [g1, g2] = await Promise.all([
    s3Client.send(new GetObjectCommand({ Bucket: bucket, Key: GUIDE_KEY })),
    s3Client.send(new GetObjectCommand({ Bucket: bucket, Key: BRITISH_KEY })),
  ]);
  return {
    guide: await bodyToUtf8(g1.Body),
    britishEnglish: await bodyToUtf8(g2.Body),
  };
}

export function isUnseenPoetrySection(meta) {
  if (!meta || typeof meta !== "object") return false;
  return meta.section === META_SECTION_UNSEEN_POETRY;
}

function defaultPoetrySystemPrompt() {
  return [
    "You coach Irish Leaving Certificate English Higher Level unseen poetry.",
    "Use British English (en-GB) and LC terminology.",
    "Do not reproduce full copyrighted poems; quote only what the student supplied.",
  ].join(" ");
}

export function buildUnseenPoetryMessages(p) {
  const system = p.systemPrompt?.trim() || defaultPoetrySystemPrompt();
  const knowledge = [
    "# HL unseen poetry — teaching guide",
    p.guide?.trim() || "",
    "",
    "# British English convention",
    p.britishEnglish?.trim() || "",
  ].join("\n");

  const parts = [];
  if (p.stimulus?.trim()) parts.push("## Poem / extract\n\n" + p.stimulus.trim());
  if (p.taskPrompt?.trim()) parts.push("## Exam question\n\n" + p.taskPrompt.trim());
  if (p.studentQuestion?.trim()) parts.push("## Student request\n\n" + p.studentQuestion.trim());
  if (p.studentDraft?.trim()) parts.push("## Student answer to review\n\n" + p.studentDraft.trim());

  const task =
    parts.length > 0
      ? parts.join("\n\n---\n\n")
      : "The student has not pasted the poem or question yet; ask them to provide it.";

  return [
    { role: "system", content: system },
    { role: "user", content: knowledge },
    { role: "user", content: task },
  ];
}
