"""Generador de respuestas del chatbot SafeScan con base de conocimiento DTC."""

from __future__ import annotations

import json
import os
import re
from typing import Any

# Base de datos en memoria para códigos DTC (4,106 códigos)
_DTC_DB: dict[str, dict[str, Any]] = {}


def _load_dtc_db() -> dict[str, dict[str, Any]]:
    global _DTC_DB
    if _DTC_DB:
        return _DTC_DB

    possible_paths = [
        os.path.join(os.path.dirname(__file__), "..", "assets", "obd2_explicaciones.json"),
        os.path.join(os.path.dirname(__file__), "assets", "obd2_explicaciones.json"),
        os.path.join(os.getcwd(), "assets", "obd2_explicaciones.json"),
        os.path.join(os.getcwd(), "..", "assets", "obd2_explicaciones.json"),
    ]
    for path in possible_paths:
        normalized_path = os.path.abspath(path)
        if os.path.exists(normalized_path):
            try:
                with open(normalized_path, "r", encoding="utf-8") as file:
                    _DTC_DB = json.load(file)
                    return _DTC_DB
            except Exception:
                pass
    return {}


# Cargar base de datos al importar el módulo
_load_dtc_db()


def map_urgencia(urgencia: str | None) -> str:
    """Mapea urgencia en español ('rojo', 'amarillo', 'verde') a severidad ('urgent', 'medium', 'low')."""
    urg = (urgencia or "").strip().lower()
    if urg == "rojo":
        return "urgent"
    if urg == "verde":
        return "low"
    return "medium"


def get_dtc_info(code: str) -> dict[str, Any]:
    """Obtiene la información detallada de un código DTC desde la base de datos o por familia SAE."""
    normalized = code.strip().upper()
    db = _load_dtc_db()

    # 1. Match exacto
    if normalized in db:
        item = db[normalized]
        return {
            "code": normalized,
            "description": item.get("titulo", f"Código {normalized}"),
            "severity": map_urgencia(item.get("urgencia")),
            "recommendation": item.get("accion") or item.get("explicacion") or "Consulta a un mecánico profesional.",
            "explanation": item.get("explicacion"),
            "technical_description": item.get("descripcion_tecnica"),
            "match_type": "exact",
        }

    # 2. Match por familia SAE (primeras 3 letras, ej. P03)
    if len(normalized) >= 3:
        family_key = normalized[:3]
        for key, item in db.items():
            if key.startswith(family_key):
                return {
                    "code": normalized,
                    "description": f"Orientación por familia {family_key} — {item.get('titulo', '')}",
                    "severity": map_urgencia(item.get("urgencia")),
                    "recommendation": item.get("accion") or "No hay ficha exacta para este código. Revisa los componentes asociados o visita un taller.",
                    "explanation": f"Orientación basada en códigos similares de la familia {family_key}.\n{item.get('explicacion', '')}",
                    "technical_description": item.get("descripcion_tecnica"),
                    "match_type": "family",
                }

    # 3. Fallback genérico
    prefix = normalized[0] if normalized else "P"
    is_urgent = prefix in ("B", "C")
    return {
        "code": normalized,
        "description": f"Código de diagnóstico {normalized}",
        "severity": "urgent" if is_urgent else "medium",
        "recommendation": "Consulta el manual de servicio del fabricante o acude a un taller de confianza.",
        "explanation": "Este código no está catalogado en la base de datos local.",
        "technical_description": None,
        "match_type": "unknown",
    }


def build_response(text: str, sensor_data: dict[str, Any] | None) -> str:
    """Construye una respuesta contextual usando texto del usuario y sensores OBD."""
    normalized = text.strip().lower()
    parts: list[str] = []

    if sensor_data:
        parts.append(_format_sensor_summary(sensor_data))
    else:
        parts.append(
            "No recibí datos de sensores en este mensaje. "
            "Si conectas el adaptador OBD y activas la opción de adjuntar lecturas, "
            "puedo interpretar métricas y códigos en tiempo real."
        )

    parts.append("")
    parts.append(_answer_user_question(normalized, sensor_data))
    return "\n".join(parts)


def _format_sensor_summary(sensor_data: dict[str, Any]) -> str:
    lines = ["Contexto OBD recibido:"]

    if sensor_data.get("obd_connected"):
        adapter_ip = sensor_data.get("adapter_ip")
        if adapter_ip:
            lines.append(f"- Adaptador conectado en {adapter_ip}")
        else:
            lines.append("- Adaptador OBD conectado")
    else:
        lines.append("- Adaptador OBD no conectado")

    vehicle = sensor_data.get("vehicle") or {}
    if vehicle:
        lines.extend(
            [
                f"- RPM: {vehicle.get('rpm', 0)}",
                f"- Temperatura refrigerante: {vehicle.get('coolant_temp', 0)} °C",
                f"- Velocidad: {vehicle.get('speed', 0)} km/h",
                f"- Batería: {vehicle.get('battery_voltage', 0)} V",
                f"- Carga motor: {vehicle.get('engine_load', 0)} %",
            ]
        )

    dtc_codes = sensor_data.get("dtc_codes") or []
    if dtc_codes:
        lines.append("- Códigos DTC activos:")
        for code in dtc_codes:
            lines.append(
                f"  · {code.get('code')} ({code.get('severity')}): "
                f"{code.get('description')}"
            )
    else:
        lines.append("- Sin códigos DTC reportados en este instante")

    return "\n".join(lines)


