# SafeScan — Requisitos Funcionales y Protocolo OBD

**SafeScan** es una aplicación móvil Flutter para diagnóstico vehicular inteligente. Conecta al vehículo mediante un adaptador **OBD-II WiFi** (chip ELM327), lee datos en vivo y códigos de falla (DTC), y los presenta con severidad y recomendaciones en español.

---

## 1. Requisitos funcionales

### 1.1 Conexión al adaptador OBD

| ID | Requisito | Estado |
|----|-----------|--------|
| RF-01 | El usuario debe poder conectar el teléfono a la red WiFi del adaptador OBD-II. | ✅ Implementado (Android) |
| RF-02 | La app debe escanear redes WiFi disponibles y permitir seleccionar la del adaptador. | ✅ Implementado (Android, `wifi_scan`) |
| RF-03 | La app debe detectar automáticamente la IP del adaptador en la red local. | ✅ Implementado |
| RF-04 | La app debe establecer comunicación TCP con el adaptador en los puertos 35000 o 23. | ✅ Implementado |
| RF-05 | La app debe mostrar estados de conexión claros: conectando, inicializando, conectado, error. | ✅ Implementado |
| RF-06 | La app debe mostrar mensajes de error amigables en español ante fallos de conexión. | ✅ Implementado |
| RF-07 | Conexión vía Bluetooth/BLE al adaptador OBD. | ❌ No implementado (solo permisos en manifest) |

### 1.2 Lectura de datos del vehículo en tiempo real

| ID | Requisito | Estado |
|----|-----------|--------|
| RF-08 | Leer RPM del motor. | ✅ Implementado |
| RF-09 | Leer temperatura del refrigerante. | ✅ Implementado |
| RF-10 | Leer velocidad del vehículo (km/h). | ✅ Implementado |
| RF-11 | Leer voltaje de batería. | ✅ Implementado |
| RF-12 | Leer carga del motor (%). | ✅ Implementado (leído, no mostrado en UI principal) |
| RF-13 | Leer temperatura de admisión de aire. | ✅ Implementado (leído, no mostrado en UI principal) |
| RF-14 | Leer posición del acelerador (%). | ✅ Implementado (leído, no mostrado en UI principal) |
| RF-15 | Leer nivel de combustible (%). | ✅ Implementado (leído, no mostrado en UI principal) |
| RF-16 | Actualizar los datos del vehículo periódicamente mientras haya conexión activa. | ✅ Implementado (cada 5 segundos) |
| RF-17 | Detectar pérdida de conexión con el adaptador y notificar al usuario. | ✅ Implementado |

### 1.3 Diagnóstico de códigos de falla (DTC)

| ID | Requisito | Estado |
|----|-----------|--------|
| RF-18 | Leer códigos DTC almacenados en la ECU del vehículo. | ✅ Implementado |
| RF-19 | Traducir códigos DTC a descripciones en lenguaje simple (español). | ✅ Implementado (~20 códigos conocidos + genérico) |
| RF-20 | Clasificar cada código por severidad: `urgent`, `medium`, `low`. | ✅ Implementado |
| RF-21 | Mostrar recomendación de acción para cada código. | ✅ Implementado |
| RF-22 | Permitir escanear códigos manualmente desde la pantalla de diagnóstico. | ✅ Implementado |
| RF-23 | Escanear códigos automáticamente al abrir el dashboard tras conectar. | ✅ Implementado |
| RF-24 | Mostrar resumen de contadores por severidad (urgente / moderado / leve). | ✅ Implementado |

### 1.4 Interfaz de usuario y navegación

| ID | Requisito | Estado |
|----|-----------|--------|
| RF-25 | Pantalla de inicio con estado de conexión OBD y accesos rápidos. | ✅ Implementado |
| RF-26 | Pantalla de conexión con flujo guiado (WiFi → detección → conexión OBD). | ✅ Implementado |
| RF-27 | Dashboard con métricas principales (RPM, temperatura, velocidad, batería). | ✅ Implementado |
| RF-28 | Pantalla de diagnóstico con tarjetas expandibles por código DTC. | ✅ Implementado |
| RF-29 | Navegación inferior con pestañas: Inicio, Diagnóstico, Historial. | ✅ Implementado |
| RF-30 | Tema visual oscuro con identidad de marca (teal). | ✅ Implementado |
| RF-31 | Banner de advertencia en dashboard si hay códigos de falla activos. | ✅ Implementado |

