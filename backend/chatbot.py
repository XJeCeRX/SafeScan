"""Generador de respuestas del chatbot SafeScan."""

from __future__ import annotations

from typing import Any


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

    if any(token in text for token in ("hola", "buenas", "saludos")):
        return (
            "Hola, soy el asistente SafeScan. "
            "Puedo ayudarte a interpretar códigos de falla y lecturas del vehículo."
        )

    if "dtc" in text or "código" in text or "codigo" in text or "falla" in text:
        if dtc_codes:
            primary = dtc_codes[0]
            return (
                f"El código {primary.get('code')} indica: {primary.get('description')}. "
                f"Recomendación: {primary.get('recommendation')}"
            )
        return (
            "No detecté códigos DTC en los datos recibidos. "
            "Ejecuta un escaneo desde Diagnóstico y vuelve a consultarme."
        )

    if "rpm" in text or "motor" in text:
        rpm = vehicle.get("rpm", 0)
        if rpm == 0:
            return "El motor parece estar detenido (0 RPM) según la última lectura."
        if rpm < 900:
            return f"El motor está en ralentí con {rpm} RPM, dentro de un rango habitual."
        return f"El motor registra {rpm} RPM. Si notas vibraciones o ruidos, conviene revisar el encendido."

    if "temperatura" in text or "caliente" in text or "refrigerante" in text:
        temp = vehicle.get("coolant_temp", 0)
        if temp >= 105:
            return (
                f"La temperatura del refrigerante ({temp} °C) está elevada. "
                "Detén el vehículo de forma segura y revisa el sistema de enfriamiento."
            )
        if temp >= 90:
            return f"Temperatura de operación normal ({temp} °C)."
        return f"Temperatura actual: {temp} °C."

    if "batería" in text or "bateria" in text or "voltaje" in text:
        voltage = vehicle.get("battery_voltage", 0)
        if voltage and voltage < 12.0:
            return (
                f"El voltaje de batería ({voltage} V) está bajo. "
                "Revisa alternador, bornes y estado de la batería."
            )
        return f"Voltaje de batería reportado: {voltage} V."

    return (
        "Entiendo tu consulta. Con los datos OBD adjuntos puedo ayudarte a interpretar "
        "códigos DTC, temperatura, RPM y voltaje. Sé más específico sobre el síntoma "
        "o la luz del tablero que observas."
    )
