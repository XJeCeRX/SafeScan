"""Backend SafeScan — chatbot con WebSocket en tiempo real."""

from __future__ import annotations

import asyncio
import json
import uuid
from typing import Any

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from chatbot import build_response

app = FastAPI(title="SafeScan Chat API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.websocket("/ws/chat")
async def chat_ws(websocket: WebSocket) -> None:
    await websocket.accept()
    session_id = str(uuid.uuid4())
    await websocket.send_json({"type": "connected", "session_id": session_id})

    try:
        while True:
            raw = await websocket.receive_text()
            payload = json.loads(raw)
            await _handle_user_message(websocket, payload)
    except WebSocketDisconnect:
        return
    except json.JSONDecodeError:
        await websocket.send_json(
            {"type": "error", "message": "Formato JSON inválido."}
        )
    except Exception as exc:  # noqa: BLE001
        await websocket.send_json(
            {"type": "error", "message": f"Error interno: {exc}"}
        )


async def _handle_user_message(
    websocket: WebSocket, payload: dict[str, Any]
) -> None:
    if payload.get("type") != "user_message":
        await websocket.send_json(
            {
                "type": "error",
                "message": "Tipo de mensaje no soportado.",
            }
        )
        return

    user_message_id = payload.get("id") or str(uuid.uuid4())
    text = (payload.get("text") or "").strip()
    sensor_data = payload.get("sensor_data")

    if not text:
        await websocket.send_json(
            {
                "type": "error",
                "message": "El mensaje de texto no puede estar vacío.",
            }
        )
        return

    assistant_id = str(uuid.uuid4())
    full_response = build_response(text, sensor_data)

    await websocket.send_json(
        {
            "type": "assistant_start",
            "id": assistant_id,
            "reply_to": user_message_id,
        }
    )

    await _stream_response(websocket, assistant_id, full_response)

    await websocket.send_json(
        {
            "type": "assistant_done",
            "id": assistant_id,
            "content": full_response,
            "reply_to": user_message_id,
        }
    )


async def _stream_response(
    websocket: WebSocket, assistant_id: str, content: str
) -> None:
    """Transmite la respuesta en fragmentos para simular streaming en tiempo real."""
    words = content.split(" ")
    buffer = ""

    for index, word in enumerate(words):
        chunk = word if index == 0 else f" {word}"
        buffer += chunk
        await websocket.send_json(
            {
                "type": "assistant_chunk",
                "id": assistant_id,
                "content": chunk,
            }
        )
        await asyncio.sleep(0.03)
