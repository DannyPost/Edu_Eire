# backend/main.py
import json, os, asyncio
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware

from firebase_admin import auth, credentials, initialize_app
from langchain.chat_models import ChatOpenAI
from langchain.schema import HumanMessage

# ── initialise Firebase Admin ───────────────────────────────
creds_json = os.getenv("FIREBASE_CREDS_JSON")          # auto-injected secret
initialize_app(credentials.Certificate(json.loads(creds_json)))

# ── FastAPI app ─────────────────────────────────────────────
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],                 # tighten in prod
    allow_headers=["Authorization", "Content-Type"],
    allow_methods=["POST"],
)

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")           # secret

llm = ChatOpenAI(
    model="gpt-4o-mini",
    temperature=0.4,
    streaming=True,
    openai_api_key=OPENAI_API_KEY,
)

async def verify_token(id_token: str) -> str:
    """Return UID if token is valid, else 401"""
    try:
        decoded = auth.verify_id_token(id_token)
        return decoded["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")

# ── HTTP target for Cloud Function ──────────────────────────
@app.post("/studybot")
async def studybot_route(req: Request):
    body = await req.json()
    prompt = body.get("prompt", "")
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt missing")

    id_token = req.headers.get("Authorization", "").removeprefix("Bearer ").strip()
    uid = await verify_token(id_token)

    user_msg = HumanMessage(content=prompt, additional_kwargs={"uid": uid})

    async def gen():
        async for chunk in llm.astream(user_msg):
            if chunk.content:
                yield chunk.content

    return StreamingResponse(gen(), media_type="text/plain")