### 1.5 Funcionalidades planificadas (no implementadas)

| ID | Requisito | Estado |
|----|-----------|--------|
| RF-32 | Escaneo visual del tablero con cámara e IA. | 📋 Placeholder |
| RF-33 | Historial persistente de diagnósticos. | 📋 Placeholder |
| RF-34 | Integración con modelo de IA para interpretación avanzada. | 📋 Pendiente |
| RF-35 | Exportación de reportes en PDF. | 📋 Pendiente |
| RF-36 | Integración de voz. | 📋 Pendiente |
| RF-37 | State management con Riverpod. | 📋 Pendiente |

---

## 2. Pantallas y flujos de usuario

### 2.1 Inicio (`HomeScreen`)

- Muestra branding SafeScan y subtítulo "Diagnóstico inteligente".
- Tarjeta de estado OBD (conectado / sin conexión) con botón "Conectar".
- CTA principal: "¿Tu vehículo enciende alguna luz?" → navega a conexión.
- Accesos rápidos a Diagnóstico e Historial.
- Tip informativo sobre luces del tablero.

### 2.2 Conexión OBD (`ConnectionScreen`)

1. Escaneo de redes WiFi (solo Android).
2. Conexión a la red del adaptador vía código nativo Kotlin (`MethodChannel`).
3. Detección automática del adaptador (`ObdManager.scanNetwork()`).
4. Conexión e inicialización del protocolo ELM327.
5. Redirección al Dashboard al conectar con éxito.

### 2.3 Dashboard (`DashboardScreen`)

- Badge de estado "Conectado".
- RPM destacado con indicador Detenido/Normal.
- Grid: temperatura (con colores por umbral), velocidad, batería.
- Banner de advertencia si hay DTC activos.
- Acciones: "Ver códigos de falla", "Ver historial".
- Escaneo automático de DTC al abrir.

### 2.4 Diagnóstico (`DiagnosisScreen`)

- Resumen: contadores Urgente / Moderado / Leve.
- Lista de códigos DTC con tarjetas expandibles (descripción + recomendación).
- Estado vacío: "Sin códigos de falla".
- Botón "Escanear códigos" si hay conexión activa.

### 2.5 Historial (`HistoryScreen`)

- Placeholder: "Sin escaneos aún". Sin persistencia de datos.

---

## 3. Arquitectura y flujo de datos

```
┌─────────────────────────────────────────────────────────┐
│                    UI (Features)                        │
│  Home │ Connection │ Dashboard │ Diagnosis │ History    │
└──────────────────────────┬──────────────────────────────┘
                           │ ListenableBuilder
┌──────────────────────────▼──────────────────────────────┐
│                   ObdManager                            │
│  status, vehicleData, dtcCodes, polling, scanNetwork    │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│  ObdEcu          │  ObdResponseParser  │  obd_data.dart  │
│  Socket TCP      │  hex/PID/DTC parse  │  modelos        │
└──────────────────────────┬──────────────────────────────┘
                           │ AT + OBD-II (ELM327)
┌──────────────────────────▼──────────────────────────────┐
│           Adaptador OBD-II WiFi → ECU del vehículo      │
└─────────────────────────────────────────────────────────┘
```

### Componentes principales

| Componente | Archivo | Responsabilidad |
|------------|---------|-----------------|
| `ObdManager` | `lib/core/services/obd_manager.dart` | Orquestador global: estado de conexión, polling, DTC, errores |
| `ObdEcu` | `lib/core/services/obd_ecu.dart` | Socket TCP, cola de comandos, inicialización AT, lectura PIDs/DTC |
| `ObdResponseParser` | `lib/core/services/obd_response_parser.dart` | Parseo de respuestas hex, payloads PID y DTC |
| `VehicleData` / `DtcCode` | `lib/core/models/obd_data.dart` | Modelos de datos del vehículo y códigos de falla |

### Flujo de datos (escáner → UI)

