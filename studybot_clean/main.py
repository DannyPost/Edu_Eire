# functions/main.py
# -----------------------------------------------------------
# Firebase / Cloud Functions Gen 2  •  Python 3.12
# FastAPI endpoint that streams LangChain output to Study-Bot
# -----------------------------------------------------------

import os, json
from typing import AsyncGenerator
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware

from firebase_admin import auth, initialize_app, credentials

# —— LangChain imports ——————————————————————————————
from langchain.chat_models import ChatOpenAI          # swap for your own chain
from langchain.schema import HumanMessage
# -----------------------------------------------------------

# 1️⃣  Firebase Admin initialisation (verifies ID-tokens)
cred_json = os.getenv("FIREBASE_CREDS_JSON")          # secret injected at deploy
if not cred_json:
    raise RuntimeError("FIREBASE_CREDS_JSON secret is missing")
initialize_app(credentials.Certificate(json.loads(cred_json)))

# 2️⃣  Build/choose your chain
openai_key = os.getenv("OPENAI_API_KEY")              # secret injected at deploy
if not openai_key:
    raise RuntimeError("OPENAI_API_KEY secret is missing")

# Simple LLM for now — later replace with EnglishSubjectChain()
llm = ChatOpenAI(
    model       = "gpt-4o-mini",
    temperature = 0.4,
    streaming   = True,
    openai_api_key = openai_key,
)

# 3️⃣  FastAPI app (Functions Gen 2 detects `app`)
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],                 # tighten for production
    allow_methods=["POST"],
    allow_headers=["Authorization", "Content-Type"],
)

# 4️⃣  Verify Firebase ID-token
async def verify_id_token(id_token: str) -> str:
    try:
        return auth.verify_id_token(id_token)["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")

# 5️⃣  HTTP endpoint  POST /studybot
@app.post("/studybot")
async def studybot(request: Request):
    body   = await request.json()
    prompt = (body.get("prompt") or "").strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="`prompt` required")

    # — Auth —
    id_token = request.headers.get("Authorization", "").removeprefix("Bearer ").strip()
    uid      = await verify_id_token(id_token)

    # — Build chain input —
    user_msg = HumanMessage(content=prompt, additional_kwargs={"uid": uid})

    # — Stream LangChain chunks back to the client —
    async def gen() -> AsyncGenerator[str, None]:
        async for chunk in llm.astream(user_msg):
            if chunk.content:
                yield chunk.content

    return StreamingResponse(gen(), media_type="text/plain")

# For local testing (python main.py)
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8081, reload=True)
