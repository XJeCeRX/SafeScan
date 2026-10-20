"""Backend SafeScan — chatbot con WebSocket en tiempo real y API de diagnóstico REST."""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
import json
import logging
import uuid
from typing import Any

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from chatbot import build_response, get_dtc_info

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("safescan_backend")

app = FastAPI(title="SafeScan Chat & Diagnosis API", version="1.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class BatchDiagnosisRequest(BaseModel):
    codes: list[str] = Field(default_factory=list, description="Lista de códigos DTC (ej. P0301, P0420)")
    sensors: dict[str, Any] | None = Field(default=None, description="Datos de telemetría y sensores del vehículo")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()}


@app.post("/codes/batch")
async def batch_diagnose(payload: BatchDiagnosisRequest) -> dict[str, Any]:
    """Diagnóstico en lote de códigos DTC y correlación con lecturas de sensores."""
    results: list[dict[str, Any]] = []

    for code in payload.codes:
        code_info = get_dtc_info(code)
        results.append(code_info)

    sensor_notes: list[str] = []
    sensors = payload.sensors or {}
    coolant = sensors.get("coolant_temp", 0)
    battery = sensors.get("battery_voltage", 0.0)
    rpm = sensors.get("rpm", 0)

    if coolant >= 105:
        sensor_notes.append(f"Alerta: Temperatura elevada de refrigerante ({coolant} °C).")
    if battery and battery < 12.0:
        sensor_notes.append(f"Alerta: Voltaje de batería bajo ({battery} V).")
    if rpm > 0 and coolant < 50:
        sensor_notes.append("Nota: Motor en frío.")

    return {
        "status": "ok",
        "results": results,
        "sensor_notes": sensor_notes,
        "analyzed_at": datetime.now(timezone.utc).isoformat(),
        "total_codes": len(results),
    }


@app.websocket("/ws/chat")
async def chat_ws(websocket: WebSocket) -> None:
    await websocket.accept()
    session_id = str(uuid.uuid4())
    logger.info("WebSocket client connected. Session: %s", session_id)
    await websocket.send_json({"type": "connected", "session_id": session_id})

    while True:
        try:
            raw = await websocket.receive_text()
        except WebSocketDisconnect:
            logger.info("WebSocket disconnected. Session: %s", session_id)
            break
        except Exception as exc:
            logger.warning("Error receiving websocket frame: %s", exc)
            break

        try:
            payload = json.loads(raw)
            await _handle_user_message(websocket, payload)
        except json.JSONDecodeError:
            await websocket.send_json(
                {"type": "error", "message": "Formato JSON inválido."}
            )
        except Exception as exc:  # noqa: BLE001
            logger.exception("Error processing user message: %s", exc)
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

    for index, word in enumerate(words):
        chunk = word if index == 0 else f" {word}"
        await websocket.send_json(
            {
                "type": "assistant_chunk",
                "id": assistant_id,
                "content": chunk,
            }
        )
        await asyncio.sleep(0.02)