1. `ConnectionScreen` conecta WiFi y llama a `ObdManager.connectToDevice(ip, port)`.
2. `ObdEcu.connect()` abre socket TCP al adaptador.
3. `ObdEcu.initialize()` ejecuta secuencia AT + verificación ECU (`0100`).
4. `ObdManager` inicia polling cada 5 s → `ObdEcu.readAllData()` → `VehicleData`.
5. `ObdManager.scanDtc()` → `ObdEcu.readDtc()` → `ObdResponseParser.dtcCodes()` → `DtcCode`.
6. Las pantallas escuchan cambios vía `ListenableBuilder(listenable: obdManager)`.

---

## 4. Protocolo OBD: ¿se hacen peticiones reales?

**Sí.** La aplicación implementa comunicación real con el adaptador OBD-II. No hay datos simulados ni mocks en la capa de comunicación.

### 4.1 Capas del protocolo

```
App (Flutter/Dart)
    ↓ Socket TCP (puerto 35000 o 23)
Adaptador WiFi (chip ELM327)
    ↓ OBD-II (CAN / ISO 9141 / KWP2000 según vehículo)
ECU del vehículo
```

- **Transporte:** `dart:io` → `Socket.connect(host, port)`.
- **Protocolo del adaptador:** comandos AT del estándar ELM327.
- **Protocolo del vehículo:** OBD-II (SAE J1979) — modos 01 (datos en vivo) y 03 (DTC almacenados).
- **Bluetooth:** no implementado en código Dart; el canal actual es exclusivamente WiFi → TCP.

### 4.2 Descubrimiento del adaptador

`ObdEcu.scanNetwork()` realiza lo siguiente:

1. Obtiene prefijos IPv4 locales (`NetworkInterface.list`).
2. Prueba IPs comunes (`192.168.0.10`, `192.168.4.1`, etc.) y derivadas del prefijo local.
3. Si no encuentra nada, escanea el rango `/24` completo (1–254).
4. Por cada IP y puerto (35000, 23): abre socket, envía `AT\r`, verifica respuesta con `OK`, `ELM` o `>`.
5. Devuelve lista de `DiscoveredDevice(ip, port)`.

### 4.3 Inicialización del adaptador (comandos AT)

Tras conectar el socket, se ejecuta esta secuencia en `ObdEcu.initialize()`:

| Orden | Comando | Propósito |
|-------|---------|-----------|
| 1 | `ATZ` | Reset del adaptador ELM327 |
| 2 | `ATE0` | Desactivar eco de comandos |
| 3 | `ATH0` | Desactivar cabeceras en respuestas |
| 4 | `ATL0` | Desactivar saltos de línea |
| 5 | `ATS0` | Desactivar espacios en respuestas hex |
| 6 | `ATAT1` | Timing adaptativo |
| 7 | `ATSP0` | Selección automática de protocolo OBD |
| 8 | `0100` | Verificar que la ECU responde (PID supported) |

Si `0100` no devuelve respuesta positiva (`41 00` en los bytes), la app lanza error: *"El adaptador responde, pero la ECU del vehículo no respondió"*.

### 4.4 Envío y recepción de comandos

Cada comando se envía así:

```dart
_connection!.write('$cmd\r');   // Comando + retorno de carro
await _connection!.flush();
// Espera hasta recibir el prompt '>' del ELM327 (timeout 2–7 s)
```

Características:

- **Cola serializada** (`_commandQueue`): un comando a la vez para evitar colisiones.
- **Buffer de recepción**: acumula bytes del socket hasta detectar el prompt `>`.
- **Timeouts**: 2 s por defecto; 3 s para `ATZ`; 7 s para `0100`.

### 4.5 Comandos OBD-II para datos en vivo (Mode 01)

| Comando enviado | PID | Dato leído | Fórmula de conversión |
|-----------------|-----|------------|----------------------|
| `010C` | 0x0C | RPM | `(A × 256 + B) / 4` |
| `0105` | 0x05 | Temp. refrigerante | `A - 40` °C |
| `010D` | 0x0D | Velocidad | `A` km/h |
| `0104` | 0x04 | Carga motor | `(A × 100) / 255` % |
| `010F` | 0x0F | Temp. admisión | `A - 40` °C |
| `0111` | 0x11 | Posición acelerador | `(A × 100) / 255` % |
| `012F` | 0x2F | Nivel combustible | `(A × 100) / 255` % |
| `0101` | 0x01 | Conteo DTC | bits bajos de A (`& 0x7F`) |
| `ATRV` | — | Voltaje batería | regex `(\d+\.?\d*)` V en respuesta |