def _answer_user_question(text: str, sensor_data: dict[str, Any] | None) -> str:
    dtc_codes = (sensor_data or {}).get("dtc_codes") or []
    vehicle = (sensor_data or {}).get("vehicle") or {}

    # 1. Saludos
    if any(token in text for token in ("hola", "buenas", "saludos", "que tal", "qué tal")):
        return (
            "Hola, soy el asistente SafeScan. "
            "Puedo ayudarte a interpretar códigos de falla, explicar síntomas del tablero "
            "y revisar las lecturas de los sensores en tiempo real."
        )

    # 2. Detección de código DTC específico en el texto del usuario (ej. P0301, P0420, C0035, etc.)
    dtc_matches = re.findall(r"\b([PCBU]\d{4})\b", text.upper())
    if dtc_matches:
        responses = []
        for code_str in dtc_matches[:2]:  # Responder hasta 2 códigos
            info = get_dtc_info(code_str)
            severity_label = "Urgente" if info["severity"] == "urgent" else ("Moderado" if info["severity"] == "medium" else "Leve")
            response = (
                f"El código {info['code']} corresponde a: {info['description']}.\n"
                f"Severidad: {severity_label}.\n"
            )
            if info.get("explanation"):
                response += f"\n¿Qué significa?: {info['explanation']}\n"
            if info.get("recommendation"):
                response += f"\nRecomendación: {info['recommendation']}"
            responses.append(response)
        return "\n\n---\n\n".join(responses)

    # 3. Pregunta general sobre códigos DTC o fallas
    if "dtc" in text or "código" in text or "codigo" in text or "falla" in text:
        if dtc_codes:
            primary = dtc_codes[0]
            info = get_dtc_info(primary.get("code", ""))
            return (
                f"Código detectado {primary.get('code')}: {info.get('description', primary.get('description'))}.\n\n"
                f"Explicación: {info.get('explanation', 'Falla reportada por la computadora de a bordo.')}\n\n"
                f"Recomendación: {info.get('recommendation', primary.get('recommendation', 'Revisar con un mecánico.'))}"
            )
        return (
            "No detecté códigos DTC en los datos recibidos. "
            "Puedes indicarme el código directamente (ej. '¿Qué es P0300?') "
            "o ejecutar un escaneo desde la pantalla de Diagnóstico."
        )

    # 4. RPM y estado del motor
    if "rpm" in text or "motor" in text:
        rpm = vehicle.get("rpm", 0)
        if rpm == 0:
            return "El motor parece estar detenido (0 RPM) según la última lectura recibida."
        if rpm < 900:
            return f"El motor está en ralentí con {rpm} RPM, dentro del rango habitual para un motor a temperatura de régimen."
        return f"El motor registra {rpm} RPM. Si notas vibraciones o tirones, conviene revisar el sistema de encendido o inyección."

    # 5. Temperatura del motor
    if "temperatura" in text or "caliente" in text or "refrigerante" in text:
        temp = vehicle.get("coolant_temp", 0)
        if temp >= 105:
            return (
                f"¡Atención! La temperatura del refrigerante ({temp} °C) es muy elevada. "
                "Detén el vehículo de forma segura tan pronto como sea posible y revisa el nivel de anticongelante y el electroventilador."
            )
        if temp >= 90:
            return f"La temperatura de operación es normal ({temp} °C, rango ideal entre 85 °C y 100 °C)."
        if temp > 0:
            return f"Temperatura actual del refrigerante: {temp} °C (el motor aún está calentando)."
        return "No tengo una lectura activa de temperatura del refrigerante. Verifica que el switch del vehículo esté en ON."

    # 6. Batería y voltaje
    if "batería" in text or "bateria" in text or "voltaje" in text:
        voltage = vehicle.get("battery_voltage", 0)
        if voltage and voltage < 12.0:
            return (
                f"El voltaje de la batería ({voltage} V) está bajo. "
                "Un valor menor a 12 V con el motor apagado indica descarga; si el motor está encendido, el alternador podría no estar cargando."
            )
        if voltage and voltage >= 13.5:
            return f"El voltaje ({voltage} V) indica que el alternador está cargando correctamente la batería."
        return f"Voltaje reportado: {voltage} V."

    return (
        "Entiendo tu consulta. Con los datos OBD adjuntos puedo ayudarte a interpretar "
        "códigos DTC (por ejemplo '¿Qué significa P0301?'), temperatura del motor, RPM y estado de batería. "
        "Cuéntame el síntoma que observas o qué luz del tablero se encendió."
    )
