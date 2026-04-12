# Studybot API (Lambda)

Node ESM handler for API Gateway HTTP API: `GET /health`, `POST /chat`, `POST /grade`, `POST /exemplar`.

## Environment

| Variable | Required | Notes |
|----------|----------|--------|
| `OPENAI_API_KEY` | Yes (for LLM routes) | |
| `OPENAI_MODEL` | No | Default `gpt-4o-mini` |
| `EXEMPLAR_BUCKET` | No | Default `studybot-knowledge-dev` |
| `AWS_REGION` | No | Default `eu-west-1` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | No | If set, verifies `Authorization: Bearer` Firebase ID tokens |

Lambda IAM: `s3:GetObject` on `arn:aws:s3:::<EXEMPLAR_BUCKET>/english/hl/paper1/reading-comprehension/*` and `.../unseen-poetry/*`.

Upload knowledge from repo root: `cd lambda && npm run upload-reading-comprehension-knowledge && npm run upload-unseen-poetry-knowledge`.

## Build zip

```bash
cd api && npm ci && zip -r ../studybot-api.zip . -x '*.zip'
```

Set handler to `handler.handler` (file `handler.mjs`, export `handler`).

## Smoke test

```bash
export API_BASE_URL=https://YOUR_API.execute-api.eu-west-1.amazonaws.com/dev
npm run smoke
```

Optional: `export FIREBASE_BEARER=eyJ...` to test `/chat` with auth.