**Ejemplo de petición/respuesta RPM:**

```
App → Adaptador:  010C\r
Adaptador → ECU:  [trama OBD-II Mode 01 PID 0C]
ECU → Adaptador:  41 0C 1A F0
Adaptador → App:  41 0C 1A F0\r\n>
App calcula:      (0x1A × 256 + 0xF0) / 4 = 1752 RPM
```

### 4.6 Lectura de códigos DTC (Mode 03)

| Comando | Modo OBD | Descripción |
|---------|----------|-------------|
| `03` | Mode 03 | Solicita códigos DTC almacenados |

**Ejemplo:**

```
App → Adaptador:  03\r
Adaptador → App:  43 01 33 00 00 00 00\r\n>
                  ↑  ↑  ↑
                  │  │  └── byte2 del DTC
                  │  └───── byte1 del DTC → P0133
                  └──────── modo 03 + cantidad de códigos
```

El parser (`ObdResponseParser.dtcCodes()`) busca el byte `0x43` y decodifica pares de bytes hasta encontrar `00 00`. `DtcCode.fromRawBytes()` traduce a formato estándar (P/C/B/U + 4 dígitos).

### 4.7 Parseo de respuestas

`ObdResponseParser` realiza:

1. Limpieza de ruido: `SEARCHING...`, `NO DATA`, `ELM327`, `OK`, etc.
2. Extracción de bytes hex con regex `[0-9A-F]{2}`.
3. Búsqueda de patrón `41 XX` para respuestas Mode 01 (XX = PID).
4. Búsqueda de byte `43` para respuestas Mode 03 (DTC).
5. Detección de errores: `NO DATA`, `UNABLE TO CONNECT`, `BUS ERROR`, `CAN ERROR`.

### 4.8 Ciclo de lectura (polling)

Tras conectar con éxito:

1. `ObdManager._startPolling()` ejecuta `readAllData()` inmediatamente.
2. `Timer.periodic` cada **5 segundos** vuelve a llamar `readAllData()`.
3. `readAllData()` envía **8 comandos secuenciales** (7 PIDs + `ATRV`).
4. Los DTC se leen por separado: al abrir Dashboard y al pulsar "Escanear códigos".

---

## 5. Requisitos no funcionales

| ID | Requisito |
|----|-----------|
| RNF-01 | Plataforma principal: Android (WiFi nativo optimizado). |
| RNF-02 | En otras plataformas, el usuario debe conectar manualmente a la red OBD. |
| RNF-03 | Timeout de conexión total: 25 segundos. |
| RNF-04 | Una única instancia de `ObdManager` compartida en toda la app. |
| RNF-05 | Mensajes de error y UI en español. |
| RNF-06 | Arquitectura por features: `features → shared → core`. |

---

## 6. Dependencias técnicas

| Paquete | Uso |
|---------|-----|
| `wifi_scan` | Escaneo de redes WiFi en Android |
| `dart:io` (Socket) | Comunicación TCP con adaptador ELM327 |
| Flutter `MethodChannel` | Conexión WiFi nativa en Android (Kotlin) |

---

## 7. Referencias de código

| Funcionalidad | Archivo |
|---------------|---------|
| Orquestación OBD | `lib/core/services/obd_manager.dart` |
| Socket + comandos AT/PID | `lib/core/services/obd_ecu.dart` |
| Parseo de respuestas | `lib/core/services/obd_response_parser.dart` |
| Modelos VehicleData / DtcCode | `lib/core/models/obd_data.dart` |
| Flujo de conexión WiFi | `lib/features/obd/connection_screen.dart` |
| Dashboard en vivo | `lib/features/obd/dashboard_screen.dart` |
| Pantalla de diagnóstico | `lib/features/diagnosis/diagnosis_screen.dart` |
